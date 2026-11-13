# ffpilot internals — pointers, not a manual

Setup, modes, WSL steps, and troubleshooting live in `../SKILL.md`. This file is only what that doc cannot say briefly.

## Specs (read these instead of a copied table)

- W3C WebDriver: https://w3c.github.io/webdriver/
- geckodriver (capabilities, `moz:*` prefs, flags): https://firefox-source-docs.mozilla.org/testing/geckodriver/
- Marionette (prefs, protocol, ports): https://firefox-source-docs.mozilla.org/testing/marionette/
- WebDriver BiDi: https://w3c.github.io/webdriver-bidi/

ffpilot-specific: element refs use key `element-6066-11e4-a52e-4f735466cecf`; every op maps to one of `POST /session/{id}/url|back|forward|refresh|element|execute/sync|execute/async|actions|window|window/new`, `GET .../element/{eid}/text|attribute/{name}|screenshot|window/handles`, `DELETE .../window`. Anything else goes through `ffpilot raw METHOD PATH [BODY]`.

## State and spawn

- `$XDG_RUNTIME_DIR/ffpilot.json` = `{port, pid, session, marionette}` (0600); `.log` = geckodriver output.
- `--gecko-host` loopback → ffpilot spawns `geckodriver --connect-existing --marionette-host <mhost>`.
- `--gecko-host` remote → no spawn, session created on the existing geckodriver, and `stop` leaves it running.
- Env equivalents: `FFPILOT_MARIONETTE_HOST`, `FFPILOT_GECKO_HOST`, `FFPILOT_MARIONETTE`, `FFPILOT_PORT`.
- Marionette serves one client: a stale geckodriver on 2828 is the usual cause of "port open, handshake failed".

## Ref cache

`snap` runs one script: reset `window.__ffp`, collect visible `a,button,input,select,textarea,summary,label,[role=*],[contenteditable=true]`, emit `@i tag[type]#id "name" -> href|= value| disabled`. Refs are per-document — dead after navigation, and `{"ref":"@i"}` raises `stale ref` rather than clicking a wrong node.

## Latency budget (localhost)

| Cost | Typical |
|---|---|
| Python start (per `ffpilot` invocation) | 25–40 ms |
| WebDriver request | 1–4 ms |
| `snap`, 500 nodes | 5–10 ms |
| native click | 2–5 ms |
| screenshot | 80–200 ms |

Batching beats everything; screenshots and selector lookups are the expensive reads. Use refs, and one `js` call for many fields.

## Patterns worth keeping

```bash
# read: one round trip for many fields
ffpilot js 'return [...document.querySelectorAll(".row")].slice(0,50).map(r=>({t:r.innerText,h:r.querySelector("a").href}))'

# write npm React-style fields in-page with an async script (no client polling)
ffpilot js 'return (async()=>{for(const v of ["a","b"]){const i=document.querySelector("input");i.value=v;i.dispatchEvent(new Event("input",{bubbles:true}))}return 1})()' -a
```

Native `type` stays the reliable default; synthetic `input` is the shortcut for controlled React fields.

## BiDi

geckodriver 0.34+ with `"webSocketUrl": true` in `alwaysMatch` gives event streams (network/console/navigation) without polling — bootstrap via `ffpilot raw`, then reuse the socket. Plain WebDriver is faster for one-shot actions.
