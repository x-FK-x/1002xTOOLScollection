#!/bin/bash

# ==============================================================================
# 1002xEASYCOMMAND Installer v3.1
# Professional Debian Command Environment
# ==============================================================================

# AUTO-FIX: Check for Windows line endings (\r)
if grep -q $'\r' "$0"; then
    echo "[!] Windows line endings detected. Fixing script format..."
    sed -i 's/\r$//' "$0"
    exec bash "$0" "$@"
fi

set -euo pipefail
shopt -s expand_aliases

VERSION="3.1"

MAIN_FILE="/etc/profile.d/1002xEASYCOMMAND.sh"
BASHRC="/etc/bash.bashrc"
LOG_FILE="/var/log/1002xEASYCOMMAND.log"

# ==============================================================================
# SUDO CHECK
# ==============================================================================

if ! sudo -v 2>/dev/null; then
    echo "[!] This installer requires sudo privileges."
    exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================

if [[ "${1:-}" == "uninstall" ]]; then

    echo "[*] Removing 1002xEASYCOMMAND..."

    sudo rm -f "$MAIN_FILE"
    sudo rm -f "$LOG_FILE"

    sudo sed -i '/1002xEASYCOMMAND/d' "$BASHRC"

    echo "[✓] 1002xEASYCOMMAND removed successfully."
    exit 0
fi

# ==============================================================================
# CREATE LOG FILE
# ==============================================================================

sudo touch "$LOG_FILE"
sudo chmod 640 "$LOG_FILE"

# ==============================================================================
# GENERATE MAIN RUNTIME FILE
# ==============================================================================

sudo tee "$MAIN_FILE" > /dev/null <<'EOF'

# =====================================================
# 1002xEASYCOMMAND Runtime Environment v3.1
# =====================================================

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# =====================================================
# LOGGING
# =====================================================

LOG() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /var/log/1002xEASYCOMMAND.log
}

# =====================================================
# SYSTEM CHECKS
# =====================================================

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

has_pkg() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"
}

has_service() {
    systemctl is-enabled "$1.service" >/dev/null 2>&1 || \
    systemctl is-active "$1.service" >/dev/null 2>&1
}

# =====================================================
# HELP MENU
# =====================================================

EASYHELP() {

    clear

    echo -e "${BLUE}=================================================${RESET}"
    echo -e "${BLUE}           1002xEASYCOMMAND v3.1${RESET}"
    echo -e "${BLUE}=================================================${RESET}"
    echo ""

    echo -e "${GREEN}SYSTEM:${RESET}"
    echo ""
    echo "  POWEROFF"
    echo "      Shutdown system immediately"
    echo ""
    echo "  REBOOT"
    echo "      Reboot system"
    echo ""
    echo "  SHUTDOWN"
    echo "      Shutdown system immediately"

    echo ""
    echo -e "${GREEN}PACKAGE MANAGEMENT:${RESET}"
    echo ""
    echo "  UPDATE"
    echo "      sudo apt update"
    echo ""
    echo "  UPGRADE"
    echo "      sudo apt upgrade -y"
    echo ""
    echo "  FULLUPGRADE"
    echo "      sudo apt full-upgrade -y"
    echo ""
    echo "  DISTUPGRADE"
    echo "      sudo apt dist-upgrade -y"
    echo ""
    echo "  INSTALL package"
    echo "      Install package"
    echo ""
    echo "  REMOVE package"
    echo "      Remove package"
    echo ""
    echo "  PURGE package"
    echo "      Remove package including configuration files"
    echo ""
    echo "  REINSTALL package"
    echo "      Reinstall package"
    echo ""
    echo "  AUTOREMOVE"
    echo "      Remove unused dependencies"
    echo ""
    echo "  AUTOCLEAN"
    echo "      Remove old package cache"
    echo ""
    echo "  CLEAN"
    echo "      Remove all package cache"
    echo ""
    echo "  APTSEARCH keyword"
    echo "      Search for packages"
    echo ""
    echo "  APTSHOW package"
    echo "      Show package details"
    echo ""
    echo "  APTPOLICY package"
    echo "      Show package policy"
    echo ""
    echo "  APTINSTALLED"
    echo "      Show installed packages"
    echo ""
    echo "  FIXBROKEN"
    echo "      Repair broken packages"
    echo ""
    echo "  APTCHECK"
    echo "      Check package database"
    echo ""
    echo "  APTFAST"
    echo "      Quick update + upgrade"
    echo ""
    echo "  APTFIX"
    echo "      Attempt package repair"
    echo ""
    echo "  APTMAINTAIN"
    echo "      Full automatic maintenance"

    echo ""
    echo -e "${GREEN}NETWORK:${RESET}"
    echo ""
    echo "  PING host"
    echo "      Send 4 ping packets"
    echo ""
    echo "  IP"
    echo "      Show IP addresses"

    echo ""
    echo -e "${GREEN}FIREWALL:${RESET}"
    echo ""
    echo "  UFWSTATUS"
    echo "      Show firewall status"
    echo ""
    echo "  OPEN80"
    echo "      Open HTTP port"
    echo ""
    echo "  OPEN443"
    echo "      Open HTTPS port"
    echo ""
    echo "  OPENSSH"
    echo "      Open SSH port"
    echo ""
    echo "  OPENSMB"
    echo "      Open SMB ports (139/tcp, 445/tcp)"
    echo ""
    echo "  BLOCK80"
    echo "      Block HTTP port"
    echo ""
    echo "  BLOCK443"
    echo "      Block HTTPS port"
    echo ""
    echo "  BLOCKSSH"
    echo "      Block SSH port"
    echo ""
    echo "  BLOCKSMB"
    echo "      Block SMB ports (139/tcp, 445/tcp)"

    echo ""
    echo -e "${GREEN}WEBSERVER:${RESET}"
    echo ""
    echo "  WEBSTART"
    echo "      Start webserver"
    echo ""
    echo "  WEBSTOP"
    echo "      Stop webserver"
    echo ""
    echo "  WEBRESTART"
    echo "      Restart webserver"

    echo ""
    echo -e "${GREEN}SECURITY:${RESET}"
    echo ""
    echo "  NMAP"
    echo "      Network mapper"
    echo ""
    echo "  METASPLOIT"
    echo "      Metasploit Framework"
    echo ""
    echo "  WIRESHARK"
    echo "      Network analyzer"
    echo ""
    echo "  SQLMAP"
    echo "      SQL injection testing tool"

    echo ""
    echo -e "${GREEN}LOG FILE:${RESET}"
    echo ""
    echo "  /var/log/1002xEASYCOMMAND.log"

    echo ""
    echo -e "${YELLOW}EXAMPLES:${RESET}"
    echo ""
    echo "  INSTALL nginx"
    echo "  REMOVE apache2"
    echo "  PING 8.8.8.8"
    echo "  APTSEARCH docker"
    echo "  APTSHOW bash"
    echo ""
}

