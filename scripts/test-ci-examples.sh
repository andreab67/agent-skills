#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
ci="$root/nextjs-monorepo-ci/SKILL.md"
deploy="$root/k8s-nextjs-deploy/SKILL.md"
if grep -Eq 'gitleaks:latest|executor:debug|alpine:latest|\[0-9a-f\]\{32\}' "$ci"; then
  echo 'Unsafe floating image or broad hex allowlist remains' >&2; exit 1
fi
grep -q -- '--redact' "$ci"
if sed -n '/^test-web:/,/^```/p' "$ci" | grep -q 'allow_failure: true'; then
  echo 'test-web remains non-blocking' >&2; exit 1
fi
grep -Fq "app:\${CI_COMMIT_SHA}" "$deploy"
echo 'Documentation example checks passed'
