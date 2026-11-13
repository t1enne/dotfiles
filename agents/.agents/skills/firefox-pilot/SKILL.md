---
name: firefox-pilot
description: Pilot Firefox through geckodriver — either attach to the user's running window (real logins, cookies, tabs, extensions) or open a new Firefox window and attach to it. The mode is a mandatory user choice, never defaulted. Use when the user wants to drive Firefox with batched actions and compact reads — clicking, filling forms, navigating, scraping, or testing a page. Triggers include "use my Firefox", "drive the running browser", "attach geckodriver", "pilot firefox", "open a Firefox window", "automate my browser session".
allowed-tools: Bash(ffpilot:*), Bash(geckodriver:*), Bash(firefox:*), Bash(python3:*)
---

# Firefox Pilot

`scripts/ffpilot` drives Firefox over Marionette through geckodriver, then exposes one thin CLI. Two modes, chosen by the user every time:

- **connect** — attach to the live window: session state, tabs, logins, extensions survive, nothing re-launched.
- **new-window** — ask Firefox for a fresh window (spawning Firefox with `--marionette` when nothing is listening), then attach.

Run it as `scripts/ffpilot` from this skill directory, or put it on PATH:

```bash
ln -s "$(pwd)/scripts/ffpilot" ~/.local/bin/ffpilot
```

## Mandatory first step — user picks the mode

There is **no default**. Never run `start` until the user chooses one:

| Mode | Command | Meaning |
|---|---|---|
| Connect | `ffpilot start --connect` | Attach to the Firefox window already open. Fails loudly if nothing speaks Marionette on 2828. |
| New window | `ffpilot start --new-window [url]` | Ask Firefox for a new window (launching it with `--marionette` if none is running), then attach. |

Ask exactly once, phrased like: *"Connect to your running Firefox, or open a new window?"* Do not infer from context, do not pick for them, do not fall back from one to the other. `start` with neither flag exits 2; both flags exits 2.

## Prerequisites (once)

Firefox must be listening for Marionette:

```bash
firefox --marionette --marionette-port 2828      # or set prefs, then restart
```

Persistent alternative in `about:config`: `marionette.enabled=true`, `marionette.port=2828`.

Verify everything:

```bash
ffpilot doctor          # geckodriver? firefox? port 2828 listening?
```

## Fast path

```bash
ffpilot start --connect                        # or --new-window https://example.com
ffpilot snap                                   # compact @refs of interactive elements
ffpilot batch <<'EOF'
[{"op":"goto","url":"https://example.com"},
 {"op":"click","sel":"#login"},
 {"op":"type","ref":"@4","text":"me@example.com","clear":true},
 {"op":"key","keys":"Enter"},
 {"op":"wait","sel":".dashboard","timeout":8000},
 {"op":"js","script":"return {title:document.title, n:document.querySelectorAll('.row').length}"}]
EOF
ffpilot stop                                   # only when done
```

## WSL → Windows Firefox

Works with WSL2 **mirrored networking**: `127.0.0.1` inside WSL reaches Windows Firefox's Marionette listener, so the Linux geckodriver attaches across the boundary. Verified: `start` 0.17 s, four-op batch 87 ms.

1. Windows Firefox: `about:config` → `marionette.enabled=true`, `marionette.port=2828`, restart.
2. `ffpilot doctor` → expects `"wsl":true`, `windows_firefox`, `marionette_handshake:true`.
3. `ffpilot start --connect` (or `--new-window`, which launches Windows Firefox via `/mnt/c/.../firefox.exe`).

Not mirrored (NAT)? Pass the Windows address: `ffpilot start --marionette-host 192.168.1.20`.

Alternate topology — geckodriver runs on Windows:

```powershell
geckodriver.exe --host 0.0.0.0 --allow-hosts 192.168.1.20 --port 4444
```
```bash
ffpilot start --gecko-host 192.168.1.20 --port 4444   # no spawn, attaches to it
```

Marionette accepts **one client**. If the port is open but the handshake fails, a stale geckodriver still holds the session — kill it, then retry.

## Rules that keep it fast

