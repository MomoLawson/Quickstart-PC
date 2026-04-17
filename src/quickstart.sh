#!/usr/bin/env bash

# 只在交互式终端中清屏和隐藏光标
if [[ -t 1 ]]; then
    clear 2>/dev/null || true
    tput civis 2>/dev/null || true
fi

# 默认配置 URL（优先级最高）
DEFAULT_CFG_URL="https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json"

# Supported languages (parallel arrays for bash 3.2 compatibility)
LANG_KEYS=("en-US" "zh-CN" "zh-Hant" "ja" "ko" "de" "fr" "ar" "pt" "it")
LANG_NAMES=("English" "简体中文" "繁體中文" "日本語" "한국어" "Deutsch" "Français" "العربية" "Português" "Italiano")

# Language code mappings (parallel arrays)
MAP_FROM=("en" "en-US" "en_GB" "zh" "zh-CN" "zh_CN" "zh-TW" "zh-Hant" "zh-HK" "zh_TW" "ja" "ja-JP" "ja_JP" "ko" "ko-KR" "ko_KR" "de" "de-DE" "de_AT" "de_CH" "fr" "fr-FR" "fr_CA" "fr_BE" "ar" "ar-SA" "ar-AE" "ar-EG" "pt" "pt-BR" "pt-PT" "it" "it-IT" "it_CH")
MAP_TO=("en-US" "en-US" "en-US" "zh-CN" "zh-CN" "zh-CN" "zh-CN" "zh-Hant" "zh-Hant" "zh-Hant" "ja" "ja" "ja" "ko" "ko" "ko" "de" "de" "de" "de" "fr" "fr" "fr" "fr" "ar" "ar" "ar" "ar" "pt" "pt" "pt" "it" "it" "it")

lang_lookup() {
    local key="$1"
    for ((i=0; i<${#MAP_FROM[@]}; i++)); do
        if [[ "${MAP_FROM[$i]}" == "$key" ]]; then echo "${MAP_TO[$i]}"; return; fi
    done
}

lang_name() {
    local key="$1"
    for ((i=0; i<${#LANG_KEYS[@]}; i++)); do
        if [[ "${LANG_KEYS[$i]}" == "$key" ]]; then echo "${LANG_NAMES[$i]}"; return; fi
    done
}


load_language_strings() {
    local lang="$1"
    local lang_file=""
    
    # 1. Try local lang path if --local-lang is set
    if [[ -n "$LOCAL_LANG_PATH" ]]; then
        lang_file="$LOCAL_LANG_PATH/${lang}.sh"
        if [[ -f "$lang_file" ]]; then
            source "$lang_file"
            return 0
        fi
    fi
    
    # 2. Try embedded lang files (for local/offline use with --local-lang not set but lang/ dir exists)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    lang_file="$script_dir/lang/${lang}.sh"
    if [[ -f "$lang_file" ]]; then
        source "$lang_file"
        return 0
    fi
    
    # 3. Try remote loading from GitHub
    local remote_url="https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/dist/lang/${lang}.sh"
    local tmp_lang
    tmp_lang=$(mktemp)
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL --connect-timeout 5 --max-time 10 "$remote_url" -o "$tmp_lang" 2>/dev/null; then
            source "$tmp_lang"
            rm -f "$tmp_lang"
            return 0
        fi
    fi
    rm -f "$tmp_lang"
    
    # 4. Fallback: if requested lang is not en-US, try en-US
    if [[ "$lang" != "en-US" ]]; then
        load_language_strings "en-US"
        return $?
    fi
    
    # 5. Last resort: embedded minimal English strings
    LANG_BANNER_TITLE="Quickstart-PC v__VERSION__"
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
    LANG_NAVIGATE="Up/Down: Move | Enter: Confirm"
    LANG_NAVIGATE_MULTI="Up/Down: Move | Space: Select | Enter: Confirm"
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
LANG_DRY_RUN_MODE="Preview mode: Show process without installing"
LANG_DRY_RUN_INSTALLING="Simulating install"
    LANG_JQ_DETECTED="jq detected, using jq"
    LANG_JQ_NOT_FOUND="jq not found, installing..."
    LANG_JQ_INSTALLED="jq installed successfully"
    LANG_JQ_INSTALL_FAILED="jq installation failed, trying fallback..."
    LANG_USING_PYTHON3="Using python3 as fallback parser"
    LANG_NO_JSON_PARSER="No JSON parser available (jq/python3)"
    LANG_CHECKING_INSTALLATION="Checking installation status..."
    LANG_SKIPPING_INSTALLED="Already installed, skipping"
    LANG_ALL_INSTALLED="All software already installed, nothing to do"
    LANG_ASK_CONTINUE="Installation complete. Continue installing other profiles?"
    LANG_CONTINUE="Continue"
    LANG_EXIT="Exit"
    LANG_TITLE_SELECT_PROFILE="Select Profile"
    LANG_TITLE_SELECT_SOFTWARE="Select Software"
    LANG_TITLE_INSTALLING="Installing"
    LANG_TITLE_ASK_CONTINUE="Continue Installing?"
    LANG_LANG_PROMPT="Please select language"
    LANG_LANG_MENU_ENTER="Confirm"
    LANG_LANG_MENU_SPACE="Select"
    LANG_NONINTERACTIVE_ERROR="Non-interactive mode requires --profile parameter"
    LANG_PROFILE_NOT_FOUND="Profile not found"
    LANG_NPM_NOT_FOUND="npm not found, installing..."
    LANG_WINGET_NOT_FOUND="winget not found, cannot auto-install npm"
    LANG_NPM_AUTO="npm"
    HELP_TITLE="Quickstart-PC - One-click computer setup"
    HELP_USAGE="Usage: quickstart.sh [OPTIONS]"
    HELP_OPTIONS="  --help    Show this help message"
}

show_help() {
    # Get language from help argument
    local help_lang="en-US"
    case "$LANG_FOR_HELP" in
        zh|zh-CN|zh_CN) help_lang="zh-CN" ;;
        zh-Hant|zh-TW|zh-HK|zh_TW) help_lang="zh-Hant" ;;
        ja|ja-JP|ja_JP) help_lang="ja" ;;
        ko|ko-KR|ko_KR) help_lang="ko" ;;
        de|de-DE|de_AT|de_CH) help_lang="de" ;;
        fr|fr-FR|fr_CA|fr_BE) help_lang="fr" ;;
        ar|ar-SA|ar-AE|ar-EG) help_lang="ar" ;;
        pt|pt-BR|pt-PT) help_lang="pt" ;;
        it|it-IT|it_CH) help_lang="it" ;;
    esac
    
    load_language_strings "$help_lang"
    
    cat << HELPEOF
$HELP_TITLE

$HELP_USAGE

$HELP_OPTIONS
HELPEOF
    exit 0
}

LANG_FOR_HELP="en"
args=("$@")
for i in "${!args[@]}"; do
    if [[ "${args[$i]}" == "--lang" ]] && [[ -n "${args[$((i+1))]}" ]]; then
        LANG_FOR_HELP="${args[$((i+1))]}"
        break
    fi
