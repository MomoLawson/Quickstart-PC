#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJECT_DIR/src"
DIST_DIR="$PROJECT_DIR/dist"
VERSION_FILE="$PROJECT_DIR/VERSION"

if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    VERSION="0.0.0"
fi

mkdir -p "$DIST_DIR"

SRC_FILE="$SRC_DIR/quickstart.sh"
DIST_FILE="$DIST_DIR/quickstart.sh"
if [[ -f "$SRC_FILE" ]]; then
    sed "s/__VERSION__/$VERSION/g" "$SRC_FILE" > "$DIST_FILE"
    chmod +x "$DIST_FILE"
    echo "[✓] Built: $DIST_FILE ($VERSION)"
    echo "    Size: $(wc -c < "$DIST_FILE") bytes"
fi

SRC_FILE="$SRC_DIR/quickstart.ps1"
DIST_FILE="$DIST_DIR/quickstart.ps1"
if [[ -f "$SRC_FILE" ]]; then
    sed "s/__VERSION__/$VERSION/g" "$SRC_FILE" > "$DIST_FILE"
    echo "[✓] Built: $DIST_FILE ($VERSION)"
    echo "    Size: $(wc -c < "$DIST_FILE") bytes"
fi
