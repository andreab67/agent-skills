#!/usr/bin/env bash
# Extract an exact version section from a changelog on stdin.
set -euo pipefail
version=${1:-}
[[ "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo 'Invalid version' >&2; exit 2; }
tr -d '\r' | awk -v header="## v$version" '
  $0 == header || index($0, header " ") == 1 { found=1; p=1; print; next }
  /^## v[0-9]+/ { p=0 }
  p
  END { if (!found) exit 1 }
'