done


DEV_MODE=false
DRY_RUN=false
DOCTOR=false
AUTO_YES=false
VERBOSE=false
LOG_FILE=""
EXPORT_PLAN=""
CUSTOM_MODE=false
RETRY_FAILED=false
LIST_SOFTWARE=false
SHOW_SOFTWARE=""
SEARCH_KEYWORD=""
VALIDATE=false
REPORT_JSON=""
REPORT_TXT=""
LIST_PROFILES=false
SHOW_PROFILE=""
SKIP_SW=()
ONLY_SW=()
FAIL_FAST=false
PROFILE_KEY=""
NON_INTERACTIVE=false
DEBUG=false
LANG_OVERRIDE=""
LOCAL_LANG_PATH=""
CFG_PATH=""
CFG_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev) DEV_MODE=true; shift ;;
--dry-run) DRY_RUN=true; shift ;;
--doctor) DOCTOR=true; shift ;;
        --yes|-y) AUTO_YES=true; shift ;;
        --verbose|-v) VERBOSE=true; shift ;;
        --log-file) LOG_FILE="$2"; shift 2 ;;
        --export-plan) EXPORT_PLAN="$2"; shift 2 ;;
        --custom) CUSTOM_MODE=true; shift ;;
        --retry-failed) RETRY_FAILED=true; shift ;;
        --list-software) LIST_SOFTWARE=true; shift ;;
        --show-software) SHOW_SOFTWARE="$2"; shift 2 ;;
        --search) SEARCH_KEYWORD="$2"; shift 2 ;;
        --validate) VALIDATE=true; shift ;;
        --report-json) REPORT_JSON="$2"; shift 2 ;;
        --report-txt) REPORT_TXT="$2"; shift 2 ;;
        --list-profiles) LIST_PROFILES=true; shift ;;
        --show-profile) SHOW_PROFILE="$2"; shift 2 ;;
        --skip) SKIP_SW+=("$2"); shift 2 ;;
        --only) ONLY_SW+=("$2"); shift 2 ;;
        --fail-fast) FAIL_FAST=true; shift ;;
        --profile) PROFILE_KEY="$2"; shift 2 ;;
        --non-interactive) NON_INTERACTIVE=true; shift ;;
        --debug) DEBUG=true; shift ;;
        --lang) LANG_OVERRIDE="$2"; shift 2 ;;
        --local-lang) LOCAL_LANG_PATH="$2"; shift 2 ;;
        --cfg-path) CFG_PATH="$2"; shift 2 ;;
        --cfg-url) CFG_URL="$2"; shift 2 ;;
        --help|-h) show_help ;;
        *) shift ;;
    esac
done

# ============================================
# Language System Functions
# ============================================

# Detect language from system environment
detect_system_language() {
    local lang=""
    
    # 1. Check LANG_OVERRIDE from command line
    if [[ -n "$LANG_OVERRIDE" ]]; then
        local mapped="$(lang_lookup "$LANG_OVERRIDE")"
        if [[ -n "$mapped" ]]; then
            echo "$mapped"
            return
        fi
    fi
    
    # 2. Check LC_ALL, LC_MESSAGES, LANG environment variables (in order of priority)
    for var in LC_ALL LC_MESSAGES LANG; do
        if [[ -n "${!var}" ]]; then
            lang="${!var}"
            break
        fi
    done
    
    if [[ -n "$lang" ]]; then
        # Extract language part (e.g., "en_US.UTF-8" -> "en_US")
        local lang_code="${lang%%.*}"
        lang_code="${lang_code%%@*}"
        
        local mapped="$(lang_lookup "$lang_code")"
        if [[ -n "$mapped" ]]; then
            echo "$mapped"
            return
        fi
    fi
    
    # 3. Check LANGUAGE environment variable (colon-separated list)
    if [[ -n "$LANGUAGE" ]]; then
        local first_lang="${LANGUAGE%%:*}"
        local mapped="$(lang_lookup "$first_lang")"
        if [[ -n "$mapped" ]]; then
            echo "$mapped"
            return
        fi
    fi
    
    # 4. Try to detect from system locale (macOS)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        local system_lang=$(defaults read -g AppleLanguages 2>/dev/null | head -1 | tr -d ' "\n' | cut -c1-5)
        if [[ -n "$system_lang" ]]; then
            local mapped="$(lang_lookup "$system_lang")"
            if [[ -n "$mapped" ]]; then
                echo "$mapped"
                return
            fi
        fi
    fi
    
    # 5. Default to English
    echo "en-US"
}

# Load language strings function



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

# --list-software 在语言选择之前处理
if [[ "$LIST_SOFTWARE" == "true" ]]; then
    if ! command -v jq &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install jq 2>/dev/null
        else
            sudo apt install -y jq 2>/dev/null
        fi
    fi
    
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    if curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
        echo "Available software:"
        echo ""
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            sw_name=$(jq -r ".software[\"$key\"].name // \"$key\"" "$CONFIG_FILE")
            sw_desc=$(jq -r ".software[\"$key\"].desc // \"\"" "$CONFIG_FILE")
            sw_tier=$(jq -r ".software[\"$key\"].tier // \"partial\"" "$CONFIG_FILE")
            echo "  $key - $sw_name: $sw_desc [$sw_tier]"
        done < <(jq -r '.software | keys[]' "$CONFIG_FILE")
        echo ""
    else
        echo "[ERROR] Failed to load configuration"
    fi
    
    rm -f "$CONFIG_FILE" 2>/dev/null
    exit 0
fi

# --show-software 在语言选择之前处理
if [[ -n "$SHOW_SOFTWARE" ]]; then
    if ! command -v jq &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install jq 2>/dev/null
        else
            sudo apt install -y jq 2>/dev/null
        fi
    fi
    
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    if curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
        sw_name=$(jq -r ".software[\"$SHOW_SOFTWARE\"].name // \"\"" "$CONFIG_FILE")
        sw_desc=$(jq -r ".software[\"$SHOW_SOFTWARE\"].desc // \"\"" "$CONFIG_FILE")
        
        if [[ -z "$sw_name" ]]; then
            echo "[ERROR] Software '$SHOW_SOFTWARE' not found"
            rm -f "$CONFIG_FILE" 2>/dev/null
            exit 1
        fi
        
        echo ""
        echo "Software: $sw_name"
        echo "Description: $sw_desc"
        
        sw_tier=$(jq -r ".software[\"$SHOW_SOFTWARE\"].tier // \"partial\"" "$CONFIG_FILE")
        echo "Status: $sw_tier"
        
        echo ""
        echo "Install commands:"
        
        for os_field in win mac linux linux_dnf linux_pacman; do
            cmd=$(jq -r ".software[\"$SHOW_SOFTWARE\"].$os_field // \"\"" "$CONFIG_FILE")
            if [[ -n "$cmd" ]]; then
                echo "  $os_field: $cmd"
            fi
        done
        echo ""
    else
        echo "[ERROR] Failed to load configuration"
    fi
    
    rm -f "$CONFIG_FILE" 2>/dev/null
    exit 0
