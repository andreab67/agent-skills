#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/tree/good"
printf '#!/bin/bash\necho ok\n' > "$work/tree/good/ok.sh"
printf 'const ok = 1;\n' > "$work/tree/good/ok.js"
bash "$repo/scripts/check-code.sh" "$work/tree"
if bash "$repo/scripts/check-code.sh" "$work/missing" > /dev/null 2>&1; then echo "missing tree passed"; exit 1; fi
printf 'if then\n' > "$work/tree/good/bad.sh"
if bash "$repo/scripts/check-code.sh" "$work/tree" > /dev/null 2>&1; then echo 'invalid shell passed'; exit 1; fi
rm "$work/tree/good/bad.sh"
printf 'const = ;\n' > "$work/tree/good/bad.js"
if bash "$repo/scripts/check-code.sh" "$work/tree" > /dev/null 2>&1; then echo 'invalid JavaScript passed'; exit 1; fi
rm "$work/tree/good/bad.js"
for ext in mjs cjs; do
  printf 'const = ;\n' > "$work/tree/good/bad.$ext"
  if bash "$repo/scripts/check-code.sh" "$work/tree" > /dev/null 2>&1; then echo "invalid $ext passed"; exit 1; fi
  rm "$work/tree/good/bad.$ext"
done
echo 'Code validation tests passed' 
