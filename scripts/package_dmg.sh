#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
APP_BUNDLE="${1:-$BUILD_DIR/EasyConnect 保活.app}"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found: $APP_BUNDLE" >&2
    echo "Run ./scripts/build.sh first." >&2
    exit 1
fi

VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_BUNDLE/Contents/Info.plist")"
OUTPUT_DMG="${2:-$DIST_DIR/EasyConnect-KeepAlive-v$VERSION-macOS-universal.dmg}"
STAGING_DIR="$(mktemp -d "$BUILD_DIR/dmg-staging.XXXXXX")"

mkdir -p "$DIST_DIR"
ditto "$APP_BUNDLE" "$STAGING_DIR/EasyConnect 保活.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "EasyConnect 保活" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$OUTPUT_DMG"

echo "$OUTPUT_DMG"
