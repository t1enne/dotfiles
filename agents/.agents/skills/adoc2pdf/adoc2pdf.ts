#!/usr/bin/env node
//
// adoc2pdf – convert AsciiDoc (string or file) to PDF
//
// Usage:
//   echo '= Hi' | ./adoc2pdf.ts [output.pdf]
//   ./adoc2pdf.ts input.adoc [output.pdf]
//
// Node.js >= 22 required (runs TS natively via --experimental-strip-types).

import { readFile, writeFile } from "node:fs/promises";
import { basename, extname } from "node:path";
import { tmpdir } from "node:os";
import { execFile } from "node:child_process";

function convertAdoc(inputPath: string, pdfPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    execFile(
      "npx",
      ["asciidoctor-pdf", "-o", pdfPath, inputPath],
      (err, stdout, stderr) => {
        if (err) return reject(new Error(stderr.trim() || err.message));
        resolve();
      },
    );
  });
}

type Source = { path: string; temp: boolean };

async function resolveSource(value: string): Promise<Source> {
  if (value === "-") {
    const chunks: Buffer[] = [];
    for await (const chunk of process.stdin) chunks.push(chunk);
    const tmp = `${tmpdir()}/adoc-${Date.now()}.adoc`;
    await writeFile(tmp, Buffer.concat(chunks));
    return { path: tmp, temp: true };
  }
  return { path: value, temp: false };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.includes("--help") || args.includes("-h")) {
    const me = basename(process.argv[1]!);
    console.error(`Usage: ${me} [output.pdf]`);
    console.error("  Reads AsciiDoc from stdin, writes PDF to output.pdf");
    console.error("  If no output given, writes to a temp file and prints its path.");
    console.error(`Usage: ${me} <input.adoc> [output.pdf]`);
    console.error("  Converts input.adoc to PDF.");
    console.error("  If no output given, writes <input>.pdf next to the source.");
    process.exit(0);
  }

  // If first arg ends with .adoc, it's a file input; otherwise it's an output path for stdin
  const firstArg = args[0];
  const isFileInput = firstArg && (firstArg.endsWith(".adoc") || firstArg.endsWith(".asciidoc") || firstArg.endsWith(".ad"));

  let src: Source;
  let pdfPath: string;

  if (isFileInput) {
    src = await resolveSource(firstArg!);
    pdfPath = args[1] ?? basename(firstArg!, extname(firstArg!)) + ".pdf";
  } else {
    // stdin mode — first arg (if any) is the output path
    src = await resolveSource("-");
    pdfPath = args[0] ?? `${tmpdir()}/adoc-${Date.now()}.pdf`;
  }

  await convertAdoc(src.path, pdfPath);
  console.log(pdfPath);
}

main().catch((err: unknown) => {
  const msg = err instanceof Error ? err.message : String(err);
  console.error("adoc2pdf:", msg);
  process.exit(1);
});
