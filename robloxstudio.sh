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

echo "Downloading Roblox Studio from:"
echo "$URL"

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

echo "Installing Roblox Studio…"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP"
mv "$APP_FOUND" "$APP"

echo "Removing quarantine flags…"
xattr -cr "$APP"

MACOS_DIR="$APP/Contents/MacOS"
PLIST="$APP/Contents/Info.plist"

echo "Restoring executable name if needed…"
if [ -f "$MACOS_DIR/Self Service" ]; then
    mv "$MACOS_DIR/Self Service" "$MACOS_DIR/RobloxStudio"
fi

echo "Fixing CFBundleExecutable…"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable RobloxStudio" "$PLIST"

echo "Deep-signing all executables…"
find "$APP" -type f -perm +111 -exec codesign --force --sign - {} \;

echo "Signing the app bundle…"
codesign --force --deep --sign - "$APP"

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

echo "Roblox Studio installed, repaired, and added to Dock successfully."
