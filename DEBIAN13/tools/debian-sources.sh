#!/bin/bash
# ============================================================
#  debian-sources.sh — Debian APT Sources Configuration
#  Supports: Debian 13 (trixie/stable) and Testing
#  Run with: sudo bash debian-sources.sh
# ============================================================

set -euo pipefail

SOURCES_FILE="/etc/apt/sources.list"
BACKUP_DIR="/etc/apt"
BACKUP_PREFIX="sources.list.bak."

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root or with sudo."
    exit 1
fi

# ============================================================
#  Mirror definitions  (label|hostname)
# ============================================================

REGIONS=(
    "Official / CDN"
    "Europe"
    "North America"
    "Asia"
    "Oceania"
    "South America"
    "Africa"
)

declare -a R0=( "deb.debian.org (official Anycast CDN)|deb.debian.org" )

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

declare -a R2=(
    "ftp.us.debian.org          (USA, official)|ftp.us.debian.org"
    "mirror.math.ucdavis.edu    (USA, UC Davis)|mirror.math.ucdavis.edu"
    "mirrors.ocf.berkeley.edu   (USA, UC Berkeley)|mirrors.ocf.berkeley.edu"
    "debian.mirror.constant.com (USA, Constant)|debian.mirror.constant.com"
    "ftp.ca.debian.org          (Canada)|ftp.ca.debian.org"
    "mirror.csclub.uwaterloo.ca (Canada, UWaterloo)|mirror.csclub.uwaterloo.ca"
)

declare -a R3=(
    "ftp.jp.debian.org              (Japan)|ftp.jp.debian.org"
    "ftp.cn.debian.org              (China)|ftp.cn.debian.org"
    "ftp.kr.debian.org              (South Korea)|ftp.kr.debian.org"
    "ftp.tw.debian.org              (Taiwan)|ftp.tw.debian.org"
    "ftp.in.debian.org              (India)|ftp.in.debian.org"
    "ftp.id.debian.org              (Indonesia)|ftp.id.debian.org"
    "mirror.nus.edu.sg              (Singapore, NUS)|mirror.nus.edu.sg"
    "mirrors.tuna.tsinghua.edu.cn   (China, Tsinghua)|mirrors.tuna.tsinghua.edu.cn"
)

declare -a R4=(
    "ftp.au.debian.org                       (Australia)|ftp.au.debian.org"
    "mirror.aarnet.edu.au                    (Australia, AARNet)|mirror.aarnet.edu.au"
    "debian.mirror.digitalpacific.com.au     (Australia, DP)|debian.mirror.digitalpacific.com.au"
    "ftp.nz.debian.org                       (New Zealand)|ftp.nz.debian.org"
    "mirror.fsmg.org.nz                      (New Zealand, FSMG)|mirror.fsmg.org.nz"
)

declare -a R5=(
    "ftp.br.debian.org      (Brazil)|ftp.br.debian.org"
    "ftp.ar.debian.org      (Argentina)|ftp.ar.debian.org"
    "ftp.cl.debian.org      (Chile)|ftp.cl.debian.org"
    "ftp.co.debian.org      (Colombia)|ftp.co.debian.org"
    "debian.c3sl.ufpr.br    (Brazil, UFPR)|debian.c3sl.ufpr.br"
)

declare -a R6=(
    "ftp.za.debian.org      (South Africa)|ftp.za.debian.org"
    "mirror.ac.za           (South Africa, TENET)|mirror.ac.za"
    "debian.mirror.ac.ke    (Kenya)|debian.mirror.ac.ke"
    "ftp.eg.debian.org      (Egypt)|ftp.eg.debian.org"
    "mirror.marwan.ma       (Morocco, MARWAN)|mirror.marwan.ma"
)

# ============================================================
#  UI helpers
# ============================================================
clr() { clear; }

print_header() {
    clr
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║       Debian APT Sources Configuration               ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
}

