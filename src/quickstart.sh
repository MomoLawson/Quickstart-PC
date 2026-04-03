#!/usr/bin/env bash

# 只在交互式终端中清屏和隐藏光标
if [[ -t 1 ]]; then
    clear 2>/dev/null || true
    tput civis 2>/dev/null || true
fi

# 默认配置 URL（优先级最高）
DEFAULT_CFG_URL="https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json"

LANG_FOR_HELP="en"
args=("$@")
for i in "${!args[@]}"; do
    if [[ "${args[$i]}" == "--lang" ]] && [[ -n "${args[$((i+1))]}" ]]; then
        LANG_FOR_HELP="${args[$((i+1))]}"
        break
    fi
done

show_help() {
    if [[ "$LANG_FOR_HELP" == "zh" || "$LANG_FOR_HELP" == "zh-CN" ]]; then
        cat << 'HELPZH'
Quickstart-PC - 一键配置新电脑

用法: quickstart.sh [选项]

选项:
  --lang LANG        设置语言 (en, zh)
  --cfg-path PATH    使用本地 profiles.json 文件
  --cfg-url URL      使用远程 profiles.json URL
  --dev              开发模式：显示选择的软件但不安装
  --dry-run          假装安装：展示安装过程但不实际安装
  --fake-install     同 --dry-run（已弃用）
  --yes, -y          自动确认所有提示
  --verbose, -v      显示详细调试信息
  --log-file FILE    将日志写入文件
  --list-profiles    列出所有可用套餐
  --show-profile KEY 显示指定套餐详情
  --skip SW          跳过指定软件（可多次使用）
  --only SW          只安装指定软件（可多次使用）
  --fail-fast        遇到错误时立即停止
  --profile NAME     直接指定安装套餐（跳过选择菜单）
  --non-interactive  非交互模式（禁止所有 TUI/prompt）
  --help             显示此帮助信息
HELPZH
    else
        cat << 'HELPEN'
Quickstart-PC - One-click computer setup

Usage: quickstart.sh [OPTIONS]

Options:
  --lang LANG        Set language (en, zh)
  --cfg-path PATH    Use local profiles.json file
  --cfg-url URL      Use remote profiles.json URL
  --dev              Dev mode
  --dry-run          Fake install: show process without installing
  --fake-install     Alias for --dry-run (deprecated)
  --yes, -y          Auto-confirm all prompts
  --verbose, -v      Show detailed debug info
  --log-file FILE    Write logs to file
  --list-profiles    List all available profiles
  --show-profile KEY Show profile details
  --skip SW          Skip specified software (repeatable)
  --only SW          Only install specified software (repeatable)
  --fail-fast        Stop on first error
  --profile NAME     Select profile directly (skip menu)
  --non-interactive  Non-interactive mode (no TUI/prompts)
  --help             Show this help message
HELPEN
    fi
    exit 0
}

DEV_MODE=false
FAKE_INSTALL=false
AUTO_YES=false
VERBOSE=false
LOG_FILE=""
LIST_PROFILES=false
SHOW_PROFILE=""
SKIP_SW=()
ONLY_SW=()
FAIL_FAST=false
PROFILE_KEY=""
NON_INTERACTIVE=false
LANG_OVERRIDE=""
CFG_PATH=""
CFG_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev) DEV_MODE=true; shift ;;
        --dry-run) FAKE_INSTALL=true; shift ;;
        --fake-install) FAKE_INSTALL=true; echo "[!] --fake-install is deprecated, use --dry-run instead" >&2; shift ;;
        --yes|-y) AUTO_YES=true; shift ;;
        --verbose|-v) VERBOSE=true; shift ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        --list-profiles) LIST_PROFILES=true; shift ;;
        --show-profile) SHOW_PROFILE="$2"; shift 2 ;;
        --skip) SKIP_SW+=("$2"); shift 2 ;;
        --only) ONLY_SW+=("$2"); shift 2 ;;
        --fail-fast) FAIL_FAST=true; shift ;;
        --profile) PROFILE_KEY="$2"; shift 2 ;;
        --non-interactive) NON_INTERACTIVE=true; shift ;;
        --lang) LANG_OVERRIDE="$2"; shift 2 ;;
        --cfg-path) CFG_PATH="$2"; shift 2 ;;
        --cfg-url) CFG_URL="$2"; shift 2 ;;
        --help|-h) show_help ;;
        *) shift ;;
    esac
done

