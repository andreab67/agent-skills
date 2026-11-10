#!/usr/bin/env bash
# Run only in a disposable container; never executes remediation on the host.
set -euo pipefail
[ -f /.dockerenv ] || { echo "Container required" >&2; exit 1; }
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
script=${1:-$repo_dir/ubuntu24-stig/remediate-mac2-sensitive.sh}
bash -n "$script"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
snapshot() {
  find /etc -type f -exec sha256sum {} + | sort
}
snapshot > "$work/before"
bash "$script" > "$work/dry-run"
grep -q 'DRY RUN' "$work/dry-run"
snapshot > "$work/after"
cmp "$work/before" "$work/after"
if compgen -G '/var/backups/stig-*' > /dev/null; then exit 1; fi
# Explicit apply still requires the recovery-access acknowledgement and yes.
if bash "$script" --apply --yes > "$work/refused" 2>&1; then exit 1; fi
grep -q 'oob-access-confirmed' "$work/refused"
if bash "$script" --apply --oob-access-confirmed > "$work/refused" 2>&1; then exit 1; fi
grep -q 'confirmation' "$work/refused"
if bash "$script" --ufw-allow-ports '22;id' > "$work/refused" 2>&1; then exit 1; fi
# Mocks stop execution at the external effects, before any remediation.
mkdir "$work/bin"
printf '#!/bin/sh\nexit 0\n' > "$work/bin/sshd"
printf '#!/bin/sh\nexit 71\n' > "$work/bin/tar"
printf '#!/bin/sh\necho APT_RAN >&2\nexit 72\n' > "$work/bin/apt-get"
chmod +x "$work/bin/"*
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed > "$work/tar-fail" 2>&1; then exit 1; else rc=$?; fi
[ "$rc" -eq 71 ]
if grep -q APT_RAN "$work/tar-fail"; then exit 1; fi
rm "$work/bin/tar"
# A real archive is created and verified; package installation then stops us.
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed > "$work/backup" 2>&1; then exit 1; else rc=$?; fi
[ "$rc" -eq 72 ]
backup=$(find /var/backups -name etc.tgz -type f)
[ "$(stat -c %a "$backup")" = 600 ]
[ "$(stat -c %a "$(dirname "$backup")")" = 700 ]
tar -tzf "$backup" > /dev/null
echo "STIG safety tests passed (dry run unchanged; preflight; tar failure; backup permissions and verification)"
