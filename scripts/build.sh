#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="EasyConnect 保活"
EXECUTABLE_NAME="EasyConnectKeepAlive"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SWIFTC="$(xcrun --find swiftc)"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
ICON_MASTER="$PROJECT_DIR/Resources/AppIcon-1024.png"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICON_FILE="$BUILD_DIR/AppIcon.icns"
ARM64_BINARY="$BUILD_DIR/$EXECUTABLE_NAME-arm64"
X86_64_BINARY="$BUILD_DIR/$EXECUTABLE_NAME-x86_64"

SOURCE_FILES=(
    "$PROJECT_DIR/Sources/Models.swift"
    "$PROJECT_DIR/Sources/ProbeEngine.swift"
    "$PROJECT_DIR/Sources/KeepAliveController.swift"
    "$PROJECT_DIR/Sources/ContentView.swift"
    "$PROJECT_DIR/Sources/EasyConnectKeepAliveApp.swift"
)

if [ "$APP_BUNDLE" != "$PROJECT_DIR/build/$APP_NAME.app" ]; then
    echo "Unexpected build path: $APP_BUNDLE" >&2
    exit 1
fi

rm -rf "$APP_BUNDLE"
rm -rf "$ICONSET_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$ICONSET_DIR"

xcrun swift \
    -framework AppKit \
    "$PROJECT_DIR/scripts/render_icon.swift" \
    "$ICON_MASTER"

sips -z 16 16 "$ICON_MASTER" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_MASTER" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_MASTER" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_MASTER" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_MASTER" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_MASTER" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_MASTER" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_MASTER" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_MASTER" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_MASTER" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"

"$SWIFTC" \
    -swift-version 5 \
    -parse-as-library \
    -O \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx14.0 \
    -framework SwiftUI \
    -framework AppKit \
    "${SOURCE_FILES[@]}" \
    -o "$ARM64_BINARY"

"$SWIFTC" \
    -swift-version 5 \
    -parse-as-library \
    -O \
    -sdk "$SDK_PATH" \
    -target x86_64-apple-macosx14.0 \
    -framework SwiftUI \
    -framework AppKit \
    "${SOURCE_FILES[@]}" \
    -o "$X86_64_BINARY"

lipo -create \
    "$ARM64_BINARY" \
    "$X86_64_BINARY" \
    -output "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

rm -f "$ARM64_BINARY" "$X86_64_BINARY"

cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ICON_FILE" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
codesign --force --sign - --timestamp=none "$APP_BUNDLE"

echo "$APP_BUNDLE"