# --list-profiles 在语言选择之前处理，默认英文输出
if [[ "$LIST_PROFILES" == "true" ]]; then
    # 检测 jq
    if ! command -v jq &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install jq 2>/dev/null
        else
            sudo apt install -y jq 2>/dev/null
        fi
    fi
    
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    if [[ -n "$CFG_URL" ]]; then
        curl -fsSL --connect-timeout 10 --max-time 30 "$CFG_URL" -o "$CONFIG_FILE" 2>/dev/null
    elif [[ -n "$CFG_PATH" ]]; then
        cp "$CFG_PATH" "$CONFIG_FILE" 2>/dev/null
    else
        curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null
    fi
    
    if [[ -f "$CONFIG_FILE" ]] && jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo ""
        echo "Available profiles:"
        echo ""
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            pname=$(jq -r ".profiles[\"$key\"].name // \"$key\"" "$CONFIG_FILE")
            pdesc=$(jq -r ".profiles[\"$key\"].desc // \"\"" "$CONFIG_FILE")
            picon=$(jq -r ".profiles[\"$key\"].icon // \"\"" "$CONFIG_FILE")
            echo "  ${picon} ${key} - ${pname}: ${pdesc}"
        done < <(jq -r '.profiles | keys[]' "$CONFIG_FILE")
        echo ""
    else
        echo "[ERROR] Failed to load configuration"
    fi
    
    rm -f "$CONFIG_FILE" 2>/dev/null
    exit 0
fi

# --show-profile 在语言选择之前处理，默认英文输出
if [[ -n "$SHOW_PROFILE" ]]; then
    # 检测 jq
    if ! command -v jq &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install jq 2>/dev/null
        else
            sudo apt install -y jq 2>/dev/null
        fi
    fi
    
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    if [[ -n "$CFG_URL" ]]; then
        curl -fsSL --connect-timeout 10 --max-time 30 "$CFG_URL" -o "$CONFIG_FILE" 2>/dev/null
    elif [[ -n "$CFG_PATH" ]]; then
        cp "$CFG_PATH" "$CONFIG_FILE" 2>/dev/null
    else
        curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null
    fi
    
    if [[ -f "$CONFIG_FILE" ]] && jq empty "$CONFIG_FILE" 2>/dev/null; then
        # 检测当前平台
        current_os=""
        case "$OSTYPE" in
            msys*|mingw*|cygwin*|win*) current_os="win" ;;
            darwin*) current_os="mac" ;;
            linux*) current_os="linux" ;;
        esac
        
        pname=$(jq -r ".profiles[\"$SHOW_PROFILE\"].name // \"\"" "$CONFIG_FILE")
        pdesc=$(jq -r ".profiles[\"$SHOW_PROFILE\"].desc // \"\"" "$CONFIG_FILE")
        picon=$(jq -r ".profiles[\"$SHOW_PROFILE\"].icon // \"\"" "$CONFIG_FILE")
        
        if [[ -z "$pname" ]]; then
            echo "[ERROR] Profile '$SHOW_PROFILE' not found"
            rm -f "$CONFIG_FILE" 2>/dev/null
            exit 1
        fi
        
        echo ""
        echo "Profile: ${picon} ${pname}"
        echo "Description: ${pdesc}"
        echo ""
        echo "Included software:"
        
        supported=0
        unsupported=0
        while IFS= read -r sw; do
            [[ -z "$sw" ]] && continue
            sw_name=$(jq -r ".software[\"$sw\"].name // \"$sw\"" "$CONFIG_FILE")
            sw_cmd=$(jq -r ".software[\"$sw\"].$current_os // \"\"" "$CONFIG_FILE")
            
            if [[ -n "$sw_cmd" ]]; then
                echo "  ✓ $sw_name"
                ((supported++))
            else
                echo "  ✗ $sw_name (not supported on this platform)"
                ((unsupported++))
            fi
        done < <(jq -r ".profiles[\"$SHOW_PROFILE\"].includes[]?" "$CONFIG_FILE")
        
        echo ""
        echo "Summary: $supported supported, $unsupported unsupported on this platform"
        echo ""
    else
        echo "[ERROR] Failed to load configuration"
    fi
    
    rm -f "$CONFIG_FILE" 2>/dev/null
    exit 0
fi

# 日志系统
log_to_file() {
    [[ -n "$LOG_FILE" ]] && echo "$*" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    log_to_file "[INFO] $*"
}
log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
    log_to_file "[SUCCESS] $*"
}
log_warn() {
    echo -e "${YELLOW}[!]${NC} $*"
    log_to_file "[WARN] $*"
}
log_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
    log_to_file "[ERROR] $*"
}
log_step() {
    echo -e "${CYAN}[→]${NC} $*"
    log_to_file "[STEP] $*"
}
log_header() {
    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}  $*${NC}"
    echo -e "${BOLD}========================================${NC}"
    log_to_file ""
    log_to_file "===== $* ====="
    log_to_file ""
}

# JSON 解析抽象层
JSON_PARSER=""

