#!/usr/bin/env bash

clear
tput civis 2>/dev/null || true

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
  --dev              开发模式
  --fake-install     假装安装
  --debug            调试模式（显示详细错误信息）
  --help             显示帮助
HELPZH
    else
        cat << 'HELPEN'
Quickstart-PC - One-click computer setup

Usage: quickstart.sh [OPTIONS]

Options:
  --lang LANG        Set language (en, zh)
  --dev              Dev mode
  --fake-install     Fake install
  --debug            Debug mode (show detailed error info)
  --help             Show help
HELPEN
    fi
    exit 0
}

DEV_MODE=false
FAKE_INSTALL=false
DEBUG_MODE=false
LANG_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev) DEV_MODE=true; shift ;;
        --fake-install) FAKE_INSTALL=true; shift ;;
        --debug) DEBUG_MODE=true; shift ;;
        --lang) LANG_OVERRIDE="$2"; shift 2 ;;
        --help|-h) show_help ;;
        *) shift ;;
    esac
done

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
        tput sc 2>/dev/null || true
        
        for ((i=0; i<num_items; i++)); do
            printf "\033[2K"
            if [[ $i -eq $cursor ]]; then
                printf "  \033[7m ▶ %s\033[0m\n" "${items[$i]}"
            else
                printf "    %s\n" "${items[$i]}"
            fi
        done
        
        local key=""
        IFS= read -rsn1 key < /dev/tty
        if [[ $? -ne 0 ]]; then
            break
        fi
        
        case "$key" in
            $'\x1b')
                local key2=""
                IFS= read -rsn1 key2 < /dev/tty
                case "$key2" in
                    '[')
                        local key3=""
                        IFS= read -rsn1 key3 < /dev/tty
                        case "$key3" in
                            'A')
                                ((cursor--))
                                [[ $cursor -lt 0 ]] && cursor=$((num_items - 1))
                                ;;
                            'B')
                                ((cursor++))
                                [[ $cursor -ge $num_items ]] && cursor=0
                                ;;
                        esac
                        ;;
                esac
                ;;
            '')
                break
                ;;
        esac
        
        tput rc 2>/dev/null || true
        tput cuu $num_items 2>/dev/null || true
    done
    
    tput cnorm 2>/dev/null || true
    return $cursor
}

select_language() {
    if [[ -n "$LANG_OVERRIDE" ]]; then
        case "$LANG_OVERRIDE" in
            zh|zh-CN) echo "zh-CN" ;;
            *) echo "en-US" ;;
        esac
        return
    fi
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║         Quickstart-PC v0.14.0          ║"
    echo "╚════════════════════════════════════════╝"
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
    LANG_BANNER="Quickstart-PC v0.14.0 - 快速配置新电脑软件环境"
    LANG_SELECT_PROFILES="选择安装套餐"
    LANG_SELECT_SOFTWARE="选择要安装的软件"
    LANG_NAVIGATE="↑↓ 移动 | 空格 选择 | 回车 确认"
    LANG_SELECTED="[✓] "
    LANG_NOT_SELECTED="[  ] "
    LANG_INSTALLED="(已安装)"
    LANG_SELECT_ALL="全选"
    LANG_CONFIRM="确认安装？[Y/n]"
    LANG_CANCELLED="已取消"
    LANG_INSTALLING="安装"
    LANG_DONE="安装完成"
    LANG_SKIP="跳过"
    LANG_DEV_MODE="开发者模式"
    LANG_FAKE_MODE="假装安装模式"
else
    LANG_BANNER="Quickstart-PC v0.14.0 - Quick setup for new computers"
    LANG_SELECT_PROFILES="Select Installation Profiles"
    LANG_SELECT_SOFTWARE="Select Software to Install"
    LANG_NAVIGATE="↑↓ Move | SPACE Select | ENTER Confirm"
    LANG_SELECTED="[✓] "
    LANG_NOT_SELECTED="[  ] "
    LANG_INSTALLED="(installed)"
    LANG_SELECT_ALL="Select All"
    LANG_CONFIRM="Confirm installation? [Y/n]"
    LANG_CANCELLED="Cancelled"
    LANG_INSTALLING="Installing"
    LANG_DONE="Installation Complete"
    LANG_SKIP="Skipped"
    LANG_DEV_MODE="Dev mode"
    LANG_FAKE_MODE="Fake install mode"
