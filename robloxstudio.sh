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
mkdir -p RobloxPlayerExtract
unzip -q /tmp/robloxplayer.zip -d RobloxPlayerExtract

APP=$(find RobloxPlayerExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Could not find Roblox Player app"
    exit 1
fi

echo "Found app: $APP"

# --- REMOVE QUARANTINE (SAFE) ---
xattr -cr "$APP" || true

# --- INSTALL (RENAME ONLY THE OUTER FOLDER) ---
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

FINAL_PATH="$INSTALL_DIR/Self Service.app"

rm -rf "$FINAL_PATH"
mv "$APP" "$FINAL_PATH"

echo "Roblox Player installed as: $FINAL_PATH"

# --- ADD TO DOCK ---
defaults write com.apple.dock persistent-apps -array-add \
"<dict>
    <key>tile-data</key>
    <dict>
        <key>file-data</key>
        <dict>
            <key>_CFURLString</key>
            <string>$FINAL_PATH</string>
            <key>_CFURLStringType</key>
            <integer>0</integer>
        </dict>
    </dict>
</dict>"

killall Dock || true

echo "Done. Roblox Player is now disguised as 'Self Service' and added to your Dock."
