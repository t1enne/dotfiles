/**
 * Mask .env output
 *
 * Detects whenever a command/tool attempts to READ a `.env*` file (e.g.
 * `cat .env`, `read: .env.local`, `grep TOKEN .env`). Instead of blocking,
 * it lets the command run but masks every env value in the returned output,
 * replacing the value portion (`KEY=secret`) with a run of `*`
 * (`KEY=****************`). Key names are preserved so the model still sees
 * *what* variables exist, but never the secret values.
 *
 * Masking is applied to both the `bash` tool result and the file-reading tools
 * (`read`, `grep`, `find`, `ls`) whose output contains env assignment lines.
 *
 * Notes/limits:
 * - Matches by basename so it works from any cwd. Could FP-match a
 *   non-secret file named e.g. `not.env.example` — rename if that's a false
 *   positive.
 * - Detection of *whether to mask* is a heuristic on the command string and
 *   tool paths. Hard guarantees run pi in a container with a bind mount that
 *   omits .env files.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { ImageContent, TextContent } from "@earendil-works/pi-ai";

type ContentPart = TextContent | ImageContent;

const ENV_BASENAME = /^\.env($|\.)/;

function isEnvPath(p: unknown): boolean {
	if (typeof p !== "string" || p.length === 0) return false;
	const base = p.replace(/\\/g, "/").split("/").pop() ?? "";
	return ENV_BASENAME.test(base); // ".env", ".env.local", ".env.production", ...
}

// Split a shell-ish line into tokens, respecting single/double quotes.
function tokenize(cmd: string): string[] {
	const re =
		/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`|\$(?:\([^)]*\)|[A-Za-z_][A-Za-z0-9_]*)|\S+/g;
	return cmd.match(re) ?? [];
}

// Assignment pattern: optional export prefix, a NAME, optional spaces around `=`,
// then a value (possibly quoted). The captured value may be empty.
const ASSIGN_RE =
	/^(\s*(?:export\s+)?)([A-Za-z_][A-Za-z0-9_]*)(\s*=\s*)(.*)$/;

// Mask the value of one env-style assignment line.
//   KEY=secret      -> KEY=********
//   KEY="secret"    -> KEY="********"
//   KEY='s e c r e t' -> KEY='********'
//   export KEY=v    -> export KEY=*
// Non-assignment lines are returned unchanged.
function maskAssignment(line: string): string {
	const m = ASSIGN_RE.exec(line);
	if (!m) return line; // not an env assignment
	const [, prefix, name, eq, rawValue] = m;

	// Determine the surrounding quote char (if any) and whether the value is
	// truly empty (KEY=) which should stay empty rather than become a secret.
	const quoteMatch = /^(['"])((?:\\.|[^'\\])*)\1$/.exec(rawValue.trim());
	const quoted = quoteMatch ? quoteMatch[1] : null;
	const inner = quoteMatch ? quoteMatch[2] : rawValue.trim();

	// Empty value, or value is a single `*` already — leave as-is.
	if (inner.length === 0 || inner === "*") return line;

	// Replace every non-whitespace char of the value with `*`. Preserve any
	// trailing comment / quote token separately? Keep simple: mask the whole value.
	const masked = "*".repeat(Math.max(inner.replace(/\s/g, "*").length, 1));

	const display = quoted ? `${quoted}${masked}${quoted}` : masked;
	return `${prefix}${name}${eq}${display}`;
}

// Scrub every text content part of env assignment values.
// Returns the scrubbed content and whether any value was actually masked.
function maskContent(
	content: ContentPart[],
): { content: ContentPart[]; masked: boolean } {
	let maskedLines = 0;
	const out = content.map((part) => {
		if (!part || part.type !== "text") return part;
		const maskedText = part.text
			.split("\n")
			.map((line) => {
				const scrubbed = maskAssignment(line);
				if (scrubbed !== line) maskedLines += 1;
				return scrubbed;
			})
			.join("\n");
		return { ...part, text: maskedText };
	});
	return { content: out, masked: maskedLines > 0 };
}

export default function (pi: ExtensionAPI) {
	// toolCallId -> the .env path detected, for the matching tool_result.
	const maskedCalls = new Map<string, string>();

	pi.on("tool_call", (event, ctx) => {
		let hit: string | null = null;

		// File-reading/writing tools: check their path args.
		if (
			event.toolName === "read" ||
			event.toolName === "grep" ||
			event.toolName === "find" ||
			event.toolName === "ls"
		) {
			const paths = [event.input?.path, event.input?.paths].filter(Boolean);
			const found = paths.find(isEnvPath);
			if (found) hit = found;
		}

		if (event.toolName === "bash") {
			const cmd = String(event.input?.command ?? "");
			const tok = tokenize(cmd);
			const found = tok
				.map((t) => t.replace(/^['"`]|['"`]$/g, ""))
				.filter(isEnvPath);
			if (found[0]) hit = found[0];
		}

		if (hit) {
			// Same toolCallId flows into tool_result; remember to scrub it.
			maskedCalls.set(event.toolCallId, hit);
			if (ctx.hasUI) {
				ctx.ui.notify(`Masking env values from .env output: ${hit}`, "warning");
			}
		}
		return undefined;
	});

	pi.on("tool_result", (event, ctx) => {
		// Only scrub output for a tool call we detected as reading a .env file.
		const detected = maskedCalls.get(event.toolCallId);
		maskedCalls.delete(event.toolCallId);
		if (!detected) return undefined;

		const { content, masked } = maskContent(event.content);
		if (!masked) return undefined;

		if (ctx.hasUI) {
			ctx.ui.notify(`Masked env values from .env output: ${detected}`, "warning");
		}
		return { content };
	});
}
