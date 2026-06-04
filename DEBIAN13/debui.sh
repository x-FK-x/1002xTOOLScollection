#!/bin/bash

# === Version Detection ===
if [[ -d /etc/modos ]]; then
  VERSION="MODOS"
  SCRIPT_DIR="/etc/modos"
elif [[ -d /etc/dodos ]]; then
  VERSION="DODOS"
  SCRIPT_DIR="/etc/dodos"
else
  whiptail --title "1002xTOOLS Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

sudo rm -f /etc/apt/sources.list.d/isenkram-autoinstall-firmware.list

NEW_CMD="@reboot sleep 60 && apt-get update >> $SCRIPT_DIR/source/update.log 2>&1"

if ! sudo crontab -l 2>/dev/null | grep -qF "$NEW_CMD"; then
    (sudo crontab -l 2>/dev/null; echo "$NEW_CMD") | sudo crontab -
fi

if id "user" &>/dev/null && ! who | grep -q "^user "; then
    userdel "user"
    [ -d /home/user ] && rm -rf /home/user && rm -rf /media/user
fi

# === Make all tools executable ===
chmod +x "$SCRIPT_DIR"/tools/*.sh 2>/dev/null
chmod -R 777 "$SCRIPT_DIR"/tools/*.sh 2>/dev/null

# === Replace system files ===
if ping -c 4 google.com > /dev/null 2>&1; then
    echo "Nothing to do."
else
    sudo rm -f "/etc/resolv.conf"
    sudo cp "$SCRIPT_DIR/tools/resolv.conf" "/etc/resolv.conf"
fi

sudo cp "$SCRIPT_DIR/tools/motd" "/etc/motd"

# === Get local version ===
LOCAL_DEV_FILE="$SCRIPT_DIR/dev.txt"
LOCAL_VERSION=""
if [[ -f "$LOCAL_DEV_FILE" ]]; then
  LOCAL_VERSION=$(head -n1 "$LOCAL_DEV_FILE")
fi

# === Create global Desktop Entry ===
DESKTOP_ENTRY_PATH="/usr/share/applications/1002xTOOLS.desktop"
if [[ ! -f "$DESKTOP_ENTRY_PATH" ]]; then
   sudo tee "$DESKTOP_ENTRY_PATH" > /dev/null <<EOF
[Desktop Entry]
Name=1002xTOOLS ($VERSION)
Exec=$SCRIPT_DIR/debui.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF
    sudo chmod +x "$DESKTOP_ENTRY_PATH"
fi

# === Ensure user Desktop shortcut exists ===
REALUSER=$(logname 2>/dev/null || echo "$SUDO_USER")
USER_DESKTOP="$HOME/Desktop"
[[ -z "$REALUSER" ]] && REALUSER=$(whoami)
USER_DESKTOP=$(eval echo "~$REALUSER/Desktop")
mkdir -p "$USER_DESKTOP"
USER_SHORTCUT="$USER_DESKTOP/1002xTOOLS.desktop"

if [[ ! -f "$USER_SHORTCUT" ]]; then
    cat <<EOF > "$USER_SHORTCUT"
[Desktop Entry]
Name=1002xTOOLS ($VERSION)
Exec=$SCRIPT_DIR/debui.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=System;
EOF
    chmod +x "$USER_SHORTCUT"
    chown "$REALUSER":"$REALUSER" "$USER_SHORTCUT"
fi

if [[ ! -f "/etc/1002xSHELL/v4.sh" ]]; then
    sudo bash "$SCRIPT_DIR/tools/1002xSHELL-installer.sh"
    sudo sed -i 's/\r$//' /etc/1002xSHELL/v4.sh
fi

# === Main Menu ===
while true; do
  CHOICE=$(whiptail --title "1002xTOOLS Menu ($VERSION Rev. $LOCAL_VERSION)" \
    --menu "Choose a category:" 20 60 6 \
    "1" "Updates" \
    "2" "Software" \
    "3" "Language" \
    "4" "User Management" \
    "5" "My Another Tools" \
    "6" "Exit" \
    3>&1 1>&2 2>&3)

  case "$CHOICE" in
    "1")
      CHOICE=$(whiptail --title "Updates Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Updater of 1002xTOOLS" \
        "2" "Debian Upgrades" \
        "3" "Firmware Scanner" \
        "4" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/updater.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/systemupgrade.sh" ;;
        "3") sudo bash "$SCRIPT_DIR/tools/firmware.sh" ;;
        "4" | *) continue ;;
      esac
      ;;
    "2")
      CHOICE=$(whiptail --title "Software Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Installer of Software" \
        "2" "Remover of Software" \
        "3" "Edit Desktop Icons" \
        "4" "Install the Gaming Pack" \
        "5" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/installer.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/remover.sh" ;;
        "3") sudo bash "$SCRIPT_DIR/tools/icons.sh" ;;
        "4") sudo bash "$SCRIPT_DIR/tools/gamingpack.sh" ;;
        "5" | *) continue ;;
      esac
      ;;
    "3")
      CHOICE=$(whiptail --title "Language Settings Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Language Settings" \
        "2" "Keyboard Manager" \
        "3" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo dpkg-reconfigure locales && LC_ALL=C.UTF-8 xdg-user-dirs-update --force;;
        "2") sudo dpkg-reconfigure keyboard-configuration && sudo setupcon ;;
        "3" | *) continue ;;
      esac
      ;;
    "4")
      CHOICE=$(whiptail --title "User Management Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "Add User" \
        "2" "Delete User" \
        "3" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/adduser.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/deluser.sh" ;;
        "3" | *) continue ;;
      esac
      ;;
    "5")
      CHOICE=$(whiptail --title "Another Tools Menu" --menu "Choose a tool:" 20 60 5 \
        "1" "1002xCMD Installer" \
        "2" "1002xEASYCOMMAND Installer" \
        "3" "1002xOPERATOR Installer" \
        "4" "Back" 3>&1 1>&2 2>&3)
      case "$CHOICE" in
        "1") sudo bash "$SCRIPT_DIR/tools/1002xCMD-installer.sh" ;;
        "2") sudo bash "$SCRIPT_DIR/tools/1002xEASYCOMMAND-installer.sh" ;;
        "3") sudo bash "$SCRIPT_DIR/tools/1002xOPERATOR-installer.sh" ;;
        "4" | *) continue ;;
      esac
      ;;
    "6") exit 0 ;;
    *) clear; exit ;;
  esac
done
