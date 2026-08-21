#!/bin/bash
set -e

echo "Downloading latest Roblox Player for macOS..."

# --- GET VERSION HASH ---
ROBLOX_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "Failed to fetch Roblox Player version"
    exit 1
fi

echo "Roblox Player version: $ROBLOX_VERSION"

# --- ARCH DETECTION ---
ARCH="arm64"
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x86-64"
fi

# --- DOWNLOAD ---
URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${ROBLOX_VERSION}-RobloxPlayer.zip"
echo "Downloading from: $URL"

curl -L --fail --show-error "$URL" -o /tmp/robloxplayer.zip

# --- VALIDATE ZIP ---
FILE_TYPE=$(file /tmp/robloxplayer.zip)
if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP"
    exit 1
fi

echo "ZIP validated."

# --- EXTRACT ---
rm -rf RobloxPlayerExtract
mkdir -p RobloxPlayer
