#!/usr/bin/env bash

clear
tput civis 2>/dev/null || true

error_handler() {
    local line=$1
    local command=$2
    local code=$3
    echo ""
    echo -e "\033[0;31m[ERROR] Script failed at line $line\033[0m"
    echo -e "\033[0;31m  Command: $command\033[0m"
    echo -e "\033[0;31m  Exit code: $code\033[0m"
    echo ""
    tput cnorm 2>/dev/null || true
    exit 1
}

trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR

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
  --fake-install     假装安装：展示安装过程但不实际安装
  --help             显示此帮助信息

示例:
  quickstart.sh --lang zh
  quickstart.sh --cfg-path /path/to/profiles.json
  quickstart.sh --fake-install
HELPZH
    else
        cat << 'HELPEN'
Quickstart-PC - One-click computer setup

Usage: quickstart.sh [OPTIONS]

Options:
  --lang LANG        Set language (en, zh)
  --cfg-path PATH    Use local profiles.json file
  --cfg-url URL      Use remote profiles.json URL
  --dev              Dev mode: show selected software without installing
  --fake-install     Fake install: show installation process without actually installing
  --help             Show this help message

Examples:
  quickstart.sh --lang en
  quickstart.sh --cfg-path /path/to/profiles.json
  quickstart.sh --fake-install
HELPEN
    fi
    exit 0
}

DEV_MODE=false
FAKE_INSTALL=false
LANG_OVERRIDE=""
CFG_PATH=""
CFG_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev) DEV_MODE=true; shift ;;
        --fake-install) FAKE_INSTALL=true; shift ;;
        --lang) LANG_OVERRIDE="$2"; shift 2 ;;
        --cfg-path) CFG_PATH="$2"; shift 2 ;;
        --cfg-url) CFG_URL="$2"; shift 2 ;;
        --help|-h) show_help ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

tui_draw_menu() {
    local cursor=$1
    shift
    local -a items=("$@")
    for ((i=0; i<${#items[@]}; i++)); do
        printf "\033[2K"
        if [[ $i -eq $cursor ]]; then
            echo -e "  \033[7m ▶ ${items[$i]} \033[0m"
        else
            echo -e "    ${items[$i]}"
        fi
    done
}

tui_interactive_select() {
    local -a items=("$@")
    local num_items=${#items[@]}
    local cursor=0
    
    tput civis 2>/dev/null || true
    tui_draw_menu $cursor "${items[@]}"
    
    while true; do
        tput cuu $num_items 2>/dev/null || true
        tui_draw_menu $cursor "${items[@]}"
        
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
    return $cursor
}

select_language() {
    if [[ -n "$LANG_OVERRIDE" ]]; then
        case "$LANG_OVERRIDE" in
            zh|zh-CN|zh_CN) echo "zh-CN" ;;
            *) echo "en-US" ;;
        esac
        return
    fi
    
    echo ""
    echo -e "\033[0;36m╔════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;36m║         \033[1mQuickstart-PC v1.0.0\033[0m\033[0;36m             ║\033[0m"
    echo -e "\033[0;36m╚════════════════════════════════════════╝\033[0m"
    echo ""
    echo "  Please select language / 请选择语言:"
    echo ""
    
    local lang_items=("English" "简体中文")
    tui_interactive_select "${lang_items[@]}"
    local choice=$?
    
    case $choice in
        0) echo "en-US" ;;
        1) echo "zh-CN" ;;
        *) echo "en-US" ;;
    esac
}

DETECTED_LANG=$(select_language)

