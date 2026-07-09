#!/usr/bin/env bash
# Fetch a Confluence page in storage format via REST API v2.
#
# Usage:
#   CONFLUENCE_EMAIL=user@example.com CONFLUENCE_TOKEN=ATATT3x... \
#     ./fetch-page.sh your-org PAGE_ID [output.json]
#
# Always requests body-format=storage (never "view" — view returns
# session-relative image URLs that 404 once unauthenticated in prod).
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <site-subdomain> <page-id> [output.json]" >&2
  exit 1
fi

SITE="$1"
PAGE_ID="$2"
OUT="${3:-page-${PAGE_ID}.json}"

: "${CONFLUENCE_EMAIL:?Set CONFLUENCE_EMAIL to your Atlassian account email}"
: "${CONFLUENCE_TOKEN:?Set CONFLUENCE_TOKEN to a personal API token}"

HTTP_STATUS=$(curl -s -o "$OUT" -w "%{http_code}" \
  -u "${CONFLUENCE_EMAIL}:${CONFLUENCE_TOKEN}" \
  "https://${SITE}.atlassian.net/wiki/api/v2/pages/${PAGE_ID}?body-format=storage")

if [[ "$HTTP_STATUS" != "200" ]]; then
  echo "Fetch failed (HTTP $HTTP_STATUS). Response body written to $OUT — inspect it:" >&2
  cat "$OUT" >&2
  exit 1
fi

echo "Wrote $OUT"
