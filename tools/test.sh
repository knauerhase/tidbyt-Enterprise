#!/usr/bin/env bash
# Checks for the Enterprise app. Needs pixlet on PATH.
#   tools/test.sh          quick: every part, Reverse on/off, each scene, community CI checks
#   FULL=1 tools/test.sh   also every ordered pair of scenes (about 40 renders)
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
limit=$((192 * 1024))
fail=0

render() {  # render <label> <config...>
  local label="$1"; shift
  if ! pixlet render "$here/enterprise.star" "$@" -o "$tmp/out.webp" >"$tmp/log" 2>&1; then
    echo "FAIL render [$label]: $(tail -1 "$tmp/log")"; fail=1; return
  fi
  local size; size=$(stat -c %s "$tmp/out.webp")
  if [ "$size" -ge "$limit" ]; then echo "FAIL size [$label]: $size bytes (limit $limit)"; fail=1
  else echo "ok   [$label] $size bytes"; fi
}

for part in flyby skirmish headon surprise; do
  for rev in false true; do render "part=$part reverse=$rev" "part=$part" "reverse=$rev"; done
done
for scene in side top bottom diagonal battle approach recede; do render "scene1=$scene" "scene1=$scene"; done
render "scene1=all (full show)" scene1=all
render "legacy view=top" view=top
render "smooth=false" part=skirmish smooth=false

if [ "${FULL:-0}" = "1" ]; then
  scenes=(side top bottom diagonal battle approach recede)
  for a in "${scenes[@]}"; do for b in "${scenes[@]}"; do
    [ "$a" = "$b" ] || render "scene1=$a scene2=$b" "scene1=$a" "scene2=$b"
  done; done
fi

# The same checks the community repo's CI runs (it checks an apps/<name> directory).
mkdir -p "$tmp/apps/enterprise"
cp "$here/enterprise.star" "$here/manifest.yaml" "$tmp/apps/enterprise/"
cp "$here/LICENSE" "$tmp/apps/enterprise/LICENSE.txt"
if (cd "$tmp" && pixlet check apps/enterprise >"$tmp/check.log" 2>&1); then echo "ok   pixlet check apps/enterprise"
else echo "FAIL pixlet check:"; sed 's/^/     /' "$tmp/check.log" | tail -15; fail=1; fi
if pixlet community validate-manifest "$here/manifest.yaml" >"$tmp/m.log" 2>&1; then echo "ok   validate-manifest"
else echo "FAIL validate-manifest: $(tail -1 "$tmp/m.log")"; fail=1; fi

[ "$fail" = 0 ] && echo "ALL PASSED" || echo "SOME CHECKS FAILED"
exit "$fail"
