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
  whiptail --title "Remover Error" --msgbox "Missing list.txt in tools directory!" 10 50
  exit 1
fi

mapfile -t RAW_LIST < "$LIST_FILE"

# === Nur installierte Programme + Sortierung ===
INSTALLED=()
for pkg in "${RAW_LIST[@]}"; do
  if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    INSTALLED+=("$pkg")
  fi
done

# Alphabetisch sortieren
IFS=$'\n' INSTALLED=($(sort <<<"${INSTALLED[*]}"))
unset IFS

# === Falls nichts installiert ===
if [[ ${#INSTALLED[@]} -eq 0 ]]; then
  whiptail --title "Remover Info" --msgbox "None of the listed tools are currently installed." 10 50
else
  while true; do
    MENU_ITEMS=()
    for i in "${!INSTALLED[@]}"; do
      pkg="${INSTALLED[$i]}"
      desc=$(apt show "$pkg" 2>/dev/null | awk -F': ' '/^Description: / {print $2; exit}')
      MENU_ITEMS+=("$i" "$pkg - $desc")
    done

    CHOICE=$(whiptail --title "Remove Installed Tools ($VERSION)" --menu \
      "Select software to remove:" 20 70 12 "${MENU_ITEMS[@]}" "q" "Quit" \
      3>&1 1>&2 2>&3)

    if [[ "$CHOICE" == "q" || -z "$CHOICE" ]]; then
      break
    fi

    SELECTED_PKG="${INSTALLED[$CHOICE]}"
    whiptail --title "Remove $SELECTED_PKG" --yesno \
      "Are you sure you want to remove $SELECTED_PKG?" 10 50
    RESPONSE=$?

    if [[ $RESPONSE -eq 0 ]]; then
      sudo apt remove --purge -y "$SELECTED_PKG" && sudo apt autoremove -y
      whiptail --title "Removed" --msgbox "$SELECTED_PKG has been removed." 10 50

      unset 'INSTALLED[CHOICE]'
      INSTALLED=("${INSTALLED[@]}")

      IFS=$'\n' INSTALLED=($(sort <<<"${INSTALLED[*]}"))
      unset IFS

      if [[ ${#INSTALLED[@]} -eq 0 ]]; then
        whiptail --msgbox "No more listed tools are installed." 10 50
        break
      fi
    fi
  done
fi

# === Rückkehrmenü ===
while true; do
  ACTION=$(whiptail --title "Remover finished" --menu "What do you want to do now?" 10 50 2 \
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