ensure_json_parser() {
    if command -v jq &>/dev/null; then
        log_info "检测到 jq，使用 jq"
        JSON_PARSER="jq"
        return 0
    fi
    
    log_info "未检测到 jq，安装中..."
    case $(detect_os) in
        macos) brew install jq ;;
        linux) sudo apt install -y jq ;;
    esac
    
    if command -v jq &>/dev/null; then
        log_info "jq 安装成功"
        JSON_PARSER="jq"
        return 0
    fi
    
    log_warn "jq 安装失败，尝试使用备用解析方案..."
    if command -v python3 &>/dev/null; then
        log_info "使用 python3 作为备用解析器"
        JSON_PARSER="python3"
        return 0
    fi
    
    log_error "无可用 JSON 解析器 (jq/python3)"
    exit 1
}

# 统一 JSON 校验函数
validate_json() {
    local json_file=$1
    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq empty "$json_file" 2>/dev/null
    else
        python3 -c "import json; json.load(open('$json_file'))" 2>/dev/null
    fi
}

# 统一 JSON 读取函数
json_get() {
    local json_file=$1
    local query=$2
    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r "$query" "$json_file" 2>/dev/null
    else
        python3 -c "
import json, sys
data = json.load(open('$json_file'))
keys = '$query'.strip('.').split('.')
result = data
for k in keys:
    if k.startswith('[') and k.endswith(']'):
        k = k[1:-1]
        result = result[k] if isinstance(result, dict) else result[int(k)]
    elif isinstance(result, dict):
        result = result.get(k, '')
    else:
        result = ''
print(result if result else '')
" 2>/dev/null
    fi
}

json_list_profiles() {
    local json_file=$1
    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r '.profiles | keys[]' "$json_file" 2>/dev/null
    else
        python3 -c "import json; [print(k) for k in json.load(open('$json_file'))['profiles'].keys()]" 2>/dev/null
    fi
}

json_get_profile_includes() {
    local json_file=$1
    local key=$2
    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r ".profiles[\"$key\"].includes[]? // empty" "$json_file" 2>/dev/null
    else
        python3 -c "import json; [print(i) for i in json.load(open('$json_file'))['profiles'].get('$key',{}).get('includes',[])]" 2>/dev/null
    fi
}

json_get_profile_field() {
    local json_file=$1
    local key=$2
    local field=$3
    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r ".profiles[\"$key\"].$field // \"\"" "$json_file" 2>/dev/null
    else
        python3 -c "import json; print(json.load(open('$json_file'))['profiles'].get('$key',{}).get('$field',''))" 2>/dev/null
    fi
}

json_get_software_field() {
    local json_file=$1
    local key=$2
    local field=$3
    if [[ "$JSON_PARSER" == "jq" ]]; then
        jq -r ".software[\"$key\"].$field // \"\"" "$json_file" 2>/dev/null
    else
        python3 -c "import json; print(json.load(open('$json_file'))['software'].get('$key',{}).get('$field',''))" 2>/dev/null
    fi
}

is_installed() {
    local json_file=$1
    local os=$2
    local key=$3
    local check_field
    
    case "$os" in
        macos) check_field="check_mac" ;;
        windows) check_field="check_win" ;;
        linux) check_field="check_linux" ;;
        *) return 1 ;;
    esac
    
    local check_cmd
    check_cmd=$(json_get_software_field "$json_file" "$key" "$check_field")
    [[ -z "$check_cmd" ]] && return 1
    
    local result=0
    eval "$check_cmd" &>/dev/null || result=$?
    return $result
}

# 语言选择
TUI_RESULT=""

tui_interactive_select() {
    local -a items=("$@")
    local num_items=${#items[@]}
    local cursor=0
    
    tput civis 2>/dev/null || true
    
    for ((i=0; i<num_items; i++)); do
        if [[ $i -eq $cursor ]]; then
            printf "  \033[7m ▶ %s\033[0m\n" "${items[$i]}"
        else
            printf "    %s\n" "${items[$i]}"
        fi
    done
    
    while true; do
        tput cuu $num_items 2>/dev/null || true
        
        for ((i=0; i<num_items; i++)); do
            printf "\033[2K"
            if [[ $i -eq $cursor ]]; then
                printf "  \033[7m ▶ %s\033[0m\n" "${items[$i]}"
            else
                printf "    %s\n" "${items[$i]}"
            fi
        done
        
        local key
        IFS= read -rsn1 key < /dev/tty
        local key_code=$(printf '%d' "'$key" 2>/dev/null || echo 0)
        
        case $key_code in
            27)
                IFS= read -rsn2 key < /dev/tty
                case "$key" in
                    '[A') ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((num_items - 1)) ;;
                    '[B') ((cursor++)); [[ $cursor -ge $num_items ]] && cursor=0 ;;
                esac
                ;;
            10|13|0) break ;;
        esac
    done
    
    tput cnorm 2>/dev/null || true
    TUI_RESULT=$cursor
}

