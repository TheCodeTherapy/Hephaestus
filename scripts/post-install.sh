#!/usr/bin/env bash
set -euo pipefail

FLAKE_DIR=~/Hephaestus
OVERRIDE_PATH="$FLAKE_DIR/etc"
FLAKE_FILE="$FLAKE_DIR/flake.nix"

echo "[*] Cleaning up password override..."

# Remove the override file
if [ -d "$OVERRIDE_PATH" ]; then
  echo " - Removing $OVERRIDE_PATH"
  sudo rm -rf "$OVERRIDE_PATH"
fi

cd $FLAKE_DIR
git reset HEAD flake.nix && git restore flake.nix
git remote set-url origin git@github.com:TheCodeTherapy/Hephaestus.git

echo "[✔] Cleanup complete. You can now rebuild your system if needed:"
echo "    sudo nixos-rebuild switch --flake ~/Hephaestus#threadripper"
