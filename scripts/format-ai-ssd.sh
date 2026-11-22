#!/usr/bin/env bash
# Reformat the external USB Samsung 990 PRO to ext4 and mount it at /mnt/ai-data.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }
OWNER=${SUDO_USER:?run via sudo from your own account}
MNT=/mnt/ai-data
LABEL=ai-data

# Pick the disk by model + USB transport; refuse unless exactly one match.
mapfile -t DISKS < <(lsblk -dn -o NAME,TRAN,MODEL | awk '$2=="usb" && /990 PRO 1TB/ {print $1}')
[ "${#DISKS[@]}" -eq 1 ] || { echo "Expected exactly one USB 990 PRO, found: ${DISKS[*]:-none}"; exit 1; }
DEV=/dev/${DISKS[0]}
[ "$DEV" != "$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" | sed 's|^|/dev/|')" ] || { echo "Refusing: $DEV holds /"; exit 1; }

lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,TRAN,MODEL "$DEV"
read -rp "ERASE everything on $DEV? Type YES: " ok
[ "$ok" = "YES" ] || { echo "Aborted"; exit 1; }

for p in $(lsblk -ln -o PATH "$DEV" | tail -n +2); do umount "$p" 2>/dev/null || true; done
wipefs -a "$DEV"
parted -s "$DEV" mklabel gpt mkpart "$LABEL" ext4 0% 100%
udevadm settle
PART=$(lsblk -ln -o PATH "$DEV" | tail -n 1)
mkfs.ext4 -F -L "$LABEL" -m 0 "$PART"
udevadm settle
UUID=$(blkid -s UUID -o value "$PART")

mkdir -p "$MNT"
cp /etc/fstab /etc/fstab.bak.$(date +%F)
grep -q " $MNT " /etc/fstab || \
  echo "UUID=$UUID $MNT ext4 defaults,noatime,nofail,x-systemd.device-timeout=10s 0 2" >> /etc/fstab
systemctl daemon-reload
mount "$MNT"
chown "$OWNER:$OWNER" "$MNT"
findmnt "$MNT"
df -h "$MNT"
echo "Done."
