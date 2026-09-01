#!/bin/bash
# === Versionserkennung ===
if [[ -d /etc/dodos ]]; then
  VERSION="dodos"
  SCRIPT_DIR="/etc/dodos"
elif [[ -d /etc/modos ]]; then
  VERSION="modos"
  SCRIPT_DIR="/etc/modos"
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

IFS=$'\n' TO_INSTALL=($(sort <<<"${TO_INSTALL[*]}"))
unset IFS

cleanup_kde_bloat() {
  local UNWANTED=(
    "kdeconnect"
    "systemsettings"
    "kde-style-breeze-data"
    "kde-style-breeze-qt5"
    "kde-style-breeze"
    "kded6"
  )

  local TO_REMOVE=()
  for pkg in "${UNWANTED[@]}"; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
      TO_REMOVE+=("$pkg")
    fi
  done

  if [[ ${#TO_REMOVE[@]} -gt 0 ]]; then
    local PKG_LIST
    PKG_LIST=$(printf ' - %s\n' "${TO_REMOVE[@]}")
    whiptail --title "KDE Cleanup" --msgbox \
      "Kdenlive pulled in unwanted KDE packages. Removing:\n\n$PKG_LIST" 20 60
    sudo apt-get remove --purge -y "${TO_REMOVE[@]}"
    sudo apt-get autoremove --purge -y
    whiptail --title "KDE Cleanup" --msgbox "Unwanted KDE packages removed." 10 50
  fi
}

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

    if [[ $? -eq 0 ]]; then
      sudo apt update
      sudo apt install -y "$SELECTED_PKG"

      # === KDE Cleanup falls kdenlive installiert wurde ===
      if [[ "$SELECTED_PKG" == "kdenlive" ]]; then
        cleanup_kde_bloat
      fi

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
      bash /etc/dodos/debui.sh
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
