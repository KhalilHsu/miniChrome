#!/bin/bash
set -e

echo "🚀 Installing PeekLink macOS App..."

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
INSTALL_PATH="/Applications/PeekLink.app"

# Navigate to macos app directory
cd apps/macos

# Run the build script
./build.sh

APP_PATH=$(pwd)/.build/PeekLink.app

echo "🛑 Closing any running PeekLink instances..."
pkill -x PeekLink || true

echo "🧹 Replacing any existing copy in /Applications..."
rm -rf "$INSTALL_PATH"
cp -R "$APP_PATH" /Applications/

echo "🔗 Registering installed app with macOS Launch Services..."
"$LSREGISTER" -u "$APP_PATH" || true
"$LSREGISTER" -f "$INSTALL_PATH"

echo "🧹 Removing build artifact from repo..."
rm -rf "$APP_PATH"

echo "▶️ Opening installed app..."
open "$INSTALL_PATH"

echo "✅ macOS App Installation Complete!"
echo ""
echo "Next Steps:"
echo "1. Go to chrome://extensions in Chrome and turn on 'Developer mode'."
echo "2. Load or reload the unpacked 'extension/chrome' directory from this project."
echo "3. Copy the generated Extension ID."
echo "4. Open /Applications/PeekLink.app."
echo "5. In the PeekLink menu bar app -> Settings, paste the Extension ID so the native bridge manifest is written."
echo "6. Go to macOS System Settings -> Desktop & Dock -> Default web browser, and select PeekLink."
echo "🎉 You're all set!"
