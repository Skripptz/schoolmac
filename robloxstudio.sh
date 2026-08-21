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
# PATCH SECTION (SAFE)
# =========================

codesign --remove-signature "$APP" 2>/dev/null || true

PLIST="$APP/Contents/Info.plist"

# Change only the app's name and identifier
/usr/libexec/PlistBuddy -c "Set :CFBundleName Self Service" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Self Service" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.jamfsoftware.selfservice.mac" "$PLIST"

# DO NOT rename the executable
# Studio requires 'RobloxStudio' to remain intact

# Remove quarantine flags
xattr -cr "$APP"

# Ad-hoc sign everything inside the bundle
find "$APP" -type f -perm +111 -exec codesign --force --sign - {} \; 2>/dev/null

# Sign the bundle itself
codesign --force --sign - "$APP"
