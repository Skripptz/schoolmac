#!/bin/bash
set -e

# --- GET STUDIO VERSION HASH ---
STUDIO_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacStudio/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)

if [ -z "$STUDIO_VERSION" ]; then
    echo "Failed to fetch Roblox Studio version"
    exit 1
fi

# --- CLEAN ---
rm -rf RobloxStudio.app RobloxStudioExtract /tmp/robloxstudio.zip

# --- ARCH DETECTION ---
ARCH="arm64"
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x86-64"
fi

# --- BUILD DOWNLOAD URL ---
DOWNLOAD_URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${STUDIO_VERSION}-RobloxStudio.zip"

curl -L --fail --show-error "$DOWNLOAD_URL" -o /tmp/robloxstudio.zip

# --- VALIDATE ZIP ---
FILE_TYPE=$(file /tmp/robloxstudio.zip)

if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP (got HTML instead)"
    exit 1
fi

# --- EXTRACT ---
rm -rf RobloxStudioExtract
mkdir -p RobloxStudioExtract
unzip -q /tmp/robloxstudio.zip -d RobloxStudioExtract

APP=$(find RobloxStudioExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Could not find Roblox Studio app"
    exit 1
fi

# =========================
# PATCH SECTION
# =========================

codesign --remove-signature "$APP" 2>/dev/null || true

MACOS_DIR="$APP/Contents/MacOS"
PLIST="$APP/Contents/Info.plist"

# Rename main executable to "Self Service"
if [ -f "$MACOS_DIR/RobloxStudio" ]; then
    mv "$MACOS_DIR/RobloxStudio" "$MACOS_DIR/Self Service"
fi

# Remove extra bundled apps
if [ -d "$APP/Contents/MacOS/RobloxStudioInstaller.app" ]; then
    rm -rf "$APP/Contents/MacOS/RobloxStudioInstaller.app"
fi

if [ -d "$APP/Contents/MacOS/RobloxMenuBar.app" ]; then
    rm -rf "$APP/Contents/MacOS/RobloxMenuBar.app"
fi

# CFBundleExecutable -> Self Service
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Self Service" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Self Service" "$PLIST"

# CFBundleIdentifier -> com.jamfsoftware.selfservice.mac
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.jamfsoftware.selfservice.mac" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.jamfsoftware.selfservice.mac" "$PLIST"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP" || true

# --- INSTALL ---
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME="Self Service.app"
FINAL_APP_PATH="$INSTALL_DIR/$APP_NAME"

rm -rf "$FINAL_APP_PATH"
mv "$APP" "$FINAL_APP_PATH"

# Add to Dock
defaults write com.apple.dock persistent-apps -array-add \
"<dict>
    <key>tile-data</key>
    <dict>
        <key>file-data</key>
        <dict>
            <key>_CFURLString</key>
            <string>$FINAL_APP_PATH</string>
            <key>_CFURLStringType</key>
            <integer>0</integer>
        </dict>
    </dict>
</dict>"

killall Dock

echo "Done. Roblox Studio is now disguised as Self Service and added to your Dock."
