#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

echo "🚀 Installing PeekLink macOS App..."

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
INSTALL_PATH="/Applications/PeekLink.app"
EXTENSION_PATH="$PROJECT_ROOT/extension/chrome"
EXTENSION_INSTALL_PATH="$HOME/Library/Application Support/PeekLink/ChromeExtension"

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
mkdir -p "$(dirname "$EXTENSION_INSTALL_PATH")"
rm -rf "$EXTENSION_INSTALL_PATH"
cp -R "$EXTENSION_PATH" "$EXTENSION_INSTALL_PATH"
defaults write com.peeklink.app extensionSourcePath "$EXTENSION_INSTALL_PATH"

echo "🧹 Removing build artifact from repo..."
rm -rf "$APP_PATH"

echo "▶️ Opening installed app..."
open "$INSTALL_PATH"

echo "✅ macOS App Installation Complete!"
echo ""
echo "Next Steps:"
echo "1. Finish setup in PeekLink -> Settings."
echo "2. Use the checklist there to load the Chrome extension from:"
echo "   $EXTENSION_INSTALL_PATH"
echo "3. Paste its ID, set the default browser, and test the bridge."
echo "🎉 You're all set!"