1. **Batch, never loop the CLI.** Every `ffpilot` call costs a Python start (~30 ms). One `batch` runs N ops in one process against one reused HTTP connection.
2. **Prefer one `js` op over N selector ops.** DOM work inside `execute/sync` is one round trip. `ffpilot js 'return [...document.querySelectorAll("a")].map(a=>a.href)'`.
3. **Snapshot once, then use `@refs`.** `snap` caches elements in `window.__ffp`; `{"ref":"@3"}` skips selector lookup. Re-snap after navigation — refs go stale.
4. **Wait inside the page.** `wait` op polls in-page at 50 ms, one request. Never shell-sleep and re-check.
5. **Read compactly.** `snap` returns ~90-char lines. Never fetch page source or full HTML; return only fields you need from `js`.
6. **Native clicks only.** `click` is one WebDriver click (trusted event), no fallback layer. If it reports `element click intercepted`, close the overlay or dispatch via `js`.
7. **No screenshots unless asked.** Slowest read by far; `raw GET /screenshot` if it is truly needed.

## Command reference

| Command | Purpose |
|---|---|
| `start --connect` | Attach geckodriver `--connect-existing` to the running Firefox, create session, cache state |
| `start --new-window [url]` | New Firefox window (spawning Firefox with Marionette if needed), then attach |
| `stop` | Delete session, kill geckodriver, clear state |
| `status` | Session health, current URL and title |
| `doctor` | Prerequisite checklist, exit 3 if Marionette missing |
| `snap [--limit N] [--json]` | Compact ref-tagged interactive elements |
| `js '<body>' [-e] [-a] [--arg JSON]` | Script with WebDriver body semantics; `-e` wraps as expression, `-a` async |
| `batch [file] [--json] [--quiet]` | JSON op array from file or stdin |
| `op '<json>'` | One op |
| `raw METHOD PATH [BODY]` | Escape hatch to any WebDriver route |
| `shot` (removed) | `raw GET /screenshot` returns base64; no helper ships with the wrapper |

Output is one line per result. Errors exit 2 with the WebDriver error name; setup errors exit 3.

## Op schema

Common: `sel` or `ref` for targeting. Any op accepts `"optional":true` to continue a batch after failure.

```json
[{"op":"goto","url":"..."},
 {"op":"wait","sel":".ready","timeout":8000},
 {"op":"wait","js":"document.readyState==='complete'"},
 {"op":"click","ref":"@2"},
 {"op":"type","sel":"input[name=q]","text":"query","clear":true,"enter":true},
 {"op":"key","keys":"ctrl+a"},
 {"op":"js","script":"return document.title","expr":false,"args":[1],"async":false},
 {"op":"snap"},
 {"op":"tabs"},
 {"op":"newtab","url":"https://..."},
 {"op":"raw","method":"POST","path":"/back"}]
```

That is the whole op set: `goto`, `js`, `click`, `type`, `key`, `wait`, `snap`, `tabs`, `newtab`, `raw`. Removed aliases (`text`, `attr`, `exists`, `back`, `shot`, `sleep`, tabs switching, click fallback) are one `js` or `raw` call each — `ffpilot raw GET /window/handles`, `ffpilot raw POST /window '{"handle":"..."}'`, `ffpilot raw POST /back`.

Routes, latency, ref cache: `references/webdriver.md`.

## Failure modes

| Symptom | Fix |
|---|---|
| `nothing listening on marionette port 2828` | Firefox not started with marionette; set prefs and restart, or rerun `start --new-window` |
| `error: one of the arguments --connect --new-window is required` | Working as intended — ask the user which mode, then pass it |
| `geckodriver exited` | Check `$XDG_RUNTIME_DIR/ffpilot.json.log`; port already used |
| `stale ref` | Page navigated or re-rendered; run `ffpilot snap` again |
| `element click intercepted` | No fallback: close the overlay, or click via `js` |
| Session dead after Firefox restart | Run `start --connect` (or `--new-window`) again |
| `Port is open but the handshake failed` | Another Marionette client (stale geckodriver) is attached; kill it |
| WSL: 127.0.0.1 does not reach Windows | Enable mirrored networking or pass `--marionette-host <windows-ip>` |
| Snapd/Fedora sandbox blocks geckodriver | Run Firefox and `ffpilot` as the same user; use the distro Firefox, not a portal-isolated build |
