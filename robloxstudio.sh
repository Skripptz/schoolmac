#!/bin/bash
set -e

INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

##############################################
# FUNCTION: Download + Install Roblox Variant
##############################################
install_roblox_variant() {
    VARIANT_NAME="$1"          # MacPlayer or MacStudio
    ZIP_NAME="$2"              # RobloxPlayer.zip or RobloxStudio.zip
    FINAL_NAME="$3"            # Folder name you want (Self Service Player.app)

    echo "Installing $VARIANT_NAME..."

    # --- GET VERSION HASH ---
    VERSION=$(
    curl -fsSL "https://clientsettings.roblox.com/v2/client-version/${VARIANT_NAME}/channel/LIVE" \
    | python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
    )

    if [ -z "$VERSION" ]; then
        echo "Failed to fetch version for $VARIANT_NAME"
        exit 1
    fi

    echo "$VARIANT_NAME version: $VERSION"

    # --- ARCH DETECTION ---
    ARCH="arm64"
    if [ "$(uname -m)" = "x86_64" ]; then
        ARCH="x86-64"
    fi

    # --- DOWNLOAD ---
    URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${VERSION}-${ZIP_NAME}"
    echo "Downloading from: $URL"

    curl -L --fail --show-error "$URL" -o /tmp/roblox_temp.zip

    # --- VALIDATE ZIP ---
    FILE_TYPE=$(file /tmp/roblox_temp.zip)
    if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
        echo "ERROR: Download is not a valid ZIP"
        exit 1
    fi

    # --- EXTRACT ---
    rm -rf RobloxExtract
    mkdir -p RobloxExtract
    unzip -q /tmp/roblox_temp.zip -d RobloxExtract

    APP=$(find RobloxExtract -name "*.app" | head -n 1)

    if [ -z "$APP" ]; then
        echo "Could not find extracted app for $VARIANT_NAME"
        exit 1
    fi

    # --- REMOVE QUARANTINE (SAFE) ---
    xattr -cr "$
