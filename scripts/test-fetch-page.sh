#!/usr/bin/env bash
set -eu
script="$(cd "$(dirname "$0")/.." && pwd)/confluence-to-nextjs/scripts/fetch-page.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/bin"
cat > "$work/bin/curl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CALLS"
cat > /dev/null
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then shift; printf '{}' > "$1"; fi
  shift
done
[ "${FAIL_CURL:-0}" = 1 ] && exit 28
[ -z "${RACE_DIR:-}" ] || mkdir "$RACE_DIR"
printf 200
MOCK
chmod +x "$work/bin/curl"
export PATH="$work/bin:$PATH" CONFLUENCE_EMAIL=dummy CONFLUENCE_TOKEN=dummy CALLS="$work/calls"
cd "$work"
for site in 'evil.com/x?' '-bad' 'a..b'; do
  if bash "$script" "$site" 123 > /dev/null 2>&1; then echo "accepted invalid site: $site"; exit 1; fi
done
for page in '../bad' '123?x'; do
  if bash "$script" good "$page" > /dev/null 2>&1; then echo "accepted invalid page: $page"; exit 1; fi
done
for out in '../outside' '/tmp/out' '-bad'; do
  if bash "$script" good 123 "$out" > /dev/null 2>&1; then echo "accepted invalid output: $out"; exit 1; fi
done
mkdir existing.json
if bash "$script" good 123 existing.json > /dev/null 2>&1; then echo 'accepted directory output'; exit 1; fi
test -z "$(find existing.json -mindepth 1 -print -quit)"
test ! -e "$CALLS"
if RACE_DIR=race.json bash "$script" good 123 race.json > /dev/null 2>&1; then echo 'directory race accepted'; exit 1; fi
test -z "$(find race.json -mindepth 1 -print -quit)"
ln -s target link.json
if bash "$script" good 123 link.json > /dev/null 2>&1; then echo 'accepted symlink output'; exit 1; fi
if CONFLUENCE_TOKEN=$'dummy\nurl = "https://evil.test"' bash "$script" good 123 out.json > /dev/null 2>&1; then
  echo 'accepted credential newline'; exit 1
fi
printf 'keep-existing' > out.json
if FAIL_CURL=1 bash "$script" good 123 out.json > /dev/null 2>&1; then echo 'transport failure accepted'; exit 1; fi
[ "$(cat out.json)" = keep-existing ] || { echo 'transport failure clobbered output'; exit 1; }
bash "$script" good 123 out.json > /dev/null
grep -q -- '--max-time' "$CALLS"
test -f out.json
echo 'Fetch validation tests passed'
