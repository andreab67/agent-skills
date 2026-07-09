#!/usr/bin/env node
// Convert a Confluence heading's text into a stable anchor-ID slug, with
// numeric-suffix dedup so repeated headings ("Overview", "Overview") don't
// collide (see SKILL.md Anti-pattern 6).
//
// Usage:
//   node slugify.mjs "Standard Support Contract"      -> standard-support-contract
//   node slugify.mjs --file headings.txt              -> one slug per line, deduped in order

import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

export function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export function dedupeSlugs(headings) {
  const seen = new Map();
  return headings.map((text) => {
    const base = slugify(text);
    const count = seen.get(base) ?? 0;
    seen.set(base, count + 1);
    return count === 0 ? base : `${base}-${count + 1}`;
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

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2));
}
