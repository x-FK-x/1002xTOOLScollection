#!/bin/bash

if whiptail --title "Gamingpack Installation" --yesno "Do you really want to install the Gamingpack?" 10 50; then
    echo "Starting installation..."
    
    # Repositories für Wine und Drittanbieter sollten vor "apt install" hinzugefügt werden!
    sudo apt install -y \
        joystick jstest-gtk antimicrox \
        xboxdrv steam-devices

    sudo apt install -y lutris steam winehq-stable

    sudo apt install -y gamemode libgamemode0 libgamemodeauto0

    echo "Installation finished. Exiting.."
    sleep 10
    exit 0
else
    echo "Installation canceled. Exiting.."
    sleep 10
    exit 0
fi