fi

# --search 在语言选择之前处理
if [[ -n "$SEARCH_KEYWORD" ]]; then
    if ! command -v jq &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install jq 2>/dev/null
        else
            sudo apt install -y jq 2>/dev/null
        fi
    fi
    
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    if curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
        echo "Search results for '$SEARCH_KEYWORD':"
        echo ""
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            sw_name=$(jq -r ".software[\"$key\"].name // \"$key\"" "$CONFIG_FILE")
            sw_desc=$(jq -r ".software[\"$key\"].desc // \"\"" "$CONFIG_FILE")
            if echo "$key $sw_name $sw_desc" | grep -qi "$SEARCH_KEYWORD"; then
                echo "  $key - $sw_name: $sw_desc"
            fi
        done < <(jq -r '.software | keys[]' "$CONFIG_FILE")
        echo ""
    else
        echo "[ERROR] Failed to load configuration"
    fi
    
rm -f "$CONFIG_FILE" 2>/dev/null
exit 0
fi

# --doctor (QC Doctor) 在语言选择之前处理
if [[ "$DOCTOR" == "true" ]]; then
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    🔧 QC Doctor                            ║"
echo "║         Quickstart-PC Environment Diagnostics              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

passed=0
warnings=0
failed=0

# 1. 系统检测
echo "━━━ System Information ━━━"
os_name=$(uname -s)
os_arch=$(uname -m)
echo "  OS: $os_name"
echo "  Arch: $os_arch"
if [[ "$os_name" == "Darwin" ]]; then
echo "  macOS Version: $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
elif [[ "$os_name" == "Linux" ]]; then
distro=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
echo "  Distro: ${distro:-Unknown}"
fi
echo ""
((passed++))

# 2. 包管理器检测
echo "━━━ Package Manager ━━━"
case "$os_name" in
Darwin)
if command -v brew &>/dev/null; then
brew_ver=$(brew --version 2>/dev/null | head -1)
echo "  [✓] Homebrew: $brew_ver"
((passed++))
else
echo "  [✗] Homebrew not found"
echo "      → Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
((failed++))
fi
;;
Linux)
if command -v apt &>/dev/null; then
echo "  [✓] apt (Debian/Ubuntu)"
((passed++))
elif command -v dnf &>/dev/null; then
echo "  [✓] dnf (Fedora/RHEL)"
((passed++))
elif command -v pacman &>/dev/null; then
echo "  [✓] pacman (Arch)"
((passed++))
else
echo "  [✗] No supported package manager found"
((failed++))
fi
;;
MINGW*|MSYS*|CYGWIN*)
if command -v winget &>/dev/null; then
echo "  [✓] winget"
((passed++))
else
echo "  [!] winget not found (optional on Windows)"
((warnings++))
fi
;;
esac
echo ""

# 3. 必要工具检测
echo "━━━ Required Tools ━━━"
if command -v jq &>/dev/null; then
jq_ver=$(jq --version 2>/dev/null)
echo "  [✓] jq: $jq_ver"
((passed++))
else
echo "  [✗] jq not found (JSON parser required)"
echo "      → Install: brew install jq (macOS) or apt install jq (Linux)"
((failed++))
fi

if command -v curl &>/dev/null; then
curl_ver=$(curl --version 2>/dev/null | head -1)
echo "  [✓] curl: available"
((passed++))
else
echo "  [✗] curl not found"
((failed++))
fi
echo ""

# 4. 网络连接检测
echo "━━━ Network Connectivity ━━━"
if curl -fsSL --connect-timeout 5 --max-time 10 "https://raw.githubusercontent.com" &>/dev/null; then
echo "  [✓] GitHub raw content: reachable"
((passed++))
else
echo "  [✗] GitHub raw content: unreachable"
echo "      → Check network connection or proxy settings"
((failed++))
fi

if curl -fsSL --connect-timeout 5 --max-time 10 "https://github.com" &>/dev/null; then
echo "  [✓] GitHub: reachable"
((passed++))
else
echo "  [!] GitHub: unreachable (may be temporary)"
((warnings++))
fi
echo ""

