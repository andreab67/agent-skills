#!/usr/bin/env bash
# Exercise production GRUB and UFW blocks against scratch files and mocks only.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
script="$repo/ubuntu24-stig/remediate-mac2-sensitive.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
awk '/^# Startup audit/{p=1;next} /^# auditd.conf settings/{exit} p' "$script" |
  sed "s|/etc/default/grub|$work/grub|g" > "$work/grub-block"
cat > "$work/run-grub" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
update-grub() { echo update >> "$CALLS"; }
stig_ok() { echo "OK: $*"; }
stig_fix() { echo "FIX: $*"; }
source "$BLOCK"
MOCK
export BLOCK="$work/grub-block" CALLS="$work/calls"
for scenario in comment audit10 missing; do
  case "$scenario" in
    comment) printf '# audit=1 comment\nGRUB_CMDLINE_LINUX_DEFAULT="quiet"\n' > "$work/grub" ;;
    audit10) printf 'GRUB_CMDLINE_LINUX_DEFAULT="quiet audit=10"\n' > "$work/grub" ;;
    missing) printf 'OTHER=1\n' > "$work/grub" ;;
  esac
  : > "$CALLS"
  if bash "$work/run-grub" > "$work/out" 2>&1; then rc=0; else rc=$?; fi
  if [ "$scenario" = missing ]; then
    if [ "$rc" -eq 0 ] || [ -s "$CALLS" ]; then
      echo 'missing GRUB assignment accepted'; exit 1
    fi
  else
    [ "$rc" -eq 0 ] || { cat "$work/out"; exit 1; }
    grep -Eq '^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*(^|[[:space:]])audit=1([[:space:]]|")' "$work/grub" || {
      echo "audit=1 missing for $scenario"; exit 1;
    }
    if grep -Eq '^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*audit=10([[:space:]]|")' "$work/grub"; then
      echo 'conflicting audit=10 retained'; exit 1
    fi
    grep -qx update "$CALLS"
  fi
done
# Refuse duplicate or shell-expanded assignments without writing or updating.
# shellcheck disable=SC2016 # The fixture must contain an unexpanded shell variable.
for contents in 'GRUB_CMDLINE_LINUX_DEFAULT="$UNTRUSTED"' $'GRUB_CMDLINE_LINUX_DEFAULT="quiet"\nGRUB_CMDLINE_LINUX_DEFAULT="other"'; do
  printf '%s\n' "$contents" > "$work/grub"
  cp "$work/grub" "$work/original"
  : > "$CALLS"
  if bash "$work/run-grub" > "$work/out" 2>&1; then echo 'ambiguous GRUB accepted'; exit 1; fi
  cmp "$work/original" "$work/grub"
  test ! -s "$CALLS"
done
# Existing correct setting should not regenerate GRUB.
printf 'GRUB_CMDLINE_LINUX_DEFAULT="quiet audit=1"\n' > "$work/grub"
: > "$CALLS"
bash "$work/run-grub" > "$work/out"
test ! -s "$CALLS"
awk '/^SSH_PORTS=\$\(printf/{p=1} p{print} /^stig_ok "UFW enabled"/{exit}' "$script" > "$work/socket-block"
test -s "$work/socket-block"
cat > "$work/run-socket" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
SSH_EFFECTIVE='port 22'
UFW_ALLOW_PORTS=auto
systemctl() {
  case "$MODE:$*" in
    failed:*) return 1 ;;
    loaded:show\ -p\ LoadState\ --value\ ssh.socket) echo loaded ;;
    loaded:show\ -p\ Listen\ --value\ ssh.socket) echo '0.0.0.0:2222 (Stream)' ;;
    listenfail:show\ -p\ LoadState\ --value\ ssh.socket) echo loaded ;;
    listenfail:show\ -p\ Listen\ --value\ ssh.socket) return 1 ;;
    unknown:show\ -p\ LoadState\ --value\ ssh.socket) echo error ;;
    empty:show\ -p\ LoadState\ --value\ ssh.socket) echo loaded ;;
    empty:show\ -p\ Listen\ --value\ ssh.socket) : ;;
    absent:show\ -p\ LoadState\ --value\ ssh.socket) echo not-found ;;
    *) return 1 ;;
  esac
}
ufw() { printf '%s\n' "$*" >> "$CALLS"; }
stig_ok() { :; }
source "$BLOCK"
MOCK
export BLOCK="$work/socket-block"
for MODE in failed listenfail unknown empty; do
  export MODE
  : > "$CALLS"
  if bash "$work/run-socket" > "$work/out" 2>&1; then echo "$MODE socket accepted"; exit 1; fi
  test ! -s "$CALLS" || { echo "$MODE socket changed UFW"; exit 1; }
done
for MODE in loaded absent; do
  export MODE
  : > "$CALLS"
  bash "$work/run-socket" > "$work/out"
  grep -qx 'allow 22/tcp' "$CALLS"
  if [ "$MODE" = loaded ]; then grep -qx 'allow 2222/tcp' "$CALLS"; fi
  if [ "$MODE" = loaded ]; then
    printf '%s\n' 'allow 22/tcp' 'allow 2222/tcp' '--force enable' 'logging on' > "$work/expected"
  else
    printf '%s\n' 'allow 22/tcp' '--force enable' 'logging on' > "$work/expected"
  fi
  cmp "$work/expected" "$CALLS"
done
# shellcheck disable=SC2016 # Search for the literal unsafe fallback.
if grep -Fq '${SSH_PORTS:-22}' "$repo/ubuntu24-stig/SKILL.md"; then
  echo 'documentation still guesses SSH port 22 after discovery failure'; exit 1
fi
echo 'GRUB and SSH socket fixture tests passed' 