select_language() {
    if [[ -n "$LANG_OVERRIDE" ]]; then
        case "$LANG_OVERRIDE" in
            zh|zh-CN|zh_CN) echo "zh-CN" ;;
            *) echo "en-US" ;;
        esac
        return
    fi
    
    # 所有显示输出重定向到 stderr，只有返回值走 stdout
    echo "" >&2
    echo -e "\033[0;36m╔════════════════════════════════════════╗\033[0m" >&2
    echo -e "\033[0;36m║         \033[1mQuickstart-PC v0.10.0\033[0m\033[0;36m          ║\033[0m" >&2
    echo -e "\033[0;36m╚════════════════════════════════════════╝\033[0m" >&2
    echo "" >&2
    echo "  Please select language / 请选择语言:" >&2
    echo "" >&2
    
    local lang_items=("English" "简体中文")
    tui_interactive_select "${lang_items[@]}" >&2
    local choice=$TUI_RESULT
    
    case $choice in
        0) echo "en-US" ;;
        1) echo "zh-CN" ;;
        *) echo "en-US" ;;
    esac
}

DETECTED_LANG=$(select_language)

if [[ "$DETECTED_LANG" == "zh-CN" ]]; then
    LANG_BANNER_TITLE="Quickstart-PC v0.10.0"
    LANG_BANNER_DESC="快速配置新电脑软件环境"
    LANG_DETECTING_SYSTEM="检测系统环境..."
    LANG_SYSTEM_INFO="系统"
    LANG_PACKAGE_MANAGER="包管理器"
    LANG_UNSUPPORTED_OS="不支持的操作系统"
    LANG_USING_REMOTE_CONFIG="使用远程配置"
    LANG_USING_CUSTOM_CONFIG="使用本地配置"
    LANG_USING_DEFAULT_CONFIG="使用默认配置"
    LANG_CONFIG_NOT_FOUND="配置文件不存在"
    LANG_CONFIG_INVALID="配置文件格式无效"
    LANG_SELECT_PROFILES="选择安装套餐"
    LANG_SELECT_SOFTWARE="选择要安装的软件"
    LANG_NAVIGATE="↑↓ 移动 | 空格 选择 | 回车 确认"
    LANG_SELECTED="[✓] "
    LANG_NOT_SELECTED="[  ] "
    LANG_SELECT_ALL="全选"
    LANG_NO_PROFILE_SELECTED="未选择任何套餐"
    LANG_NO_SOFTWARE_SELECTED="未选择任何软件"
    LANG_CONFIRM_INSTALL="确认安装？[Y/n]"
    LANG_CANCELLED="已取消"
    LANG_START_INSTALLING="开始安装软件"
    LANG_INSTALLING="安装"
    LANG_INSTALL_SUCCESS="安装完成"
    LANG_INSTALL_FAILED="安装失败"
    LANG_PLATFORM_NOT_SUPPORTED="不支持的平台"
    LANG_INSTALLATION_COMPLETE="安装完成"
    LANG_TOTAL_INSTALLED="共安装"
    LANG_DEV_MODE="开发者模式：仅显示选择的软件，不实际安装"
    LANG_FAKE_INSTALL_MODE="假装安装模式：展示安装过程但不实际安装"
    LANG_FAKE_INSTALLING="模拟安装"
else
    LANG_BANNER_TITLE="Quickstart-PC v0.10.0"
    LANG_BANNER_DESC="Quick setup for new computers"
    LANG_DETECTING_SYSTEM="Detecting system environment..."
    LANG_SYSTEM_INFO="System"
    LANG_PACKAGE_MANAGER="Package Manager"
    LANG_UNSUPPORTED_OS="Unsupported operating system"
    LANG_USING_REMOTE_CONFIG="Using remote configuration"
    LANG_USING_CUSTOM_CONFIG="Using local configuration"
    LANG_USING_DEFAULT_CONFIG="Using default configuration"
    LANG_CONFIG_NOT_FOUND="Configuration file not found"
    LANG_CONFIG_INVALID="Configuration file format invalid"
    LANG_SELECT_PROFILES="Select Installation Profiles"
    LANG_SELECT_SOFTWARE="Select Software to Install"
    LANG_NAVIGATE="↑↓ Move | SPACE Select | ENTER Confirm"
    LANG_SELECTED="[✓] "
    LANG_NOT_SELECTED="[  ] "
    LANG_SELECT_ALL="Select All"
    LANG_NO_PROFILE_SELECTED="No profile selected"
    LANG_NO_SOFTWARE_SELECTED="No software selected"
    LANG_CONFIRM_INSTALL="Confirm installation? [Y/n]"
    LANG_CANCELLED="Cancelled"
    LANG_START_INSTALLING="Starting software installation"
    LANG_INSTALLING="Installing"
    LANG_INSTALL_SUCCESS="installed successfully"
    LANG_INSTALL_FAILED="installation failed"
    LANG_PLATFORM_NOT_SUPPORTED="Platform not supported"
    LANG_INSTALLATION_COMPLETE="Installation Complete"
    LANG_TOTAL_INSTALLED="Total installed"
    LANG_DEV_MODE="Dev mode: Show selected software without installing"
    LANG_FAKE_INSTALL_MODE="Fake install mode: Show installation process without actually installing"
    LANG_FAKE_INSTALLING="Simulating install"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
