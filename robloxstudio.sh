#!/bin/bash
set -e

# Get latest Roblox Studio version
ROBLOX_VERSION=$(
    curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacStudio/channel/LIVE" |
    python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "Failed to fetch Roblox version"
    exit 1
fi

echo "Roblox Studio version: $ROBLOX_VERSION"

# Detect Mac architecture
ARCH="arm64"
if [ "$(uname -m)" = "x86_64" ]; then
    ARCH="x86-64"
fi

# Download official DMG
DOWNLOAD_URL="https://setup-aws.rbxcdn.com/mac/${ARCH}/${ROBLOX_VERSION}-RobloxStudio.dmg"

echo "Downloading Roblox Studio..."
curl -L --fail --show-error "$DOWNLOAD_URL" -o /tmp/RobloxStudio.dmg

# Verify download
FILE_TYPE=$(file /tmp/RobloxStudio.dmg)
echo "Downloaded file type: $FILE_TYPE"

if echo "$FILE_TYPE" | grep -qi "HTML"; then
    echo "ERROR: Download returned an HTML error page."
    exit 1
fi

# Mount DMG
echo "Mounting Roblox Studio..."
MOUNT_OUTPUT=$(hdiutil attach /tmp/RobloxStudio.dmg)

echo "$MOUNT_OUTPUT"

# Find mounted Roblox volume
VOLUME=$(echo "$MOUNT_OUTPUT" | grep '/Volumes/' | sed 's/.*\t//')

if [ -z "$VOLUME" ]; then
    echo "Could not find mounted Roblox volume"
    exit 1
fi

echo "Mounted at: $VOLUME"

# Open the official installer
open "$VOLUME/RobloxStudioInstaller.app"

echo "Roblox Studio installer opened."
