#!/usr/bin/env bash

if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi

# ===== 配置 =====
CONFIG_URL=""  # 云端配置链接，留空则使用本地配置
# 示例: CONFIG_URL="https://raw.githubusercontent.com/user/repo/main/config/profiles.yaml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
UTILS_DIR="$SCRIPT_DIR/utils"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
LANG_DIR="$SCRIPT_DIR/languages"

source "$UTILS_DIR/log.sh"
source "$SCRIPTS_DIR/detect.sh"
source "$SCRIPTS_DIR/menu.sh"
source "$SCRIPTS_DIR/install.sh"

# 加载语言配置
source "$LANG_DIR/loader.sh"
DETECTED_LANG=$(detect_language)
load_language "$DETECTED_LANG"

load_config() {
    local config_file="$CONFIG_DIR/profiles.yaml"
    
    if [[ -n "$CONFIG_URL" ]]; then
        log_info "$LANG_LOADING_REMOTE_CONFIG" >&2
        local tmp_config=$(mktemp /tmp/quickstart-config-XXXXXX.yaml)
        
        if curl -fsSL --connect-timeout 5 --max-time 10 "$CONFIG_URL" -o "$tmp_config" 2>/dev/null; then
            if grep -q "^profiles:" "$tmp_config" && grep -q "^software:" "$tmp_config"; then
                log_success "$LANG_REMOTE_CONFIG_SUCCESS" >&2
                echo "$tmp_config"
                return 0
            else
                log_warn "$LANG_REMOTE_CONFIG_INVALID" >&2
                rm -f "$tmp_config"
            fi
        else
            log_warn "$LANG_REMOTE_CONFIG_FAILED" >&2
            rm -f "$tmp_config"
        fi
    fi
    
    if [[ -f "$config_file" ]]; then
        log_info "$LANG_USING_LOCAL_CONFIG: $config_file" >&2
        echo "$config_file"
        return 0
    else
        log_error "$LANG_CONFIG_NOT_FOUND: $config_file" >&2
        return 1
    fi
}

show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         ${BOLD}${LANG_BANNER_TITLE}${CYAN}             ║${NC}"
    echo -e "${CYAN}║    ${LANG_BANNER_DESC}              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

main() {
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
    
    local config_file=$(load_config)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    if [[ "$config_file" == /tmp/quickstart-config-* ]]; then
        trap 'rm -f "$config_file"' EXIT
    fi
    
    local selected_profiles=()
    show_menu "$config_file" selected_profiles
    
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

main "$@"
