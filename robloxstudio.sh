#!/bin/bash
set -e

INSTALL_DIR="$HOME/Applications"
APP="$INSTALL_DIR/RobloxStudio.app"

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

echo "Downloading Roblox Studio…"
curl -L --fail --show-error "$URL" -o /tmp/robloxstudio.zip

echo "Extracting…"
rm -rf /tmp/RobloxStudioExtract
mkdir -p /tmp/RobloxStudioExtract
unzip -q /tmp/robloxstudio.zip -d /tmp/RobloxStudioExtract

APP_FOUND=$(find /tmp/RobloxStudioExtract -name "*.app" | head -n 1)

if [ -z "$APP_FOUND" ]; then
    echo "Studio app not found."
    exit 1
fi

echo "Installing clean Roblox Studio…"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP"
mv "$APP_FOUND" "$APP"

echo "Removing quarantine…"
xattr -cr "$APP"

echo "Adding Roblox Studio to Dock…"

defaults write com.apple.dock persistent-apps -array-add \
"<dict>
    <key>tile-data</key>
    <dict>
        <key>file-data</key>
        <dict>
            <key>_CFURLString</key>
            <string>$APP</string>
            <key>_CFURLStringType</key>
            <integer>0</integer>
        </dict>
    </dict>
</dict>"

killall Dock

echo "Roblox Studio installed and added to Dock successfully."