# =====================================================
# MAIN MENU
# =====================================================

1002xEASYCOMMAND() {

    clear

    echo -e "${BLUE}=================================================${RESET}"
    echo -e "${BLUE}           1002xEASYCOMMAND v3.1${RESET}"
    echo -e "${BLUE}=================================================${RESET}"
    echo ""

    echo -e "${GREEN}SYSTEM:${RESET}"
    echo "  POWEROFF  REBOOT  SHUTDOWN"

    echo ""
    echo -e "${GREEN}APT MANAGEMENT:${RESET}"
    echo "  UPDATE  UPGRADE  FULLUPGRADE  DISTUPGRADE"
    echo "  INSTALL REMOVE PURGE REINSTALL"
    echo "  AUTOREMOVE AUTOCLEAN CLEAN"
    echo "  APTSEARCH APTSHOW APTPOLICY"
    echo "  APTINSTALLED"
    echo "  FIXBROKEN APTCHECK"
    echo "  APTFAST APTFIX APTMAINTAIN"

    if has_cmd ping; then
        echo ""
        echo -e "${GREEN}NETWORK:${RESET}"
        echo "  PING  IP"
    fi

    if has_pkg ufw; then
        echo ""
        echo -e "${GREEN}FIREWALL:${RESET}"
        echo "  UFWSTATUS"
        echo "  OPEN80 OPEN443 OPENSSH OPENSMB"
        echo "  BLOCK80 BLOCK443 BLOCKSSH BLOCKSMB"
    fi

    if has_service nginx || has_service apache2; then
        echo ""
        echo -e "${GREEN}WEBSERVER:${RESET}"
        echo "  WEBSTART WEBSTOP WEBRESTART"
    fi

    if has_cmd nmap || has_cmd msfconsole; then
        echo ""
        echo -e "${GREEN}SECURITY:${RESET}"
        echo "  NMAP METASPLOIT WIRESHARK SQLMAP"
    fi

    echo ""
    echo -e "${YELLOW}Type EASYHELP for detailed help${RESET}"
    echo ""
}

# =====================================================
# SYSTEM COMMANDS
# =====================================================

alias POWEROFF='LOG "POWEROFF executed"; sudo poweroff'
alias REBOOT='LOG "REBOOT executed"; sudo reboot'
alias SHUTDOWN='LOG "SHUTDOWN executed"; sudo shutdown now'

# =====================================================
# PACKAGE MANAGEMENT
# =====================================================

alias UPDATE='LOG "APT UPDATE executed"; sudo apt update'
alias UPGRADE='LOG "APT UPGRADE executed"; sudo apt upgrade -y'
alias FULLUPGRADE='LOG "APT FULL-UPGRADE executed"; sudo apt full-upgrade -y'
alias DISTUPGRADE='LOG "APT DIST-UPGRADE executed"; sudo apt dist-upgrade -y'