if [[ "$DETECTED_LANG" == "zh-CN" ]]; then
    LANG_BANNER_TITLE="Quickstart-PC v1.0.0"
    LANG_BANNER_DESC="快速配置新电脑软件环境"
    LANG_DETECTING_SYSTEM="检测系统环境..."
    LANG_SYSTEM_INFO="系统"
    LANG_PACKAGE_MANAGER="包管理器"
    LANG_UNSUPPORTED_OS="不支持的操作系统"
    LANG_USING_CUSTOM_CONFIG="使用自定义配置"
    LANG_USING_REMOTE_CONFIG="使用远程配置"
    LANG_USING_EMBEDDED_CONFIG="使用内嵌配置"
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
    LANG_BANNER_TITLE="Quickstart-PC v1.0.0"
    LANG_BANNER_DESC="Quick setup for new computers"
    LANG_DETECTING_SYSTEM="Detecting system environment..."
    LANG_SYSTEM_INFO="System"
    LANG_PACKAGE_MANAGER="Package Manager"
    LANG_UNSUPPORTED_OS="Unsupported operating system"
    LANG_USING_CUSTOM_CONFIG="Using custom configuration"
    LANG_USING_REMOTE_CONFIG="Using remote configuration"
    LANG_USING_EMBEDDED_CONFIG="Using embedded configuration"
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

# Profile data
PROFILE_KEYS=(recommended ai developer)
PROFILE_NAMES=("推荐套餐/Recommended" "AI 赋能/AI Powered" "开发者/Developer")
PROFILE_ICONS=("⭐" "🤖" "💻")
PROFILE_DESCS=("综合均衡/Balanced" "AI 工具/AI tools" "开发工具/Dev tools")
PROFILE_SW_0="chrome vscode git nodejs python wps vlc"
PROFILE_SW_1="cursor ollama"
PROFILE_SW_2="vscode git nodejs python"

# Software data
SW_KEYS_ALL=(chrome vscode git nodejs python cursor ollama wps vlc ffmpeg)
SW_NAME_0="Chrome" SW_DESC_0="浏览器/Browser"
SW_NAME_1="VS Code" SW_DESC_1="代码编辑器/Code editor"
SW_NAME_2="Git" SW_DESC_2="版本控制/Version control"
SW_NAME_3="Node.js" SW_DESC_3="JavaScript 运行时/Runtime"
SW_NAME_4="Python" SW_DESC_4="Python 编程语言/Programming language"
SW_NAME_5="Cursor" SW_DESC_5="AI 代码编辑器/AI editor"
SW_NAME_6="Ollama" SW_DESC_6="本地 LLM/Local LLM"
SW_NAME_7="WPS Office" SW_DESC_7="办公套件/Office suite"
SW_NAME_8="VLC" SW_DESC_8="媒体播放器/Media player"
SW_NAME_9="FFmpeg" SW_DESC_9="音视频工具/Media tool"

# Install commands
SW_WIN_0="winget install Google.Chrome"
SW_MAC_0="brew install --cask google-chrome"
SW_LINUX_0="sudo apt install -y google-chrome-stable"
SW_WIN_1="winget install Microsoft.VisualStudioCode"
SW_MAC_1="brew install --cask visual-studio-code"
SW_LINUX_1="sudo snap install --classic code"
SW_WIN_2="winget install Git.Git"
SW_MAC_2="brew install git"
SW_LINUX_2="sudo apt install -y git"
SW_WIN_3="winget install OpenJS.NodeJS.LTS"
SW_MAC_3="brew install node"
SW_LINUX_3="curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt install -y nodejs"
SW_WIN_4="winget install Python.Python.3.12"
SW_MAC_4="brew install python@3.12"
SW_LINUX_4="sudo apt install -y python3 python3-pip"
SW_WIN_5="winget install Cursor.Cursor"
SW_MAC_5="brew install --cask cursor"
SW_LINUX_5="echo Download from https://cursor.sh"
SW_WIN_6="winget install Ollama.Ollama"
SW_MAC_6="brew install ollama"
SW_LINUX_6="curl -fsSL https://ollama.ai/install.sh | sh"
SW_WIN_7="winget install Kingsoft.WPSOffice"
SW_MAC_7="brew install --cask wps-office"
SW_LINUX_7="sudo apt install -y wps-office"
SW_WIN_8="winget install VideoLAN.VLC"
SW_MAC_8="brew install --cask vlc"
SW_LINUX_8="sudo apt install -y vlc"
SW_WIN_9="winget install FFmpeg"
SW_MAC_9="brew install ffmpeg"
SW_LINUX_9="sudo apt install -y ffmpeg"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
ORANGE='\033[38;5;208m'
NC='\033[0m'
BOLD='\033[1m'
REVERSE='\033[7m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }
log_step() { echo -e "${CYAN}[→]${NC} $*"; }
log_header() { echo ""; echo -e "${BOLD}========================================${NC}"; echo -e "${BOLD}  $*${NC}"; echo -e "${BOLD}========================================${NC}"; }

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

