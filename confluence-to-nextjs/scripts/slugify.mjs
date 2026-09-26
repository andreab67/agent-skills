#!/usr/bin/env node
// Convert a Confluence heading's text into a stable anchor-ID slug, with
// numeric-suffix dedup so repeated headings ("Overview", "Overview") don't
// collide (see SKILL.md Anti-pattern 6).
//
// Non-ASCII text is normalized (NFKD) and stripped of combining diacritics
// before slugifying, so accented Latin text degrades gracefully (e.g.
// "Café Überblick" -> "cafe-uberblick"). Text with no ASCII-letter/digit
// content left after that (e.g. CJK-only headings like "日本語") falls back
// to the literal slug "section" rather than an empty id, and dedupeSlugs()
// numbers repeats of that fallback the same as any other collision
// ("section", "section-2", ...).
//
// Usage:
//   node slugify.mjs "Standard Support Contract"      -> standard-support-contract
//   node slugify.mjs --file headings.txt              -> one slug per line, deduped in order

import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

export function slugify(text) {
  const slug = text
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
  return slug || "section";
}

export function dedupeSlugs(headings) {
  const used = new Set();
  return headings.map((text) => {
    const base = slugify(text);
    let candidate = base;
    let suffix = 2;
    while (used.has(candidate)) {
      candidate = `${base}-${suffix}`;
      suffix++;
    }
    used.add(candidate);
    return candidate;
  });
}

function main(argv) {
  if (argv[0] === "--file") {
    const lines = readFileSync(argv[1], "utf8").split(/\r?\n/).filter(Boolean);
    for (const slug of dedupeSlugs(lines)) console.log(slug);
    return;
  }
  if (argv.length === 0) {
    console.error("Usage: node slugify.mjs \"Heading Text\"  |  node slugify.mjs --file headings.txt");
    process.exit(1);
  }
  console.log(slugify(argv.join(" ")));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2));
}