fi

# Profile data
PROFILE_KEYS=(recommended ai developer)
PROFILE_NAME_0="⭐ 推荐套餐/Recommended"
PROFILE_DESC_0="综合均衡/Balanced"
PROFILE_NAME_1="🤖 AI 赋能/AI Powered"
PROFILE_DESC_1="AI 工具/AI tools"
PROFILE_NAME_2="💻 开发者/Developer"
PROFILE_DESC_2="开发工具/Dev tools"

# Profile to software mapping
PROFILE_SW_0="chrome vscode git nodejs python wps vlc"
PROFILE_SW_1="cursor ollama"
PROFILE_SW_2="vscode git nodejs python"

# Software data (index based)
SW_KEYS=(chrome vscode git nodejs python cursor ollama wps vlc ffmpeg)
SW_NAME_0="Chrome" SW_DESC_0="浏览器/Browser"
SW_NAME_1="VS Code" SW_DESC_1="代码编辑器/Editor"
SW_NAME_2="Git" SW_DESC_2="版本控制/Version control"
SW_NAME_3="Node.js" SW_DESC_3="JavaScript 运行时"
SW_NAME_4="Python" SW_DESC_4="Python 语言"
SW_NAME_5="Cursor" SW_DESC_5="AI 编辑器/AI editor"
SW_NAME_6="Ollama" SW_DESC_6="本地 LLM/Local LLM"
SW_NAME_7="WPS Office" SW_DESC_7="办公套件/Office"
SW_NAME_8="VLC" SW_DESC_8="播放器/Player"
SW_NAME_9="FFmpeg" SW_DESC_9="音视频工具/Media"

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
SW_LINUX_5="echo Download from cursor.sh"

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

# Check commands
SW_CHECK_MAC_0="ls /Applications/Google\\ Chrome.app 2>/dev/null"
SW_CHECK_MAC_1="ls /Applications/Visual\\ Studio\\ Code.app 2>/dev/null"
SW_CHECK_MAC_2="which git"
SW_CHECK_MAC_3="which node"
SW_CHECK_MAC_4="which python3"
SW_CHECK_MAC_5="ls /Applications/Cursor.app 2>/dev/null"
SW_CHECK_MAC_6="which ollama"
SW_CHECK_MAC_7="ls /Applications/WPS\\ Office.app 2>/dev/null"
SW_CHECK_MAC_8="ls /Applications/VLC.app 2>/dev/null"
SW_CHECK_MAC_9="which ffmpeg"

get_sw_index() {
    local key=$1
    for ((i=0; i<${#SW_KEYS[@]}; i++)); do
        if [[ "${SW_KEYS[$i]}" == "$key" ]]; then
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

get_sw_check() {
    local idx=$1
    local os=$2
    eval "echo \$SW_CHECK_${os}_$idx"
}

is_installed() {
    local key=$1
    local os=$2
    local idx=$(get_sw_index "$key")
    [[ $idx -eq -1 ]] && return 1
    
    local check_cmd=$(get_sw_check $idx "$os")
    [[ -z "$check_cmd" ]] && return 1
    eval "$check_cmd" &>/dev/null
}

detect_os() {
    case "$OSTYPE" in
        msys*|mingw*|cygwin*|win*) echo "WIN" ;;
        darwin*) echo "MAC" ;;
        linux*) echo "LINUX" ;;
        *) echo "MAC" ;;
    esac
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
ORANGE='\033[38;5;208m'
GRAY='\033[0;90m'
NC='\033[0m'
REVERSE='\033[7m'

trap 'log_error "Error on line $LINENO"; exit 1' ERR

# 调试模式（可通过 --debug 参数启用）
DEBUG_MODE=false

debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${GRAY}[DEBUG] $*${NC}" >&2
    fi
}

