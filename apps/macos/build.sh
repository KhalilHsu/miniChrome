#!/bin/bash
set -e

APP_NAME="PeekLink"
BUILD_DIR=".build/release"
APP_BUNDLE=".build/${APP_NAME}.app"
ASSET_DIR=".build/brand-assets"
XCODE_DEV_DIR="/Applications/Xcode.app/Contents/Developer"

if [ -d "${XCODE_DEV_DIR}" ]; then
    export DEVELOPER_DIR="${XCODE_DEV_DIR}"
fi

echo "Building Swift Package..."
swift build -c release

echo "Generating brand assets..."
swift scripts/make-brand-assets.swift

echo "Creating app icon..."
iconutil -c icns "${ASSET_DIR}/AppIcon.iconset" -o "${ASSET_DIR}/AppIcon.icns"
iconutil -c icns "${ASSET_DIR}/MenuBarIcon.iconset" -o "${ASSET_DIR}/MenuBarIcon.icns"

echo "Creating App Bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "Copying Executable..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
cp "${BUILD_DIR}/${APP_NAME}Host" "${APP_BUNDLE}/Contents/MacOS/"

echo "Copying Info.plist..."
cp Info.plist "${APP_BUNDLE}/Contents/"

echo "Copying brand assets..."
cp "${ASSET_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
cp "${ASSET_DIR}/MenuBarIcon.icns" "${APP_BUNDLE}/Contents/Resources/"

echo "Done! App created at ${APP_BUNDLE}"
