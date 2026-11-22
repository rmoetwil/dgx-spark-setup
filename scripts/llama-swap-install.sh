#!/usr/bin/env bash
# Install or upgrade llama-swap (linux arm64) from its GitHub releases into ~/.local/bin.
#
# Usage: llama-swap-install.sh [version]     version without the "v", e.g. 275; default: latest
set -euo pipefail

REPO=mostlygeek/llama-swap
DEST=${LLAMA_SWAP_BIN_DIR:-$HOME/.local/bin}

die() { echo "llama-swap-install: $*" >&2; exit 1; }
log() { echo "llama-swap-install: $*" >&2; }

version=${1:-}
if [ -z "$version" ]; then
  tag=$(curl -fsSL --max-time 30 "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
  [ -n "$tag" ] || die "could not find the latest release"
  version=${tag#v}
fi
[[ "$version" =~ ^[0-9]+$ ]] || die "unexpected version '$version'"

current=$("$DEST/llama-swap" --version 2>/dev/null | sed -n 's/^version: v\([0-9]*\).*/\1/p' || true)
log "installed: ${current:-none}, requested: $version"
[ "$current" != "$version" ] || { log "up to date"; exit 0; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
base=https://github.com/$REPO/releases/download/v$version
file=llama-swap_${version}_linux_arm64.tar.gz
log "downloading $file"
curl -fsSL -o "$tmp/$file" "$base/$file" || die "download failed"
curl -fsSL -o "$tmp/checksums.txt" "$base/llama-swap_${version}_checksums.txt" || die "checksums download failed"
(cd "$tmp" && grep " $file\$" checksums.txt | sha256sum -c --quiet -) || die "checksum mismatch"

tar -xzf "$tmp/$file" -C "$tmp" llama-swap
mkdir -p "$DEST"
install -m 755 "$tmp/llama-swap" "$DEST/llama-swap"
log "$("$DEST/llama-swap" --version | head -1)"
log "restart llama-swap to use the new version"
