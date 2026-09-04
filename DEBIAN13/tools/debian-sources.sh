#!/bin/bash
# ============================================================
#  debian-sources.sh — Debian APT Sources Configuration
#  Supports: Debian 13 (trixie/stable) and Testing
#  Run with: sudo bash debian-sources.sh
# ============================================================

set -euo pipefail

SOURCES_FILE="/etc/apt/sources.list"
BACKUP_FILE="/etc/apt/sources.list.bak.$(date +%Y%m%d_%H%M%S)"

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root or with sudo."
    exit 1
fi

# ============================================================
#  Mirror definitions  (label|hostname)
# ============================================================

# Each region is a separate indexed array of "label|hostname" entries.
# Add or remove entries freely — the menu is built dynamically.

REGIONS=(
    "Official / CDN"
    "Europe"
    "North America"
    "Asia"
    "Oceania"
    "South America"
    "Africa"
)

# Official
declare -a R0=(
    "deb.debian.org (official Anycast CDN)|deb.debian.org"
)

# Europe
declare -a R1=(
    "ftp.de.debian.org     (Germany)|ftp.de.debian.org"
    "ftp.at.debian.org     (Austria)|ftp.at.debian.org"
    "ftp.ch.debian.org     (Switzerland)|ftp.ch.debian.org"
    "ftp.nl.debian.org     (Netherlands)|ftp.nl.debian.org"
    "ftp.fr.debian.org     (France)|ftp.fr.debian.org"
    "ftp.uk.debian.org     (United Kingdom)|ftp.uk.debian.org"
    "ftp.pl.debian.org     (Poland)|ftp.pl.debian.org"
    "ftp.se.debian.org     (Sweden)|ftp.se.debian.org"
    "mirror.selfnet.de     (Germany, Selfnet)|mirror.selfnet.de"
    "debian.anexia.at      (Austria, Anexia)|debian.anexia.at"
)

# North America
declare -a R2=(
    "ftp.us.debian.org     (USA, official)|ftp.us.debian.org"
    "mirror.math.ucdavis.edu (USA, UC Davis)|mirror.math.ucdavis.edu"
    "mirrors.ocf.berkeley.edu (USA, UC Berkeley)|mirrors.ocf.berkeley.edu"
    "debian.mirror.constant.com (USA, Constant)|debian.mirror.constant.com"
    "ftp.ca.debian.org     (Canada)|ftp.ca.debian.org"
    "mirror.csclub.uwaterloo.ca (Canada, UWaterloo)|mirror.csclub.uwaterloo.ca"
)

# Asia
declare -a R3=(
    "ftp.jp.debian.org     (Japan)|ftp.jp.debian.org"
    "ftp.cn.debian.org     (China)|ftp.cn.debian.org"
    "ftp.kr.debian.org     (South Korea)|ftp.kr.debian.org"
    "ftp.tw.debian.org     (Taiwan)|ftp.tw.debian.org"
    "ftp.in.debian.org     (India)|ftp.in.debian.org"
    "ftp.id.debian.org     (Indonesia)|ftp.id.debian.org"
    "mirror.nus.edu.sg     (Singapore, NUS)|mirror.nus.edu.sg"
    "mirrors.tuna.tsinghua.edu.cn (China, Tsinghua)|mirrors.tuna.tsinghua.edu.cn"
)

# Oceania
declare -a R4=(
    "ftp.au.debian.org     (Australia)|ftp.au.debian.org"
    "mirror.aarnet.edu.au  (Australia, AARNet)|mirror.aarnet.edu.au"
    "debian.mirror.digitalpacific.com.au (Australia, DP)|debian.mirror.digitalpacific.com.au"
    "ftp.nz.debian.org     (New Zealand)|ftp.nz.debian.org"
    "mirror.fsmg.org.nz    (New Zealand, FSMG)|mirror.fsmg.org.nz"
)

# South America
declare -a R5=(
    "ftp.br.debian.org     (Brazil)|ftp.br.debian.org"
    "ftp.ar.debian.org     (Argentina)|ftp.ar.debian.org"
    "ftp.cl.debian.org     (Chile)|ftp.cl.debian.org"
    "ftp.co.debian.org     (Colombia)|ftp.co.debian.org"
    "debian.c3sl.ufpr.br   (Brazil, UFPR)|debian.c3sl.ufpr.br"
)

# Africa
declare -a R6=(
    "ftp.za.debian.org     (South Africa)|ftp.za.debian.org"
    "mirror.ac.za          (South Africa, TENET)|mirror.ac.za"
    "debian.mirror.ac.ke   (Kenya)|debian.mirror.ac.ke"
    "ftp.eg.debian.org     (Egypt)|ftp.eg.debian.org"
    "mirror.marwan.ma      (Morocco, MARWAN)|mirror.marwan.ma"
)

