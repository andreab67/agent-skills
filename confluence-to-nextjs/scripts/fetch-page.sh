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

# Escape backslashes and double quotes so the value is safe inside a
# double-quoted curl config entry (see `man curl` "-K, --config").
escape_for_curl_config() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Pass credentials via a curl config on stdin (-K -) instead of -u, so the
# token never appears in this process's argv (and thus never in `ps` output
# on shared hosts/CI runners).
CURL_CONFIG=$(printf 'user = "%s:%s"\n' \
  "$(escape_for_curl_config "$CONFLUENCE_EMAIL")" \
  "$(escape_for_curl_config "$CONFLUENCE_TOKEN")")

HTTP_STATUS=$(printf '%s\n' "$CURL_CONFIG" | curl -sS -K - -o "$OUT" -w "%{http_code}" \
  "https://${SITE}.atlassian.net/wiki/api/v2/pages/${PAGE_ID}?body-format=storage")

if [[ "$HTTP_STATUS" != "200" ]]; then
  echo "Fetch failed (HTTP $HTTP_STATUS). Response body written to $OUT — inspect it:" >&2
  cat "$OUT" >&2
  exit 1
fi

echo "Wrote $OUT"
