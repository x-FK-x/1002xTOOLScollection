#!/bin/bash

# === Versionserkennung ===
if [[ -d /etc/godos ]]; then
  VERSION="godos"
  SCRIPT_DIR="/etc/godos"
elif [[ -d /etc/modos ]]; then
  VERSION="modos"
  SCRIPT_DIR="/etc/modos"
elif [[ -d /etc/wodos ]]; then
  VERSION="wodos"
  SCRIPT_DIR="/etc/wodos"
else
  whiptail --title "Updater Error" --msgbox "No valid version directory detected. Exiting." 10 50
  exit 1
fi

# === Liste einlesen ===
LIST_FILE="$SCRIPT_DIR/tools/list.txt"

if [[ ! -f "$LIST_FILE" ]]; then
  whiptail --title "Installer Error" --msgbox "Missing list.txt in tools directory!" 10 50
  exit 1
fi

mapfile -t RAW_LIST < "$LIST_FILE"

# === Nur nicht installierte Programme + Sortierung ===
TO_INSTALL=()
for pkg in "${RAW_LIST[@]}"; do
  if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    TO_INSTALL+=("$pkg")
  fi
done

# Alphabetisch sortieren
IFS=$'\n' TO_INSTALL=($(sort <<<"${TO_INSTALL[*]}"))
unset IFS

# === Falls alles bereits installiert ===
if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
  whiptail --title "Installer Info" --msgbox "All listed tools are already installed." 10 50
else
  while true; do
    MENU_ITEMS=()
    for i in "${!TO_INSTALL[@]}"; do
      pkg="${TO_INSTALL[$i]}"
      desc=$(apt show "$pkg" 2>/dev/null | awk -F': ' '/^Description: / {print $2; exit}')
      MENU_ITEMS+=("$i" "$pkg - $desc")
    done

    CHOICE=$(whiptail --title "Install Available Tools ($VERSION)" --menu \
      "Select software to install:" 20 70 12 "${MENU_ITEMS[@]}" "q" "Quit" \
      3>&1 1>&2 2>&3)

    if [[ "$CHOICE" == "q" || -z "$CHOICE" ]]; then
      break
    fi

    SELECTED_PKG="${TO_INSTALL[$CHOICE]}"
    whiptail --title "Install $SELECTED_PKG" --yesno \
      "Do you want to install $SELECTED_PKG?" 10 50
    RESPONSE=$?

    if [[ $RESPONSE -eq 0 ]]; then
      sudo apt update
      sudo apt install -y "$SELECTED_PKG"
      whiptail --title "Installed" --msgbox "$SELECTED_PKG has been installed." 10 50

      unset 'TO_INSTALL[CHOICE]'
      TO_INSTALL=("${TO_INSTALL[@]}")

      IFS=$'\n' TO_INSTALL=($(sort <<<"${TO_INSTALL[*]}"))
      unset IFS

      if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
        whiptail --msgbox "All listed tools are now installed." 10 50
        break
      fi
    fi
  done
fi

# === Rückkehrmenü ===
while true; do
  ACTION=$(whiptail --title "Installer finished" --menu "What do you want to do now?" 10 50 2 \
    "1" "Return to main menu" \
    "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

  case "$ACTION" in
    "1")
      bash /etc/wodos/debui.sh
      ;;
    "2")
      exit 0
      ;;
    *)
      whiptail --msgbox "Invalid option. Please choose again." 8 40
      ;;
  esac
done
#DODOS - DownTown1002xCollection of Debian OS
