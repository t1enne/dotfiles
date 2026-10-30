/**
 * Mask secret values in tool output.
 *
 * A tool call "triggers" when it touches a path matched by a `.piignore`
 * pattern, or runs a command that dumps the environment / expands a
 * secret-named variable. Nothing is blocked: the call runs, then every
 * secret-looking value in the returned text is replaced with `*`. Keys and
 * names stay visible so the agent can still reason about structure.
 *
 * Rule sources, later wins (so a local `!` un-ignores a global pattern):
 *   1. $PI_HOME/.piignore       (default ~/.pi/.piignore)
 *   2. $PI_HOME/agent/.piignore
 *   3. .piignore in every ancestor of cwd, root -> cwd
 *
 * No patterns are baked in here: what gets masked is declared by the
 * `.piignore` files themselves. No global file means no path rules at all --
 * only the env-dump / `$SECRET` command heuristics remain.
 *
 * Known limit: detection is a heuristic over command strings and tool paths.
 * A hard guarantee needs a container whose bind mount omits the secrets.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { ImageContent, TextContent } from "@earendil-works/pi-ai";

type ContentPart = TextContent | ImageContent;

/** Minimum mask width, so short secrets do not leak their length. */
const MIN_MASK_WIDTH = 8;

/** Variable / key names that look secret-bearing. */
const SENSITIVE_NAME =
  /(key|token|secret|passw(or)?d|credential|auth|session|cookie|private|salt|signature|dsn|conn(ection)?_?str)/i;

/** Tools whose path arguments are checked against the ignore rules. */
const PATH_TOOLS = new Set(["read", "grep", "find", "ls"]);

// ---------------------------------------------------------------------------
// Ignore rules
// ---------------------------------------------------------------------------

type Rule = {
  re: RegExp;
  negate: boolean;
  source: string;
};

type CachedRules = { mtimeMs: number; size: number; rules: Rule[] };

/** Translate gitignore-ish glob syntax into a regex source fragment. */
function globToRegexSource(glob: string): string {
  let re = "";
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i]!;
    if (c === "*") {
      if (glob[i + 1] === "*") {
        i += 1;
        if (glob[i + 1] === "/") {
          i += 1;
          re += "(?:.*/)?"; // `**/` = zero or more directories
        } else {
          re += ".*"; // trailing `**` swallows the rest
        }
      } else {
        re += "[^/]*";
      }
    } else if (c === "?") {
      re += "[^/]";
    } else if (c === "[") {
      const end = glob.indexOf("]", i + 1);
      if (end === -1) {
        re += "\\[";
      } else {
        let body = glob.slice(i + 1, end);
        if (body.startsWith("!")) body = "^" + body.slice(1);
        re += "[" + body.replace(/\\/g, "\\\\") + "]";
        i = end;
      }
    } else {
      re += c.replace(/[.+^${}()|\\\]]/g, "\\$&");
    }
  }
  return re;
}

/**
 * Compile one ignore line. Returns null for blank lines and unparseable
 * patterns so a typo cannot take down the whole rule set.
 */
function compileRule(pattern: string, source: string): Rule | null {
  let p = pattern.trim();
  if (p.length === 0) return null;

  const negate = p.startsWith("!");
  if (negate) p = p.slice(1).trim();
  if (p.length === 0) return null;

  // Trailing `/` marks a directory; the `(/.*)?$` tail covers its contents.
  const dirOnly = p.endsWith("/");
  if (dirOnly) p = p.replace(/\/+$/, "");

  // A slash anywhere means the pattern is anchored to the matched path;
  // otherwise it matches a basename at any depth.
  const anchored = p.startsWith("/") || p.includes("/");
  if (p.startsWith("/")) p = p.slice(1);

  const body = globToRegexSource(p);
  const core = anchored ? `^${body}` : `(^|/)${body}`;
  try {
    return { re: new RegExp(core + "(/.*)?$"), negate, source };
  } catch {
    return null;
  }
}

function parseIgnoreFile(file: string): Rule[] {
  let text: string;
  try {
    text = fs.readFileSync(file, "utf8");
  } catch {
    return [];
  }
  const rules: Rule[] = [];
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (line.length === 0 || line.startsWith("#")) continue;
    const rule = compileRule(line, file);
    if (rule) rules.push(rule);
  }
  return rules;
}

/** Parsed rules keyed by file, invalidated on mtime/size change. */
const rulesCache = new Map<string, CachedRules>();

function rulesFor(file: string): Rule[] {
  let st: fs.Stats;
  try {
    st = fs.statSync(file);
  } catch {
    rulesCache.delete(file); // file disappeared: drop its stale rules
    return [];
  }
  if (!st.isFile()) return [];

  const hit = rulesCache.get(file);
  if (hit && hit.mtimeMs === st.mtimeMs && hit.size === st.size) {
    return hit.rules;
  }
  const rules = parseIgnoreFile(file);
  rulesCache.set(file, { mtimeMs: st.mtimeMs, size: st.size, rules });
  return rules;
}

function globalIgnoreFiles(): string[] {
  const piHome = process.env.PI_HOME || path.join(os.homedir(), ".pi");
  return [
    path.join(piHome, ".piignore"),
    path.join(piHome, "agent", ".piignore"),
  ];
}

