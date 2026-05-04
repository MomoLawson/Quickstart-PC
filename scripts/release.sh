#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
VERSION_FILE="$PROJECT_DIR/VERSION"
BUILD_SCRIPT="$PROJECT_DIR/scripts/build.sh"

show_usage() {
    cat <<EOF
Usage: $(basename "$0") <build|beta>

Release automation script for Quickstart-PC (v1.0.0-beta phase).

Arguments:
    build   Increment build number (Y) and release
    beta    Increment beta version (X), reset build to 1, and release

Version format: v1.0.0-betaX-buildY
    X = beta version (only increment when explicitly requested)
    Y = build count (increment with each build)

Examples:
    $(basename "$0") build   # 1.0.0-beta1-build1 → 1.0.0-beta1-build2
    $(basename "$0") beta    # 1.0.0-beta1-build5 → 1.0.0-beta2-build1
EOF
}

parse_version() {
    local version="$1"
    local beta build
    
    if [[ "$version" =~ ^1\.0\.0-beta([0-9]+)-build([0-9]+)$ ]]; then
        beta="${BASH_REMATCH[1]}"
        build="${BASH_REMATCH[2]}"
        echo "$beta $build"
    else
        echo "[ERROR] Invalid version format: $version (expected 1.0.0-betaX-buildY)"
        exit 1
    fi
}

bump_version() {
    local version="$1"
    local type="$2"
    
    local beta build
    read -r beta build <<< "$(parse_version "$version")"
    
    case "$type" in
        build)
            build=$((build + 1))
            ;;
        beta)
            beta=$((beta + 1))
            build=1
            ;;
    esac
    
    echo "1.0.0-beta${beta}-build${build}"
}

main() {
    local release_type="$1"
    
    if [[ -z "$release_type" ]] || [[ ! "$release_type" =~ ^(build|beta)$ ]]; then
        show_usage
        exit 1
    fi
    
    # Read current version
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "[ERROR] VERSION file not found: $VERSION_FILE"
        exit 1
    fi
    
    local old_version
    old_version=$(cat "$VERSION_FILE" | tr -d '[:space:]')
    echo "[INFO] Current version: $old_version"
    parse_version "$old_version" > /dev/null
    
    # Bump version
    local new_version
    new_version=$(bump_version "$old_version" "$release_type")
    echo "[→] Bumping version to $new_version..."
    
    # Write new version to VERSION file
    echo -n "$new_version" > "$VERSION_FILE"
    echo "[✓] Version updated: $new_version"
    
    # Run build
    echo "[→] Running build..."
    if ! bash "$BUILD_SCRIPT"; then
        echo "[ERROR] Build failed, rolling back..."
        echo -n "$old_version" > "$VERSION_FILE"
        exit 1
    fi
    echo "[✓] Build successful"
    
    # Git commit
    echo "[→] Committing changes..."
    git add -A
    git commit -m "release: v$new_version"
    echo "[✓] Committed: v$new_version"
    
    # Git tag
    echo "[→] Creating tag..."
    git tag "v$new_version"
    echo "[✓] Tagged: v$new_version"
    
    # Git push
    echo "[→] Pushing to remote..."
    if ! git push origin main --tags; then
        echo "[ERROR] Push failed, rolling back..."
        git tag -d "v$new_version"
        git reset --soft HEAD~1
        echo -n "$old_version" > "$VERSION_FILE"
        echo "[✓] Rolled back"
        exit 1
    fi
    echo "[✓] Pushed to remote"
    
    # Create GitHub release (pre-release)
    echo "[→] Creating GitHub release (pre-release)..."
    local notes="See commit history for changes."
    if [[ -f "$PROJECT_DIR/changelog.md" ]]; then
        notes=$(cat "$PROJECT_DIR/changelog.md")
    fi
    
    # Generate SHA256 checksum for profiles.json
    echo "[→] Generating SHA256 checksum for profiles.json..."
    local profiles_json="$PROJECT_DIR/config/profiles.json"
    if [[ -f "$profiles_json" ]]; then
        shasum -a 256 "$profiles_json" | awk '{print $1}' > "$PROJECT_DIR/dist/profiles.json.sha256"
        echo "[✓] SHA256 checksum generated"
    else
        echo "[!] profiles.json not found, skipping checksum"
    fi
    
    gh release create "v$new_version" \
        --title "v$new_version" \
        --notes "$notes" \
        --prerelease \
        "$PROJECT_DIR/dist/quickstart.sh" \
        "$PROJECT_DIR/dist/quickstart.ps1" \
        "$PROJECT_DIR/dist/profiles.json.sha256"
    echo "[✓] GitHub release created: v$new_version (pre-release)"
    
    # Clear changelog after release
    if [[ -f "$PROJECT_DIR/changelog.md" ]]; then
        echo -n "" > "$PROJECT_DIR/changelog.md"
        echo "[✓] Changelog cleared for next release"
    fi
}

main "$@"
