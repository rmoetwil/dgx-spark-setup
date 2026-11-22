#!/usr/bin/env bash
# Upgrade the LM Studio AppImage (linux arm64) to the latest version.
#
# Layout:
#   ~/Applications/LM-Studio-<version>-arm64.AppImage   one file per version
#   ~/Applications/LM-Studio.AppImage                   symlink to the current version
#   ~/.local/share/applications/lm-studio.desktop      launcher; runs the symlink
# Because the launcher runs the symlink, an upgrade only has to repoint it.
# The previous version is kept for rollback; older ones are deleted.
#
# Usage: lmstudio-upgrade.sh              download and activate the latest version
#        lmstudio-upgrade.sh --check      only report whether an upgrade is available
#        lmstudio-upgrade.sh --rollback   switch to the other kept version
set -euo pipefail

APP_DIR=$HOME/Applications
LINK=$APP_DIR/LM-Studio.AppImage
DESKTOP=$HOME/.local/share/applications/lm-studio.desktop
LATEST_URL=https://lmstudio.ai/download/latest/linux/arm64

die() { echo "lmstudio-upgrade: $*" >&2; exit 1; }
log() { echo "lmstudio-upgrade: $*" >&2; }

version_of() { local f=${1##*/}; f=${f#LM-Studio-}; echo "${f%-arm64.AppImage}"; }

# Installed versions, oldest first.
installed() { { ls -1 "$APP_DIR"/LM-Studio-*-arm64.AppImage 2>/dev/null || true; } | sort -V; }

# installed versions except $1 (grep exits 1 on no match, which pipefail would turn fatal)
others() { installed | { grep -vxF "$1" || true; }; }

current() {
  if [ -L "$LINK" ]; then
    readlink -f "$LINK"
  else
    # Before the first run of this script, the launcher names the file directly.
    sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$DESKTOP" 2>/dev/null | head -1
  fi
}

# Match only processes whose command starts with an LM Studio AppImage or its mounted binary,
# not other commands that merely mention the file name.
running() { pgrep -f '^([^ ]*/)?LM-Studio[^ /]*\.AppImage|^[^ ]*/\.mount_LM-Stu[^ /]*/' >/dev/null; }

write_desktop() {
  mkdir -p "$(dirname "$DESKTOP")"
  [ -f "$DESKTOP" ] && cp "$DESKTOP" "$DESKTOP.bak"
  cat >"$DESKTOP" <<EOF
[Desktop Entry]
Name=LM Studio
Comment=LLM tool and more
Exec=$LINK --no-sandbox
Icon=$APP_DIR/lm-studio.png
Type=Application
Categories=Development;AI;
Terminal=false
EOF
  command -v update-desktop-database >/dev/null && update-desktop-database "$(dirname "$DESKTOP")" || true
}

activate() {   # point the symlink and launcher at $1
  ln -sfn "$(basename "$1")" "$LINK"
  write_desktop
  log "active version: $(version_of "$1")"
}

cmd_rollback() {
  running && die "LM Studio is running; quit it first"
  local cur prev
  cur=$(current)
  prev=$(others "$cur" | tail -1)
  [ -n "$prev" ] || die "no previous version to roll back to"
  activate "$prev"
}

cmd_upgrade() {
  local check=${1:-}
  local url file latest cur
  url=$(curl -fsSIL -o /dev/null -w '%{url_effective}' --max-time 30 "$LATEST_URL") \
    || die "could not reach $LATEST_URL"
  file=${url##*/}
  [[ "$file" =~ ^LM-Studio-[0-9][0-9.]*-[0-9]+-arm64\.AppImage$ ]] \
    || die "unexpected download name: $file"
  latest=$(version_of "$file")
  cur=$(current)
  local cur_v=none; [ -z "$cur" ] || cur_v=$(version_of "$cur")
  log "installed: $cur_v, latest: $latest"

  if [ "$(readlink -f "$cur" 2>/dev/null)" = "$APP_DIR/$file" ]; then
    # Already on the latest version; still migrate an old-style launcher to the symlink.
    [ -L "$LINK" ] || { [ -n "$check" ] || activate "$APP_DIR/$file"; }
    log "up to date"; return 0
  fi
  [ -z "$check" ] || { log "upgrade available"; return 0; }
  running && die "LM Studio is running; quit it first"

  local dest=$APP_DIR/$file
  if [ ! -f "$dest" ]; then
    log "downloading $file"
    curl -fL --progress-bar --retry 3 -o "$dest.part" "$url" || { rm -f "$dest.part"; die "download failed"; }
    # Sanity check: an AppImage is an ELF executable.
    [ "$(head -c 4 "$dest.part" | od -An -c | tr -d ' ')" = '177ELF' ] \
      || { rm -f "$dest.part"; die "download is not an AppImage"; }
    chmod +x "$dest.part"
    mv "$dest.part" "$dest"
  fi
  activate "$dest"

  # Keep the new version and the one before it; delete the rest.
  local old
  others "$dest" | head -n -1 | while read -r old; do
    log "removing old version $(version_of "$old")"
    rm -f "$old"
  done
}

case "${1:-}" in
  '') cmd_upgrade ;;
  --check) cmd_upgrade check ;;
  --rollback) cmd_rollback ;;
  -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) die "unknown option '$1'; use --check, --rollback or no option" ;;
esac
