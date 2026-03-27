#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/dist/quickstart.sh"

mkdir -p "$SCRIPT_DIR/dist"

cat > "$OUTPUT" << 'HEADER'
#!/usr/bin/env bash
# Quickstart-PC - 一键配置新电脑
# 自动生成的单文件版本，请勿手动修改
# 用法: curl -fsSL https://example.com/quickstart.sh | bash

set -e

if [ -z "$BASH_VERSION" ]; then exec bash "$0" "$@"; fi

# ===== 配置 =====
CONFIG_URL=""  # 云端配置链接，留空则使用内嵌配置
# 示例: CONFIG_URL="https://raw.githubusercontent.com/user/repo/main/config/profiles.yaml"

HEADER

# 嵌入配置文件
echo "# ===== 内嵌配置数据 =====" >> "$OUTPUT"
echo 'EMBEDDED_CONFIG=$(cat << '\''CONFIGEOF'\'' 
' >> "$OUTPUT"
cat "$SCRIPT_DIR/config/profiles.yaml" >> "$OUTPUT"
echo '
CONFIGEOF
)' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# 嵌入工具函数
echo "# ===== 工具函数 =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/utils/log.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# 嵌入系统检测
echo "# ===== 系统检测 =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/scripts/detect.sh" | grep -v '^#!/' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# 嵌入菜单
echo "# ===== 交互菜单 =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/scripts/menu.sh" | grep -v '^#!/' | sed 's/source "$SCRIPT_DIR\/..\/utils\/log.sh"/# 使用内嵌的 log 函数/' | sed 's|"\$SCRIPT_DIR/../config/profiles.yaml"|"\$CONFIG_FILE"|g' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# 嵌入安装逻辑
echo "# ===== 安装逻辑 =====" >> "$OUTPUT"
cat "$SCRIPT_DIR/scripts/install.sh" | grep -v '^#!/' | sed 's/source "$SCRIPT_DIR\/..\/utils\/log.sh"/# 使用内嵌的 log 函数/' | sed 's|"\$SCRIPT_DIR/../config/profiles.yaml"|"\$CONFIG_FILE"|g' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# 主函数
cat >> "$OUTPUT" << 'MAIN'

# ===== 配置加载 =====

load_config() {
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.yaml)
    
    # 如果指定了云端配置链接，优先从云端获取
    if [[ -n "$CONFIG_URL" ]]; then
        log_info "正在从云端获取配置..."
        
        if curl -fsSL --connect-timeout 5 --max-time 10 "$CONFIG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
            # 验证文件是否是有效的 YAML（简单检查）
            if grep -q "^profiles:" "$CONFIG_FILE" && grep -q "^software:" "$CONFIG_FILE"; then
                log_success "云端配置加载成功"
                return 0
            else
                log_warn "云端配置格式无效，使用内嵌配置"
            fi
        else
            log_warn "云端配置获取失败，使用内嵌配置"
        fi
    fi
    
    # 使用内嵌配置
    log_info "使用内嵌配置"
    echo "$EMBEDDED_CONFIG" > "$CONFIG_FILE"
    return 0
}

# ===== 主程序 =====

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
    
    # 加载配置（云端或内嵌）
    load_config
    
    local selected_profiles=()
    show_menu "$CONFIG_FILE" selected_profiles
    
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

# 捕获退出时清理
trap 'rm -f "$CONFIG_FILE" 2>/dev/null' EXIT

# 修复路径问题
SCRIPT_DIR="/tmp/quickstart"

main "$@"
MAIN

chmod +x "$OUTPUT"

echo "✅ 构建完成: $OUTPUT"
echo "📄 文件大小: $(wc -c < "$OUTPUT") bytes"
echo "📋 行数: $(wc -l < "$OUTPUT") 行"
