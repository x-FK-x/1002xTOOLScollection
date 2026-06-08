#!/bin/bash
LOG_FILE="$TARGET_TOOLS_DIR/1002xTOOLS_updater.log"
echo "=== 1002xTOOLS Updater Log ===" > "$LOG_FILE"
echo "Start time: $(date)" >> "$LOG_FILE"
log() {
    echo "$1" | tee -a "$LOG_FILE"
}


# ==============================
# 1002xOPERATOR Update (autonom)
# ==============================
OP_DIR="/etc/1002xOPERATOR"
OP_TMP="/tmp/1002xOPERATOR_update"
OP_URL="https://github.com/x-FK-x/1002xOPERATOR/archive/refs/heads/main.zip"

log "Starting 1002xOPERATOR updater..."

if [[ ! -d "$OP_DIR" ]]; then
    log "1002xOPERATOR not installed."
    whiptail --title "1002xOPERATOR" --msgbox "1002xOPERATOR is not installed. Skipping update." 10 50
else
    rm -rf "$OP_TMP"
    mkdir -p "$OP_TMP"

    log "Downloading latest 1002xOPERATOR..."
    curl -Ls "$OP_URL" -o "$OP_TMP/op.zip"
    unzip -q "$OP_TMP/op.zip" -d "$OP_TMP"

    OP_SRC=$(find "$OP_TMP" -maxdepth 1 -type d -name "1002xOPERATOR-*")
    if [[ ! -f "$OP_SRC/release.txt" ]]; then
        log "release.txt missing in repo."
        whiptail --title "1002xOPERATOR" --msgbox "release.txt missing in repo. Update aborted." 10 50g
        rm -rf "$OP_TMP"
    else
        REPO_VER=$(head -n1 "$OP_SRC/release.txt")
        LOCAL_VER=$(head -n1 "$OP_DIR/release.txt" 2>/dev/null)

        log "Local version: $LOCAL_VER"
        log "Repo version: $REPO_VER"

        if [[ "$LOCAL_VER" == "$REPO_VER" ]]; then
            log "1002xOPERATOR already up to date."
            whiptail --title "1002xOPERATOR" --msgbox "Already up to date.\nVersion: $LOCAL_VER" 10 50
        else
            log "Updating 1002xOPERATOR..."
            sudo cp -rf "$OP_SRC"/. "$OP_DIR/"
            sudo chmod -R 755 "$OP_DIR"
            log "Updated to $REPO_VER"
            whiptail --title "1002xOPERATOR" --msgbox "Update successful.\nNew version: $REPO_VER" 10 50
        fi

        rm -rf "$OP_TMP"
    fi
fi
#-------
if [ -f "/etc/profile.d/1002xEASYCOMMAND.sh" ]; then
   whiptail --title "1002xEASYCOMMAND" --msgbox "1002xEASYCOMMAND is installed. Checking update." 10 50
   bash "$SCRIPT_DIR/tools/1002xEASYCOMMAND-updater.sh" 
      whiptail --title "1002xEASYCOMMAND" --msgbox "1002xEASYCOMMAND is installed. Finishing update." 10 50
      sleep 10
else
    whiptail --title "1002xEASYCOMMAND" --msgbox "1002xEASYCOMMAND is not installed. Skipping update." 10 50
fi
#-----

LOCAL_CMD_FILE="/etc/modos/tools/1002xCMD-ver.txt"
REMOTE_URL="https://raw.githubusercontent.com/x-FK-x/1002xCMD/refs/heads/main/version.txt"

