#!/usr/bin/env bash
# Install or upgrade Node.js and promptfoo in the home directory, without sudo.
#
#   ~/.local/opt/node-v<version>   Node.js, official linux-arm64 release, checksum verified
#   ~/.local/opt/node              symlink to the active Node.js version
#   ~/.local/opt/promptfoo         promptfoo, installed with that Node.js
#
# Run promptfoo through scripts/promptfoo-offline, which switches off telemetry.
#
# Usage: promptfoo-install.sh [promptfoo-version]     default: latest
# Set NODE_MAJOR to choose the Node.js line (default 24, the LTS line promptfoo recommends).
set -euo pipefail

NODE_MAJOR=${NODE_MAJOR:-24}
OPT=$HOME/.local/opt
PF_VERSION=${1:-latest}

die() { echo "promptfoo-install: $*" >&2; exit 1; }
log() { echo "promptfoo-install: $*" >&2; }

[ "$(uname -m)" = aarch64 ] || die "this script installs the linux-arm64 build; adapt it for $(uname -m)"

# ---- Node.js ----
node_version=$(curl -fsSL --max-time 30 https://nodejs.org/dist/index.json \
  | grep -o "\"version\":\"v${NODE_MAJOR}\.[0-9.]*\"" | head -1 | cut -d'"' -f4)
[ -n "$node_version" ] || die "could not find the latest Node.js $NODE_MAJOR release"
node_dir=$OPT/node-$node_version

if [ -x "$node_dir/bin/node" ]; then
  log "Node.js $node_version already installed"
else
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  file=node-$node_version-linux-arm64.tar.xz
  base=https://nodejs.org/dist/$node_version
  log "downloading $file"
  curl -fsSL -o "$tmp/$file" "$base/$file" || die "download failed"
  curl -fsSL -o "$tmp/SHASUMS256.txt" "$base/SHASUMS256.txt" || die "checksums download failed"
  (cd "$tmp" && grep "  $file\$" SHASUMS256.txt | sha256sum -c --quiet -) || die "checksum mismatch"
  mkdir -p "$OPT"
  tar -xJf "$tmp/$file" -C "$tmp"
  mv "$tmp/node-$node_version-linux-arm64" "$node_dir"
  log "installed Node.js $node_version"
fi
ln -sfn "node-$node_version" "$OPT/node"

# ---- promptfoo ----
export PATH=$OPT/node/bin:$PATH
# No telemetry or update checks during the installation either.
export PROMPTFOO_DISABLE_TELEMETRY=1 PROMPTFOO_DISABLE_UPDATE=1
log "installing promptfoo@$PF_VERSION"
npm install --global --prefix "$OPT/promptfoo" --no-fund --no-audit "promptfoo@$PF_VERSION" >&2
log "promptfoo $("$OPT/promptfoo/bin/promptfoo" --version) with Node.js $(node --version)"