# 5. 磁盘空间检测
echo "━━━ Disk Space ━━━"
if [[ "$os_name" == "Darwin" ]]; then
free_space=$(df -g /tmp 2>/dev/null | tail -1 | awk '{print $4}')
if [[ "$free_space" -gt 1 ]]; then
echo "  [✓] Available: ${free_space}GB"
((passed++))
else
echo "  [!] Available: ${free_space}GB (recommend >1GB)"
((warnings++))
fi
elif [[ "$os_name" == "Linux" ]]; then
free_space=$(df -BG /tmp 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
if [[ "$free_space" -gt 1 ]]; then
echo "  [✓] Available: ${free_space}GB"
((passed++))
else
echo "  [!] Available: ${free_space}GB (recommend >1GB)"
((warnings++))
fi
fi
echo ""

# 6. 临时目录检测
echo "━━━ Temp Directory ━━━"
tmp_dir="/tmp"
if [[ -d "$tmp_dir" && -w "$tmp_dir" ]]; then
echo "  [✓] $tmp_dir: writable"
((passed++))
else
echo "  [✗] $tmp_dir: not writable"
((failed++))
fi
echo ""

# 7. 配置文件检测
echo "━━━ Configuration ━━━"
test_config=$(mktemp /tmp/qc-doctor-config-XXXXXX.json)
if curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$test_config" 2>/dev/null; then
if command -v jq &>/dev/null && jq empty "$test_config" 2>/dev/null; then
profile_count=$(jq '.profiles | length' "$test_config" 2>/dev/null)
sw_count=$(jq '.software | length' "$test_config" 2>/dev/null)
echo "  [✓] profiles.json: valid ($sw_count software, $profile_count profiles)"
((passed++))
else
echo "  [✗] profiles.json: invalid JSON"
((failed++))
fi
rm -f "$test_config"
else
echo "  [!] Could not download profiles.json (network issue?)"
((warnings++))
fi
echo ""

# 总结
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Summary: $passed passed, $warnings warnings, $failed failed"
if [[ $failed -eq 0 ]]; then
echo " Status: ✅ Environment ready for Quickstart-PC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tput cnorm 2>/dev/null || true
exit 0
else
echo " Status: ⚠️  Some issues need attention before installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tput cnorm 2>/dev/null || true
exit 1
fi
fi

# --validate 在语言选择之前处理
if [[ "$VALIDATE" == "true" ]]; then
    if ! command -v jq &>/dev/null; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install jq 2>/dev/null
        else
            sudo apt install -y jq 2>/dev/null
        fi
    fi
    
    CONFIG_FILE=$(mktemp /tmp/quickstart-config-XXXXXX.json)
    if curl -fsSL --connect-timeout 10 --max-time 30 "$DEFAULT_CFG_URL" -o "$CONFIG_FILE" 2>/dev/null; then
        errors=0
        warnings=0
        
        echo "Validating configuration..."
        echo ""
        
        # Check JSON validity
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            echo "[✓] JSON syntax valid"
        else
            echo "[✗] JSON syntax invalid"
            ((errors++))
        fi
        
        # Check profiles structure
        profile_count=$(jq '.profiles | length' "$CONFIG_FILE")
        echo "[✓] Profiles: $profile_count"
        
        # Check software structure
        sw_count=$(jq '.software | length' "$CONFIG_FILE")
        echo "[✓] Software entries: $sw_count"
        
        # Check profile references
        while IFS= read -r pkey; do
            [[ -z "$pkey" ]] && continue
            while IFS= read -r sw; do
                [[ -z "$sw" ]] && continue
                if ! jq -e ".software[\"$sw\"]" "$CONFIG_FILE" &>/dev/null; then
                    echo "[✗] Profile '$pkey' references unknown software '$sw'"
                    ((errors++))
                fi
            done < <(jq -r ".profiles[\"$pkey\"].includes[]?" "$CONFIG_FILE")
        done < <(jq -r '.profiles | keys[]' "$CONFIG_FILE")
        
        # Check software fields
        while IFS= read -r sw; do
            [[ -z "$sw" ]] && continue
            has_platform=false
            for platform in win mac linux linux_dnf linux_pacman; do
                cmd=$(jq -r ".software[\"$sw\"].$platform // \"\"" "$CONFIG_FILE")
                if [[ -n "$cmd" && "$cmd" != "null" ]]; then
                    has_platform=true
                    break
                fi
            done
            if [[ "$has_platform" == "false" ]]; then
                echo "[✗] Software '$sw' has no platform install commands"
                ((errors++))
            fi
            
            # Check tier field
            tier=$(jq -r ".software[\"$sw\"].tier // \"\"" "$CONFIG_FILE")
            if [[ -n "$tier" && "$tier" != "stable" && "$tier" != "partial" && "$tier" != "experimental" && "$tier" != "deprecated" ]]; then
                echo "[✗] Software '$sw' has invalid tier: '$tier'"
                ((errors++))
            fi
        done < <(jq -r '.software | keys[]' "$CONFIG_FILE")
        
        echo ""
        if [[ $errors -eq 0 ]]; then
            echo "✓ Validation passed ($sw_count software, $profile_count profiles)"
        else
            echo "✗ Validation failed: $errors error(s), $warnings warning(s)"
        fi
    else
        echo "[ERROR] Failed to load configuration"
    fi
    
    rm -f "$CONFIG_FILE" 2>/dev/null
    exit 0
fi

# 日志系统
log_to_file() {
    [[ -n "$LOG_FILE" ]] && echo "$*" >> "$LOG_FILE"
    return 0
}

debug_log() {
    [[ "$DEBUG" == "true" ]] && echo -e "\033[0;90m[DEBUG] $*\033[0m" >&2
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

# 设置终端窗口标题
set_title() {
    printf '\033]0;%s\007' "$1"
}

# 语言分割函数：返回对应语言的部分
lang_text() {
    local text="$1"
    if [[ "$DETECTED_LANG" == "zh-CN" ]]; then
        echo "${text%%/*}"
    else
        echo "${text##*/}"
    fi
}

# JSON 解析抽象层
JSON_PARSER=""

ensure_json_parser() {
    if command -v jq &>/dev/null; then
        log_info "$LANG_JQ_DETECTED"
        JSON_PARSER="jq"
        return 0
    fi
    
    log_info "$LANG_JQ_NOT_FOUND"
    case $(detect_os) in
        macos) brew install jq ;;
        linux) sudo apt install -y jq ;;
    esac
    
    if command -v jq &>/dev/null; then
        log_info "$LANG_JQ_INSTALLED"
        JSON_PARSER="jq"
        return 0
    fi
    
    log_warn "$LANG_JQ_INSTALL_FAILED"
    if command -v python3 &>/dev/null; then
        log_info "$LANG_USING_PYTHON3"
        JSON_PARSER="python3"
        return 0
    fi
    
    log_error "$LANG_NO_JSON_PARSER"
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
		# recommended profile 始终排在最前面
		jq -r 'if .profiles | has("recommended") then "recommended" end, (.profiles | keys[] | select(. != "recommended"))' "$json_file" 2>/dev/null
	else
		python3 -c "
import json
data = json.load(open('$json_file'))
if 'recommended' in data['profiles']:
    print('recommended')
for k in data['profiles'].keys():
    if k != 'recommended':
        print(k)
" 2>/dev/null
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
    local raw
    if [[ "$JSON_PARSER" == "jq" ]]; then
        raw=$(jq -r ".profiles[\"$key\"].$field // \"\"" "$json_file" 2>/dev/null)
    else
        raw=$(python3 -c "import json; print(json.load(open('$json_file'))['profiles'].get('$key',{}).get('$field',''))" 2>/dev/null)
    fi
    lang_text "$raw"
}

json_get_software_field() {
    local json_file=$1
    local key=$2
    local field=$3
    local raw
    if [[ "$JSON_PARSER" == "jq" ]]; then
        raw=$(jq -r ".software[\"$key\"].$field // \"\"" "$json_file" 2>/dev/null)
    else
        raw=$(python3 -c "import json; print(json.load(open('$json_file'))['software'].get('$key',{}).get('$field',''))" 2>/dev/null)
    fi
    # 只对 name/desc 等需要语言分割的字段使用 lang_text
    # check_mac/check_win/check_linux/mac/win/linux 等命令字段直接返回
    case "$field" in
        name|desc) lang_text "$raw" ;;
        *) echo "$raw" ;;
    esac
}

is_installed() {
    local json_file=$1
    local os=$2
    local key=$3
    local check_field
    
    case "$os" in
        macos) check_field="check_mac" ;;
        windows) check_field="check_win" ;;
        linux)
            local linux_field=$(get_linux_field "$PKG_MANAGER")
            check_field="check_${linux_field}"
            ;;
        *) return 1 ;;
    esac
    
    local check_cmd
    check_cmd=$(json_get_software_field "$json_file" "$key" "$check_field")
    
    debug_log "is_installed: key=$key os=$os check_field=$check_field cmd=[$check_cmd]"
    
    [[ -z "$check_cmd" ]] && return 1
    
    local result=0
    eval "$check_cmd" &>/dev/null || result=$?
    debug_log "is_installed: key=$key result=$result"
    return $result
}

# 语言选择
TUI_RESULT=""

