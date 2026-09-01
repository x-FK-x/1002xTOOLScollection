#!/bin/bash

# === Logged-in user HOME detection ===
REALUSER=$(logname 2>/dev/null || echo "$SUDO_USER")
USERHOME=$(eval echo "~$REALUSER")

LIST="/etc/modos/tools/list.txt"
DESKTOP_DIR="$USERHOME/Desktop"

if [[ ! -f "$LIST" ]]; then
    whiptail --title "Error" --msgbox "The file /etc/modos/tools/list.txt was not found!" 10 50
    exit 1
fi

mkdir -p "$DESKTOP_DIR"

declare -A STATUS

# === Scan tools and collect menu data ===
MENU_ITEMS=()
while IFS= read -r TOOL || [[ -n "$TOOL" ]]; do
    [[ -z "$TOOL" ]] && continue

    INSTALLED="no"
    DESK="no"

    command -v "$TOOL" &>/dev/null && INSTALLED="yes"
    [[ -f "$DESKTOP_DIR/$TOOL.desktop" ]] && DESK="yes"

    STATUS["$TOOL"]="$INSTALLED|$DESK"

    LABEL="$TOOL (installed: $INSTALLED, desktop: $DESK)"
    MENU_ITEMS+=("$TOOL" "$LABEL" "OFF")

done < "$LIST"


# === Multi selection menu ===
SELECTIONS=$(whiptail --title "Desktop Entry Manager" \
    --checklist "Select tools to sync (create/remove desktop entries):" \
    25 80 15 \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3)

[[ $? -ne 0 ]] && exit 0


# === Icon Finder ===
find_icon() {
    local TOOL="$1"
    local ICON=""

    SEARCH_PATHS=(
        "/usr/share/icons/hicolor/*/apps"
        "/usr/share/icons/*/*/apps"
        "/usr/share/pixmaps"
        "/usr/share/icons"
    )

    for DIR in "${SEARCH_PATHS[@]}"; do
        ICON_FILE=$(find $DIR -maxdepth 1 -type f \
            \( -name "${TOOL}.png" -o -name "${TOOL}.svg" \) 2>/dev/null | head -n 1)

        if [[ -n "$ICON_FILE" ]]; then
            ICON="$ICON_FILE"
            break
        fi
    done

    # Fallback icon
    [[ -z "$ICON" ]] && ICON="utilities-terminal"

    echo "$ICON"
}


# === Create desktop entry ===
create_desktop_entry() {
    local NAME="$1"
    local FILE="$DESKTOP_DIR/$NAME.desktop"
    local ICON
    ICON=$(find_icon "$NAME")

cat <<EOF > "$FILE"
[Desktop Entry]
Name=$NAME
Exec=$NAME
Icon=$ICON
Terminal=false
Type=Application
Categories=Utility;
EOF

    chmod +x "$FILE"
    chown "$REALUSER":"$REALUSER" "$FILE"
}


# === Process selected items ===
for TOOL in $SELECTIONS; do
    TOOL=$(echo "$TOOL" | tr -d '"')

    INSTALLED=$(echo "${STATUS[$TOOL]}" | cut -d '|' -f1)
    HAS_DESK=$(echo "${STATUS[$TOOL]}" | cut -d '|' -f2)

    if [[ "$INSTALLED" == "no" ]]; then
        whiptail --title "Skipping" --msgbox \
            "'$TOOL' is not installed. Skipping." 10 50
        continue
    fi

    DESK_FILE="$DESKTOP_DIR/$TOOL.desktop"

    if [[ "$HAS_DESK" == "yes" ]]; then
        rm -f "$DESK_FILE"
        whiptail --title "Removed" --msgbox \
            "Removed desktop entry for '$TOOL'." 10 50
    else
        create_desktop_entry "$TOOL"
        whiptail --title "Created" --msgbox \
            "Created desktop entry for '$TOOL'." 10 50
    fi
done

whiptail --title "Done" --msgbox "All selected tools processed." 10 50
exit 0
