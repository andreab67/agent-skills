#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/tree/right-name"
cat > "$work/bin/yq" <<'MOCK'
#!/bin/sh
sed -n 's/^name: //p'
MOCK
chmod +x "$work/bin/yq"
export PATH="$work/bin:$PATH"
printf '%s\n' '---' 'name: right-name' '---' > "$work/tree/right-name/SKILL.md"
bash "$repo/scripts/check-skill-names.sh" "$work/tree"
printf '%s\n' '---' 'name: wrong-name' '---' > "$work/tree/right-name/SKILL.md"
if bash "$repo/scripts/check-skill-names.sh" "$work/tree" > /dev/null 2>&1; then echo 'mismatched name passed'; exit 1; fi
echo 'Skill name tests passed'
