#!/bin/bash

if [[ "${1:-}" == "uninstall" ]]; then
    echo "[*] Removing 1002xCMD..."
    sudo rm -r "/etc/1002xCMD"
    sudo sed -i '/1002xCMD/d' /etc/bash.bashrc
    sudo sed -i '/cmd/d' /etc/bash.bashrc
    source /etc/bash.bashrc
    echo "[✓] Successfully removed."
    exit 0
fi

ZIP_URL="https://github.com/x-FK-x/1002xCMD/releases/download/v0.5/v0.5.zip"
ZIP_FILE="1002xCMD-0.5.zip"

# === Herunterladen ===
echo "[*] Downloading 1002xCMD..."

if ! command -v curl &> /dev/null; then
    echo "curl not installed. Installing..."
    sudo apt update && sudo apt install -y curl | tee -a "$LOG_FILE"
    if ! command -v curl &> /dev/null; then
        echo "Failed to install curl. Exiting."
        exit 1
    fi
fi

curl -sL -o "$ZIP_FILE" "$ZIP_URL"




# === Entpacken ===
echo "[*] Extracting archive..."
sudo rm -rf /temp && sudo mkdir /temp
sudo unzip -q "$ZIP_FILE" -d /temp

# === Pfad-Logik (FIX) ===
# Suche zuerst nach einem Unterordner
FOUND_DIR=$(find /temp -maxdepth 1 -type d -name "1002xCMD*" | head -n 1)

# Wenn kein Unterordner da ist, liegen die Dateien direkt in /temp
if [ -z "$FOUND_DIR" ]; then
    EXTRACTED_DIR="/temp"
else
    EXTRACTED_DIR="$FOUND_DIR"
fi

# === Ausführen ===
echo "[*] Running installer from $EXTRACTED_DIR..."
sudo chmod +x "$EXTRACTED_DIR/installer.sh"
sudo bash "$EXTRACTED_DIR/installer.sh"

# === Aufräumen ===
echo "[*] Cleaning up..."
#sudo rm -rf /temp
rm -f "$ZIP_FILE"
source /etc/bash.bashrc
echo "[✓] 1002xCMD installation complete."