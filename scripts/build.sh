#!/usr/bin/env bash
set -e

# Build script for Quickstart-PC
# Generates dist/quickstart.sh from src/quickstart.sh

SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
DIST_DIR="$(cd "$(dirname "$0")/../dist" && pwd)"
SRC_FILE="$SRC_DIR/quickstart.sh"
DIST_FILE="$DIST_DIR/quickstart.sh"

mkdir -p "$DIST_DIR"

if [[ ! -f "$SRC_FILE" ]]; then
    echo "[ERROR] Source file not found: $SRC_FILE"
    exit 1
fi

# Copy source to dist
cp "$SRC_FILE" "$DIST_FILE"

# Make executable
chmod +x "$DIST_FILE"

echo "[✓] Built: $DIST_FILE"
echo "    Source: $SRC_FILE"
echo "    Size: $(wc -c < "$DIST_FILE") bytes"
