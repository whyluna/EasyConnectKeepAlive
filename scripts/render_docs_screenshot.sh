#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_PNG="${1:-$PROJECT_DIR/docs/app-screenshot.png}"
RENDERER="$BUILD_DIR/DocumentationScreenshotRenderer"
SWIFTC="$(xcrun --find swiftc)"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
HOST_ARCH="$(uname -m)"

mkdir -p "$BUILD_DIR" "$(dirname "$OUTPUT_PNG")"

"$SWIFTC" \
    -swift-version 5 \
    -parse-as-library \
    -D DOCS_SCREENSHOT \
    -O \
    -sdk "$SDK_PATH" \
    -target "$HOST_ARCH-apple-macosx14.0" \
    -framework SwiftUI \
    -framework AppKit \
    "$PROJECT_DIR/Sources/Models.swift" \
    "$PROJECT_DIR/Sources/ProbeEngine.swift" \
    "$PROJECT_DIR/Sources/KeepAliveController.swift" \
    "$PROJECT_DIR/Sources/ContentView.swift" \
    "$PROJECT_DIR/scripts/render_docs_screenshot.swift" \
    -o "$RENDERER"

"$RENDERER" "$OUTPUT_PNG" "$PROJECT_DIR/Resources/AppIcon-1024.png"
