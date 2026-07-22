#!/bin/bash

set -u

echo "Getting Roblox version..."

ROBLOX_VERSION=$(
    curl -fsSL \
    "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" |
    python3 -c '
import sys, json
data = json.load(sys.stdin)
print(data["clientVersionUpload"])
'
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "Failed to get Roblox version."
    exit 1
fi

echo "Version: $ROBLOX_VERSION"

ARCH=$(uname -m)

case "$ARCH" in
    arm64)
        ROBLOX_ARCH="arm64"
        ;;
    x86_64)
        ROBLOX_ARCH="x86-64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://setup-aws.rbxcdn.com/mac/${ROBLOX_ARCH}/${ROBLOX_VERSION}-RobloxPlayer.zip"

echo "Downloading Roblox..."
echo "$DOWNLOAD_URL"

rm -f /tmp/roblox.zip
rm -rf /tmp/RobloxExtract

if ! curl -fL --show-error "$DOWNLOAD_URL" -o /tmp/roblox.zip; then
    echo "Download failed."
    exit 1
fi

if ! file /tmp/roblox.zip | grep -qi "zip archive"; then
    echo "Downloaded file is not a valid ZIP."
    file /tmp/roblox.zip
    exit 1
fi

mkdir -p /tmp/RobloxExtract

if ! unzip -q /tmp/roblox.zip -d /tmp/RobloxExtract; then
    echo "Extraction failed."
    exit 1
fi

APP=$(find /tmp/RobloxExtract -type d -name "*.app" -print -quit)

if [ -z "$APP" ]; then
    echo "No application was found in the downloaded archive."
    exit 1
fi

echo "Found app:"
echo "$APP"

INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

FINAL_APP_PATH="$INSTALL_DIR/Roblox.app"

rm -rf "$FINAL_APP_PATH"
mv "$APP" "$FINAL_APP_PATH"

echo "Roblox installed to:"
echo "$FINAL_APP_PATH"

open "$FINAL_APP_PATH"

echo "Finished."
