#!/usr/bin/env bash
set -euo pipefail
scanner=$(realpath "${1:-scripts/check-secrets.sh}")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
git init -q
echo clean > sample.txt
git add sample.txt
bash "$scanner" > output
# Every family is generated at runtime. Logs must identify the line, not value.
for prefix in sk- ASIA AKIA glpat-; do
  if [[ "$prefix" = ASIA || "$prefix" = AKIA ]]; then suffix=ABCDEFGHIJKLMNOP; else suffix=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'); fi
  canary=$prefix$suffix
  printf '%s\n' "$canary" > sample.txt
  if bash "$scanner" > output; then exit 1; else rc=$?; fi
  [ "$rc" -eq 1 ]
  grep -qx 'sample.txt:1' output
  if grep -qF -- "$canary" output; then echo "Scanner disclosed canary" >&2; exit 1; fi
done
# A read/grep error must fail, never become a clean result.
rm sample.txt
if bash "$scanner" > output 2> error; then exit 1; else rc=$?; fi
[ "$rc" -eq 2 ]
echo "Secret scanner tests passed (four token families, redacted output, read errors)"
