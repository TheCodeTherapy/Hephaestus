#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ CONFIG                                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝
PROJECT_NAME="Hephaestus"
GH_USER="TheCodeTherapy"
REPO_URL="https://github.com/$GH_USER/$PROJECT_NAME.git"

USERNAME="marcogomez"
FLAKE_HOST="threadripper"
DISK="/dev/nvme0n1"

MOUNTPOINT="/mnt"
PART_BOOT_SIZE="513MiB"
PART_ROOT_SIZE="262144MiB"

USER_HOME="$MOUNTPOINT/home/$USERNAME"
USER_REPO="$USER_HOME/$PROJECT_NAME"

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ SANITY CHECK                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Error trap + logging
exec > >(tee install.log) 2>&1
trap 'echo "❌ An error occurred. Check install.log for details."' ERR

# Ensure disk exists
if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk $DISK does not exist"
  exit 1
fi

# Ensure network is up
ping -c 1 github.com >/dev/null || { echo "❌ No internet. Abort."; exit 1; }

# Sync time to avoid SSL issues
timedatectl set-ntp true

# Unmount previous mounts (safe fallback)
umount -R "$MOUNTPOINT" || true

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ PARTITIONING                                                             ║
# ╚══════════════════════════════════════════════════════════════════════════╝
read -p "!!! WARNING: This will WIPE $DISK. Continue? (yes/no): " confirm
[[ "$confirm" == "yes" ]] || exit 1

echo "[*] Wiping and partitioning $DISK..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
sgdisk -n1:1MiB:+$PART_BOOT_SIZE -t1:ef00 -c1:"BOOT" "$DISK"
sgdisk -n2:0:+$PART_ROOT_SIZE    -t2:8300 -c2:"ROOT" "$DISK"
sgdisk -n3:0:0                   -t3:8300 -c3:"HOME" "$DISK"
partprobe "$DISK"
sleep 3

BOOT="${DISK}p1"
ROOT="${DISK}p2"
HOME="${DISK}p3"

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ FORMATTING                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════╝
echo "[*] Creating filesystems..."
mkfs.vfat -F32 -n BOOT "$BOOT"
mkfs.ext4 -L ROOT "$ROOT"
mkfs.ext4 -L HOME "$HOME"

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ MOUNTING                                                                 ║
# ╚══════════════════════════════════════════════════════════════════════════╝
echo "[*] Mounting target system..."
mount "$ROOT" "$MOUNTPOINT"
mkdir -p "$MOUNTPOINT"/{boot,home}
mount "$BOOT" "$MOUNTPOINT/boot"
mount "$HOME" "$MOUNTPOINT/home"

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ CLONE FLAKE REPO TO USER HOME                                            ║
# ╚══════════════════════════════════════════════════════════════════════════╝
echo "[*] Cloning flake repo into $USER_REPO..."
mkdir -p "$USER_HOME"
git clone "$REPO_URL" "$USER_REPO"
chown -R 1000:100 "$USER_HOME"  # UID:GID of first user (assumes 1000)

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INSTALL NIXOS                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════╝
echo "[*] Installing NixOS from flake in user home..."
nixos-install --no-root-password --flake "/home/$USERNAME/$PROJECT_NAME#$FLAKE_HOST"

echo "[✔] Installation complete. Reboot into your flake-managed system."
