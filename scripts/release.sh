#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
VERSION_FILE="$PROJECT_DIR/VERSION"
BUILD_SCRIPT="$PROJECT_DIR/scripts/build.sh"

show_usage() {
    cat <<EOF
Usage: $(basename "$0") <major|minor|patch>

Release automation script for Quickstart-PC.

Arguments:
  major  Bump major version (X.0.0)
  minor  Bump minor version (0.X.0)
  patch  Bump patch version (0.0.X)

Examples:
  $(basename "$0") patch  # 0.82.1 → 0.82.2
  $(basename "$0") minor  # 0.82.1 → 0.83.0
  $(basename "$0") major  # 0.82.1 → 1.0.0
EOF
}

bump_version() {
    local version="$1"
    local type="$2"
    
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    
    case "$type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[ERROR] Invalid version format: $version"
        exit 1
    fi
}

main() {
    local release_type="$1"
    
    if [[ -z "$release_type" ]] || [[ ! "$release_type" =~ ^(major|minor|patch)$ ]]; then
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
    validate_version "$old_version"
    
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
    
    # Git push (no hardcoded proxy)
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
    
    # Create GitHub release
    echo "[→] Creating GitHub release..."
    gh release create "v$new_version" \
        --title "v$new_version" \
        --notes "See commit history for changes." \
        "$PROJECT_DIR/dist/quickstart.sh" \
        "$PROJECT_DIR/dist/quickstart.ps1"
    echo "[✓] GitHub release created: v$new_version"
}

main "$@"
