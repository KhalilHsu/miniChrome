#!/bin/bash
set -e

echo "🚀 Installing PeekLink macOS App..."

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
INSTALL_PATH="/Applications/PeekLink.app"
PROJECT_ROOT=$(pwd)
EXTENSION_PATH="$PROJECT_ROOT/extension/chrome"

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

echo "🧭 Saving local extension path for setup..."
defaults write com.peeklink.app extensionSourcePath "$EXTENSION_PATH"

echo "🧹 Removing build artifact from repo..."
rm -rf "$APP_PATH"

echo "▶️ Opening installed app..."
open "$INSTALL_PATH"

echo "✅ macOS App Installation Complete!"
echo ""
echo "Next Steps:"
echo "1. Finish setup in PeekLink -> Settings."
echo "2. Use the checklist there to load the Chrome extension, paste its ID, set the default browser, and test the bridge."
echo "🎉 You're all set!"
