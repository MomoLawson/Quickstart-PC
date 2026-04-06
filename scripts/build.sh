#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$PROJECT_DIR/src"
DIST_DIR="$PROJECT_DIR/dist"
CONFIG_DIR="$PROJECT_DIR/config"
VERSION_FILE="$PROJECT_DIR/VERSION"

if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    VERSION="0.0.0"
fi

mkdir -p "$DIST_DIR"

# Merge config/software/*.json into config/profiles.json for distribution
if [[ -d "$CONFIG_DIR/software" ]]; then
    echo "[→] Merging software config files..."
    python3 -c "
import json, os, glob

with open('$CONFIG_DIR/profiles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

data['software'] = {}
for f in sorted(glob.glob('$CONFIG_DIR/software/*.json')):
    with open(f, 'r', encoding='utf-8') as sf:
        cat_data = json.load(sf)
        data['software'].update(cat_data)

with open('$CONFIG_DIR/profiles.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f'✓ Merged {len(data[\"software\"])} software entries into profiles.json')
"
fi

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

# Copy language files to dist/lang/
LANG_SRC="$SRC_DIR/lang"
LANG_DIST="$DIST_DIR/lang"
if [[ -d "$LANG_SRC" ]]; then
    mkdir -p "$LANG_DIST"
    for lang_file in "$LANG_SRC"/*.sh "$LANG_SRC"/*.json; do
        if [[ -f "$lang_file" ]]; then
            cp "$lang_file" "$LANG_DIST/"
            echo "[✓] Lang: $(basename "$lang_file")"
        fi
    done
fi
