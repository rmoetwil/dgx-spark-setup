# Install LM Studio

LM Studio runs as an AppImage for the `arm64` architecture.
The script `scripts/lmstudio-upgrade.sh` installs and upgrades it.

## Layout

| Path | Purpose |
|---|---|
| `~/Applications/LM-Studio-<version>-arm64.AppImage` | one file per version |
| `~/Applications/LM-Studio.AppImage` | symlink to the active version |
| `~/Applications/lm-studio.png` | launcher icon |
| `~/.local/share/applications/lm-studio.desktop` | desktop launcher; runs the symlink |

The launcher runs the symlink, so an upgrade only repoints the symlink.
The launcher itself never has to be edited.

## Install the script

Link the script into `~/.local/bin` once:

```bash
ln -s ~/data/github/rmoetwil/dgx-spark-setup/scripts/lmstudio-upgrade.sh ~/.local/bin/lmstudio-upgrade
```

## Upgrade

Quit LM Studio first; the script refuses to run while it is open.

```bash
lmstudio-upgrade --check     # only report whether an upgrade is available
lmstudio-upgrade             # download and activate the latest version
lmstudio-upgrade --rollback  # switch to the other kept version
```

The script finds the latest version through `https://lmstudio.ai/download/latest/linux/arm64`, which redirects to the newest AppImage.
It keeps the previous version for rollback and deletes older ones.

## Models folder

`downloadsFolder` in `~/.lmstudio/settings.json` points to `/mnt/ai-data/models` on the external SSD.
LM Studio stores models there as `<publisher>/<model>/<file>.gguf`, and also lists the other GGUFs in that folder.

## Manual install

If the script fails, download the AppImage from https://lmstudio.ai/download and select the `arm64` architecture.
Move it to `~/Applications`, make it executable and point the symlink at it:

```bash
chmod +x ~/Applications/LM-Studio-<version>-arm64.AppImage
ln -sfn LM-Studio-<version>-arm64.AppImage ~/Applications/LM-Studio.AppImage
```