if [ -d "/etc/1002xCMD" ]; then
    echo "1002xCMD is installed"
    
    
    if [ ! -f "$LOCAL_CMD_FILE" ]; then
        echo "Local version file not found. Creating a blank one."
        touch "$LOCAL_CMD_FILE"
    fi

 
    REMOTE_VERSION=$(curl -sf "$REMOTE_URL")

    # Prüfen, ob der curl-Befehl erfolgreich war
    if [ $? -ne 0 ] || [ -z "$REMOTE_VERSION" ]; then
        echo "Error: Could not fetch remote version."
    else
        # 3. Inhalt der lokalen Datei auslesen
        LOCAL_VERSION=$(cat "$LOCAL_CMD_FILE")

       
        if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
            echo "Versions match ($LOCAL_VERSION). No update needed."
        else
            echo "Update available! Local: '$LOCAL_VERSION' vs Remote: '$REMOTE_VERSION'"
            bash "$SCRIPT_DIR/tools/1002xCMD-installer.sh" 
        fi
        sleep 10
    fi
else
    echo "1002xCMD is not installed. Skipping Update."
    sleep 5
fi
#----



# Logfile im tools-Ordner
TARGET_TOOLS_DIR="/etc/modos/tools"
mkdir -p "$TARGET_TOOLS_DIR"
mkdir -p /etc/modos/source

log "Starting updater..."

if ! command -v whiptail &> /dev/null; then
    log "Whiptail not installed. Installing..."
    sudo apt update && sudo apt install -y whiptail | tee -a "$LOG_FILE"
    if ! command -v whiptail &> /dev/null; then
        log "Failed to install whiptail. Exiting."
        exit 1
    fi
fi


if ! command -v dos2unix &> /dev/null; then
    log "dos2unix not installed. Installing..."
    sudo apt update && sudo apt install -y dos2unix | tee -a "$LOG_FILE"
    if ! command -v dos2unix &> /dev/null; then
        log "Failed to install dos2unix. Exiting."
        exit 1
    fi
fi
# === Version erkennen ===
if [[ -d /etc/dodos ]]; then
    VERSION="dodos"
    SCRIPT_DIR="/etc/dodos"
elif [[ -d /etc/modos ]]; then
    VERSION="modos"
    SCRIPT_DIR="/etc/modos"
else
    log "No valid version directory detected. Exiting."
    whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
    exit 1
fi

log "Detected version: $VERSION, SCRIPT_DIR: $SCRIPT_DIR"
OS_VERSION=$(head -n1 "/etc/modos/tools/osversion.txt")
echo "$OS_VERSION"
log "OS version: $OS_VERSION"

if [ "$OS_VERSION" = "DEBIAN13" ]; then
    log "DEBIAN 13"
    whiptail --title "Updater" --msgbox "DEBIAN13 installed. Continue." 10 50
elif [ "$OS_VERSION" = "DEBIAN14" ]; then
    log "DEBIAN 14"
  elif [ "$OS_VERSION" = "DEBIAN15" ]; then
    log "DEBIAN 15"
else
    log "Unkown Version: $OS_VERSION"
    exit 0
fi



# === Repo & Temp ===
REPO="x-FK-x/1002xTOOLScollection"
BRANCH="$VERSION"
TMP_DIR="$HOME/.1002xtools_temp"
FOLDER="DEBIAN13"
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"

mkdir -p "$TMP_DIR"

log "Downloading branch $BRANCH from repo $REPO..."
ZIP_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.zip"
ZIP_FILE="$TMP_DIR/$BRANCH.zip"

wget -q -O "$ZIP_FILE" "$ZIP_URL"
if [[ $? -ne 0 ]]; then
    log "Failed to download $ZIP_URL"
    whiptail --title "Updater" --msgbox "Failed to download $ZIP_URL" 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi
log "Downloaded zip to $ZIP_FILE"

# Repo entpacken
log "Extracting archive..."
unzip -q -o "$ZIP_FILE" -d "$TMP_DIR"
if [[ $? -ne 0 ]]; then
    log "Failed to extract archive."
    whiptail --title "Updater" --msgbox "Failed to extract archive." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi

