#!/bin/bash

set -euo pipefail

INSTALLER="/etc/dodos/tools/1002xEASYCOMMAND-installer.sh"
MAIN_FILE="/etc/profile.d/1002xEASYCOMMAND.sh"
BASHRC="/etc/bash.bashrc"
LOG_FILE="/var/log/1002xEASYCOMMAND_RESET.log"

# =====================================================
# ROOT CHECK
# =====================================================

if [[ $EUID -ne 0 ]]; then
    echo "[!] Run as root (sudo)"
    exit 1
fi

touch "$LOG_FILE"

log() {
    echo "$(date '+%F %T') | $1" >> "$LOG_FILE"
}

# =====================================================
# FILE CHECK
# =====================================================

if [[ ! -f "$MAIN_FILE" ]]; then
    echo "[!] Runtime missing → reinstall required"
    log "Runtime missing"
    [[ -f "$INSTALLER" ]] && bash "$INSTALLER"
    exit 0
fi

# =====================================================
# ANALYSIS (NO HARDCODED LIST)
# =====================================================

TOTAL_ALIASES=$(grep -cE "^alias [A-Z0-9_]+=" "$MAIN_FILE" || true)
TOTAL_FUNCTIONS=$(grep -cE "^[A-Z0-9_]+\(\)\s*\{" "$MAIN_FILE" || true)

TOTAL_ENTRIES=$((TOTAL_ALIASES + TOTAL_FUNCTIONS))

echo "[*] Detected aliases:   $TOTAL_ALIASES"
echo "[*] Detected functions: $TOTAL_FUNCTIONS"
echo "[*] Total runtime entries: $TOTAL_ENTRIES"

log "Aliases=$TOTAL_ALIASES Functions=$TOTAL_FUNCTIONS Total=$TOTAL_ENTRIES"

# =====================================================
# HEALTH CHECK (STRUCTURAL ONLY)
# =====================================================

if [[ "$TOTAL_ENTRIES" -lt 10 ]]; then
    echo "[!] Runtime looks broken → full reinstall"
    log "Runtime corrupted (too few entries)"

    rm -f "$MAIN_FILE"
    sed -i '/1002xEASYCOMMAND/d' "$BASHRC"

    [[ -f "$INSTALLER" ]] && bash "$INSTALLER"
    exit 0
fi

# =====================================================
# OPTIONAL REFRESH (NO REBUILD IF OK)
# =====================================================

echo "[✓] Runtime structure OK → soft reload only"
log "Runtime OK → soft update"

[[ -f "$INSTALLER" ]] && bash "$INSTALLER"

echo ""
echo "====================================="
echo "  1002xEASYCOMMAND CHECK COMPLETE"
echo "  NO RESET REQUIRED"
echo "====================================="
echo ""
