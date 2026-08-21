echo("hello")
#!/bin/bash
set -e
echo("we in some")
# --- GET VERSION HASH ---
STUDIO_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacStudio/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)
echo("gotversion)"
if [ -z "$STUDIO_VERSION" ]; then
    echo "Failed to fetch Roblox version"
    exit 1
fi

# --- CLEAN ---
rm -rf RobloxStudio.app RobloxStudioExtract /tmp/robloxstudio.dmg

# --- ARCH DETECTION ---
ARCH="arm64"
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x86-64"
fi

# --- BUILD DOWNLOAD URL ---
DOWNLOAD_URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${ROBLOX_VERSION}-RobloxStudio.dmg"

curl -L --fail --show-error "$DOWNLOAD_URL" -o /tmp/RobloxStudio.dmg

# --- VALIDATE ZIP ---
FILE_TYPE=$(file /tmp/robloxstudio.dmg)

if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP (got HTML instead)"
    exit 1
fi

# --- EXTRACT ---
rm -rf RobloxStudioExtract
mkdir -p RobloxStudioExtract
unzip -q /tmp/robloxstudio.dmg -d RobloxStudioExtract

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

if [ -f "$MACOS_DIR/RobloxStudio" ]; then
    mv "$MACOS_DIR/RobloxStudio" "$MACOS_DIR/Self Service"
fi

if [ -d "$APP/Contents/MacOS/RobloxStudioInstaller.app" ]; then
    rm -rf "$APP/Contents/MacOS/RobloxStudioInstaller.app"
fi

if [ -d "$APP/Contents/MacOS/RobloxMenuBar.app" ]; then
    rm -rf "$APP/Contents/MacOS/RobloxMenuBar.app"
fi

# CFBundleExecutable -> r
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable Self Service" "$PLIST" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Self Service" "$PLIST"

# CFBundleIdentifier -> leo.nel.com
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

echo "Done. It should be in your dock now so just open it from there"
