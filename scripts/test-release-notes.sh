#!/usr/bin/env bash
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
extract="$root/scripts/release-notes.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '## v1.2\r\n\r\nFirst notes\r\n## v1.20 -- 2026-01-01\r\nWrong notes\r\n' > "$work/changelog"
bash "$extract" 1.2 < "$work/changelog" > "$work/result"
printf '## v1.2\n\nFirst notes\n' > "$work/expected"
cmp "$work/expected" "$work/result"
if bash "$extract" 1.3 < "$work/changelog" > /dev/null; then echo 'missing version accepted'; exit 1; fi
if bash "$extract" '1.2|.*' < "$work/changelog" > /dev/null 2>&1; then echo 'invalid version accepted'; exit 1; fi
echo 'Release notes tests passed'