tui_interactive_select() {
    local -a items=("$@")
    local num_items=${#items[@]}
    local cursor=0
    local debug_log="/tmp/quickstart-tui-debug.log"
    
    echo "=== TUI Start: num_items=$num_items ===" > "$debug_log"
    
    tput civis 2>/dev/null || true
    stty -echo 2>/dev/null
    
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
        
        local key=""
        IFS= read -rsn1 key < /dev/tty
        local key_code=$(printf '%d' "'$key" 2>/dev/null || echo 0)
        
        echo "DEBUG: key='$key' key_code=$key_code" >> "$debug_log"
        
        case $key_code in
            27)
                IFS= read -rsn2 key < /dev/tty
                case "$key" in
                    '[A'|'OA') ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((num_items - 1)) ;;
                    '[B'|'OB') ((cursor++)); [[ $cursor -ge $num_items ]] && cursor=0 ;;
                esac
                ;;
            10|13|0) break ;;
        esac
    done
    
    echo "DEBUG: final cursor=$cursor" >> "$debug_log"
    tput cnorm 2>/dev/null || true
    stty echo 2>/dev/null
    TUI_RESULT=$cursor
    return $cursor
}

select_language() {
    # Check for language override first
    if [[ -n "$LANG_OVERRIDE" ]]; then
        local mapped="$(lang_lookup "$LANG_OVERRIDE")"
        if [[ -n "$mapped" ]]; then
            echo "$mapped"
            return
        fi
        # Check if override is a supported language directly
        if [[ -n "$(lang_name "$LANG_OVERRIDE")" ]]; then
            echo "$LANG_OVERRIDE"
            return
        fi
        echo "en-US"
        return
    fi
    
    # All display output redirects to stderr, only return value goes to stdout
    echo "" >&2
    printf "\033[0;34m╔══════════════════════════════════════╗\n" >&2
    printf "\033[0;34m║  ██████╗ ███████╗██████╗  ██████╗    ║\n" >&2
    printf "\033[0;34m║ ██╔═══██╗██╔════╝██╔══██╗██╔════╝    ║\n" >&2
    printf "\033[0;34m║ ██║   ██║███████╗██████╔╝██║         ║\n" >&2
    printf "\033[0;34m║ ██║▄▄ ██║╚════██║██╔═══╝ ██║         ║\n" >&2
    printf "\033[0;34m║ ╚██████╔╝███████║██║     ╚██████╗    ║\n" >&2
    printf "\033[0;34m║  ╚══▀▀═╝ ╚══════╝╚═╝      ╚═════╝    ║\n" >&2
    printf "\033[0;34m║            Quickstart-PC             ║\n" >&2
    printf "\033[0;34m╚══════════════════════════════════════╝\n" >&2
    echo "" >&2
    printf "\033[0m%s:\n" "$LANG_LANG_PROMPT" >&2
    echo "" >&2
    
    # Build language menu items from available.json
    local lang_items=()
    local lang_codes=()
    local avail_file=""
    
    # Try to find available.json
    if [[ -n "$LOCAL_LANG_PATH" ]] && [[ -f "$LOCAL_LANG_PATH/available.json" ]]; then
        avail_file="$LOCAL_LANG_PATH/available.json"
    else
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        avail_file="$script_dir/lang/available.json"
    fi
    
    if [[ -f "$avail_file" ]]; then
        # Try jq first, fallback to python3
        local json_output=""
        if command -v jq &>/dev/null; then
            json_output=$(jq -r '.languages[]? | "\(.code)|\(.name)"' "$avail_file" 2>/dev/null)
        fi
        if [[ -z "$json_output" ]] && command -v python3 &>/dev/null; then
            json_output=$(python3 -c "
import json
with open('$avail_file') as f:
    data = json.load(f)
for lang in data.get('languages', []):
    print(f\"{lang['code']}|{lang['name']}\")
" 2>/dev/null)
        fi
        if [[ -n "$json_output" ]]; then
            while IFS='|' read -r code name; do
                [[ -z "$code" ]] && continue
                lang_codes+=("$code")
                lang_items+=("$name")
            done <<< "$json_output"
        fi
    fi
    
    # Fallback to hardcoded list if available.json not found
    if [[ ${#lang_codes[@]} -eq 0 ]]; then
        for code in en-US zh-CN zh-Hant ja ko de fr ar pt it; do
            lang_codes+=("$code")
            lang_items+=("$(lang_name "$code")")
        done
    fi
    
    tui_interactive_select "${lang_items[@]}" >&2
    local choice=$?
    
    # Map choice index to language code
    echo "${lang_codes[$choice]}"
}

# Auto-detect system language (for initial detection)
auto_detect_language() {
    local detected=$(detect_system_language)
    echo "$detected"
}

# Initial language detection
DETECTED_LANG=$(auto_detect_language)

# Load strings for detected language
load_language_strings "$DETECTED_LANG"

# Now show language selection menu (allows user to override)
DETECTED_LANG=$(select_language)

# Reload strings for final language
load_language_strings "$DETECTED_LANG"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
ORANGE='\033[38;5;208m'
NC='\033[0m'
BOLD='\033[1m'
REVERSE='\033[7m'
GRAY='\033[0;90m'

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
        linux)
            if command -v apt &>/dev/null; then echo "apt"
            elif command -v dnf &>/dev/null; then echo "dnf"
            elif command -v pacman &>/dev/null; then echo "pacman"
            else echo "none"
            fi
            ;;
    esac
}

# 获取 Linux 安装命令字段名
get_linux_field() {
    local pkg_mgr=$1
    case "$pkg_mgr" in
        apt) echo "linux" ;;
        dnf) echo "linux_dnf" ;;
        pacman) echo "linux_pacman" ;;
        *) echo "linux" ;;
    esac
}

load_config() {
    CONFIG_FILE="/tmp/quickstart-config-$$.json"
    rm -f "$CONFIG_FILE" 2>/dev/null
    
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
    stty -echo 2>/dev/null
    
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
                    '[A'|'OA') ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((num_profiles - 1)) ;;
                    '[B'|'OB') ((cursor++)); [[ $cursor -ge $num_profiles ]] && cursor=0 ;;
                esac
                ;;
            10|13|0) break ;;
        esac
    done
    
    tput cnorm 2>/dev/null || true
    stty echo 2>/dev/null
    
    SELECTED_PROFILES=("${profile_keys[$cursor]}")
}

