#!/usr/bin/env bash
# Scan tracked files without disclosing the matched value. Exit 2 is an error.
set -euo pipefail
PATTERNS='(AKIA[0-9A-Z]{16})|(ASIA[0-9A-Z]{16})|(glpat-[A-Za-z0-9_-]{20,})|((^|[^A-Za-z0-9_-])sk-[A-Za-z0-9_-]{20,})|(bearer [A-Za-z0-9._-]{30,})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)'
scan() {
  local file=$1 rc
  if grep -Ein -- "$PATTERNS" "$file"; then rc=0; else rc=$?; fi
  return "$rc"
}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# Generated at runtime: never store a credential-looking canary in the tree.
printf 'sk-%s\n' "$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')" > "$work/canary"
if ! scan "$work/canary" > "$work/hits"; then
  echo "FAIL: secret scanner canary was not detected" >&2; exit 2
fi
fail=0
git ls-files -z > "$work/files"
while IFS= read -r -d '' file; do
  if scan "$file" > "$work/hits"; then
    # grep's first field is the line number. Never emit the hit text.
    while IFS=: read -r line _; do printf '%s:%s\n' "$file" "$line"; done < "$work/hits"
    fail=1
  else
    rc=$?
    if [ "$rc" -ne 1 ]; then echo "FAIL: secret scan could not read $file" >&2; exit 2; fi
  fi
done < "$work/files"
exit "$fail"
