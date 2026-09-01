#!/bin/bash

# ==========================================
# 1002xOPERATOR Installer (CURL/UNZIP Check)
# ==========================================

ZIP_URL="https://github.com/x-FK-x/1002xOPERATOR/archive/refs/heads/main.zip"
ZIP_FILE="/tmp/1002xOPERATOR.zip"
INSTALL_DIR="/etc/1002xOPERATOR"
BASHRC="/etc/bash.bashrc"



if [[ "${1:-}" == "uninstall" ]]; then
    echo "[*] Removing 1002xOPERATOR..."
    sudo rm -r "$INSTALL_DIR"
    sudo sed -i '/1002xOPERATOR/d' "$BASHRC"
    echo "[✓] Successfully removed."
    exit 0
fi

echo "========================================="
echo "      1002xOPERATOR Installer"
echo "========================================="

# ==========================
# CHECK DEPENDENCIES
# ==========================
for pkg in curl unzip; do
    if ! command -v $pkg &> /dev/null; then
        echo "[*] $pkg is missing. Installing..."
        sudo apt-get update && sudo apt-get install -y $pkg
    fi
done

# ==========================
# DOWNLOAD
# ==========================
echo "[*] Downloading archive..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
# -L follows redirects, -o specifies output file
sudo curl -L "$ZIP_URL" -o "$ZIP_FILE"

if [[ ! -s "$ZIP_FILE" ]]; then
    echo "[!] Download failed or file is empty."
    exit 1
fi

# ==========================
# EXTRACT & RESTRUCTURE
# ==========================
echo "[*] Extracting and restructuring..."
# Extracting into /etc/1002xOPERATOR (creates /etc/1002xOPERATOR/1002xOPERATOR-main/)
sudo unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

# Locate the automatically created subdirectory
SUBDIR=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "1002xOPERATOR-main")

if [ -d "$SUBDIR" ]; then
    echo "[*] Moving files from $SUBDIR to $INSTALL_DIR..."
    # Move all contents (including hidden files) from subdir to root
    sudo cp -rf "$SUBDIR"/. "$INSTALL_DIR/"
    # Delete the now empty subdir
    sudo rm -rf "$SUBDIR"
    echo "[✓] Files moved successfully."
else
    echo "[!] Error: Subdirectory 1002xOPERATOR-main not found."
    exit 1
fi

# ==========================
# FINISH
# ==========================
sudo rm -f "$ZIP_FILE"
sudo chmod -R 755 "$INSTALL_DIR"

# Add global alias if it doesn't exist
if ! grep -q "alias 1002xOPERATOR=" "$BASHRC"; then
    echo "alias 1002xOPERATOR='bash $INSTALL_DIR/menu.sh'" | sudo tee -a "$BASHRC" >/dev/null
    echo "[✓] Global alias added to $BASHRC"
fi

echo
if [[ -f "$INSTALL_DIR/menu.sh" ]]; then
    echo "[✓] Installation successful!"
    echo "-----------------------------------------"
    echo "Structure in $INSTALL_DIR:"
    ls -F "$INSTALL_DIR"
    echo "-----------------------------------------"
    echo "To activate, run: source $BASHRC"
    echo "Then simply type: 1002xOPERATOR"
else
    echo "[!] Critical Error: menu.sh not found in $INSTALL_DIR."
fi
source /etc/bash.bashrc