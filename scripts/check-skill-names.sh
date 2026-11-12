#!/usr/bin/env bash
set -euo pipefail
root=${1:-.}
fail=0
list=$(mktemp)
trap 'rm -f "$list"' EXIT
find "$root" -type d -name .git -prune -o -type f -name SKILL.md -print0 > "$list"
while IFS= read -r -d '' file; do
  name=$(awk '{ sub(/\r$/, ""); if (/^---$/) { c++; if (c==2) exit }; if (c) print }' "$file" | yq -r '.name // ""')
  directory=$(basename "$(dirname "$file")")
  if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ || "$name" != "$directory" ]]; then
    echo "FAIL: $file name '$name' must be kebab-case and match '$directory'" >&2
    fail=1
  fi
done < "$list"
exit "$fail"