# Map region index -> array name
get_region_entries() {
    local idx="$1"
    case "$idx" in
        0) echo "${R0[@]}" ;;
        1) echo "${R1[@]}" ;;
        2) echo "${R2[@]}" ;;
        3) echo "${R3[@]}" ;;
        4) echo "${R4[@]}" ;;
        5) echo "${R5[@]}" ;;
        6) echo "${R6[@]}" ;;
    esac
}

get_region_count() {
    local idx="$1"
    case "$idx" in
        0) echo "${#R0[@]}" ;;
        1) echo "${#R1[@]}" ;;
        2) echo "${#R2[@]}" ;;
        3) echo "${#R3[@]}" ;;
        4) echo "${#R4[@]}" ;;
        5) echo "${#R5[@]}" ;;
        6) echo "${#R6[@]}" ;;
    esac
}

# ============================================================
#  UI helpers
# ============================================================
print_header() {
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║       Debian APT Sources Configuration               ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================
#  Step 1 — Release
# ============================================================
choose_release() {
    echo "  ── Select Release ──"
    echo "  [1] Debian 13 Trixie  (stable — recommended)"
    echo "  [2] Testing            (rolling, latest packages)"
    echo "  [3] Quit"
    echo ""

    local choice
    while true; do
        read -rp "  Choice [1-3]: " choice
        case "$choice" in
            1) RELEASE="trixie";  RELEASE_LABEL="Debian 13 Trixie (stable)"; break ;;
            2) RELEASE="testing"; RELEASE_LABEL="Testing (rolling)";          break ;;
            3) echo "Cancelled."; exit 0 ;;
            *) echo "  Invalid input, please choose 1–3." ;;
        esac
    done
}

# ============================================================
#  Step 2 — Region then Mirror
# ============================================================
choose_mirror() {
    # --- Region ---
    echo ""
    echo "  ── Select Region ──"
    for i in "${!REGIONS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "${REGIONS[$i]}"
    done
    echo ""

    local reg_choice reg_idx
    while true; do
        read -rp "  Region [1-${#REGIONS[@]}]: " reg_choice
        if [[ "$reg_choice" =~ ^[0-9]+$ ]] && \
           (( reg_choice >= 1 && reg_choice <= ${#REGIONS[@]} )); then
            reg_idx=$(( reg_choice - 1 ))
            break
        fi
        echo "  Invalid input."
    done

    # --- Mirror within region ---
    echo ""
    echo "  ── Select Mirror — ${REGIONS[$reg_idx]} ──"

    # Build temporary arrays from the chosen region
    local -a LABELS URLS
    LABELS=(); URLS=()
    while IFS='|' read -r lbl url; do
        LABELS+=("$lbl")
        URLS+=("$url")
    done < <(get_region_entries "$reg_idx" | tr ' ' '\n' | paste - - | sed 's/\t/|/')

    # Re-parse properly (entries contain spaces, so use mapfile trick)
    LABELS=(); URLS=()
    local raw_entries
    mapfile -t raw_entries < <(
        case "$reg_idx" in
            0) printf '%s\n' "${R0[@]}" ;;
            1) printf '%s\n' "${R1[@]}" ;;
            2) printf '%s\n' "${R2[@]}" ;;
            3) printf '%s\n' "${R3[@]}" ;;
            4) printf '%s\n' "${R4[@]}" ;;
            5) printf '%s\n' "${R5[@]}" ;;
            6) printf '%s\n' "${R6[@]}" ;;
        esac
    )

    local i=1
    for entry in "${raw_entries[@]}"; do
        local lbl="${entry%%|*}"
        local url="${entry##*|}"
        LABELS+=("$lbl")
        URLS+=("$url")
        printf "  [%d] %s\n" "$i" "$lbl"
        (( i++ ))
    done
    echo ""

    local mir_choice
    while true; do
        read -rp "  Mirror [1-${#URLS[@]}]: " mir_choice
        if [[ "$mir_choice" =~ ^[0-9]+$ ]] && \
           (( mir_choice >= 1 && mir_choice <= ${#URLS[@]} )); then
            MIRROR="${URLS[$((mir_choice-1))]}"
            MIRROR_LABEL="${LABELS[$((mir_choice-1))]}"
            break
        fi
        echo "  Invalid input."
    done
}

# ============================================================
#  Step 3 — Components
# ============================================================
choose_components() {
    echo ""
    echo "  ── Select Components ──"
    echo "  [1] main                                      (free software only)"
    echo "  [2] main contrib                              (+ contrib)"
    echo "  [3] main contrib non-free                     (+ non-free)"
    echo "  [4] main contrib non-free non-free-firmware   (full, recommended)"
    echo ""

    local choice
    while true; do
        read -rp "  Choice [1-4]: " choice
        case "$choice" in
            1) COMPONENTS="main";                                      break ;;
            2) COMPONENTS="main contrib";                              break ;;
            3) COMPONENTS="main contrib non-free";                     break ;;
            4) COMPONENTS="main contrib non-free non-free-firmware";   break ;;
            *) echo "  Invalid input." ;;
        esac
    done
}

