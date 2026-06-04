#!/bin/bash

# === Benutzername abfragen ===
USERNAME=$(whiptail --inputbox "Enter the new username:" 10 50 3>&1 1>&2 2>&3) || exit 1

# === Benutzer anlegen ===
if id "$USERNAME" &>/dev/null; then
  whiptail --title "User Config" --msgbox "User '$USERNAME' already exists." 10 50
else
  sudo adduser "$USERNAME"
fi

SUDO=$(whiptail --title "SUDO" --yesno "Should '$USERNAME' get SUDO/ROOT rights?" 10 60 3>&1 1>&2 2>&3 && echo "yes" || echo "no")

if [[ "$SUDO" == "yes" ]]; then
 sudo echo "$USERNAME  ALL=(ALL:ALL) ALL" >> /etc/sudoers
 sudo adduser $USERNAME sudo
fi

if [[ -f /etc/sddm.conf.d/autologin.conf ]]; then
sudo rm -f /etc/sddm.conf.d/autologin.conf
fi

if [[ -f /etc/lightdm/lightdm.conf.d/49-autologin.conf ]]; then
sudo rm -f /etc/lightdm/lightdm.conf.d/49-autologin.conf
fi


# === Autologin fragen ===
AUTOLOGIN=$(whiptail --title "Autologin" --yesno "Should '$USERNAME' be configured for autologin?" 10 60 3>&1 1>&2 2>&3 && echo "yes" || echo "no")

# === Display Manager erkennen ===
detect_display_manager() {
  if pidof lightdm &>/dev/null; then echo "lightdm"
  elif pidof sddm &>/dev/null; then echo "sddm"
  elif [ -f /etc/systemd/system/display-manager.service ]; then
    readlink /etc/systemd/system/display-manager.service | grep -q lightdm && echo "lightdm"
    readlink /etc/systemd/system/display-manager.service | grep -q sddm && echo "sddm"
  fi
}

DM=$(detect_display_manager)

# === Autologin konfigurieren ===
if [[ "$AUTOLOGIN" == "yes" ]]; then
  if [[ "$DM" == "lightdm" ]]; then
    sudo mkdir -p /etc/lightdm/lightdm.conf.d
    echo -e "[Seat:*]\nautologin-user=$USERNAME\nautologin-user-timeout=0" | sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null
  elif [[ "$DM" == "sddm" ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[Autologin]\nUser=$USERNAME\nSession=plasma.desktop" | sudo tee /etc/sddm.conf.d/10-autologin.conf > /dev/null
  else
    whiptail --title "Autologin Error" --msgbox "Unsupported or unknown display manager." 10 50
  fi
else
  # Autologin deaktivieren
  sudo rm -f /etc/lightdm/lightdm.conf.d/50-autologin.conf
  sudo rm -f /etc/sddm.conf.d/10-autologin.conf
fi

# === Abschlussmeldung ===
whiptail --title "User Config" --msgbox "Configuration complete.\nUser: $USERNAME\nAutologin: $AUTOLOGIN\nSudo-Rights: $SUDO" 10 50
#DODOS - DownTown1002xCollection of Debian OS