alias INSTALL='LOG "APT INSTALL executed"; sudo apt install -y'
alias REMOVE='LOG "APT REMOVE executed"; sudo apt remove -y'
alias PURGE='LOG "APT PURGE executed"; sudo apt remove --purge -y'
alias REINSTALL='LOG "APT REINSTALL executed"; sudo apt install --reinstall -y'

alias AUTOREMOVE='LOG "APT AUTOREMOVE executed"; sudo apt autoremove -y'
alias AUTOCLEAN='LOG "APT AUTOCLEAN executed"; sudo apt autoclean -y'
alias CLEAN='LOG "APT CLEAN executed"; sudo apt clean'

alias FIXBROKEN='LOG "APT FIXBROKEN executed"; sudo apt --fix-broken install -y'
alias APTCHECK='LOG "APT CHECK executed"; sudo apt check'

alias APTSEARCH='apt search'
alias APTSHOW='apt show'
alias APTPOLICY='apt policy'
alias APTINSTALLED='apt list --installed'

alias APTFAST='LOG "APT FAST executed"; sudo apt update && sudo apt upgrade -y'

alias APTFIX='LOG "APT FIX executed"; sudo apt update && sudo apt --fix-broken install -y && sudo dpkg --configure -a'

alias APTMAINTAIN='LOG "APT MAINTAIN executed"; sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove --purge -y && sudo apt autoclean -y'

# =====================================================
# NETWORK COMMANDS
# =====================================================

alias PING='ping -c 4'
alias IP='ip address show'

# =====================================================
# FIREWALL COMMANDS
# =====================================================

alias UFWSTATUS='sudo ufw status verbose'

alias OPEN80='LOG "OPEN80 executed"; sudo ufw allow 80/tcp'
alias OPEN443='LOG "OPEN443 executed"; sudo ufw allow 443/tcp'
alias OPENSSH='LOG "OPENSSH executed"; sudo ufw allow 22/tcp'
alias OPENSMB='LOG "OPENSMB executed"; sudo ufw allow 139/tcp && sudo ufw allow 445/tcp'

alias BLOCK80='LOG "BLOCK80 executed"; sudo ufw deny 80/tcp'
alias BLOCK443='LOG "BLOCK443 executed"; sudo ufw deny 443/tcp'
alias BLOCKSSH='LOG "BLOCKSSH executed"; sudo ufw deny 22/tcp'
alias BLOCKSMB='LOG "BLOCKSMB executed"; sudo ufw deny 139/tcp && sudo ufw deny 445/tcp'

# =====================================================
# WEBSERVER COMMANDS
# =====================================================

if has_service nginx; then

    alias WEBSTART='LOG "NGINX START"; sudo systemctl start nginx'
    alias WEBSTOP='LOG "NGINX STOP"; sudo systemctl stop nginx'
    alias WEBRESTART='LOG "NGINX RESTART"; sudo systemctl restart nginx'

elif has_service apache2; then

    alias WEBSTART='LOG "APACHE START"; sudo systemctl start apache2'
    alias WEBSTOP='LOG "APACHE STOP"; sudo systemctl stop apache2'
    alias WEBRESTART='LOG "APACHE RESTART"; sudo systemctl restart apache2'

fi

# =====================================================
# SECURITY TOOLS
# =====================================================

alias NMAP='sudo nmap'
alias METASPLOIT='sudo msfconsole'
alias WIRESHARK='sudo wireshark'
alias SQLMAP='sqlmap'

EOF

# ==============================================================================
# FILE PERMISSIONS
# ==============================================================================

sudo chmod 644 "$MAIN_FILE"

# ==============================================================================
# BASHRC PERSISTENCE
# ==============================================================================

if ! grep -q "1002xEASYCOMMAND" "$BASHRC"; then

    echo "" | sudo tee -a "$BASHRC" >/dev/null
    echo "# 1002xEASYCOMMAND" | sudo tee -a "$BASHRC" >/dev/null
    echo "source $MAIN_FILE" | sudo tee -a "$BASHRC" >/dev/null
fi

# ==============================================================================
# SOURCE ENVIRONMENT
# ==============================================================================

source "$MAIN_FILE"

# ==============================================================================
# INSTALLATION SUMMARY
# ==============================================================================

BLUE="\e[34m"
GREEN="\e[32m"
RESET="\e[0m"

echo ""
echo -e "${BLUE}=================================================${RESET}"
echo -e "${BLUE}           INSTALLATION COMPLETE${RESET}"
echo -e "${BLUE}=================================================${RESET}"
echo ""

echo -e "${GREEN}[✓] Version:${RESET}      $VERSION"
echo -e "${GREEN}[✓] Main File:${RESET}    $MAIN_FILE"
echo -e "${GREEN}[✓] Log File:${RESET}     $LOG_FILE"

echo ""
echo "Please run one of the following:"
echo ""
echo "  source /etc/bash.bashrc"
echo "  OR"
echo "  restart your terminal session"
echo ""

echo "Then type:"
echo ""
echo "  1002xEASYCOMMAND"
echo ""
