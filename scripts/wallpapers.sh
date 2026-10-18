#!/usr/bin/env bash
# Fetch wallpapers into ~/Pictures/Wallpapers.
# Wallpapers are intentionally NOT tracked by this repo (size + licensing).
#
#   ./wallpapers.sh                 # clone the reference collection only
#   ./wallpapers.sh --with-personal # also download URLs from wallpapers.personal.txt
#
# Put your own image URLs (one per line, # for comments) in
# scripts/wallpapers.personal.txt — that file is gitignored.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
SOURCE_REPO="${WALLPAPER_REPO:-https://github.com/RanXom/glassy-niri}"
PERSONAL_LIST="$SCRIPT_DIR/wallpapers.personal.txt"

WITH_PERSONAL=0
[[ "${1:-}" == "--with-personal" ]] && WITH_PERSONAL=1

mkdir -p "$DEST"

echo "==> Reference collection: $SOURCE_REPO"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth=1 --filter=blob:none --sparse "$SOURCE_REPO" "$TMP/repo"
git -C "$TMP/repo" sparse-checkout set wallpapers
cp -an "$TMP/repo/wallpapers/." "$DEST/" || true
echo "    copied into $DEST"

if (( WITH_PERSONAL )); then
  if [[ ! -f "$PERSONAL_LIST" ]]; then
    echo "!! $PERSONAL_LIST not found — create it, one URL per line" >&2
    exit 1
  fi
  echo "==> Personal list: $PERSONAL_LIST"
  while read -r url; do
    [[ -z "$url" || "$url" == \#* ]] && continue
    name="$(basename "${url%%\?*}")"
    echo "    $name"
    curl -fsSL "$url" -o "$DEST/$name"
  done < "$PERSONAL_LIST"
fi

echo "==> Done. Files in $DEST"
