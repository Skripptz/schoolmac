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

echo "Roblox Studio version hash: $STUDIO_VERSION"

# --- CLEAN ---
rm -rf RobloxStudio.app RobloxStudioExtract /tmp/robloxstudio.zip

# --- ARCH DETECTION ---
ARCH="arm64"
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x86-64"
fi

echo "Detected architecture: $ARCH"

# --- BUILD DOWNLOAD URL ---
DOWNLOAD_URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${STUDIO_VERSION}-RobloxStudio.zip"
echo "Downloading from: $DOWNLOAD_URL"

curl -L --fail --show-error "$DOWNLOAD_URL" -o /tmp/robloxstudio.zip

# --- VALIDATE ZIP ---
FILE_TYPE=$(file /tmp/robloxstudio.zip)

if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP (got HTML instead)"
    exit 1
fi

echo "ZIP validated."

# --- EXTRACT ---
rm -rf RobloxStudioExtract
mkdir -p RobloxStudioExtract
unzip -q /tmp/robloxstudio.zip -d RobloxStudioExtract

APP=$(find RobloxStudioExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Could not find Roblox Studio app in extracted files"
    exit 1
fi

echo "Found app: $APP"

# =========================
# PATCH SECTION (SAFE)
# =========================

# Do NOT modify anything inside the bundle.
# Studio will break if signatures or plist entries change.

# Remove quarantine flags (safe)
xattr -cr "$APP" || true

# --- INSTALL ---
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME="Self Service.app"
FINAL_APP_PATH="$INSTALL_DIR/$APP_NAME"

rm -rf "$FINAL_APP_PATH"
mv "$APP" "$FINAL_APP_PATH"

echo "Installed to: $FINAL_APP_PATH"

# --- ADD TO DOCK ---
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

killall Dock || true

echo "Done. 'Self Service' (Roblox Studio) should now be in your Dock. Open it from there."
