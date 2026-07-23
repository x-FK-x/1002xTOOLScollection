#!/bin/bash

if whiptail --title "Gamingpack Installation" --yesno "Do you really want to install the Gamingpack?" 10 50; then
    echo "Starting installation..."
    
    # Repositories für Wine und Drittanbieter sollten vor "apt install" hinzugefügt werden!
    sudo apt install -y \
        joystick jstest-gtk antimicrox \
        xboxdrv steam-devices

    sudo apt install -y lutris winehq-stable

    sudo dpkg --add-architecture i386

    echo "deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/steam-temp.list

    sudo apt update
    sudo apt install -y steam
    sudo rm -f /etc/apt/sources.list.d/steam-temp.list
    sudo apt update

    sudo apt install -y gamemode libgamemode0 libgamemodeauto0

    echo "Installation finished. Exiting.."
    sleep 10
    exit 0
else
    echo "Installation canceled. Exiting.."
    sleep 10
    exit 0
fi