show_software_menu() {
    local json_file=$1
    local os=$2
    local profile_key=$3
    
    # 一次性加载所有软件数据到内存，避免重复调用 jq
    local sw_data=""
    if [[ "$JSON_PARSER" == "jq" ]]; then
        sw_data=$(jq -r '.software | to_entries[] | "\(.key)\t\(.value.name)\t\(.value.desc)\t\(.value.check_mac)\t\(.value.check_win)\t\(.value.check_linux)"' "$json_file" 2>/dev/null)
    else
        sw_data=$(python3 -c "
import json
data = json.load(open('$json_file'))
for k, v in data['software'].items():
    print(f'{k}\t{v.get(\"name\",\"\")}\t{v.get(\"desc\",\"\")}\t{v.get(\"check_mac\",\"\")}\t{v.get(\"check_win\",\"\")}\t{v.get(\"check_linux\",\"\")}')
" 2>/dev/null)
    fi
    
    local -a sw_keys=()
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        if [[ ${#ONLY_SW[@]} -gt 0 ]] && [[ ! " ${ONLY_SW[*]} " =~ " $key " ]]; then continue; fi
        if [[ ${#SKIP_SW[@]} -gt 0 ]] && [[ " ${SKIP_SW[*]} " =~ " $key " ]]; then continue; fi
        sw_keys+=("$key")
    done < <(json_get_profile_includes "$json_file" "$profile_key")
    
    local -a menu_keys menu_names
    local -a checked
    
    menu_keys=("select_all")
    menu_names=("${ORANGE}$LANG_SELECT_ALL${NC}")
    checked=(0)
    
    for key in "${sw_keys[@]}"; do
        local line=$(echo "$sw_data" | grep "^${key}	" | head -1)
        local name=$(echo "$line" | cut -f2)
        local desc=$(echo "$line" | cut -f3)
        
        local check_cmd=""
        case "$os" in
            macos) check_cmd=$(echo "$line" | cut -f4) ;;
            windows) check_cmd=$(echo "$line" | cut -f5) ;;
            linux) check_cmd=$(echo "$line" | cut -f6) ;;
        esac
        
        menu_keys+=("$key")
        menu_names+=("$name - $desc")
        checked+=(0)
    done
    
    local num_items=${#menu_keys[@]}
    local cursor=0
    
    tput civis 2>/dev/null || true
    stty -echo 2>/dev/null
    
    echo ""
    log_header "$LANG_SELECT_SOFTWARE"
    echo ""
    echo -e "  ${CYAN}$LANG_NAVIGATE_MULTI${NC}"
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
                    '[A'|'OA') ((cursor--)); [[ $cursor -lt 0 ]] && cursor=$((num_items - 1)) ;;
                    '[B'|'OB') ((cursor++)); [[ $cursor -ge $num_items ]] && cursor=0 ;;
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
    stty echo 2>/dev/null
    
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
        linux) platform=$(get_linux_field "$PKG_MANAGER") ;;
    esac
    
    local cmd=$(json_get_software_field "$json_file" "$key" "$platform")
    
    if [[ -z "$cmd" ]]; then
        log_warn "$LANG_PLATFORM_NOT_SUPPORTED: $key"
        return 1
    fi
    
if [[ "$DRY_RUN" == "true" ]]; then
log_step "$LANG_DRY_RUN_INSTALLING: $key"
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

# 自定义软件选择模式
custom_select_software() {
    local json_file=$1
    local os=$2
    local profile_key=$3
    
    # 获取套餐包含的软件
    local -a sw_keys=()
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        sw_keys+=("$key")
    done < <(json_get_profile_includes "$json_file" "$profile_key")
    
    local num_sw=${#sw_keys[@]}
    
    echo ""
    log_header "$LANG_SELECT_SOFTWARE"
    echo ""
    echo -e "  ${CYAN}$LANG_NAVIGATE_MULTI${NC}"
    echo ""
    
    # 构建菜单项
    local -a menu_names=()
    local -a checked=()
    
    # 全选
    menu_names+=("${ORANGE}$LANG_SELECT_ALL${NC}")
    checked+=(0)
    
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
    
    local num_items=${#menu_names[@]}
    local cursor=0
    local running=true
    
    tput civis 2>/dev/null || true
    stty -echo 2>/dev/null
    
    while [[ "$running" == "true" ]]; do
        printf "\r\033[2K"
        for ((i=0; i<num_items; i++)); do
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
        
        local key=""
        IFS= read -rsn1 key < /dev/tty
        
        # 空字符串 = 回车
        if [[ -z "$key" ]]; then
            running=false
        # ESC 开头 = 方向键
        elif [[ "$key" == $'\x1b' ]]; then
            local seq=""
            IFS= read -rsn2 seq < /dev/tty
            if [[ "$seq" == "[A" ]]; then
                ((cursor--))
                [[ $cursor -lt 0 ]] && cursor=$((num_items - 1))
            elif [[ "$seq" == "[B" ]]; then
                ((cursor++))
                [[ $cursor -ge $num_items ]] && cursor=0
            fi
        # 空格 = 切换选择
        elif [[ "$key" == " " ]]; then
            if [[ $cursor -eq 0 ]]; then
                local new_state=$((1 - checked[0]))
                for ((i=0; i<num_items; i++)); do
                    checked[$i]=$new_state
                done
            else
                checked[$cursor]=$((1 - checked[$cursor]))
            fi
        fi
        
        # 上移光标重绘
        printf '\033[%dA' "$num_items"
    done
    
    tput cnorm 2>/dev/null || true
    stty echo 2>/dev/null
    echo ""
    
    SELECTED_SOFTWARE=()
    for ((i=1; i<num_items; i++)); do
        [[ ${checked[$i]} -eq 1 ]] && SELECTED_SOFTWARE+=("${sw_keys[$((i-1))]}")
    done
}

show_banner() {
    echo ""
    printf "\033[0;34m╔══════════════════════════════════════╗\n"
    printf "\033[0;34m║  ██████╗ ███████╗██████╗  ██████╗    ║\n"
    printf "\033[0;34m║ ██╔═══██╗██╔════╝██╔══██╗██╔════╝    ║\n"
    printf "\033[0;34m║ ██║   ██║███████╗██████╔╝██║         ║\n"
    printf "\033[0;34m║ ██║▄▄ ██║╚════██║██╔═══╝ ██║         ║\n"
    printf "\033[0;34m║ ╚██████╔╝███████║██║     ╚██████╗    ║\n"
    printf "\033[0;34m║  ╚══▀▀═╝ ╚══════╝╚═╝      ╚═════╝    ║\n"
    printf "\033[0;34m║            Quickstart-PC             ║\n"
    printf "\033[0;34m╚══════════════════════════════════════╝\n\033[0m"
    echo ""
}

main() {
    trap 'set_title ""; stty echo 2>/dev/null; tput cnorm 2>/dev/null || true; rm -f "$CONFIG_FILE" 2>/dev/null' EXIT
    
    while true; do
        clear
        tput civis 2>/dev/null || true
        stty -echo 2>/dev/null
        
        # 清理旧配置和选择
        rm -f "$CONFIG_FILE" 2>/dev/null
        CONFIG_FILE=""
        SELECTED_PROFILES=()
        SELECTED_SOFTWARE=()
        
        show_banner
        
        [[ "$DEV_MODE" == "true" ]] && log_warn "$LANG_DEV_MODE" && echo ""
        [[ "$DRY_RUN" == "true" ]] && log_warn "$LANG_DRY_RUN_MODE" && echo ""
        
        log_info "$LANG_DETECTING_SYSTEM"
        local os=$(detect_os)
        local system_info=$(get_system_info)
        PKG_MANAGER=$(check_package_manager "$os")
        
        log_info "$LANG_SYSTEM_INFO: $system_info"
        
        # 检查并安装 npm
        local display_pm="$PKG_MANAGER"
        if ! command -v npm &>/dev/null; then
            log_info "$LANG_NPM_NOT_FOUND"
            case "$os" in
                macos) brew install node ;;
                linux)
                    case "$PKG_MANAGER" in
                        apt) sudo apt install -y npm ;;
                        dnf) sudo dnf install -y npm ;;
                        pacman) sudo pacman -S npm --noconfirm ;;
                    esac
                    ;;
                windows)
                    if command -v winget &>/dev/null; then
                        winget install OpenJS.NodeJS --accept-package-agreements --accept-source-agreements
                    else
                        log_warn "$LANG_WINGET_NOT_FOUND"
                    fi
                    ;;
            esac
            hash -r 2>/dev/null
            export PATH="$PATH:/usr/local/bin"
        fi
        if command -v npm &>/dev/null; then
            display_pm="$display_pm, $LANG_NPM_AUTO"
        fi
        
        log_info "$LANG_PACKAGE_MANAGER: $display_pm"
        
        [[ "$os" == "unknown" ]] && log_error "$LANG_UNSUPPORTED_OS" && exit 1
        
        ensure_json_parser
        load_config
    
    # --non-interactive 模式处理
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        if [[ -z "$PROFILE_KEY" ]]; then
            log_error "$LANG_NONINTERACTIVE_ERROR"
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
            log_error "${LANG_PROFILE_NOT_FOUND/'$PROFILE_KEY'/$PROFILE_KEY}"
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
log_error "${LANG_PROFILE_NOT_FOUND/'$PROFILE_KEY'/$PROFILE_KEY}"
exit 1
fi

