#!/bin/bash
set -e

echo "Fetching latest Roblox Studio version…"

VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacStudio/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)

if [ -z "$VERSION" ]; then
    echo "Failed to get version."
    exit 1
fi

echo "Latest version: $VERSION"

ARCH="arm64"
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x86-64"
fi

URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${VERSION}-RobloxStudio.zip"

echo "Downloading Roblox Studio from:"
echo "$URL"

curl -L --fail --show-error "$URL" -o /tmp/robloxstudio.zip

echo "Extracting…"
rm -rf /tmp/RobloxStudioExtract
mkdir -p /tmp/RobloxStudioExtract
unzip -q /tmp/robloxstudio.zip -d /tmp/RobloxStudioExtract

APP=$(find /tmp/RobloxStudioExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Studio app not found."
    exit 1
fi

INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

echo "Installing to $INSTALL_DIR…"
rm -rf "$INSTALL_DIR/RobloxStudio.app"
mv "$APP" "$INSTALL_DIR/RobloxStudio.app"

echo "Roblox Studio installed successfully."
