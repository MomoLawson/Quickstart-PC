#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/dist/quickstart.sh"

mkdir -p "$SCRIPT_DIR/dist"

cat > "$OUTPUT" << 'HEADER'
#!/usr/bin/env bash
# Quickstart-PC - One-click computer setup
# Auto-generated single file version, do not edit manually
# Usage: curl -fsSL https://example.com/quickstart.sh | bash

set -e

if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi

# ===== Configuration =====
CONFIG_URL=""  # Remote config URL, leave empty for embedded config
# Example: CONFIG_URL="https://raw.githubusercontent.com/user/repo/main/config/profiles.yaml"

HEADER

# Embed language files
echo "# ===== Language: English (US) =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/languages/en-US.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "# ===== Language: Chinese (Simplified) =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/languages/zh-CN.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Embed language loader
echo "# ===== Language Loader =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/languages/loader.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Embed config
echo "# ===== Embedded Configuration =====" >> "$OUTPUT"
echo 'EMBEDDED_CONFIG=$(cat << '\''CONFIGEOF'\''
' >> "$OUTPUT"
cat "$SCRIPT_DIR/config/profiles.yaml" >> "$OUTPUT"
echo '
CONFIGEOF
)' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Embed log utilities
echo "# ===== Log Utilities =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/utils/log.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Embed system detection
echo "# ===== System Detection =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/scripts/detect.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Embed menu
echo "# ===== Menu =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/scripts/menu.sh" | grep -v '^#!/' | sed 's/source "$SCRIPT_DIR\/..\/utils\/log.sh"/# Uses embedded log functions/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Embed install logic
echo "# ===== Install Logic =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/scripts/install.sh" | grep -v '^#!/' | sed 's/source "$SCRIPT_DIR\/..\/utils\/log.sh"/# Uses embedded log functions/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Main function
cat >> "$OUTPUT" << 'MAIN'

# ===== Config Loading =====

load_config() {
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.yaml)
    
    if [[ -n "$CONFIG_URL" ]]; then
        log_info "$LANG_LOADING_REMOTE_CONFIG"
        
        if curl -fsSL --connect-timeout 5 --max-time 10 "$CONFIG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
            if grep -q "^profiles:" "$CONFIG_FILE" && grep -q "^software:" "$CONFIG_FILE"; then
                log_success "$LANG_REMOTE_CONFIG_SUCCESS"
                return 0
            else
                log_warn "$LANG_REMOTE_CONFIG_INVALID"
            fi
        else
            log_warn "$LANG_REMOTE_CONFIG_FAILED"
        fi
    fi
    
    log_info "$LANG_USING_EMBEDDED_CONFIG"
    echo "$EMBEDDED_CONFIG" > "$CONFIG_FILE"
    return 0
}

show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         ${BOLD}${LANG_BANNER_TITLE}${CYAN}             ║${NC}"
    echo -e "${CYAN}║    ${LANG_BANNER_DESC}              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# ===== Main Program =====

main() {
    # Detect and load language
    DETECTED_LANG=$(detect_language)
    load_language "$DETECTED_LANG"
    
    show_banner
    
    log_info "$LANG_DETECTING_SYSTEM"
    local os=$(detect_os)
    local system_info=$(get_system_info)
    local pkg_manager=$(check_package_manager "$os")
    
    log_info "$LANG_SYSTEM_INFO: $system_info"
    log_info "$LANG_PACKAGE_MANAGER: $pkg_manager"
    
    if [[ "$os" == "unknown" ]]; then
        log_error "$LANG_UNSUPPORTED_OS"
        exit 1
    fi
    
    if [[ "$pkg_manager" == "none" ]]; then
        log_warn "$LANG_NO_PACKAGE_MANAGER"
        echo ""
        read -p "$LANG_INSTALL_PACKAGE_MANAGER " install_mgr
        if [[ ! "$install_mgr" =~ ^[Nn] ]]; then
            if install_package_manager "$os" "scoop"; then
                pkg_manager=$(check_package_manager "$os")
                log_info "$LANG_PACKAGE_MANAGER_UPDATED: $pkg_manager"
            else
                log_error "$LANG_PACKAGE_MANAGER_FAILED"
            fi
        fi
    fi
    
    load_config
    
    local selected_profiles=()
    show_menu "$CONFIG_FILE" selected_profiles
    
    if [[ ${#selected_profiles[@]} -eq 0 ]]; then
        log_warn "$LANG_NO_PROFILE_SELECTED"
        exit 0
    fi
    
    log_info "$LANG_SELECTED_PROFILES: ${selected_profiles[*]}"
    
    echo ""
    read -p "$LANG_CONFIRM_INSTALL " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        log_info "$LANG_CANCELLED"
        exit 0
    fi
    
    local software_list=($(resolve_software_list "$os" "${selected_profiles[@]}"))
    
    if [[ ${#software_list[@]} -eq 0 ]]; then
        log_warn "$LANG_NO_SOFTWARE_TO_INSTALL"
        exit 0
    fi
    
    log_header "$LANG_START_INSTALLING"
    
    local total=${#software_list[@]}
    local current=0
    
    for sw in "${software_list[@]}"; do
        ((current++))
        log_progress $current $total "$LANG_INSTALLING $sw"
        install_software "$os" "$sw"
    done
    
    log_header "$LANG_INSTALLATION_COMPLETE"
    log_success "$LANG_TOTAL_INSTALLED $total"
}

trap 'rm -f "$CONFIG_FILE" 2>/dev/null' EXIT

SCRIPT_DIR="/tmp/quickstart"

main "$@"
MAIN

chmod +x "$OUTPUT"

echo "✅ Build complete: $OUTPUT"
echo "📄 Size: $(wc -c < "$OUTPUT") bytes"
echo "📋 Lines: $(wc -l < "$OUTPUT")"
