/**
 * Beep on completion
 *
 * Plays a short, quiet beep when the LLM finishes responding (the agent
 * settles: it will not auto-retry, auto-compact, or continue with queued
 * follow-ups). Lets you work in another window and get a gentle nudge the
 * moment pi is done and ready for your next prompt.
 *
 * The tone is synthesized once at load time and cached in this extension's
 * directory as `beep-on-complete.wav`: a ~120 ms, low-amplitude sine wave so
 * it stays short and not-too-loud. Playback picks the best audio command the
 * platform has:
 *
 *   macOS  -> afplay
 *   Linux  -> paplay / pw-play / aplay / ffplay
 *   fallback -> terminal BEL character (subject to terminal settings)
 *
 * Written in a functional style: pure, side-effect-free transformers compose
 * into data pipelines; the only effects (file write, audio spawn, bell) live
 * at the leaf of each pipeline and take their inputs as arguments.
 *
 * Tune it by editing the constants at the top of this file, then `/reload`.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import * as childProcess from "node:child_process";

/* ------------------------------- Tuning knobs ---------------------------- */

const FREQ_HZ = 880; // Sine-wave frequency. Higher = brighter "ding".
const DURATION_MS = 120; // Beep length. Keep it short.
const FADE_MS = 12; // Fade in/out each end to avoid clicks/pops.
const AMPLITUDE = 0.2; // Peak amplitude 0..1. Lower = softer.
const SAMPLE_RATE = 44100; // WAV sample rate.
const FILE_NAME = "beep-on-complete.wav";
const ONLY_INTERACTIVE = true; // Only beep in TUI mode (skip print/json/rpc).
const DISABLED = false; // Set true to silence entirely.

/* ------------------------------ Pure functions --------------------------- */

// --- counting helpers ---
const totalSamples = (rate: number, ms: number): number =>
	Math.max(1, Math.floor((ms / 1000) * rate));

const fadeSamples = (total: number, ms: number): number =>
	Math.min(total, Math.floor((ms / 1000) * SAMPLE_RATE));

// Normalized time for the i-th sample.
const timeOf = (i: number): number => i / SAMPLE_RATE;

// Linear attack / release envelope in [0, 1].
const envelope = (i: number, total: number, fade: number): number =>
	i < fade
		? i / fade
		: i > total - fade
			? (total - i) / fade
			: 1;

// One PCM sample from its index, given the total length and fade span.
const pcm = (i: number, total: number, fade: number): number => {
	const t = timeOf(i);
	const env = envelope(i, total, fade);
	const clamped = Math.min(1, Math.max(-1, Math.sin(2 * Math.PI * FREQ_HZ * t) * AMPLITUDE * env));
	return Math.round(clamped * 32767);
};

// Build the PCM sample buffer (Int16Array) for a tone.
const samplesBuffer = (
	rate: number,
	ms: number,
	fadeMs: number,
): Int16Array => {
	const total = totalSamples(rate, ms);
	const fade = fadeSamples(total, fadeMs);
	return Int16Array.from({ length: total }, (_, i) => pcm(i, total, fade));
};

// --- WAV header construction ---
const le16 = (n: number): [number, number] => [n & 0xff, (n >> 8) & 0xff];
const le32 = (n: number): [number, number, number, number] => [
	n & 0xff,
	(n >> 8) & 0xff,
	(n >> 16) & 0xff,
	(n >> 24) & 0xff,
];

// Header bytes for a mono PCM WAV with the given data byte length.
const wavHeader = (dataSize: number, rate: number): number[] => [
	..."RIFF".split("").map(charCode),
	...le32(36 + dataSize),
	..."WAVE".split("").map(charCode),
	..."fmt ".split("").map(charCode),
	...le32(16), // fmt chunk size
	...le16(1), // PCM
	...le16(1), // mono
	...le32(rate),
	...le32(rate * 2), // byte rate
	...le16(2), // block align
	...le16(16), // bits per sample
	..."data".split("").map(charCode),
	...le32(dataSize),
];

const charCode = (c: string): number => c.charCodeAt(0);

// Merge byte-array segments (numbers, number[]s, or Buffers) into one Buffer.
const concatBytes = (parts: Array<number | number[] | Buffer>): Buffer =>
	Buffer.concat(
		parts.map((p) => {
			if (typeof p === "number") return Buffer.from([p]);
			if (Array.isArray(p)) return Buffer.from(p);
			return p;
		}),
	);

// Full WAV file bytes for a configured tone.
const wavBytes = (rate: number, ms: number, fadeMs: number): Buffer => {
	const body = Buffer.from(samplesBuffer(rate, ms, fadeMs).buffer);
	return concatBytes([wavHeader(body.length, rate), body]);
};

// --- platform-aware playback command selection ---
type Player = { command: string; args: string[] };
const playerForPlatform = (platform: NodeJS.Platform): Player[] => {
	const players: Record<string, Player[]> = {
		darwin: [{ command: "afplay", args: [] }],
		win32: [
			{ command: "powershell", args: ["-c", "(New-Object Media.SoundPlayer 'X').PlaySync()"] },
		],
		linux: [
			{ command: "paplay", args: [] },
			{ command: "pw-play", args: [] },
			{ command: "aplay", args: ["-q"] },
		],
	};
	return players[platform] ?? players.linux;
};

/* ------------------------- Effectful leaf functions ---------------------- */

// Write the silence-cached WAV if it is missing or empty, and return the path.
const ensureWav = (file: string, bytes: Buffer): string => {
	const size = safeStatSize(file);
	if (size === 0) fs.writeFileSync(file, bytes);
	return file;
};

// Spawn the platform's audio player with the WAV; fire and forget.
const playWith = (player: Player, file: string): void => {
	childProcess.spawn(player.command, [...player.args, file], {
		stdio: "ignore",
		detached: true,
	}).unref();
};

// Ring the terminal bell character as a last-resort fallback.
const ringBell = (): void => {
	try {
		process.stdout.write("\x07");
	} catch {
		/* give up silently */
	}
};

// Stat a file's size without throwing; returns 0 for missing/unreadable.
const safeStatSize = (file: string): number => {
	try {
		return fs.existsSync(file) && fs.statSync(file).size > 0 ? fs.statSync(file).size : 0;
	} catch {
		return 0;
	}
};

/* ------------------------------- Extension ------------------------------- */

export default function (pi: ExtensionAPI) {
	if (DISABLED) return;

	const file = path.join(__dirname, FILE_NAME);

	// Compose the full pipeline once at load time: bytes -> cached file path.
	// A write failure is tolerated (it falls back to lazy on first beep).
	try {
		ensureWav(file, wavBytes(SAMPLE_RATE, DURATION_MS, FADE_MS));
	} catch {
		/* fall back to generating the file on first beep */
	}

	const beep = (): void => {
		try {
			const player = playerForPlatform(os.platform())[0];
			playWith(player, ensureWav(file, wavBytes(SAMPLE_RATE, DURATION_MS, FADE_MS)));
		} catch {
			ringBell();
		}
	};

	pi.on("agent_settled", (_event, ctx) => {
		if (ONLY_INTERACTIVE && !ctx.hasUI) return;
		beep();
	});
}
