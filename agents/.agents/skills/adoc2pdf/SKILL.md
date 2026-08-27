---
name: adoc2pdf
description: Create PDF documents from AsciiDoc. Use when the user asks to "create a PDF", "generate a document", "make a report", "write a PDF", or produce any formatted document for download/sharing. The agent writes AsciiDoc content, pipes it to the conversion script, and returns the PDF path.
---

# adoc2pdf — PDF Document Creator

Generate PDF documents by composing AsciiDoc content and piping it to the converter. You (the agent) write the adoc markup; the script handles rendering.

## Workflow

1. **Compose** AsciiDoc content from the user's request
2. **Pipe** it to `adoc2pdf.ts` via stdin with an output filename
3. **Return** the PDF path (printed to stdout by the script)

```
echo '= Report Title
:toc:

== Section One

Content here.' | ./adoc2pdf.ts report.pdf
# → prints: report.pdf
```

If you omit the output path, the script writes to a temp file and prints its path.

## AsciiDoc Quick Reference

```
= Document Title
Author Name
:toc:
:sectnums:

== Section

Paragraph text with *bold*, _italic_, and `mono`.

.Bullet list
* item one
* item two

.Numbered list
. step one
. step two

[cols="2,3"]
|===
| Header A | Header B
| Cell 1   | Cell 2
|===

image::chart.png[Chart,width=600]

[NOTE]
====
Admonition block — note, tip, warning, caution, important.
====

---
''' <<<  # page break
```

## Script Path

`./adoc2pdf.ts` — resolves relative to the skill directory.

## Requirements

- Node.js >= 22 (native TS via `--experimental-strip-types`)
- `asciidoctor-pdf` available via `npx` (auto-installs on first run)