# ============================================================
#  Step 4 — Extra repos
# ============================================================
choose_extras() {
    echo ""
    echo "  ── Additional Repositories ──"

    read -rp "  Include Security updates? [Y/n]: " sec
    USE_SECURITY="${sec,,}"; [[ -z "$USE_SECURITY" ]] && USE_SECURITY="y"

    read -rp "  Include Updates repo?     [Y/n]: " upd
    USE_UPDATES="${upd,,}";  [[ -z "$USE_UPDATES"  ]] && USE_UPDATES="y"

    if [[ "$RELEASE" == "trixie" ]]; then
        read -rp "  Include Backports?        [y/N]: " bp
        USE_BACKPORTS="${bp,,}"; [[ -z "$USE_BACKPORTS" ]] && USE_BACKPORTS="n"
    else
        USE_BACKPORTS="n"
    fi
}

# ============================================================
#  Build sources.list content
# ============================================================
build_sources() {
    local proto="http"
    SOURCES_CONTENT=""

    SOURCES_CONTENT+="# Debian ${RELEASE_LABEL}\n"
    SOURCES_CONTENT+="# Generated by debian-sources.sh on $(date)\n"
    SOURCES_CONTENT+="# Mirror: ${MIRROR_LABEL}\n\n"

    # Main repo
    SOURCES_CONTENT+="# Main repository\n"
    SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"
    SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"

    # Security
    if [[ "$USE_SECURITY" == "y" ]]; then
        if [[ "$RELEASE" == "trixie" ]]; then
            SOURCES_CONTENT+="\n# Security\n"
            SOURCES_CONTENT+="deb ${proto}://security.debian.org/debian-security ${RELEASE}-security ${COMPONENTS}\n"
            SOURCES_CONTENT+="deb-src ${proto}://security.debian.org/debian-security ${RELEASE}-security ${COMPONENTS}\n"
        else
            SOURCES_CONTENT+="\n# Security (testing)\n"
            SOURCES_CONTENT+="deb ${proto}://security.debian.org/debian-security testing-security ${COMPONENTS}\n"
            SOURCES_CONTENT+="deb-src ${proto}://security.debian.org/debian-security testing-security ${COMPONENTS}\n"
        fi
    fi

    # Updates
    if [[ "$USE_UPDATES" == "y" ]]; then
        SOURCES_CONTENT+="\n# Updates\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
    fi

    # Backports (stable only)
    if [[ "$USE_BACKPORTS" == "y" ]]; then
        SOURCES_CONTENT+="\n# Backports\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
    fi
}

# ============================================================
#  Preview
# ============================================================
show_preview() {
    echo ""
    echo "  ── Preview: ${SOURCES_FILE} ──"
    echo "  ┌────────────────────────────────────────────────────"
    echo -e "$SOURCES_CONTENT" | sed 's/^/  │ /'
    echo "  └────────────────────────────────────────────────────"
    echo ""
}

# ============================================================
#  Apply
# ============================================================
apply_sources() {
    if [[ -f "$SOURCES_FILE" ]]; then
        echo "  Creating backup: $BACKUP_FILE"
        cp "$SOURCES_FILE" "$BACKUP_FILE"
    fi

    echo -e "$SOURCES_CONTENT" > "$SOURCES_FILE"
    echo "  ✔ ${SOURCES_FILE} written."

    read -rp "  Run apt update now? [Y/n]: " do_update
    do_update="${do_update,,}"; [[ -z "$do_update" ]] && do_update="y"

    if [[ "$do_update" == "y" ]]; then
        echo ""
        apt update
    fi
}

# ============================================================
#  Main
# ============================================================
print_header
choose_release
choose_mirror
choose_components
choose_extras
build_sources
show_preview

read -rp "  Apply changes? [Y/n]: " confirm
confirm="${confirm,,}"; [[ -z "$confirm" ]] && confirm="y"

if [[ "$confirm" == "y" ]]; then
    apply_sources
    echo ""
    echo "  ✔ Done! Sources configured successfully."
else
    echo "  Cancelled. No changes made."
fi

echo ""
