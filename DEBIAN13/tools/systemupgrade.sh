#!/bin/bash

# Prüfe, ob als root gestartet, sonst sudo benutzen
if [[ $EUID -ne 0 ]]; then
  SUDO='sudo'
else
  SUDO=''
fi

function run_cmd() {
  CMD=$*
  echo "Running: $SUDO $CMD"
  $SUDO $CMD
  local STATUS=$?
  if [[ $STATUS -ne 0 ]]; then
    echo "Error: Command failed: $CMD with exit code $STATUS"
    exit $STATUS
  fi
}

echo "Starting system update..."
# Entferne MX Linux Repo nur, wenn vorhanden
if [[ -f /etc/apt/sources.list.d/mx.list ]]; then
  run_cmd rm /etc/apt/sources.list.d/mx.list
  run_cmd apt remove --purge mx-snapshot -y
fi

run_cmd apt update
run_cmd apt upgrade -y
run_cmd apt autoremove -y
run_cmd apt autoclean

# === Rückkehrmenü ===
while true; do
  ACTION=$(whiptail --title "Debian Updates finished" --menu "What do you want to do now?" 10 50 2 \
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
