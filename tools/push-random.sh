#!/usr/bin/env bash
# Render a random view and direction of the Enterprise and push it to your Tidbyt
# as the installation "enterprise", quietly in the background (it won't interrupt
# whatever is showing; it joins the rotation).
#
# Needs pixlet on PATH and an env file (default ~/.config/tidbyt/env, chmod 600) with:
#   export TIDBYT_DEVICE_ID=...
#   export TIDBYT_API_KEY=...
# Set DRY_RUN=1 to render without pushing.
#
# Example cron entry (hourly):
#   0 * * * * /path/to/tidbyt-enterprise/tools/push-random.sh >> ~/.cache/tidbyt-enterprise.log 2>&1
set -euo pipefail

ENV_FILE="${TIDBYT_ENV:-$HOME/.config/tidbyt/env}"
# shellcheck disable=SC1090
. "$ENV_FILE"
: "${TIDBYT_DEVICE_ID:?set TIDBYT_DEVICE_ID in $ENV_FILE}"
: "${TIDBYT_API_KEY:?set TIDBYT_API_KEY in $ENV_FILE}"

here="$(cd "$(dirname "$0")/.." && pwd)"
views=(side top bottom diagonal battle approach recede)
dirs=(right left)
view="${views[RANDOM % ${#views[@]}]}"
dir="${dirs[RANDOM % ${#dirs[@]}]}"

out="$(mktemp --suffix=.webp)"
trap 'rm -f "$out"' EXIT
pixlet render "$here/enterprise.star" "view=$view" "direction=$dir" -o "$out"

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "dry run: rendered view=$view direction=$dir ($(stat -c %s "$out") bytes)"
  exit 0
fi
pixlet push --background --api-token "$TIDBYT_API_KEY" --installation-id enterprise "$TIDBYT_DEVICE_ID" "$out"
echo "$(date -Is) pushed view=$view direction=$dir"
