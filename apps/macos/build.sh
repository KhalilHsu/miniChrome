#!/bin/bash
set -e

APP_NAME="PeekLink"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "Building Swift Package..."
swift build -c release

echo "Creating App Bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "Copying Executable..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

echo "Copying Info.plist..."
cp Info.plist "${APP_BUNDLE}/Contents/"

echo "Done! App created at apps/macos/${APP_BUNDLE}"
