#!/bin/bash
set -e

echo "🚀 Installing PeekLink macOS App..."

# Navigate to macos app directory
cd apps/macos

# Run the build script
./build.sh

# Register the app with macOS Launch Services so it appears in Default Browser list
APP_PATH=$(pwd)/PeekLink.app
echo "🔗 Registering $APP_PATH with macOS Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP_PATH"

echo "✅ macOS App Installation Complete!"
echo ""
echo "Next Steps:"
echo "1. Go to chrome://extensions in Chrome and turn on 'Developer mode'."
echo "2. Click 'Load unpacked' and select the 'extension/chrome' directory from this project."
echo "3. Copy the generated Extension ID."
echo "4. Open apps/macos/PeekLink.app"
echo "5. Click the PeekLink chain icon in your Mac menu bar -> Settings, and paste the Extension ID."
echo "6. Go to macOS System Settings -> Desktop & Dock -> Default web browser, and select PeekLink."
echo "🎉 You're all set!"