ORANGE='\033[38;5;208m'
NC='\033[0m'
BOLD='\033[1m'
REVERSE='\033[7m'

detect_os() {
    case "$OSTYPE" in
        msys*|mingw*|cygwin*|win*) echo "windows" ;;
        darwin*) echo "macos" ;;
        linux*) echo "linux" ;;
        *) echo "unknown" ;;
    esac
}

get_system_info() {
    case $(detect_os) in
        windows) echo "Windows" ;;
        macos) echo "macOS $(sw_vers -productVersion 2>/dev/null || echo unknown)" ;;
        linux) echo "Linux" ;;
        *) echo "Unknown" ;;
    esac
}

check_package_manager() {
    case $1 in
        windows) command -v winget &>/dev/null && echo "winget" || echo "none" ;;
        macos) command -v brew &>/dev/null && echo "brew" || echo "none" ;;
        linux) command -v apt &>/dev/null && echo "apt" || echo "none" ;;
    esac
}

load_config() {
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    
    if [[ -n "$CFG_URL" ]]; then
        log_info "$LANG_USING_REMOTE_CONFIG: $CFG_URL"
        if curl -fsSL --connect-timeout 10 --max-time 30 "$CFG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
            if validate_json "$CONFIG_FILE"; then
                return 0
            else
                log_error "$LANG_CONFIG_INVALID: $CFG_URL"
                exit 1
            fi
        else
            log_error "$LANG_CONFIG_NOT_FOUND: $CFG_URL"
            exit 1
        fi
    fi
    
    if [[ -n "$CFG_PATH" ]]; then
        if [[ -f "$CFG_PATH" ]]; then
            if validate_json "$CFG_PATH"; then
                log_info "$LANG_USING_CUSTOM_CONFIG: $CFG_PATH"
                cp "$CFG_PATH" "$CONFIG_FILE"
                return 0
            else
                log_error "$LANG_CONFIG_INVALID: $CFG_PATH"
                exit 1
            fi
        else
            log_error "$LANG_CONFIG_NOT_FOUND: $CFG_PATH"
            exit 1
        fi
    fi
    
    log_info "$LANG_USING_DEFAULT_CONFIG"
    if curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
        if validate_json "$CONFIG_FILE"; then
            return 0
        fi
    fi
    
    log_error "$LANG_CONFIG_NOT_FOUND"
    exit 1
}

SELECTED_PROFILES=()
SELECTED_SOFTWARE=()

show_profile_menu() {
    local json_file=$1
    
    local -a profile_keys=()
    local -a profile_names=()
    local -a profile_icons=()
    local -a profile_descs=()
    
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        profile_keys+=("$key")
        profile_names+=("$(json_get_profile_field "$json_file" "$key" "name")")
        profile_icons+=("$(json_get_profile_field "$json_file" "$key" "icon")")
        profile_descs+=("$(json_get_profile_field "$json_file" "$key" "desc")")
    done < <(json_list_profiles "$json_file")
    
    local num_profiles=${#profile_keys[@]}
    local -a menu_names
    local cursor=0
    
    for ((i=0; i<num_profiles; i++)); do
        menu_names+=("${profile_icons[$i]} ${profile_names[$i]} - ${profile_descs[$i]}")
    done
    
    tput civis 2>/dev/null || true
    
    echo ""
    log_header "$LANG_SELECT_PROFILES"
    echo ""
    echo -e "  ${CYAN}$LANG_NAVIGATE${NC}"
    echo ""
    
    draw_menu() {
        for ((i=0; i<num_profiles; i++)); do
            printf "\033[2K"
            if [[ $i -eq $cursor ]]; then
                echo -e "  ${REVERSE} ▶ ${menu_names[$i]}${NC}"
            else
                echo -e "    ${menu_names[$i]}"
            fi
        done
    }
    
    draw_menu
    
    while true; do
        tput cuu $num_profiles 2>/dev/null || true
        draw_menu
        
        local key
        IFS= read -rsn1 key < /dev/tty
        local key_code=$(printf '%d' "'$key" 2>/dev/null || echo 0)
        
        case $key_code in
            27)
                IFS= read -rsn2 key < /dev/tty
                case "$key" in
                    '[A') ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((num_profiles - 1)) ;;
                    '[B') ((cursor++)); [[ $cursor -ge $num_profiles ]] && cursor=0 ;;
                esac
                ;;
            10|13|0) break ;;
        esac
    done
    
    tput cnorm 2>/dev/null || true
    
    SELECTED_PROFILES=("${profile_keys[$cursor]}")
}

