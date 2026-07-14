#!/bin/bash

# === Release Version (ANPASSEN) ===
RELEASE_VERSION=""          # 0 … 999
SHELL_SCRIPT="v${RELEASE_VERSION}.sh"

# === URLs ===
ZIP_URL="https://github.com/x-FK-x/1002xSHELL/releases/download/v${RELEASE_VERSION}/v${RELEASE_VERSION}.zip"
ZIP_FILE="1002xSHELL-v${RELEASE_VERSION}.zip"

# === Paths ===
INSTALL_DIR="/etc/1002xSHELL"
TEMP_DIR="/tmp/1002xSHELL-install"
BASHRC_FILE="/etc/bash.bashrc"
BASHRC_TAG="# 1002xSHELL AUTOLOAD"

# === Download ===
echo "[*] Downloading 1002xSHELL V${RELEASE_VERSION}..."
wget -q -O "$ZIP_FILE" "$ZIP_URL"

if [[ $? -ne 0 || ! -f "$ZIP_FILE" ]]; then
    echo "[!] Failed to download archive"
    exit 1
fi

# === Prepare temp directory ===
echo "[*] Preparing temporary directory..."
sudo rm -rf "$TEMP_DIR"
sudo mkdir -p "$TEMP_DIR"

# === Extract ===
echo "[*] Extracting archive..."
sudo unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# === Validate shell script ===
if ! find "$TEMP_DIR" -type f -name "$SHELL_SCRIPT" | grep -q .; then
    echo "[!] $SHELL_SCRIPT not found in archive"
    exit 1
fi

echo "[*] Detected shell script: $SHELL_SCRIPT"

# === Install ===
echo "[*] Installing shell..."
sudo mkdir -p "$INSTALL_DIR"
sudo cp "$TEMP_DIR/$SHELL_SCRIPT" "$INSTALL_DIR/$SHELL_SCRIPT"
sudo chmod +x "$INSTALL_DIR/$SHELL_SCRIPT"

# === Update bash.bashrc ===
echo "[*] Updating global shell loader..."

sudo sed -i "/$BASHRC_TAG/,+5d" "$BASHRC_FILE"

sudo tee -a "$BASHRC_FILE" > /dev/null <<EOF

$BASHRC_TAG
if [[ -f $INSTALL_DIR/$SHELL_SCRIPT ]]; then
    source $INSTALL_DIR/$SHELL_SCRIPT
fi
EOF


sudo sed -i 's/\r$//' /etc/1002xSHELL/v3.sh
if grep -q "# 1002xSHELL AUTOLOAD" /etc/bash.bashrc; then
    sudo sed -i '
    /# 1002xSHELL AUTOLOAD/{
        n
        s|/etc/1002xSHELL/v[0-9]\+\.sh|/etc/1002xSHELL/v4.sh|
        n
        s|/etc/1002xSHELL/v[0-9]\+\.sh|/etc/1002xSHELL/v4.sh|
    }' /etc/bash.bashrc
else
    sudo tee -a /etc/bash.bashrc > /dev/null <<'EOF'

# 1002xSHELL AUTOLOAD
if [[ -f /etc/1002xSHELL/v5.sh ]]; then
    source /etc/1002xSHELL/v5.sh
fi
EOF
fi



# === Cleanup ===
echo "[*] Cleaning up..."
sudo rm -rf "$TEMP_DIR"
rm -f "$ZIP_FILE"

echo "[✓] 1002xSHELL V${RELEASE_VERSION} installed successfully"

# DODOS - DownTown1002xCollection of Debian OS
