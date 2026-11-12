#!/usr/bin/env bash
# Check every maintained shell and JavaScript file, excluding Git internals.
set -euo pipefail
root=${1:-.}
list=$(mktemp)
trap 'rm -f "$list"' EXIT
find "$root" -type d -name .git -prune -o -type f -name '*.sh' -print0 > "$list"
while IFS= read -r -d '' file; do
  bash -n "$file"
  shellcheck "$file"
done < "$list"
find "$root" -type d -name .git -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) -print0 > "$list"
while IFS= read -r -d '' file; do
  node --check "$file"
done < "$list"
