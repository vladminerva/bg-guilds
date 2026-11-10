#!/usr/bin/env bash
# Build and publish a BG Guilds release. Players' updaters pick it up at their next Windows login.
# Usage: ./release.sh            build + publish
#        ./release.sh --dry-run  build only (dist/), publish nothing
set -euo pipefail
cd "$(dirname "$0")"
REPO="${BGG_REPO:-vladminerva/bg-guilds}"
ADDON_VER=$(sed -n 's/^## Version: //p' addon/BGGuilds/BGGuilds.toc | tr -d '\r')
DATA_VER=$(sed -n 's/^  version = "\(.*\)",$/\1/p' addon/BGGuilds_Data/Data.lua)
STAMP=$(date +%Y%m%d-%H%M)
VERSION="${ADDON_VER}-${STAMP}"
TAG="v${VERSION}"

rm -rf dist && mkdir -p dist/stage/addon dist/stage/installer
cp -R addon/BGGuilds addon/BGGuilds_Data dist/stage/addon/
printf '%s\n' "$VERSION" > dist/stage/addon/BGGuilds_Data/version.txt
(cd dist/stage/addon && zip -qr -X ../../BGGuilds.zip BGGuilds BGGuilds_Data -x '*.DS_Store')
printf '%s\n' "$VERSION" > dist/version.txt

# Windows files: fill in the repo, convert to CRLF (cmd mishandles labels in LF-only batch files).
for f in install-updater.bat update.bat uninstall-updater.bat README.txt; do
  sed "s#__REPO__#${REPO}#g" "windows/$f" | perl -pe 's/\r?\n/\r\n/' > "dist/stage/installer/$f"
done
grep -q "__REPO__" dist/stage/installer/*.bat && { echo "repo placeholder left in installer"; exit 1; }
(cd dist/stage/installer && zip -q -X ../../BGGuilds-installer.zip *)

luajit -bl addon/BGGuilds/BGGuilds.lua >/dev/null
luajit -bl addon/BGGuilds_Data/Data.lua >/dev/null
luajit test/smoke.lua "$PWD" | tail -1

echo "Built $VERSION (data $DATA_VER):"
ls -la dist/*.zip dist/version.txt
if [[ "${1:-}" == "--dry-run" ]]; then exit 0; fi

gh release create "$TAG" --repo "$REPO" --title "BG Guilds $VERSION" \
  --notes "Addon ${ADDON_VER}, guild data from ${DATA_VER}. Installed players get this automatically at their next Windows login." \
  dist/BGGuilds.zip dist/BGGuilds-installer.zip dist/version.txt
echo "Published: https://github.com/${REPO}/releases/tag/${TAG}"
