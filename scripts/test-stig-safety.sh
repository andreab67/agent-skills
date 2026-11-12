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
# A missing trusted AIDE baseline blocks apply before any backup or change.
mkdir -p /var/lib/aide
rm -f /var/lib/aide/aide.db
if bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/no-baseline" 2>&1; then exit 1; fi
grep -qi 'AIDE.*baseline' "$work/no-baseline"
printf 'fixture baseline\n' > /var/lib/aide/aide.db
# Mocks stop execution at the external effects, before any remediation.
mkdir "$work/bin"
printf '#!/bin/sh\nexit 0\n' > "$work/bin/sshd"
printf '#!/bin/sh\nexit 71\n' > "$work/bin/tar"
printf '#!/bin/sh\necho APT_RAN >&2\nexit 72\n' > "$work/bin/apt-get"
chmod +x "$work/bin/"*
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/tar-fail" 2>&1; then exit 1; else rc=$?; fi
[ "$rc" -eq 71 ]
if grep -q APT_RAN "$work/tar-fail"; then exit 1; fi
rm "$work/bin/tar"
# A real archive is created and verified; package installation then stops us.
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/backup" 2>&1; then exit 1; else rc=$?; fi
[ "$rc" -eq 72 ]
backup=$(find /var/backups -name etc.tgz -type f)
[ "$(stat -c %a "$backup")" = 600 ]
[ "$(stat -c %a "$(dirname "$backup")")" = 700 ]
tar -tzf "$backup" > /dev/null
# Owned documentation snippets replace their files on rerun.
grep -Fq "cat > /etc/ssh/ssh_config.d/99-stig-fips.conf" "$repo_dir/ubuntu24-stig/SKILL.md"
grep -Fq 'echo "* hard maxlogins 10" > /etc/security/limits.d/99-stig.conf' "$repo_dir/ubuntu24-stig/SKILL.md"
awk '/^cat > \/etc\/ssh\/ssh_config.d\/99-stig-fips.conf/{p=1} p{print} p && /^EOF$/{exit}' "$repo_dir/ubuntu24-stig/SKILL.md" |
  sed "s|/etc/ssh/ssh_config.d/99-stig-fips.conf|$work/ssh-config|g" > "$work/doc-ssh.sh"
test -s "$work/doc-ssh.sh"
bash "$work/doc-ssh.sh"
cp "$work/ssh-config" "$work/ssh-once"
bash "$work/doc-ssh.sh"
cmp "$work/ssh-once" "$work/ssh-config"
grep -F 'echo "* hard maxlogins 10" > /etc/security/limits.d/99-stig.conf' "$repo_dir/ubuntu24-stig/SKILL.md" |
  sed "s|/etc/security/limits.d/99-stig.conf|$work/limits|g" > "$work/doc-limits.sh"
bash "$work/doc-limits.sh"
cp "$work/limits" "$work/limits-once"
bash "$work/doc-limits.sh"
cmp "$work/limits-once" "$work/limits"
# Test required service failures and immutable audit without host effects.
printf '#!/bin/sh\nexit 0\n' > "$work/bin/apt-get"
printf '#!/bin/sh\nexit 55\n' > "$work/bin/systemctl"
chmod +x "$work/bin/apt-get" "$work/bin/systemctl"
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/service-fail" 2>&1; then exit 1; fi
grep -qi 'auditd could not be enabled' "$work/service-fail"
printf '#!/bin/sh\nexit 0\n' > "$work/bin/systemctl"
printf '#!/bin/sh\nprintf "enabled 2\\n"\n' > "$work/bin/auditctl"
chmod +x "$work/bin/auditctl"
mkdir -p /etc/audit/rules.d
rm -f /etc/audit/rules.d/99-stig.rules
backups_before=$(find /var/backups -name etc.tgz -type f | wc -l)
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/immutable" 2>&1; then exit 1; fi
grep -qi 'immutable' "$work/immutable"
test ! -e /etc/audit/rules.d/99-stig.rules
[ "$(find /var/backups -name etc.tgz -type f | wc -l)" -eq "$backups_before" ]
# Explicit reader acknowledgement is mandatory even when a baseline exists.
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed > "$work/no-journal-ack" 2>&1; then exit 1; fi
grep -qi 'journalctl' "$work/no-journal-ack"
# Failed audit loading must stop before SSH changes.
mkdir -p /etc/default /etc/audit/rules.d /etc/ssh/sshd_config.d /etc/ssh/ssh_config.d
printf 'GRUB_CMDLINE_LINUX_DEFAULT="audit=1"\n' > /etc/default/grub
printf 'log_format = RAW\nspace_left_action = SYSLOG\naction_mail_acct = root\n' > /etc/audit/auditd.conf
# shellcheck disable=SC2016 # Literal variables belong to the fixture command.
printf '#!/bin/sh\n[ "$1" = -s ] && { echo "enabled 1"; exit 0; }; exit 1\n' > "$work/bin/auditctl"
printf '#!/bin/sh\nexit 1\n' > "$work/bin/augenrules"
chmod +x "$work/bin/auditctl" "$work/bin/augenrules"
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/load-fail" 2>&1; then exit 1; fi
grep -qi 'audit rules could not be loaded' "$work/load-fail"
test ! -e /etc/ssh/sshd_config.d/99-stig.conf
# Conflicting effective SSH settings must stop before restarting sshd.
mkdir -p /etc/default /etc/audit/rules.d /etc/ssh/sshd_config.d /etc/ssh/ssh_config.d
printf 'GRUB_CMDLINE_LINUX_DEFAULT="audit=1"\n' > /etc/default/grub
printf 'log_format = RAW\nspace_left_action = SYSLOG\naction_mail_acct = root\n' > /etc/audit/auditd.conf
printf 'original fixture\n' > /etc/ssh/sshd_config.d/99-stig.conf
# shellcheck disable=SC2016 # Literal variables belong to the fixture command.
printf '#!/bin/sh\n[ "$1" = -s ] && { echo "enabled 1"; exit 0; }; exit 1\n' > "$work/bin/auditctl"
printf '#!/bin/sh\nexit 0\n' > "$work/bin/augenrules"
# shellcheck disable=SC2016 # Literal variables belong to the fixture command.
printf '#!/bin/sh\n[ "$1" = -T ] && { echo "ciphers unsafe"; exit 0; }; exit 0\n' > "$work/bin/sshd"
# shellcheck disable=SC2016 # Literal variables belong to the fixture command.
printf '#!/bin/sh\necho "$*" >> "$SYSTEMCTL_LOG"\nexit 0\n' > "$work/bin/systemctl"
chmod +x "$work/bin/"*
export SYSTEMCTL_LOG="$work/systemctl.log"
if PATH="$work/bin:$PATH" bash "$script" --apply --yes --oob-access-confirmed --aide-baseline-confirmed --journalctl-readers-confirmed > "$work/ssh-conflict" 2>&1; then exit 1; fi
grep -qi 'effective SSH' "$work/ssh-conflict"
grep -qx 'original fixture' /etc/ssh/sshd_config.d/99-stig.conf
if grep -q 'restart sshd' "$SYSTEMCTL_LOG"; then echo "restarted conflicting sshd" >&2; exit 1; fi
echo "STIG safety tests passed (dry run unchanged; preflight; tar failure; backup permissions and verification)"