SELECTED_PROFILES=("$PROFILE_KEY")
local profile_name=$(json_get_profile_field "$CONFIG_FILE" "$PROFILE_KEY" "name")
set_title "QSPC | $profile_name | $LANG_TITLE_SELECT_SOFTWARE"
# 清屏，准备显示软件选择界面
clear
echo ""
log_header "$LANG_SELECT_SOFTWARE"
echo ""
if [[ "$CUSTOM_MODE" == "true" ]]; then
custom_select_software "$CONFIG_FILE" "$os" "${SELECTED_PROFILES[@]}"
else
show_software_menu "$CONFIG_FILE" "$os" "${SELECTED_PROFILES[@]}"
fi
else
set_title "QSPC | $LANG_TITLE_SELECT_PROFILE"
show_profile_menu "$CONFIG_FILE"
[[ ${#SELECTED_PROFILES[@]} -eq 0 ]] && log_warn "$LANG_NO_PROFILE_SELECTED" && exit 0
local profile_name=$(json_get_profile_field "$CONFIG_FILE" "${SELECTED_PROFILES[@]}" "name")
# 清屏，准备显示软件选择界面
clear
echo ""
log_header "$LANG_SELECT_SOFTWARE"
echo ""
set_title "QSPC | $profile_name | $LANG_TITLE_SELECT_SOFTWARE"
if [[ "$CUSTOM_MODE" == "true" ]]; then
custom_select_software "$CONFIG_FILE" "$os" "${SELECTED_PROFILES[@]}"
else
show_software_menu "$CONFIG_FILE" "$os" "${SELECTED_PROFILES[@]}"
fi
fi
    
    if [[ ${#SELECTED_SOFTWARE[@]} -eq 0 ]]; then
        log_warn "$LANG_NO_SOFTWARE_SELECTED"
        # 非交互模式直接退出
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            exit 0
        fi
        echo ""
        log_info "$LANG_ASK_CONTINUE"
        
        local continue_cursor=0
        local continue_running=true
        
        tput civis 2>/dev/null || true
        stty sane 2>/dev/null
        
        while [[ "$continue_running" == "true" ]]; do
            printf "\r\033[2K"
            if [[ $continue_cursor -eq 0 ]]; then
                printf "  \033[7m ▶ %s \033[0m    %s" "$LANG_CONTINUE" "$LANG_EXIT"
            else
                printf "    %s    \033[7m ▶ %s \033[0m" "$LANG_CONTINUE" "$LANG_EXIT"
            fi
            
            local key=""
            IFS= read -rsn1 key < /dev/tty
            
            # 空字符串 = 回车
            if [[ -z "$key" ]]; then
                tput cnorm 2>/dev/null || true
                echo ""
                if [[ $continue_cursor -eq 0 ]]; then
                    continue_running=false
                else
                    exit 0
                fi
            # ESC 开头 = 方向键
            elif [[ "$key" == $'\x1b' ]]; then
                local seq=""
                IFS= read -rsn2 seq < /dev/tty
                if [[ "$seq" == "[C" || "$seq" == "OC" ]]; then
                    continue_cursor=1
                elif [[ "$seq" == "[D" || "$seq" == "OD" ]]; then
                    continue_cursor=0
                fi
            fi
        done
        
        continue
    fi
    
    echo ""
    log_info "Selected: ${SELECTED_SOFTWARE[*]}"
    echo ""
    
    # 导出安装计划
    if [[ -n "$EXPORT_PLAN" ]]; then
        {
            echo "# Quickstart-PC Installation Plan"
            echo ""
            echo "**Platform:** $os ($(get_system_info))"
            echo "**Profile:** ${SELECTED_PROFILES[*]}"
            echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            echo "## Software to Install (${#SELECTED_SOFTWARE[@]} total)"
            echo ""
            for sw in "${SELECTED_SOFTWARE[@]}"; do
                local sw_name=$(json_get_software_field "$CONFIG_FILE" "$sw" "name")
                local sw_desc=$(json_get_software_field "$CONFIG_FILE" "$sw" "desc")
                local cmd=$(json_get_software_field "$CONFIG_FILE" "$sw" "${os:0:3}")
                if is_installed "$CONFIG_FILE" "$os" "$sw"; then
                    echo "- ~~$sw_name~~ ($sw_desc) - Already installed"
                else
                    echo "- **$sw_name** ($sw_desc)"
                    if [[ -n "$cmd" ]]; then
                        echo "  \`\`\`bash"
                        echo "  $cmd"
                        echo "  \`\`\`"
                    fi
                fi
            done
            echo ""
            echo "## Summary"
            echo "- Total selected: ${#SELECTED_SOFTWARE[@]}"
            local installed_count=0
            local to_install_count=0
            for sw in "${SELECTED_SOFTWARE[@]}"; do
                if is_installed "$CONFIG_FILE" "$os" "$sw"; then
                    ((installed_count++))
                else
                    ((to_install_count++))
                fi
            done
            echo "- Already installed: $installed_count"
            echo "- To install: $to_install_count"
        } > "$EXPORT_PLAN"
        log_info "Installation plan exported to $EXPORT_PLAN"
        [[ "$NON_INTERACTIVE" == "true" ]] && exit 0
    fi
    
    [[ "$DEV_MODE" == "true" ]] && log_info "Dev mode: Done" && exit 0
    
    if [[ "$AUTO_YES" == "true" ]] || [[ "$NON_INTERACTIVE" == "true" ]]; then
        echo ""
    else
        printf "%s " "$LANG_CONFIRM_INSTALL"
        local confirm=""
        IFS= read -rsn1 confirm < /dev/tty
        echo ""
        if [[ "$confirm" =~ ^[Nn] ]]; then
            log_info "$LANG_CANCELLED"
            echo ""
            log_info "$LANG_ASK_CONTINUE"
            
            local cancel_cursor=0
            local cancel_running=true
            
            while [[ "$cancel_running" == "true" ]]; do
                printf "\r\033[2K"
                if [[ $cancel_cursor -eq 0 ]]; then
                    printf "  \033[7m ▶ %s \033[0m    %s" "$LANG_CONTINUE" "$LANG_EXIT"
                else
                    printf "    %s    \033[7m ▶ %s \033[0m" "$LANG_CONTINUE" "$LANG_EXIT"
                fi
                
                local key=""
                IFS= read -rsn1 key < /dev/tty
                
                # 空字符串 = 回车
                if [[ -z "$key" ]]; then
                    tput cnorm 2>/dev/null || true
                    echo ""
                    if [[ $cancel_cursor -eq 0 ]]; then
                        cancel_running=false
                    else
                        exit 0
                    fi
                # ESC 开头 = 方向键
                elif [[ "$key" == $'\x1b' ]]; then
                    local seq=""
                    IFS= read -rsn2 seq < /dev/tty
                    if [[ "$seq" == "[C" || "$seq" == "OC" ]]; then
                        cancel_cursor=1
                    elif [[ "$seq" == "[D" || "$seq" == "OD" ]]; then
                        cancel_cursor=0
                    fi
                fi
            done
            
            continue
        fi
    fi
    
    log_info "$LANG_CHECKING_INSTALLATION"
    
    local -a to_install=()
    local -a already_installed=()
    
    debug_log "DEBUG: os=[$os] CONFIG_FILE=[$CONFIG_FILE]"
    debug_log "DEBUG: SELECTED_SOFTWARE=(${SELECTED_SOFTWARE[*]})"
    
    for sw in "${SELECTED_SOFTWARE[@]}"; do
        local sw_name=$(json_get_software_field "$CONFIG_FILE" "$sw" "name")
        debug_log "DEBUG: checking sw=[$sw] name=[$sw_name]"
        if is_installed "$CONFIG_FILE" "$os" "$sw"; then
            echo -e "  ${GREEN}[✓]${NC} $sw_name - $LANG_SKIPPING_INSTALLED"
            already_installed+=("$sw_name")
        else
            echo -e "  ${CYAN}[→]${NC} $sw_name - $LANG_INSTALLING"
            to_install+=("$sw")
fi
done
echo ""

# 执行实际安装 (Bug 2 修复: 之前缺少安装循环)
if [[ ${#to_install[@]} -gt 0 ]]; then
    log_info "$LANG_START_INSTALLING"
    local -a install_failed=()
    for sw in "${to_install[@]}"; do
        local sw_name=$(json_get_software_field "$CONFIG_FILE" "$sw" "name")
        if install_software "$CONFIG_FILE" "$os" "$sw"; then
            echo -e " ${GREEN}[✓]${NC} $sw_name - $LANG_INSTALL_SUCCESS"
        else
            echo -e " ${RED}[✗]${NC} $sw_name - $LANG_INSTALL_FAILED"
            install_failed+=("$sw_name")
        fi
    done
    echo ""
    if [[ ${#install_failed[@]} -gt 0 ]]; then
        log_warn "以下软件安装失败: ${install_failed[*]}"
    fi
fi

if [[ ${#to_install[@]} -eq 0 ]]; then
        log_info "$LANG_ALL_INSTALLED"
        # 非交互模式直接退出
        if [[ "$NON_INTERACTIVE" == "true" ]]; then
            exit 0
        fi
        echo ""
        log_info "$LANG_ASK_CONTINUE"
        
        local continue_cursor=0
        local continue_running=true
        
        tput civis 2>/dev/null || true
        stty sane 2>/dev/null
        
        while [[ "$continue_running" == "true" ]]; do
            printf "\r\033[2K"
            if [[ $continue_cursor -eq 0 ]]; then
                printf "  \033[7m ▶ %s \033[0m    %s" "$LANG_CONTINUE" "$LANG_EXIT"
            else
                printf "    %s    \033[7m ▶ %s \033[0m" "$LANG_CONTINUE" "$LANG_EXIT"
            fi
            
            local key=""
            IFS= read -rsn1 key < /dev/tty
            
            # 空字符串 = 回车
            if [[ -z "$key" ]]; then
                tput cnorm 2>/dev/null || true
                echo ""
                if [[ $continue_cursor -eq 0 ]]; then
                    continue_running=false
                else
                    exit 0
                fi
            # ESC 开头 = 方向键
            elif [[ "$key" == $'\x1b' ]]; then
                local seq=""
                IFS= read -rsn2 seq < /dev/tty
                if [[ "$seq" == "[C" || "$seq" == "OC" ]]; then
                    continue_cursor=1
                elif [[ "$seq" == "[D" || "$seq" == "OD" ]]; then
                    continue_cursor=0
                fi
            fi
        done
        
        continue
    fi
    
    # 非交互模式直接退出
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        set_title "QSPC"
        exit 0
    fi
    
    # 安装完成后询问是否继续
    set_title "QSPC | $LANG_TITLE_ASK_CONTINUE"
    echo ""
    log_info "$LANG_ASK_CONTINUE"
    
    local continue_cursor=0
    local continue_running=true
    
    tput civis 2>/dev/null || true
    
    while [[ "$continue_running" == "true" ]]; do
        printf "\r\033[2K"
        if [[ $continue_cursor -eq 0 ]]; then
            printf "  \033[7m ▶ %s \033[0m    %s" "$LANG_CONTINUE" "$LANG_EXIT"
        else
            printf "    %s    \033[7m ▶ %s \033[0m" "$LANG_CONTINUE" "$LANG_EXIT"
        fi
        
        local key=""
        IFS= read -rsn1 key < /dev/tty
        
        # 空字符串 = 回车
        if [[ -z "$key" ]]; then
            tput cnorm 2>/dev/null || true
            echo ""
            if [[ $continue_cursor -eq 0 ]]; then
                continue_running=false
            else
                exit 0
            fi
        # ESC 开头 = 方向键
        elif [[ "$key" == $'\x1b' ]]; then
            local seq=""
            IFS= read -rsn2 seq < /dev/tty
            if [[ "$seq" == "[C" || "$seq" == "OC" ]]; then
                continue_cursor=1
            elif [[ "$seq" == "[D" || "$seq" == "OD" ]]; then
                continue_cursor=0
            fi
        fi
    done
    
    continue
    done
}

trap 'set_title ""; stty echo 2>/dev/null; tput cnorm 2>/dev/null || true; rm -f "$CONFIG_FILE" 2>/dev/null' EXIT
main "$@"