show_software_menu() {
    local json_file=$1
    local os=$2
    local profile_key=$3
    
    local -a sw_keys=()
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        
        # --only 过滤
        if [[ ${#ONLY_SW[@]} -gt 0 ]] && [[ ! " ${ONLY_SW[*]} " =~ " $key " ]]; then
            continue
        fi
        
        # --skip 过滤
        if [[ ${#SKIP_SW[@]} -gt 0 ]] && [[ " ${SKIP_SW[*]} " =~ " $key " ]]; then
            continue
        fi
        
        sw_keys+=("$key")
    done < <(json_get_profile_includes "$json_file" "$profile_key")
    
    local num_sw=${#sw_keys[@]}
    local -a menu_keys menu_names
    local -a checked
    
    menu_keys=("select_all")
    menu_names=("${ORANGE}$LANG_SELECT_ALL${NC}")
    checked=(0)
    
    for key in "${sw_keys[@]}"; do
        local name=$(json_get_software_field "$json_file" "$key" "name")
        local desc=$(json_get_software_field "$json_file" "$key" "desc")
        menu_keys+=("$key")
        if is_installed "$json_file" "$os" "$key"; then
            menu_names+=("${GRAY}$name - $desc $LANG_INSTALLED${NC}")
        else
            menu_names+=("$name - $desc")
        fi
        checked+=(0)
    done
    
    local num_items=${#menu_keys[@]}
    local cursor=0
    
    tput civis 2>/dev/null || true
    
    echo ""
    log_header "$LANG_SELECT_SOFTWARE"
    echo ""
    echo -e "  ${CYAN}$LANG_NAVIGATE${NC}"
    echo ""
    
    draw_menu() {
        for ((i=0; i<num_items; i++)); do
            printf "\033[2K"
            if [[ $i -eq $cursor ]]; then
                if [[ ${checked[$i]} -eq 1 ]]; then
                    echo -e "  ${REVERSE}${GREEN}${LANG_SELECTED}${NC}${REVERSE}${menu_names[$i]}${NC}"
                else
                    echo -e "  ${REVERSE}${LANG_NOT_SELECTED}${menu_names[$i]}${NC}"
                fi
            else
                if [[ ${checked[$i]} -eq 1 ]]; then
                    echo -e "  ${GREEN}${LANG_SELECTED}${NC}${menu_names[$i]}"
                else
                    echo -e "  ${LANG_NOT_SELECTED}${menu_names[$i]}"
                fi
            fi
        done
    }
    
    draw_menu
    
    while true; do
        tput cuu $num_items 2>/dev/null || true
        draw_menu
        
        local key
        IFS= read -rsn1 key < /dev/tty
        local key_code=$(printf '%d' "'$key" 2>/dev/null || echo 0)
        
        case $key_code in
            27)
                IFS= read -rsn2 key < /dev/tty
                case "$key" in
                    '[A') ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((num_items - 1)) ;;
                    '[B') ((cursor++)); [[ $cursor -ge $num_items ]] && cursor=0 ;;
                esac
                ;;
            32)
                if [[ $cursor -eq 0 ]]; then
                    local new_state=$((1 - checked[0]))
                    for ((i=0; i<num_items; i++)); do
                        checked[$i]=$new_state
                    done
                else
                    checked[$cursor]=$((1 - checked[$cursor]))
                fi
                ;;
            10|13|0) break ;;
        esac
    done
    
    tput cnorm 2>/dev/null || true
    
    SELECTED_SOFTWARE=()
    for ((i=1; i<num_items; i++)); do
        [[ ${checked[$i]} -eq 1 ]] && SELECTED_SOFTWARE+=("${menu_keys[$i]}")
    done
}

install_software() {
    local json_file=$1
    local os=$2
    local key=$3
    local platform
    
    case "$os" in
        windows) platform="win" ;;
        macos) platform="mac" ;;
        linux) platform="linux" ;;
    esac
    
    local cmd=$(json_get_software_field "$json_file" "$key" "$platform")
    
    if [[ -z "$cmd" ]]; then
        log_warn "$LANG_PLATFORM_NOT_SUPPORTED: $key"
        return 1
    fi
    
    if [[ "$FAKE_INSTALL" == "true" ]]; then
        log_step "$LANG_FAKE_INSTALLING: $key"
        echo -e "  ${CYAN}→ Command: $cmd${NC}"
        sleep 1
        log_success "$key $LANG_INSTALL_SUCCESS (simulated)"
        return 0
    fi
    
    log_step "$LANG_INSTALLING: $key"
    if eval "$cmd" 2>/dev/null; then
        log_success "$key $LANG_INSTALL_SUCCESS"
    else
        log_error "$key $LANG_INSTALL_FAILED"
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
    
    [[ "$DEV_MODE" == "true" ]] && log_warn "$LANG_DEV_MODE" && echo ""
    [[ "$FAKE_INSTALL" == "true" ]] && log_warn "$LANG_FAKE_INSTALL_MODE" && echo ""
    
    log_info "$LANG_DETECTING_SYSTEM"
    local os=$(detect_os)
    local system_info=$(get_system_info)
    local pkg_manager=$(check_package_manager "$os")
    
    log_info "$LANG_SYSTEM_INFO: $system_info"
    log_info "$LANG_PACKAGE_MANAGER: $pkg_manager"
    
    [[ "$os" == "unknown" ]] && log_error "$LANG_UNSUPPORTED_OS" && exit 1
    
    ensure_json_parser
    load_config
    
    # --non-interactive 模式处理
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        if [[ -z "$PROFILE_KEY" ]]; then
            log_error "非交互模式需要 --profile 参数"
            exit 1
        fi
        
        # 验证 profile 是否存在
        local profile_exists=false
        while IFS= read -r key; do
            if [[ "$key" == "$PROFILE_KEY" ]]; then
                profile_exists=true
                break
            fi
        done < <(json_list_profiles "$CONFIG_FILE")
        
        if [[ "$profile_exists" != "true" ]]; then
            log_error "Profile '$PROFILE_KEY' 不存在"
            exit 1
        fi
        
        SELECTED_PROFILES=("$PROFILE_KEY")
        
        # 非交互模式：自动选择所有软件
        local -a sw_keys=()
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            
            # --only 过滤
            if [[ ${#ONLY_SW[@]} -gt 0 ]] && [[ ! " ${ONLY_SW[*]} " =~ " $key " ]]; then
                continue
            fi
            
            # --skip 过滤
            if [[ ${#SKIP_SW[@]} -gt 0 ]] && [[ " ${SKIP_SW[*]} " =~ " $key " ]]; then
                continue
            fi
            
            sw_keys+=("$key")
        done < <(json_get_profile_includes "$CONFIG_FILE" "$PROFILE_KEY")
        
        SELECTED_SOFTWARE=("${sw_keys[@]}")
    elif [[ -n "$PROFILE_KEY" ]]; then
        # --profile 参数：跳过菜单，直接选择
        local profile_exists=false
        while IFS= read -r key; do
            if [[ "$key" == "$PROFILE_KEY" ]]; then
                profile_exists=true
                break
            fi
        done < <(json_list_profiles "$CONFIG_FILE")
        
        if [[ "$profile_exists" != "true" ]]; then
            log_error "Profile '$PROFILE_KEY' 不存在"
            exit 1
        fi
        
        SELECTED_PROFILES=("$PROFILE_KEY")
        show_software_menu "$CONFIG_FILE" "$os" "${SELECTED_PROFILES[@]}"
    else
        show_profile_menu "$CONFIG_FILE"
        [[ ${#SELECTED_PROFILES[@]} -eq 0 ]] && log_warn "$LANG_NO_PROFILE_SELECTED" && exit 0
        show_software_menu "$CONFIG_FILE" "$os" "${SELECTED_PROFILES[@]}"
    fi
    
    [[ ${#SELECTED_SOFTWARE[@]} -eq 0 ]] && log_warn "$LANG_NO_SOFTWARE_SELECTED" && exit 0
    
    echo ""
    log_info "Selected: ${SELECTED_SOFTWARE[*]}"
    echo ""
    
    [[ "$DEV_MODE" == "true" ]] && log_info "Dev mode: Done" && exit 0
    
    if [[ "$AUTO_YES" == "true" ]] || [[ "$NON_INTERACTIVE" == "true" ]]; then
        echo ""
    else
        read -p "$LANG_CONFIRM_INSTALL " confirm < /dev/tty
        [[ "$confirm" =~ ^[Nn] ]] && log_info "$LANG_CANCELLED" && exit 0
    fi
    
    log_header "$LANG_START_INSTALLING"
    
    local total=${#SELECTED_SOFTWARE[@]}
    local current=0
    local -a installed_list=()
    local -a skipped_list=()
    local -a failed_list=()
    local -a warning_list=()
    
    for sw in "${SELECTED_SOFTWARE[@]}"; do
        ((current++))
        local sw_name=$(json_get_software_field "$CONFIG_FILE" "$sw" "name")
        printf "\r${CYAN}[%3d%%]${NC} %s" "$((current * 100 / total))" "$LANG_INSTALLING $sw_name"
        
        if is_installed "$CONFIG_FILE" "$os" "$sw"; then
            skipped_list+=("$sw_name")
        else
            if install_software "$CONFIG_FILE" "$os" "$sw"; then
                installed_list+=("$sw_name")
            else
                failed_list+=("$sw_name")
                if [[ "$FAIL_FAST" == "true" ]]; then
                    echo ""
                    log_error "Fail-fast: stopping at $sw_name"
                    break
                fi
            fi
        fi
    done
    echo ""
    
    log_header "$LANG_INSTALLATION_COMPLETE"
    echo ""
    echo -e "${GREEN}Installed:${NC}"
    log_to_file "Installed:"
    if [[ ${#installed_list[@]} -eq 0 ]]; then
        echo -e "${GRAY}  (none)${NC}"
        log_to_file "  (none)"
    else
        for item in "${installed_list[@]}"; do
            echo -e "  ${GREEN}- $item${NC}"
            log_to_file "  - $item"
        done
    fi
    
    echo ""
    echo -e "${CYAN}Skipped:${NC}"
    log_to_file ""
    log_to_file "Skipped:"
    if [[ ${#skipped_list[@]} -eq 0 ]]; then
        echo -e "${GRAY}  (none)${NC}"
        log_to_file "  (none)"
    else
        for item in "${skipped_list[@]}"; do
            echo -e "  ${GRAY}- $item${NC}"
            log_to_file "  - $item"
        done
    fi
    
    echo ""
    echo -e "${RED}Failed:${NC}"
    log_to_file ""
    log_to_file "Failed:"
    if [[ ${#failed_list[@]} -eq 0 ]]; then
        echo -e "${GRAY}  (none)${NC}"
        log_to_file "  (none)"
    else
        for item in "${failed_list[@]}"; do
            echo -e "  ${RED}- $item${NC}"
            log_to_file "  - $item"
        done
    fi
    
    echo ""
    echo -e "${YELLOW}Warnings:${NC}"
    log_to_file ""
    log_to_file "Warnings:"
    if [[ ${#warning_list[@]} -eq 0 ]]; then
        echo -e "${GRAY}  (none)${NC}"
        log_to_file "  (none)"
    else
        for item in "${warning_list[@]}"; do
            echo -e "  ${YELLOW}- $item${NC}"
            log_to_file "  - $item"
        done
    fi
    
    echo ""
    log_success "$LANG_TOTAL_INSTALLED ${#installed_list[@]} / $total"
    
    # Verbose output
    if [[ "$VERBOSE" == "true" ]]; then
        echo ""
        echo "===== Verbose Debug Info ====="
        log_to_file ""
        log_to_file "===== Verbose Debug Info ====="
        echo "[PLATFORM] $(detect_os) - $(get_system_info)"
        log_to_file "[PLATFORM] $(detect_os) - $(get_system_info)"
        echo "[PKG_MANAGER] $(check_package_manager "$os")"
        log_to_file "[PKG_MANAGER] $(check_package_manager "$os")"
        echo "[CONFIG] $CONFIG_FILE"
        log_to_file "[CONFIG] $CONFIG_FILE"
        echo "[PROFILE] ${SELECTED_PROFILES[*]}"
        log_to_file "[PROFILE] ${SELECTED_PROFILES[*]}"
        echo ""
        log_to_file ""
        for sw in "${SELECTED_SOFTWARE[@]}"; do
            local sw_name=$(json_get_software_field "$CONFIG_FILE" "$sw" "name")
            local check_field
            case "$os" in
                macos) check_field="check_mac" ;;
                windows) check_field="check_win" ;;
                linux) check_field="check_linux" ;;
            esac
            local check_cmd=$(json_get_software_field "$CONFIG_FILE" "$sw" "$check_field")
            local install_cmd=$(json_get_software_field "$CONFIG_FILE" "$sw" "${os:0:3}")
            
            if [[ " ${skipped_list[*]} " =~ " $sw_name " ]]; then
                echo "[CHECK] $sw_name -> installed"
                log_to_file "[CHECK] $sw_name -> installed"
            elif [[ " ${failed_list[*]} " =~ " $sw_name " ]]; then
                echo "[CHECK] $sw_name -> not installed"
                log_to_file "[CHECK] $sw_name -> not installed"
                echo "[PLAN] $sw_name -> $install_cmd"
                log_to_file "[PLAN] $sw_name -> $install_cmd"
                echo "[FAIL] $sw_name -> installation failed"
                log_to_file "[FAIL] $sw_name -> installation failed"
            else
                echo "[CHECK] $sw_name -> not installed"
                log_to_file "[CHECK] $sw_name -> not installed"
                echo "[PLAN] $sw_name -> $install_cmd"
                log_to_file "[PLAN] $sw_name -> $install_cmd"
            fi
        done
        echo "===== End Verbose ====="
        log_to_file "===== End Verbose ====="
    fi
}

trap 'tput cnorm 2>/dev/null || true; rm -f "$CONFIG_FILE" 2>/dev/null' EXIT
main "$@"