EXTRACTED_ROOT=$(find "$TMP_DIR" -maxdepth 1 -type d -name "1002xTOOLS*" | head -n1)
if [[ ! -d "$EXTRACTED_ROOT" ]]; then
    log "Extracted repo folder not found."
    whiptail --title "Updater" --msgbox "Extracted repo folder not found." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi
log "Extracted root: $EXTRACTED_ROOT"

EXTRACTED_DIR="$EXTRACTED_ROOT/$FOLDER"
if [[ ! -d "$EXTRACTED_DIR" ]]; then
    log "Folder $FOLDER not found in the repo."
    whiptail --title "Updater" --msgbox "Folder $FOLDER not found in the repo." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi
log "Using folder: $EXTRACTED_DIR"

# Versionscheck
if [[ -f "$EXTRACTED_DIR/dev.txt" ]]; then
    cp -f "$EXTRACTED_DIR/dev.txt" "$TMP_DIR/dev.txt"
    REPO_VERSION=$(head -n1 "$TMP_DIR/dev.txt")
    log "Repo version: $REPO_VERSION"
else
    log "dev.txt not found in folder."
    whiptail --title "Updater" --msgbox "dev.txt not found in DEBIAN13 folder." 10 50
    rm -rf "$TMP_DIR"
    exit 1
fi



LOCAL_VERSION=$( [[ -f "$LOCAL_DEV_FILE" ]] && head -n1 "$LOCAL_DEV_FILE" || echo "" )
log "Local version: $LOCAL_VERSION"

if [[ "$LOCAL_VERSION" == "$REPO_VERSION" ]]; then
    log "Tools are already up to date."
    whiptail --title "Updater" --msgbox "Tools are already up to date (version $OS_VERSION Rev. $LOCAL_VERSION)." 10 50
    rm -rf "$TMP_DIR"
    exit 0
fi

# --- Dateien kopieren ---
# dev.txt
cp -f "$TMP_DIR/dev.txt" "$LOCAL_DEV_FILE"
log "Copied dev.txt to $LOCAL_DEV_FILE"

# debui.sh 
if [[ -f "$EXTRACTED_DIR/debui.sh" ]]; then
    cp -f "$EXTRACTED_DIR/debui.sh" "$SCRIPT_DIR/debui.sh"
    chmod +x "$SCRIPT_DIR/debui.sh"
    log "Copied debui.sh to $SCRIPT_DIR/debui.sh"
else
    log "DEBIANui.sh not found in folder."
    whiptail --title "Updater" --msgbox "debui.sh not found in folder." 10 50
fi

# motd 
if [[ -f "$EXTRACTED_DIR/tools/motd" ]]; then
    cp -f "$EXTRACTED_DIR/tools/motd" "$SCRIPT_DIR/tools/motd"
       log "Copied motd to $SCRIPT_DIR/tools/motd"
else
    log "motd not found in folder."
    whiptail --title "Updater" --msgbox "motd not found in folder." 10 50
fi


# gaming 
if [[ -f "$EXTRACTED_DIR/tools/gamingpack.sh" ]]; then
    cp -f "$EXTRACTED_DIR/tools/gamingpack.sh" "$SCRIPT_DIR/tools/gamingpack.sh"
       log "Copied gamingpack.sh to $SCRIPT_DIR/tools/gamingpack.sh"
else
    log "gamingpack.sh not found in folder."
    whiptail --title "Updater" --msgbox "gamingpack.sh not found in folder." 10 50
fi

# osversion 
if [[ -f "$EXTRACTED_DIR/tools/1002xSHELL-installer.sh" ]]; then
    cp -f "$EXTRACTED_DIR/tools/1002xSHELL-installer.sh" "$SCRIPT_DIR/tools/1002xSHELL-installer.sh"
    log "Copied 1002xSHELL-installer.sh to $SCRIPT_DIR/tools/1002xSHELL-installer.sh"
else
    log "1002xSHELL-installer.sh not found in folder."
    whiptail --title "Updater" --msgbox "1002xSHELL-installer.sh not found in folder." 10 50
