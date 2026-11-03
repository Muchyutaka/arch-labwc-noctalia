#!/usr/bin/env bash
#
# Download five free-use wallpapers from Unsplash into a local folder.
#
# The images are fetched at run time, never bundled in this repo. Unsplash's
# licence allows free use (personal and commercial); see WALLPAPERS.md.
#
# Safe to re-run: existing files are left alone unless --force is given.
#
# Usage:
#   ./scripts/fetch-wallpapers.sh [--force] [--dir <folder>]
#
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers/free-use}"
FORCE=0

while (($#)); do
  case "$1" in
    --force) FORCE=1 ;;
    --dir)
      [[ $# -ge 2 ]] || { echo "error: --dir needs a folder" >&2; exit 1; }
      DEST=$2
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Download five free-use wallpapers from Unsplash into a local folder.

The images are fetched at run time, never bundled in this repo.
Safe to re-run: existing files are left alone unless --force is given.

Usage:
  ./scripts/fetch-wallpapers.sh [--force] [--dir <folder>]

Options:
  --force       Re-download files that already exist
  --dir <dir>   Destination (default: ~/Pictures/Wallpapers/free-use)
  -h, --help    Show this help
EOF
      exit 0
      ;;
    *) echo "error: unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done

command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }

# Five landscape photos. The w/q/fm/fit parameters ask Unsplash's CDN for a
# 1920 px JPEG that is suitable as a desktop wallpaper.
BASE="https://images.unsplash.com/photo-"
SUFFIX="?w=1920&q=85&fm=jpg&fit=crop"

IDS=(
  1519681393784-d120267933ba
  1470071459604-3b5ec3a7fe05
  1441974231531-c6227db76b6e
  1506905925346-21bda4d32df4
  1464822759023-fed622ff2c3b
)

NAMES=(
  01-milky-way-peaks.jpg
  02-valley-mist.jpg
  03-forest-sunlight.jpg
  04-sea-of-clouds.jpg
  05-glacier-valley.jpg
)

DEST="$(realpath -m -- "$DEST")"
mkdir -p "$DEST"
downloaded=0
skipped=0

for i in "${!IDS[@]}"; do
  file="$DEST/${NAMES[$i]}"
  if [[ -s $file && $FORCE -eq 0 ]]; then
    skipped=$((skipped + 1))
    continue
  fi

  printf '  downloading %s\n' "${NAMES[$i]}"
  tmp="$file.part"
  if ! curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 180 \
       -o "$tmp" "${BASE}${IDS[$i]}${SUFFIX}"; then
    rm -f "$tmp"
    echo "error: failed to download ${NAMES[$i]}" >&2
    exit 1
  fi
  mv -f "$tmp" "$file"
  downloaded=$((downloaded + 1))
done

# Keep the licence note next to the images.
if [[ -f $REPO_DIR/WALLPAPERS.md ]]; then
  install -m 0644 "$REPO_DIR/WALLPAPERS.md" "$DEST/CREDITS.md"
fi

# Point Noctalia's wallpaper picker at the folder holding this set, but keep
# ~/Pictures/Wallpapers as the browse root so the user's own images stay
# visible next to the free-use subfolder.
if command -v noctalia >/dev/null 2>&1; then
  browse="$DEST"
  if [[ $DEST == "$HOME/Pictures/Wallpapers/free-use" ]]; then
    browse="$HOME/Pictures/Wallpapers"
  fi
  noctalia msg config-set wallpaper.directory "\"$browse\"" >/dev/null 2>&1 || true
fi

echo "Wallpapers in $DEST (${downloaded} downloaded, ${skipped} already present)"
for name in "${NAMES[@]}"; do
  [[ -s $DEST/$name ]] && echo "  $name"
done