get_sw_index() {
    local key=$1
    for ((i=0; i<${#SW_KEYS_ALL[@]}; i++)); do
        if [[ "${SW_KEYS_ALL[$i]}" == "$key" ]]; then
            echo $i
            return
        fi
    done
    echo "-1"
}

get_sw_name() {
    local idx=$1
    eval "echo \$SW_NAME_$idx"
}

get_sw_desc() {
    local idx=$1
    eval "echo \$SW_DESC_$idx"
}

get_sw_cmd() {
    local idx=$1
    local os=$2
    eval "echo \$SW_${os}_$idx"
}

SELECTED_PROFILES=()
SELECTED_SOFTWARE=()

show_profile_menu() {
    local num_profiles=${#PROFILE_KEYS[@]}
    local -a menu_names
    local cursor=0
    
    for ((i=0; i<num_profiles; i++)); do
        menu_names+=("${PROFILE_ICONS[$i]} ${PROFILE_NAMES[$i]} - ${PROFILE_DESCS[$i]}")
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
    
    SELECTED_PROFILES=("${PROFILE_KEYS[$cursor]}")
}

show_software_menu() {
    local os=$1
    local profile_idx=$2
    
    local sw_list=$(eval "echo \$PROFILE_SW_$profile_idx")
    local -a sw_keys=($sw_list)
    local num_sw=${#sw_keys[@]}
    
    local -a menu_keys menu_names
    local -a checked
    
    menu_keys=("select_all")
    menu_names=("${ORANGE}$LANG_SELECT_ALL${NC}")
    checked=(0)
    
    for key in "${sw_keys[@]}"; do
        local idx=$(get_sw_index "$key")
        menu_keys+=("$key")
        menu_names+=("$(get_sw_name $idx) - $(get_sw_desc $idx)")
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
    local os=$1
    local key=$2
    local platform
    local idx=$(get_sw_index "$key")
    
    case "$os" in
        windows) platform="WIN" ;;
        macos) platform="MAC" ;;
        linux) platform="LINUX" ;;
    esac
    
    if [[ $idx -eq -1 ]]; then
        log_warn "$LANG_PLATFORM_NOT_SUPPORTED: $key"
        return 1
    fi
    
    local cmd=$(get_sw_cmd $idx "$platform")
    
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
    
    show_profile_menu
    
    [[ ${#SELECTED_PROFILES[@]} -eq 0 ]] && log_warn "$LANG_NO_PROFILE_SELECTED" && exit 0
    
    show_software_menu "$os" "${SELECTED_PROFILES[@]}"
    
    [[ ${#SELECTED_SOFTWARE[@]} -eq 0 ]] && log_warn "$LANG_NO_SOFTWARE_SELECTED" && exit 0
    
    echo ""
    log_info "Selected: ${SELECTED_SOFTWARE[*]}"
    echo ""
    
    [[ "$DEV_MODE" == "true" ]] && log_info "Dev mode: Done" && exit 0
    
    read -p "$LANG_CONFIRM_INSTALL " confirm < /dev/tty
    [[ "$confirm" =~ ^[Nn] ]] && log_info "$LANG_CANCELLED" && exit 0
    
    log_header "$LANG_START_INSTALLING"
    
    local total=${#SELECTED_SOFTWARE[@]}
    local current=0
    local failed=0
    
    for sw in "${SELECTED_SOFTWARE[@]}"; do
        ((current++))
        printf "\r${CYAN}[%3d%%]${NC} %s" "$((current * 100 / total))" "$LANG_INSTALLING $sw"
        install_software "$os" "$sw" || ((failed++))
    done
    echo ""
    
    log_header "$LANG_INSTALLATION_COMPLETE"
    [[ $failed -eq 0 ]] && log_success "$LANG_TOTAL_INSTALLED $total" || log_warn "$LANG_TOTAL_INSTALLED $((total - failed)) / $total ($failed failed)"
}

trap 'tput cnorm 2>/dev/null || true' EXIT
main "$@"
