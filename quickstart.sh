#!/usr/bin/env bash

if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi

# ===== 配置 =====
CONFIG_URL=""  # 云端配置链接，留空则使用本地配置
# 示例: CONFIG_URL="https://raw.githubusercontent.com/user/repo/main/config/profiles.yaml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
UTILS_DIR="$SCRIPT_DIR/utils"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

source "$UTILS_DIR/log.sh"
source "$SCRIPTS_DIR/detect.sh"
source "$SCRIPTS_DIR/menu.sh"
source "$SCRIPTS_DIR/install.sh"

load_config() {
    local config_file="$CONFIG_DIR/profiles.yaml"
    
    # 如果指定了云端配置链接，优先从云端获取
    if [[ -n "$CONFIG_URL" ]]; then
        log_info "正在从云端获取配置..." >&2
        local tmp_config=$(mktemp /tmp/quickstart-config-XXXXXX.yaml)
        
        if curl -fsSL --connect-timeout 5 --max-time 10 "$CONFIG_URL" -o "$tmp_config" 2>/dev/null; then
            # 验证文件是否是有效的 YAML（简单检查）
            if grep -q "^profiles:" "$tmp_config" && grep -q "^software:" "$tmp_config"; then
                log_success "云端配置加载成功" >&2
                echo "$tmp_config"
                return 0
            else
                log_warn "云端配置格式无效，使用本地配置" >&2
                rm -f "$tmp_config"
            fi
        else
            log_warn "云端配置获取失败，使用本地配置" >&2
            rm -f "$tmp_config"
        fi
    fi
    
    # 使用本地配置
    if [[ -f "$config_file" ]]; then
        log_info "使用本地配置: $config_file" >&2
        echo "$config_file"
        return 0
    else
        log_error "配置文件不存在: $config_file" >&2
        return 1
    fi
}

main() {
    show_banner
    
    log_info "检测系统环境..."
    local os=$(detect_os)
    local system_info=$(get_system_info)
    local pkg_manager=$(check_package_manager "$os")
    
    log_info "系统: $system_info"
    log_info "包管理器: $pkg_manager"
    
    if [[ "$os" == "unknown" ]]; then
        log_error "不支持的操作系统"
        exit 1
    fi
    
    if [[ "$pkg_manager" == "none" ]]; then
        log_warn "未检测到包管理器"
        echo ""
        read -p "是否自动安装包管理器？[Y/n]: " install_mgr
        if [[ ! "$install_mgr" =~ ^[Nn] ]]; then
            if install_package_manager "$os" "scoop"; then
                pkg_manager=$(check_package_manager "$os")
                log_info "包管理器已更新为: $pkg_manager"
            else
                log_error "包管理器安装失败，部分软件可能无法自动安装"
            fi
        fi
    fi
    
    # 加载配置（云端或本地）
    local config_file=$(load_config)
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    # 如果是临时文件，退出时清理
    if [[ "$config_file" == /tmp/quickstart-config-* ]]; then
        trap 'rm -f "$config_file"' EXIT
    fi
    
    local selected_profiles=()
    show_menu "$config_file" selected_profiles
    
    if [[ ${#selected_profiles[@]} -eq 0 ]]; then
        log_warn "未选择任何套餐"
        exit 0
    fi
    
    log_info "选择的套餐: ${selected_profiles[*]}"
    
    echo ""
    read -p "确认安装？[Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        log_info "已取消"
        exit 0
    fi
    
    local software_list=($(resolve_software_list "$os" "${selected_profiles[@]}"))
    
    if [[ ${#software_list[@]} -eq 0 ]]; then
        log_warn "没有软件需要安装"
        exit 0
    fi
    
    log_header "开始安装软件"
    
    local total=${#software_list[@]}
    local current=0
    
    for sw in "${software_list[@]}"; do
        ((current++))
        log_progress $current $total "安装 $sw"
        install_software "$os" "$sw"
    done
    
    log_header "安装完成"
    log_success "共安装 $total 个软件"
}

main "$@"