fi

# list 
if [[ -f "$EXTRACTED_DIR/tools/list.txt" ]]; then
    cp -f "$EXTRACTED_DIR/tools/list.txt" "$SCRIPT_DIR/tools/list.txt"
    log "Copied list.txt to $SCRIPT_DIR/tools/list.txt"
else
    log "list.txt not found in folder."
    whiptail --title "Updater" --msgbox "list.txt not found in folder." 10 50
fi




# Alle .sh-Dateien aus DEBIAN13/tools nach tools kopieren
if [[ -d "$EXTRACTED_DIR/tools" ]]; then
    for file in "$EXTRACTED_DIR/tools/"*.sh; do
        [ -f "$file" ] || continue
        cp -f "$file" "$TARGET_TOOLS_DIR/"
        chmod +x "$TARGET_TOOLS_DIR/$(basename "$file")"
        log "Copied $file to $TARGET_TOOLS_DIR/"
    done
else
    log "No tools folder found in DEBIAN13"
fi

if [[ -f "$EXTRACTED_DIR/tools/1002xCMD-ver.txt" ]]; then
    cp -f "$EXTRACTED_DIR/tools/1002xCMD-ver.txt" "$SCRIPT_DIR/tools/1002xCMD-ver.txt"
    log "Copied list.txt to $SCRIPT_DIR/tools/1002xCMD-ver.txt"
else
    log "1002xCMD-ver.txt not found in folder."
    whiptail --title "Updater" --msgbox "1002xCMD-ver.txt not found in folder." 10 50
fi


if [[ -f "$EXTRACTED_DIR/tools/resolv.conf" ]]; then
    cp -f "$EXTRACTED_DIR/tools/resolv.conf" "$SCRIPT_DIR/tools/resolv.conf"
    log "Copied list.txt to $SCRIPT_DIR/tools/resolv.conf"
else
    log "resolv.conf not found in folder."
    whiptail --title "Updater" --msgbox "resolv.conf not found in folder." 10 50
fi


# Alle .sh im Ziel ausführbar machen
sudo find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} +
sudo find "$SCRIPT_DIR" -type f -name "*.sh" -exec dos2unix {} +


ALIAS_LINE="alias 1002xUPDATES='sudo bash $SCRIPT_DIR/tools/updater.sh'"
ALIAS_LINE2="alias 1002xTOOLS='sudo bash $SCRIPT_DIR/debui.sh'"
ALIAS_LINE3="alias 1002xDNS='sudo rm /etc/resolv.conf && sudo cp $SCRIPT_DIR/tools/resolv.conf /etc'"

for ALIAS in "$ALIAS_LINE" "$ALIAS_LINE2" "$ALIAS_LINE3"; do
    if ! grep -Fxq "$ALIAS" /etc/bash.bashrc; then
        echo "$ALIAS" | sudo tee -a /etc/bash.bashrc >/dev/null
    fi
done

log "Aliases for 1002xTOOLS, 1002xUPDATES and 1002xDNS set in /etc/bash.bashrc"

source /etc/bash.bashrc

# Cleanup
rm -rf "$TMP_DIR"
log "Temporary files cleaned."

whiptail --title "1002xTOOLS Updater" --msgbox "Update completed successfully to version $REPO_VERSION." 10 50
log "Update completed successfully to version $REPO_VERSION."




# === Rückkehrmenü ===
while true; do
    ACTION=$(whiptail --title "Updater finished" --menu "What do you want to do now?" 10 50 2 \
        "1" "Return to main menu" \
        "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

    case "$ACTION" in
        "1")
            bash "$SCRIPT_DIR/debui.sh"
            ;;
        "2")
            exit 0
            ;;
        *)
            whiptail --msgbox "Invalid option. Please choose again." 8 40
            ;;
    esac
done

#DODOS - DownTown1002xCollection of DEBIAN OS