/** `.piignore` from filesystem root down to cwd, so local rules win last. */
function localIgnoreFiles(cwd: string): string[] {
  const dirs: string[] = [];
  let dir = path.resolve(cwd || process.cwd());
  for (;;) {
    dirs.push(dir);
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return dirs.reverse().map((d) => path.join(d, ".piignore"));
}

function currentRules(cwd: string): Rule[] {
  const rules: Rule[] = [];
  for (const file of [...globalIgnoreFiles(), ...localIgnoreFiles(cwd)]) {
    rules.push(...rulesFor(file));
  }
  return rules;
}

function toSlashes(p: string): string {
  return p.replace(/\\/g, "/");
}

/**
 * Returns the source file of the last rule that matched and did not negate,
 * or null when the path is not ignored. Last match wins, mirroring gitignore.
 */
function isIgnored(target: string, cwd: string, rules: Rule[]): string | null {
  const base = cwd || process.cwd();
  const candidates = [
    toSlashes(path.resolve(base, target)),
    toSlashes(path.relative(base, target)),
    toSlashes(target),
  ];

  let matchedBy: string | null = null;
  for (const rule of rules) {
    if (!candidates.some((c) => rule.re.test(c))) continue;
    matchedBy = rule.negate ? null : rule.source;
  }
  return matchedBy;
}

// ---------------------------------------------------------------------------
// Value and line masking
// ---------------------------------------------------------------------------

// KEY=value / export KEY=value, value may be quoted.
const ASSIGN_RE = /^(\s*(?:export\s+)?)([A-Za-z_][A-Za-z0-9_]*)(\s*=\s*)(.*)$/;

// "name": "value" / 'name': 'value'. Not line-anchored: one JSON line can
// hold several pairs, and only the sensitive ones may be masked.
const QUOTED_PAIR_RE =
  /(?<q1>["']?)(?<name>[A-Za-z_][\w.-]*)\k<q1>(\s*[:=]\s*)(?<q2>["'])(?<val>(?:\\.|(?!\k<q2>).)*)\k<q2>/g;

// Unquoted YAML/ini form: `name: value` consumes the rest of the line.
const UNQUOTED_PAIR_RE = /^(\s*(?:-\s+)?)([A-Za-z_][\w.-]*)(\s*:\s+)(\S.*)$/;

// `name=value` anywhere in a line (.npmrc `//host/:_authToken=...`).
const INLINE_ASSIGN_RE = /([A-Za-z_][\w.-]*)(\s*=\s*)([^\s"'#]+)/g;

const starRun = (width: number): string =>
  "*".repeat(Math.max(width, MIN_MASK_WIDTH));

const isAlreadyMasked = (value: string): boolean => /^\*+$/.test(value);

/**
 * Mask a single value, preserving surrounding quotes so the output still
 * parses. Returns null when there is nothing to hide.
 */
function maskValue(rawValue: string): string | null {
  const trimmed = rawValue.trim();
  if (trimmed.length === 0 || isAlreadyMasked(trimmed)) return null;

  const quoted = /^(['"])((?:\\.|(?!\1).)*)\1$/.exec(trimmed);
  const inner = quoted ? quoted[2] : trimmed;
  if (inner.length === 0) return null;

  const masked = starRun(inner.length);
  return quoted ? `${quoted[1]}${masked}${quoted[1]}` : masked;
}

function maskLine(line: string): string {
  // 1. Quoted key/value pairs anywhere on the line (JSON, quoted YAML).
  let out = line.replace(QUOTED_PAIR_RE, (match, q1, name, sep, q2, value) => {
    if (!SENSITIVE_NAME.test(name)) return match;
    const masked = maskValue(`${q2}${value}${q2}`);
    return masked === null ? match : `${q1}${name}${q1}${sep}${masked}`;
  });

  // 2. A whole-line assignment. Reaching this point already required a rule
  // match, so every assignment is masked, not just sensitive-looking names.
  const assign = ASSIGN_RE.exec(out);
  if (assign) {
    const [, prefix, name, eq, rawValue] = assign;
    const masked = maskValue(rawValue);
    return masked === null ? out : `${prefix}${name}${eq}${masked}`;
  }

  // 3. Sensitive `name=value` embedded mid-line (.npmrc, query strings).
  out = out.replace(INLINE_ASSIGN_RE, (match, name, eq, value) => {
    if (!SENSITIVE_NAME.test(name)) return match;
    if (isAlreadyMasked(value)) return match;
    return `${name}${eq}${starRun(value.length)}`;
  });

  // 4. Unquoted `name: value`, sensitive names only.
  const pair = UNQUOTED_PAIR_RE.exec(out);
  if (pair) {
    const [, prefix, name, sep, rawValue] = pair;
    if (!SENSITIVE_NAME.test(name)) return out;
    const masked = maskValue(rawValue);
    return masked === null ? out : `${prefix}${name}${sep}${masked}`;
  }

  return out;
}

/**
 * Mask every non-whitespace char. Used for whole-output triggers, where the
 * output is a bare value with no key to anchor on.
 */
const maskAll = (text: string): string => text.replace(/\S/g, "*");

function maskContent(
  content: ContentPart[],
  whole: boolean,
): { content: ContentPart[]; masked: boolean } {
  let masked = false;

  const out = content.map((part) => {
    if (!part || part.type !== "text") return part;

    if (whole) {
      const maskedText = maskAll(part.text);
      if (maskedText !== part.text) masked = true;
      return { ...part, text: maskedText };
    }

    const maskedText = part.text
      .split("\n")
      .map((line) => {
        const scrubbed = maskLine(line);
        if (scrubbed !== line) masked = true;
        return scrubbed;
      })
      .join("\n");
    return { ...part, text: maskedText };
  });

  return { content: out, masked };
}

// ---------------------------------------------------------------------------
// Trigger detection
// ---------------------------------------------------------------------------

/** What caused a call to be masked, and whether the whole output goes. */
type Trigger = { label: string; whole: boolean };

/**
 * Commands that print the whole environment. Anchored to command position so
 * a filename like `.env` or `prod.env` does not trip it -- those are handled by
 * the ignore-pattern rules instead.
 */
const ENV_DUMP_RE =
  /(^|[;&|]\s*)((sudo|command|exec|xargs)\s+)*(env|printenv)\b|\bexport\s+-p\b|\bdeclare\s+-x\b|\bset\s+-o\s+posix\b/;

/** Split a shell command line into rough tokens, keeping quoting intact. */
function tokenize(cmd: string): string[] {
  const re =
    /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`|\$(?:\([^)]*\)|\{[^}]*\}|[A-Za-z_][A-Za-z0-9_]*)|\S+/g;
  return cmd.match(re) ?? [];
}

const unquote = (token: string): string => token.replace(/^['"`]|['"`]$/g, "");

/** Tools can pass a bare variable name; the expansion yields the raw secret. */
const SECRET_VAR_RE = /^\$(?:\{)?([A-Za-z_][A-Za-z0-9_]*)/;

function commandTouchesSecret(cmd: string, cwd: string): Trigger | null {
  if (ENV_DUMP_RE.test(cmd)) {
    return { label: "environment dump command", whole: false };
  }

  let rules: Rule[] | null = null; // load lazily: most tokens are not paths
  for (const raw of tokenize(cmd)) {
    const tok = unquote(raw);

    const variable = SECRET_VAR_RE.exec(tok);
    if (variable && SENSITIVE_NAME.test(variable[1]!)) {
      return { label: `$${variable[1]}`, whole: true };
    }

    if (tok.includes("/proc/") && tok.includes("environ")) {
      return { label: "/proc/*/environ", whole: false };
    }

    // Skip flags and obvious non-paths.
    if (tok.startsWith("-")) continue;
    if (!/[./]/.test(tok) && !tok.includes("*")) continue;

    const hit = isIgnored(tok, cwd, rules ?? (rules = currentRules(cwd)));
    if (hit) return { label: hit, whole: false };
  }
  return null;
}

/** Tool input is `unknown`; coerce exactly like a shell string would. */
const commandOf = (input: Record<string, unknown>): string =>
  input.command === undefined || input.command === null
    ? ""
    : String(input.command);

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.length > 0;
}

function pathArguments(input: Record<string, unknown>): string[] {
  const out: string[] = [];
  if (isNonEmptyString(input.path)) out.push(input.path);
  if (Array.isArray(input.paths)) {
    for (const p of input.paths) if (isNonEmptyString(p)) out.push(p);
  }
  return out;
}

function pathTouchesSecret(
  input: Record<string, unknown>,
  cwd: string,
): Trigger | null {
  const rules = currentRules(cwd);
  for (const p of pathArguments(input)) {
    const hit = isIgnored(p, cwd, rules);
    if (hit) return { label: hit, whole: false };
  }
  return null;
}

// ---------------------------------------------------------------------------
// Extension wiring
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // toolCallId -> why it was flagged; consumed by the matching tool_result.
  const pending = new Map<string, Trigger>();

  pi.on("tool_call", (event, ctx) => {
    const cwd = process.cwd();
    const input = (event.input ?? {}) as Record<string, unknown>;

    let hit: Trigger | null = null;
    if (PATH_TOOLS.has(event.toolName)) {
      hit = pathTouchesSecret(input, cwd);
    }
    if (event.toolName === "bash") {
      hit = commandTouchesSecret(commandOf(input), cwd);
    }
    if (!hit) return undefined;

    pending.set(event.toolCallId, hit);
    if (ctx.hasUI) {
      ctx.ui.notify(`Masking secret values (matched: ${hit.label})`, "warning");
    }
    return undefined;
  });

  pi.on("tool_result", (event, ctx) => {
    const detected = pending.get(event.toolCallId);
    pending.delete(event.toolCallId);
    if (!detected) return undefined;

    const { content, masked } = maskContent(event.content, detected.whole);
    if (!masked) return undefined;

    if (ctx.hasUI) {
      ctx.ui.notify(
        `Masked secret values (matched: ${detected.label})`,
        "warning",
      );
    }
    return { content };
  });
}
