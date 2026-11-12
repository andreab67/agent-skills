#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
log=$(mktemp)
trap 'rm -rf "$work"; rm -f "$log"' EXIT
public=0123456789abcdef0123456789abcdef
other=fedcba9876543210fedcba9876543210
mkdir -p "$work/apps/web/public"
awk '/^# .gitleaks.toml/{p=1} p && /^```$/{exit} p{print}' "$repo/nextjs-monorepo-ci/SKILL.md" > "$work/.gitleaks.toml"
printf 'api_%s = "%s"\n' key "$public" > "$work/apps/web/public/0123456789abcdef0123456789abcdef.txt"
printf 'api_%s = "%s"\n' key "$other" > "$work/apps/web/public/real.txt"
if docker run --rm --network none -v "$work:/src:ro" zricethezav/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f detect --no-git --source /src --config /src/.gitleaks.toml --redact --report-format json --report-path /tmp/report.json --exit-code 1 > "$log" 2>&1; then
 echo 'Expected real synthetic secret to be detected'; cat "$log"; exit 1
fi
rm "$work/apps/web/public/real.txt"
printf 'api_%s = "%s"\n' key "$other" >> "$work/apps/web/public/0123456789abcdef0123456789abcdef.txt"
if docker run --rm --network none -v "$work:/src:ro" zricethezav/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f detect --no-git --source /src --config /src/.gitleaks.toml --redact --exit-code 1 > "$log" 2>&1; then
 echo 'Other secret in public file was suppressed'; exit 1
fi
printf 'api_%s = "%s"\n' key "$public" > "$work/apps/web/public/0123456789abcdef0123456789abcdef.txt"
if ! docker run --rm --network none -v "$work:/src:ro" zricethezav/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f detect --no-git --source /src --config /src/.gitleaks.toml --redact --exit-code 1 > "$log" 2>&1; then
 echo 'Reviewed public token was not scoped correctly'; cat "$log"; exit 1
fi
echo 'Gitleaks scoped fixtures passed'
