#!/usr/bin/env bash
# Install Antumbra (the binary released by the Penumbra project) for the
# current user. No root required.
#
# Antumbra is the MTK flash tool; `penumbra` is kept as a symlink so the old
# name keeps working. Override the destination with BINDIR=/some/dir.

set -euo pipefail

BINDIR="${BINDIR:-$HOME/.local/bin}"
mkdir -p "$BINDIR"

case "$(uname -m)" in
  x86_64)  asset=antumbra ;;
  aarch64) asset=antumbra-linux-aarch64 ;;
  *) printf 'error: unsupported architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
esac

url="https://github.com/shomykohai/penumbra/releases/latest/download/$asset"
tmp="$BINDIR/.antumbra.download.$$"
trap 'rm -f "$tmp"' EXIT

printf 'Downloading Antumbra (%s)\n' "$asset"
curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 --max-time 300 \
  -o "$tmp" "$url"

chmod 0755 "$tmp"
mv -f "$tmp" "$BINDIR/antumbra"
ln -sfn antumbra "$BINDIR/penumbra"

printf 'Installed %s to %s\n' \
  "$("$BINDIR/antumbra" --version 2>/dev/null || echo Antumbra)" "$BINDIR/antumbra"
printf 'Run: antumbra --help   (penumbra is a symlink)\n'