# ============================================================
#  Main menu
# ============================================================
main_menu() {
    while true; do
        print_header
        echo "  ── Main Menu ──"
        echo "  [1] Configure APT Sources"
        echo "  [2] Restore from backup"
        echo "  [3] List / delete backups"
        echo "  [4] Show current sources.list"
        echo "  [5] Quit"
        echo ""

        local choice
        read -rp "  Choice [1-5]: " choice
        case "$choice" in
            1) configure_sources ;;
            2) restore_backup    ;;
            3) manage_backups    ;;
            4) show_current      ;;
            5) echo ""; echo "  Bye."; echo ""; exit 0 ;;
            *) echo "  Invalid input."; sleep 1 ;;
        esac
    done
}

# ============================================================
#  Show current sources.list
# ============================================================
show_current() {
    clr
    echo ""
    echo "  ── Current: ${SOURCES_FILE} ──"
    if [[ -f "$SOURCES_FILE" ]]; then
        echo "  ┌────────────────────────────────────────────────────"
        sed 's/^/  │ /' "$SOURCES_FILE"
        echo "  └────────────────────────────────────────────────────"
    else
        echo "  (file does not exist)"
    fi
    echo ""
    read -rp "  Press Enter to return..." _
}

# ============================================================
#  Restore backup
# ============================================================
restore_backup() {
    clr
    echo ""
    echo "  ── Restore from Backup ──"
    echo ""

    # Collect backup files sorted newest first
    local -a BACKUPS
    mapfile -t BACKUPS < <(
        ls -t "${BACKUP_DIR}/${BACKUP_PREFIX}"* 2>/dev/null || true
    )

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo "  No backups found in ${BACKUP_DIR}."
        echo ""
        read -rp "  Press Enter to return..." _
        return
    fi

    echo "  Available backups (newest first):"
    echo ""
    local i=1
    for f in "${BACKUPS[@]}"; do
        local ts="${f##*${BACKUP_PREFIX}}"
        local size
        size=$(du -h "$f" | cut -f1)
        printf "  [%2d] %s  (%s)  %s\n" "$i" "$(basename "$f")" "$size" ""
        (( i++ ))
    done
    echo ""
    echo "  [0] Cancel"
    echo ""

    local choice
    while true; do
        read -rp "  Select backup [0-${#BACKUPS[@]}]: " choice
        if [[ "$choice" == "0" ]]; then return; fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && \
           (( choice >= 1 && choice <= ${#BACKUPS[@]} )); then
            break
        fi
        echo "  Invalid input."
    done

    local selected="${BACKUPS[$((choice-1))]}"

    echo ""
    echo "  ── Preview of selected backup ──"
    echo "  ┌────────────────────────────────────────────────────"
    sed 's/^/  │ /' "$selected"
    echo "  └────────────────────────────────────────────────────"
    echo ""

    read -rp "  Restore this backup? [Y/n]: " confirm
    confirm="${confirm,,}"; [[ -z "$confirm" ]] && confirm="y"

    if [[ "$confirm" == "y" ]]; then
        # Back up the current file before overwriting
        if [[ -f "$SOURCES_FILE" ]]; then
            local now_bak="${BACKUP_DIR}/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
            cp "$SOURCES_FILE" "$now_bak"
            echo "  Current sources.list backed up to: $(basename "$now_bak")"
        fi
        cp "$selected" "$SOURCES_FILE"
        echo "  ✔ Restored: $(basename "$selected") → ${SOURCES_FILE}"

        read -rp "  Run apt update now? [Y/n]: " do_update
        do_update="${do_update,,}"; [[ -z "$do_update" ]] && do_update="y"
        if [[ "$do_update" == "y" ]]; then
            echo ""
            apt update
        fi
    else
        echo "  Cancelled."
    fi

    echo ""
    read -rp "  Press Enter to return..." _
}

# ============================================================
#  Manage (list / delete) backups
# ============================================================
manage_backups() {
    clr
    echo ""
    echo "  ── Manage Backups ──"
    echo ""

    local -a BACKUPS
    mapfile -t BACKUPS < <(
        ls -t "${BACKUP_DIR}/${BACKUP_PREFIX}"* 2>/dev/null || true
    )

    if [[ ${#BACKUPS[@]} -eq 0 ]]; then
        echo "  No backups found."
        echo ""
        read -rp "  Press Enter to return..." _
        return
    fi

    local i=1
    for f in "${BACKUPS[@]}"; do
        local size
        size=$(du -h "$f" | cut -f1)
        printf "  [%2d] %s  (%s)\n" "$i" "$(basename "$f")" "$size"
        (( i++ ))
    done
    echo ""
    echo "  Options:"
    echo "  [d <n>]  Delete backup number <n>   (e.g. d 3)"
    echo "  [d all]  Delete ALL backups"
    echo "  [0]      Return to main menu"
    echo ""

    while true; do
        read -rp "  Command: " cmd arg

        case "$cmd" in
            0) return ;;
            d|D)
                if [[ "${arg,,}" == "all" ]]; then
                    read -rp "  Delete ALL ${#BACKUPS[@]} backups? [y/N]: " yn
                    yn="${yn,,}"
                    if [[ "$yn" == "y" ]]; then
                        for f in "${BACKUPS[@]}"; do rm -f "$f"; done
                        echo "  ✔ All backups deleted."
                    else
                        echo "  Cancelled."
                    fi
                    echo ""
                    read -rp "  Press Enter to return..." _
                    return
                elif [[ "$arg" =~ ^[0-9]+$ ]] && \
                     (( arg >= 1 && arg <= ${#BACKUPS[@]} )); then
                    local target="${BACKUPS[$((arg-1))]}"
                    read -rp "  Delete $(basename "$target")? [y/N]: " yn
                    yn="${yn,,}"
                    if [[ "$yn" == "y" ]]; then
                        rm -f "$target"
                        echo "  ✔ Deleted."
                    else
                        echo "  Cancelled."
                    fi
                    echo ""
                    read -rp "  Press Enter to return..." _
                    return
                else
                    echo "  Invalid number."
                fi
                ;;
            *) echo "  Unknown command. Use 'd <n>', 'd all', or '0'." ;;
        esac
    done
}

# ============================================================
#  Configure sources — Step 1: Release
# ============================================================
choose_release() {
    print_header
    echo "  ── Step 1/4 — Select Release ──"
    echo ""
    echo "  [1] Debian 13 Trixie  (stable — recommended)"
    echo "  [2] Testing            (rolling, latest packages)"
    echo "  [0] Back to main menu"
    echo ""

    local choice
    while true; do
        read -rp "  Choice: " choice
        case "$choice" in
            1) RELEASE="trixie";  RELEASE_LABEL="Debian 13 Trixie (stable)"; return 0 ;;
            2) RELEASE="testing"; RELEASE_LABEL="Testing (rolling)";          return 0 ;;
            0) return 1 ;;
            *) echo "  Invalid input." ;;
        esac
    done
}

# ============================================================
#  Step 2 — Region then Mirror
# ============================================================
choose_mirror() {
    print_header
    echo "  ── Step 2/4 — Select Region ──"
    echo ""
    for i in "${!REGIONS[@]}"; do
        printf "  [%d] %s\n" "$((i+1))" "${REGIONS[$i]}"
    done
    echo "  [0] Back"
    echo ""

    local reg_choice reg_idx
    while true; do
        read -rp "  Region: " reg_choice
        if [[ "$reg_choice" == "0" ]]; then return 1; fi
        if [[ "$reg_choice" =~ ^[0-9]+$ ]] && \
           (( reg_choice >= 1 && reg_choice <= ${#REGIONS[@]} )); then
            reg_idx=$(( reg_choice - 1 ))
            break
        fi
        echo "  Invalid input."
    done

    # Build mirror list for chosen region
    local -a raw_entries
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

    print_header
    echo "  ── Step 2/4 — Select Mirror — ${REGIONS[$reg_idx]} ──"
    echo ""

    local -a LABELS URLS
    LABELS=(); URLS=()
    local i=1
    for entry in "${raw_entries[@]}"; do
        local lbl="${entry%%|*}"
        local url="${entry##*|}"
        LABELS+=("$lbl")
        URLS+=("$url")
        printf "  [%d] %s\n" "$i" "$lbl"
        (( i++ ))
    done
    echo "  [0] Back"
    echo ""

    local mir_choice
    while true; do
        read -rp "  Mirror: " mir_choice
        if [[ "$mir_choice" == "0" ]]; then return 1; fi
        if [[ "$mir_choice" =~ ^[0-9]+$ ]] && \
           (( mir_choice >= 1 && mir_choice <= ${#URLS[@]} )); then
            MIRROR="${URLS[$((mir_choice-1))]}"
            MIRROR_LABEL="${LABELS[$((mir_choice-1))]}"
            return 0
        fi
        echo "  Invalid input."
    done
}

# ============================================================
#  Step 3 — Components
# ============================================================
choose_components() {
    print_header
    echo "  ── Step 3/4 — Select Components ──"
    echo ""
    echo "  [1] main                                      (free software only)"
    echo "  [2] main contrib                              (+ contrib)"
    echo "  [3] main contrib non-free                     (+ non-free)"
    echo "  [4] main contrib non-free non-free-firmware   (full, recommended)"
    echo "  [0] Back"
    echo ""

    local choice
    while true; do
        read -rp "  Choice: " choice
        case "$choice" in
            1) COMPONENTS="main";                                      return 0 ;;
            2) COMPONENTS="main contrib";                              return 0 ;;
            3) COMPONENTS="main contrib non-free";                     return 0 ;;
            4) COMPONENTS="main contrib non-free non-free-firmware";   return 0 ;;
            0) return 1 ;;
            *) echo "  Invalid input." ;;
        esac
    done
}

# ============================================================
#  Step 4 — Extra repos
# ============================================================
choose_extras() {
    print_header
    echo "  ── Step 4/4 — Additional Repositories ──"
    echo ""

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
    return 0
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
    SOURCES_CONTENT+="# Main repository\n"
    SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"
    SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE} ${COMPONENTS}\n"

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

    if [[ "$USE_UPDATES" == "y" ]]; then
        SOURCES_CONTENT+="\n# Updates\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-updates ${COMPONENTS}\n"
    fi

    if [[ "$USE_BACKPORTS" == "y" ]]; then
        SOURCES_CONTENT+="\n# Backports\n"
        SOURCES_CONTENT+="deb ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
        SOURCES_CONTENT+="deb-src ${proto}://${MIRROR}/debian ${RELEASE}-backports ${COMPONENTS}\n"
    fi
}

# ============================================================
#  Preview + Apply
# ============================================================
show_preview_and_apply() {
    print_header
    echo "  ── Preview: ${SOURCES_FILE} ──"
    echo "  ┌────────────────────────────────────────────────────"
    echo -e "$SOURCES_CONTENT" | sed 's/^/  │ /'
    echo "  └────────────────────────────────────────────────────"
    echo ""

    read -rp "  Apply changes? [Y/n]: " confirm
    confirm="${confirm,,}"; [[ -z "$confirm" ]] && confirm="y"

    if [[ "$confirm" == "y" ]]; then
        if [[ -f "$SOURCES_FILE" ]]; then
            local bak="${BACKUP_DIR}/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
            cp "$SOURCES_FILE" "$bak"
            echo "  Backup created: $(basename "$bak")"
        fi
        echo -e "$SOURCES_CONTENT" > "$SOURCES_FILE"
        echo "  ✔ ${SOURCES_FILE} written."

        read -rp "  Run apt update now? [Y/n]: " do_update
        do_update="${do_update,,}"; [[ -z "$do_update" ]] && do_update="y"
        if [[ "$do_update" == "y" ]]; then
            echo ""
            apt update
        fi
        echo ""
        echo "  ✔ Done! Sources configured successfully."
        echo ""
        read -rp "  Press Enter to return to main menu..." _
    else
        echo "  Cancelled. No changes made."
        echo ""
        read -rp "  Press Enter to return to main menu..." _
    fi
}

# ============================================================
#  Configure sources — full wizard
# ============================================================
configure_sources() {
    RELEASE=""
    RELEASE_LABEL=""
    MIRROR=""
    MIRROR_LABEL=""
    COMPONENTS=""
    USE_SECURITY="y"
    USE_UPDATES="y"
    USE_BACKPORTS="n"
    SOURCES_CONTENT=""

    choose_release  || return
    choose_mirror   || return
    choose_components || return
    choose_extras
    build_sources
    show_preview_and_apply
}

# ============================================================
#  Entry point
# ============================================================
main_menu