# 捕获并报告错误
handle_error() {
    local exit_code=$?
    local line_no=$1
    log_error "脚本错误：行 $line_no，退出码 $exit_code"
    log_error "最后执行的命令可能有问题"
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

log_info() { echo -e "${CYAN}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*" >&2; }
log_step() { echo -e "${CYAN}[→]${NC} $*"; }
log_header() {
    echo ""
    echo "========================================"
    echo "  $*"
    echo "========================================"
}

SELECTED_SW=()

show_profile_menu() {
    debug_log "进入 show_profile_menu"
    local num=${#PROFILE_KEYS[@]}
    local -a names=()
    
    for ((i=0; i<num; i++)); do
        local pname=$(eval "echo \$PROFILE_NAME_$i")
        local pdesc=$(eval "echo \$PROFILE_DESC_$i")
        names+=("$pname - $pdesc")
    done
    
    debug_log "配置文件数量: $num"
    
    tput civis 2>/dev/null || true
    
    echo "" >&2
    log_header "$LANG_SELECT_PROFILES" >&2
    echo "" >&2
    echo -e "  ${CYAN}$LANG_NAVIGATE${NC}" >&2
    echo "" >&2
    
    local cursor=0
    local running=true
    
    while [[ "$running" == "true" ]]; do
        for ((i=0; i<num; i++)); do
            if [[ $i -eq $cursor ]]; then
                echo -e "  ${REVERSE} ▶ ${names[$i]}${NC}" >&2
            else
                echo -e "    ${names[$i]}" >&2
            fi
        done
        
        local key=""
        IFS= read -rsn1 key < /dev/tty
        if [[ $? -ne 0 ]]; then
            debug_log "读取按键失败"
            break
        fi
        
        debug_log "按键: $(printf '%q' "$key")"
        
        case "$key" in
            $'\x1b')
                local key2=""
                IFS= read -rsn1 key2 < /dev/tty
                case "$key2" in
                    '[')
                        local key3=""
                        IFS= read -rsn1 key3 < /dev/tty
                        case "$key3" in
                            'A')
                                ((cursor--))
                                [[ $cursor -lt 0 ]] && cursor=$((num - 1))
                                debug_log "上箭头，新光标: $cursor"
                                ;;
                            'B')
                                ((cursor++))
                                [[ $cursor -ge $num ]] && cursor=0
                                debug_log "下箭头，新光标: $cursor"
                                ;;
                        esac
                        ;;
                esac
                ;;
            '')
                debug_log "回车，选择: $cursor"
                running=false
                ;;
        esac
        
        for ((i=0; i<num; i++)); do
            printf '\033[A\033[2K' >&2
        done
    done
    
    tput cnorm 2>/dev/null || true
    
    debug_log "返回选择: $cursor"
    echo "$cursor"
}

show_software_menu() {
    debug_log "进入 show_software_menu"
    local os=$1
    local profile_idx=$2
    
    debug_log "操作系统: $os, 配置文件索引: $profile_idx"
    
    local sw_list=$(eval "echo \$PROFILE_SW_$profile_idx")
    local -a sw_keys=($sw_list)
    local num_sw=${#sw_keys[@]}
    
    debug_log "软件列表: $sw_list, 数量: $num_sw"
    
    local -a names=()
    local -a checked=()
    
    names=("${ORANGE}${LANG_SELECT_ALL}${NC}")
    checked=(0)
    
    for key in "${sw_keys[@]}"; do
        local idx=$(get_sw_index "$key")
        local name=$(get_sw_name $idx)
        local desc=$(get_sw_desc $idx)
        
        if is_installed "$key" "$os"; then
            names+=("${GRAY}${name} - ${desc} ${LANG_INSTALLED}${NC}")
        else
            names+=("${name} - ${desc}")
        fi
        checked+=(0)
    done
    
    local num_items=${#names[@]}
    local cursor=0
    local running=true
    
    debug_log "菜单项数量: $num_items"
    
    tput civis 2>/dev/null || true
    
    echo "" >&2
    log_header "$LANG_SELECT_SOFTWARE" >&2
    echo "" >&2
    echo -e "  ${CYAN}$LANG_NAVIGATE${NC}" >&2
    echo "" >&2
    
    while [[ "$running" == "true" ]]; do
        for ((i=0; i<num_items; i++)); do
            if [[ $i -eq $cursor ]]; then
                if [[ ${checked[$i]} -eq 1 ]]; then
                    echo -e "  ${REVERSE}${GREEN}${LANG_SELECTED}${NC}${REVERSE}${names[$i]}${NC}" >&2
                else
                    echo -e "  ${REVERSE}${LANG_NOT_SELECTED}${names[$i]}${NC}" >&2
                fi
            else
                if [[ ${checked[$i]} -eq 1 ]]; then
                    echo -e "  ${GREEN}${LANG_SELECTED}${NC}${names[$i]}" >&2
                else
                    echo -e "  ${LANG_NOT_SELECTED}${names[$i]}" >&2
                fi
            fi
        done
        
        local key=""
        IFS= read -rsn1 key < /dev/tty
        if [[ $? -ne 0 ]]; then
            debug_log "读取按键失败"
            break
        fi
        
        debug_log "按键: $(printf '%q' "$key")"
        
        case "$key" in
            $'\x1b')
                local key2=""
                IFS= read -rsn1 key2 < /dev/tty
                case "$key2" in
                    '[')
                        local key3=""
                        IFS= read -rsn1 key3 < /dev/tty
                        case "$key3" in
                            'A')
                                ((cursor--))
                                [[ $cursor -lt 0 ]] && cursor=$((num_items - 1))
                                debug_log "上箭头，新光标: $cursor"
                                ;;
                            'B')
                                ((cursor++))
                                [[ $cursor -ge $num_items ]] && cursor=0
                                debug_log "下箭头，新光标: $cursor"
                                ;;
                        esac
                        ;;
                esac
                ;;
            ' ')
                if [[ $cursor -eq 0 ]]; then
                    local new_state=$((1 - checked[0]))
                    for ((i=0; i<num_items; i++)); do
                        checked[$i]=$new_state
                    done
                    debug_log "全选切换: $new_state"
                else
                    checked[$cursor]=$((1 - checked[$cursor]))
                    debug_log "单选切换: $cursor -> ${checked[$cursor]}"
                fi
                ;;
            '')
                debug_log "回车确认"
                running=false
                ;;
        esac
        
        for ((i=0; i<num_items; i++)); do
            printf '\033[A\033[2K' >&2
        done
    done
    
    tput cnorm 2>/dev/null || true
    
    SELECTED_SW=()
    for ((i=1; i<num_items; i++)); do
        [[ ${checked[$i]} -eq 1 ]] && SELECTED_SW+=("${sw_keys[$((i-1))]}")
    done
    
    debug_log "选择的软件: ${SELECTED_SW[*]}"
}

