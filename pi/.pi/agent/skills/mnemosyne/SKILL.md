---
name: mnemosyne
description: Local-first memory store (recall, remember, forget, update, stats, sleep, repair) backed by the `mnemosyne` CLI (Python mnemosyne-memory). Drop-in replacement for the @mnemosyne-oss/pi-mnemosyne extension so you can uninstall it. Use when you need to persist or retrieve durable facts, preferences, and project context across sessions.
license: MIT
---

# Mnemosyne (self-contained skill — uses the `mnemosyne` CLI)

This skill talks directly to the `mnemosyne` CLI (Python `mnemosyne-memory`, typically at
`~/.local/bin/mnemosyne`). It does **not** depend on the `@mnemosyne-oss/pi-mnemosyne` Pi extension
or its `mnemosyne_*` MCP tools, so you can uninstall that package.

```
pi uninstall npm:@mnemosyne-oss/pi-mnemosyne
```

## Runtime check

Always confirm the CLI is present before using it; fall back to the built-in SQLite commands below
if it is missing.

```
command -v mnemosyne
```

If present, use the CLI for **every** action. It gives you semantic (vector) recall, clean
importance/source handling, consolidation (`sleep`), stats, backups, and named bank support — all
things raw SQLite does not. Only fall back to the raw-SQLite snippets in this file when the CLI is
unavailable (e.g. a fresh machine) or you need an exact/auditable literal match.

## The database

The CLI operates on a SQLite database. Default path (stand as-is if present):

```
DB=${MNEMOSYNE_DB:-$HOME/.hermes/mnemosyne/data/mnemosyne.db}
```

Main tables (`mnemosyne stats` reports counts):
- `working_memory` — the live memory rows (what recall surfaces).
- `memories` — mirror of `working_memory` (same `id`, content, source, importance).
- `memory_embeddings` — embeddings keyed by `memory_id` (used for semantic recall).
- `facts`, `episodic_memory`, `triples` — advanced tables; usually small/empty, safe to ignore.

`mnemosyne diagnose [--fix]` and `mnemosyne verification/cmd` come with the CLI for health checks;
use `mnemosyne backup` before bulk operations.

> **Why prefer the CLI:** `recall` is *semantic* (vector) — "make more money as a freelancer"
> surfaces a memory stored as "~80K EUR yearly target · ~30-35 EUR/hr". Keyword/SQLite matching
> cannot do that. Preference order: **CLI recall > keyword SQLite recall** (the latter only when the
> CLI is absent or you need an exact/auditable literal match).

## Conventions

Every memory has:
- **content** — one concise, factual sentence.
- **importance** — float, use `0.7`–`0.95` for durable facts (`0.9`+ for high-priority identity/targets).
- **source** — a **label**, not a number. Use values like:
  `identity`, `preference`, `project`, `goal`, `fact`, `constraint`, `decided` (a decision taken and its rationale).

> **⚠️ Historical bug (safe now with CLI):** the old extension's `mnemosyne_remember` wrote the
> `importance` number into the `source` column and flattened every `importance` to `0.5`. The CLI's
> `store` accepts source + importance as separate positional args and writes them correctly, so this
> can't recur when you work through the CLI. If legacy rows still look scrambled, run REPAIR below.

## Actions (primary: CLI)

### 1. RECALL — semantically find relevant memories
Search by *meaning*. Prefer this before starting related work.

```
mnemosyne recall "<natural language query>" 8
```

Useful flags:
- `--json` — machine-readable output.
- `--explain` — show why each result matched.

### 2. REMEMBER — store a memory
Replace placeholders. `source` from the labels above; `importance` 0.7–0.95.

```
mnemosyne store "CONTENT goes here" project 0.9
```

> The 3rd positional (`importance`) is optional; if omitted the CLI applies a default. Pass it
> explicitly for durable facts.
> **Convention:** the skill's keyword-recall snippets (below) filter numeric source columns as a
> red flag for the old scramble bug. You can confirm a stored row is clean with
> `mnemosyne recall --json` or by checking `mnemosyne export`.

### 3. UPDATE — change an existing memory
Use when a fact, preference, target, or project detail changes; this keeps a single authoritative row.

```
mnemosyne update <memory_id> "New content" [importance]
```

### 4. FORGET — delete a memory by id
```
mnemosyne delete <memory_id>
```

### 5. SLEEP — consolidate working memories into long-term summaries
Run at the end of a long/major session to compress working memories.

```
mnemosyne sleep
```

### 6. STATS — show totals by source and importance
```
mnemosyne stats
```

### 7. BACKUP / VERIFY — before bulk or destructive ops
```
mnemosyne backup [output_dir]      # create a timestamped .db.gz backup
mnemosyne verify [db_path] [--quick]   # integrity check
mnemosyne backups [backup_dir]     # list available backups
```

### 8. REPAIR — fix scrambled legacy metadata
When the old extension wrote `importance` into `source` (numeric source + flattened `0.5`
importance), repair the rows. Get the affected IDs in two steps:

```
mnemosyne export /tmp/mnemo_export.json   # then inspect working_memory[] entries
```

Find rows whose `source` field is a number string (e.g. `"0.7"`). For each, update both the
importance and the source label with the CLI. The source label is positional #3 and importance #4 in
`store`; for existing rows the CLI `update` takes `<id> <content> [importance]` but **not** source —
so to fully repair, either re-store the corrected row and delete the old one, or use the raw-SQLite
UPDATE below (which can set both columns at once). The raw-UPDATE path is the pragmatic choice for
repair because it touches both `working_memory` and `memories` in one operation.

**Repair via SQLite UPDATE** (fill in the id → (importance, source) map for the affected ids)
```
python3 - "$DB" <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1]); cur = con.cursor()
fix = {
  # id: (importance, source) — fill from mnemosyne export for scrambled ids
  #  e.g. "5dc25c5810f366c6": (0.8, "project"),
}
cur.execute("SELECT id, source, importance FROM working_memory")
scrambled = [r for r in cur.fetchall() if str(r[1]) in ("0.5","0.7","0.75","0.8","0.85","0.9","0.95")]
for mid, src_val, imp in scrambled:
    imp2, src2 = fix.get(mid, (0.85, "fact"))  # default label last resort
    for t in ("working_memory","memories"):
        cur.execute(f"UPDATE {t} SET importance=?, source=? WHERE id=?", (imp2, src2, mid))
con.commit()
print("repaired", len(scrambled), "rows")
cur.execute("SELECT id, source, importance, substr(content,1,50) FROM working_memory ORDER BY importance DESC")
for r in cur.fetchall(): print(f"  {r[2]:.2f} {r[1]!r:12} {r[0]} :: {r[3]}")
PY
```

## Fallback (CLI unavailable): raw SQLite

Use only when `command -v mnemosyne` is empty, or you need an exact/auditable literal substring
match.

### RECALL (literal keyword match)
```
python3 - "$DB" "query words..." <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1]); cur = con.cursor()
terms = sys.argv[2].split()
like = " OR ".join(["content LIKE ?"]*len(terms))
args = [f"%{t}%" for t in terms]
cur.execute(f"SELECT id, source, importance, content FROM working_memory "
            f"WHERE {like} ORDER BY importance DESC, timestamp DESC", args)
for r in cur.fetchall()[:15]:
    print(f"[{r[1]}|imp={r[2]:.2f}] {r[0]} :: {r[3]}")
PY
```

### REMEMBER
```
python3 - "$DB" "CONTENT_GOES_HERE" "source_label" 0.9 <<'PY'
import sqlite3, sys, uuid, datetime
con = sqlite3.connect(sys.argv[1]); cur = con.cursor()
mid = uuid.uuid4().hex[:16]; now = datetime.datetime.now()
content, src, imp = sys.argv[2], sys.argv[3], float(sys.argv[4])
row = (mid, content, src, now.isoformat(), "local", imp, "{}", "stated",
       now.strftime("%Y-%m-%d %H:%M:%S"), "context")
cur.execute("""INSERT INTO working_memory
 (id,content,source,timestamp,session_id,importance,metadata_json,veracity,created_at,memory_type)
 VALUES (?,?,?,?,?,?,?,?,?,?)""", row)
cur.execute("""INSERT OR IGNORE INTO memories
 (id,content,source,timestamp,session_id,importance,metadata_json,created_at)
 VALUES (?,?,?,?,?,?,?,?)""", (mid, content, src, now.isoformat(), "local", imp, "{}", now.strftime("%Y-%m-%d %H:%M:%S")))
con.commit()
print("stored", mid)
PY
```

### FORGET
```
python3 - "$DB" MEMORY_ID <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1]); cur = con.cursor()
for t in ("working_memory","memories"):
    cur.execute(f"DELETE FROM {t} WHERE id=?", (sys.argv[2],))
con.commit(); print("forgot", sys.argv[2])
PY
```

## Best practices

- Store concise, single-fact sentences (avoid dumping conversations).
- Use importance `0.7`–`0.95`; `0.9`+ for identity, career targets, and long-lived decisions.
- Use meaningful `source` labels (`identity`, `preference`, `project`, `goal`, `fact`, `decided`).
- **Prefer `mnemosyne recall` (semantic) over keyword matching** before starting related work.
- Prefer `mnemosyne update` over delete+re-store to keep a single authoritative row for changes.
- Forget stale/contradictory memories; avoid conflicts.
- **`mnemosyne backup` before any repair or bulk operation.**
- Note: `mnemosyne stats` may report a few legacy rows beyond `working_memory` (e.g. `legacy`); these
  are historical and not surfaced by recall. You can audit them via `mnemosyne export`.

## Files

- This skill: `SKILL.md`
- Session history it can mine: `$HOME/.pi/agent/sessions/` (JSONL session logs)
- Data: `$HOME/.hermes/mnemosyne/data/mnemosyne.db` (+ `.bak*` backups created by `mnemosyne backup`)
