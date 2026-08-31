#!/bin/bash

# === Detect version directory ===
if [[ -d /etc/DODOS ]]; then
  BASE_DIR="/etc/DODOS"
elif [[ -d /etc/modos ]]; then
  BASE_DIR="/etc/modos"
else
  echo "No valid *odos directory found."
  exit 1
fi

sudo apt-get install curl -y

TOOLS_DIR="$BASE_DIR/tools"
OSVERSION_FILE="$TOOLS_DIR/osversion.txt"
UPDATER_FILE="$TOOLS_DIR/updater.sh"
UPDATER_URL="https://raw.githubusercontent.com/x-FK-x/1002xTOOLS/refs/heads/_odos/DEBIAN13/tools/updater.sh"
TARGET_VERSION="DEBIAN13"

# === Check current OS version ===
if [[ -f "$OSVERSION_FILE" ]]; then
  CURRENT_VERSION=$(head -n1 "$OSVERSION_FILE" | tr -d '[:space:]')
else
  CURRENT_VERSION=""
fi

if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]]; then
  echo "System already on $TARGET_VERSION. No migration needed."
  exit 0
fi

# === Update osversion.txt ===
echo "$TARGET_VERSION" > "$OSVERSION_FILE"

# === Replace updater.sh ===
rm -f "$UPDATER_FILE"
echo "0" > /etc/_odos/dev.txt

curl -fsSL "$UPDATER_URL" -o "$UPDATER_FILE"
chmod +x "$UPDATER_FILE"
sudo bash "$UPDATER_FILE"
rm /etc/_odos/tools/migration.sh

echo "Migration completed: $CURRENT_VERSION -> $TARGET_VERSION"