main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║         Quickstart-PC v0.14.0          ║"
    echo "║    $LANG_BANNER"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    [[ "$DEV_MODE" == "true" ]] && echo -e "${YELLOW}[!] $LANG_DEV_MODE${NC}" && echo ""
    [[ "$FAKE_INSTALL" == "true" ]] && echo -e "${YELLOW}[!] $LANG_FAKE_MODE${NC}" && echo ""
    
    local os=$(detect_os)
    log_info "OS: $os"
    
    local profile_idx=$(show_profile_menu)
    
    show_software_menu "$os" "$profile_idx"
    
    [[ ${#SELECTED_SW[@]} -eq 0 ]] && echo "No software selected" && exit 0
    
    echo ""
    log_info "Selected: ${SELECTED_SW[*]}"
    echo ""
    
    [[ "$DEV_MODE" == "true" ]] && exit 0
    
    read -p "$LANG_CONFIRM " confirm < /dev/tty
    [[ "$confirm" =~ ^[Nn] ]] && echo "$LANG_CANCELLED" && exit 0
    
    log_header "$LANG_INSTALLING"
    
    local total=${#SELECTED_SW[@]}
    local current=0
    local skipped=0
    
    for sw in "${SELECTED_SW[@]}"; do
        ((current++))
        local idx=$(get_sw_index "$sw")
        local name=$(get_sw_name $idx)
        
        printf "\r[%3d%%] %s %s" "$((current * 100 / total))" "$LANG_INSTALLING" "$name"
        
        if is_installed "$sw" "$os"; then
            ((skipped++))
            continue
        fi
        
        local cmd=$(get_sw_cmd $idx "$os")
        
        if [[ "$FAKE_INSTALL" == "true" ]]; then
            echo ""
            echo -e "  ${CYAN}→ $cmd${NC}"
            sleep 1
            echo -e "  ${GREEN}[✓] $name (simulated)${NC}"
        else
            eval "$cmd" &>/dev/null && echo -e "\n  ${GREEN}[✓] $name${NC}" || echo -e "\n  ${RED}[✗] $name failed${NC}"
        fi
    done
    
    echo ""
    log_header "$LANG_DONE"
    echo -e "${GREEN}[✓] Total: $total, Skipped: $skipped${NC}"
}

trap 'tput cnorm 2>/dev/null || true' EXIT
main "$@"
