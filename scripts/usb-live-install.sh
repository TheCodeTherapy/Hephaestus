#!/usr/bin/env bash
set -euo pipefail

# https://mgz.me/nixinstall.sh
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
exec > >(tee install.log) 2>&1
trap 'echo "❌ An error occurred. Check install.log for details."' ERR

if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root. Try: sudo ./install.sh"
  exit 1
fi

if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk $DISK does not exist"
  exit 1
fi

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
# ║ PASSWORD SETUP                                                           ║
# ╚══════════════════════════════════════════════════════════════════════════╝
echo "[*] Set password for user $USERNAME"
read -s -p "Password: " user_pass
echo
read -s -p "Confirm: " user_pass_confirm
echo

if [[ "$user_pass" != "$user_pass_confirm" ]]; then
  echo "❌ Passwords do not match. Aborting."
  exit 1
fi

echo "[*] Hashing password..."
hashed_pass=$(nix-shell -p whois --run "mkpasswd -m sha-512 '$user_pass'")

echo "[*] Injecting password override into flake..."
mkdir -p "$USER_REPO/etc/nixos"
cat > "$USER_REPO/etc/nixos/password-override.nix" <<EOF
{ config, pkgs, ... }: {
  users.users.$USERNAME.hashedPassword = "$hashed_pass";
  users.users.root.hashedPassword = "$hashed_pass";
}
EOF

# Add the override module to flake.nix if not already added
if ! grep -q 'password-override.nix' "$USER_REPO/flake.nix"; then
  sed -i "/\/configuration\.nix/a\        ./etc/nixos/password-override.nix" "$USER_REPO/flake.nix"
fi

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ INSTALL NIXOS                                                            ║
# ╚══════════════════════════════════════════════════════════════════════════╝
echo "[*] Installing NixOS from flake in user home..."
nixos-install --no-root-password --flake "/home/$USERNAME/$PROJECT_NAME#$FLAKE_HOST"

echo "[✔] Installation complete. After boot:"
echo "    rm ~/Hephaestus/etc/nixos/password-override.nix"
echo "    and remove the line from flake.nix"
