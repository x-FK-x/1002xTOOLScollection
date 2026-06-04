#!/bin/bash

# Function to install isenkram-cli and your core bundle safety net
install_firmware_tools() {
    echo "=================================================="
    echo "🔄 Updating package lists & installing core tools..."
    echo "=================================================="
    sudo apt update
    
    # Universal safety net bundle (Covers Realtek & Intel Wireless/Bluetooth)
    local pkgs="firmware-linux firmware-misc-nonfree firmware-realtek firmware-iwlwifi"

    # Dynamische CPU-Erkennung für Microcode
    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        echo "🟢 AMD CPU detected. Adding amd64-microcode to installation..."
        pkgs="$pkgs amd64-microcode"
    elif grep -q "GenuineIntel" /proc/cpuinfo; then
        echo "🟢 Intel CPU detected. Adding intel-microcode to installation..."
        pkgs="$pkgs intel-microcode"
    else
        echo "⚠️ Unknown CPU vendor. Skipping CPU microcode installation."
    fi
    
    # 1. Install core firmware and matching CPU microcode
    echo "📦 Installing core firmware bundle..."
    sudo apt install -y $pkgs
    
    # 2. Install the hardware scanning tool
    echo "📦 Installing isenkram-cli..."
    sudo apt install -y isenkram-cli
}

# Function to automatically scan and install missing firmware via isenkram
auto_install_firmware() {
    echo -e "\n=================================================="
    echo "🔍 Scanning for missing hardware firmware..."
    echo "=================================================="
    sudo isenkram-autoinstall-firmware
}

# Function to check the GPU and install appropriate drivers/acceleration
check_gpu_drivers() {
    echo -e "\n=================================================="
    echo "🎨 Checking Graphics Card (GPU)..."
    echo "=================================================="
    GPU_INFO=$(lspci -nn | grep -E -i "vga|3d|display")
    echo "Detected: $GPU_INFO"

    if echo "$GPU_INFO" | grep -iq "nvidia"; then
        echo "🟢 NVIDIA GPU detected. Triggering driver configuration..."
        sudo apt install -y nvidia-detect
        if command -v nvidia-detect >/dev/null 2>&1; then
            sudo apt install -y $(nvidia-detect | grep -E "nvidia-driver|nvidia-legacy")
        else
            sudo apt install -y nvidia-driver
        fi
    elif echo "$GPU_INFO" | grep -iq "amd\|ati"; then
        echo "🟢 AMD/ATI GPU detected. Ensuring accelerated Mesa drivers..."
        sudo apt install -y libglx-mesa0 mesa-vulkan-drivers
    elif echo "$GPU_INFO" | grep -iq "intel"; then
        echo "🟢 Intel GPU detected. Enabling hardware video acceleration..."
        sudo apt install -y intel-media-va-driver-non-free mesa-vulkan-drivers
    fi
}

# Function to ensure Bluetooth stack and services are installed and active
configure_bluetooth() {
    # 1. Check for Bluetooth hardware
    local bt_check
    bt_check=$(lsusb | grep -qi "bluetooth" && echo "yes" || (ls /sys/class/bluetooth/ 2>/dev/null | grep -q . && echo "yes") || echo "no")

    if [ "$bt_check" = "no" ]; then
        whiptail --title "Bluetooth Error" --msgbox "No Bluetooth hardware was detected on this system.\nInstallation will be skipped." 10 60
        return 1
    fi

    # 2. Gather details of the detected controllers for display
    local bt_info
    bt_info=$(lsusb | grep -i "bluetooth" || ls /sys/class/bluetooth/)

    # 3. Display info box with the detected hardware
    whiptail --title "Bluetooth Hardware Found" --msgbox "The following Bluetooth hardware was detected:\n\n$bt_info" 12 60

    # 4. Yes/No query for the installation
    if whiptail --title "Bluetooth Installation" --yesno "Do you really want to install the Bluetooth stack and management tools?" 10 60; then
        
        echo -e "\n=================================================="
        echo "🌐 Checking and configuring Bluetooth Stack..."
        echo "=================================================="
        
        echo "📦 Installing bluez and bluetooth management tools..."
        sudo apt install -y bluez bluez-tools blueman
        
        echo "⚙️ Enabling and starting Bluetooth system service..."
        sudo systemctl enable bluetooth
        sudo systemctl start bluetooth
        
        whiptail --title "Success" --msgbox "Bluetooth has been successfully installed and started!" 8 50
    else
        echo "Bluetooth installation canceled by the user."
    fi
}

# Main Script Execution
echo "🚀 Starting Firmware-Installation Script for Debian..."

install_firmware_tools
auto_install_firmware
check_gpu_drivers
configure_bluetooth

echo -e "\n=================================================="
echo "✅ Firmware-Installation finished!"
echo "🔄 Please reboot your system ('sudo reboot') to apply changes."
echo "=================================================="
