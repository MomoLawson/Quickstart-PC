# Quickstart-PC - PowerShell Version
# One-click computer setup for Windows/macOS/Linux
# Supports: powershell -ExecutionPolicy Bypass -File quickstart.ps1
# Or: iwr https://.../quickstart.ps1 | iex

param(
    [string]$lang,
    [string]$cfgPath,
    [string]$cfgUrl,
    [switch]$dev,
    [switch]$dryRun,
    [switch]$fakeInstall,
    [switch]$yes,
    [switch]$verbose,
    [string]$logFile,
    [string]$exportPlan,
    [switch]$custom,
    [switch]$retryFailed,
    [switch]$listSoftware,
    [string]$showSoftware,
    [string]$search,
    [switch]$validate,
    [string]$reportJson,
    [string]$reportTxt,
    [switch]$listProfiles,
    [string]$showProfile,
    [string[]]$skip,
    [string[]]$only,
    [switch]$failFast,
    [string]$profile,
    [switch]$nonInteractive,
    [switch]$debug,
    [switch]$help
)

$VERSION = "1.0.0"
$DEFAULT_CFG_URL = "https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json"

# Supported languages configuration
$script:SUPPORTED_LANGUAGES = @{
    "en-US" = "English"
    "zh-CN" = "简体中文"
    "zh-Hant" = "繁體中文"
    "ja" = "日本語"
    "ko" = "한국어"
    "de" = "Deutsch"
    "fr" = "Français"
    "ar" = "العربية"
    "pt" = "Português"
    "it" = "Italiano"
}

# Language code mappings
$script:LANGUAGE_MAPPINGS = @{
    "en" = "en-US"; "en-US" = "en-US"; "en_GB" = "en-US"
    "zh" = "zh-CN"; "zh-CN" = "zh-CN"; "zh_CN" = "zh-CN"; "zh-TW" = "zh-CN"
    "zh-Hant" = "zh-Hant"; "zh-HK" = "zh-Hant"
    "ja" = "ja"; "ja-JP" = "ja"; "ja_JP" = "ja"
    "ko" = "ko"; "ko-KR" = "ko"; "ko_KR" = "ko"
    "de" = "de"; "de-DE" = "de"; "de_AT" = "de"; "de_CH" = "de"
    "fr" = "fr"; "fr-FR" = "fr"; "fr_CA" = "fr"; "fr_BE" = "fr"
    "ar" = "ar"; "ar-SA" = "ar"; "ar-AE" = "ar"; "ar-EG" = "ar"
    "pt" = "pt"; "pt-BR" = "pt"; "pt-PT" = "pt"
    "it" = "it"; "it-IT" = "it"; "it_CH" = "it"
}

# Handle deprecated --fake-install
if ($fakeInstall) {
    $dryRun = $true
    Write-Warning "--fake-install is deprecated, use --dry-run instead"
}

# Script variables
$script:CONFIG_FILE = ""
$script:SELECTED_PROFILES = @()
$script:SELECTED_SOFTWARE = @()
$script:DETECTED_LANG = "en-US"
$script:PKG_MANAGER = "none"
$script:DEBUG = $debug

# ============================================
# Console helpers (cross-platform safe)
# ============================================
function Set-CursorVisible {
    param([bool]$Visible)
    try { [Console]::CursorVisible = $Visible } catch {}
}

function Get-CursorVisible {
    try { return [Console]::CursorVisible } catch { return $true }
}

function Set-WindowTitle {
    param([string]$Title)
    try { $Host.UI.RawUI.WindowTitle = $Title } catch {}
}

# ============================================
# Language Detection Functions
# ============================================
function Detect-SystemLanguage {
    # 1. Check LANG_OVERRIDE from command line
    if ($script:LANG_OVERRIDE) {
        $mapped = $script:LANGUAGE_MAPPINGS[$script:LANG_OVERRIDE]
        if ($mapped) { return $mapped }
    }
    
    # 2. Check LC_ALL, LC_MESSAGES, LANG environment variables
    $lang = $null
    foreach ($var in @("LC_ALL", "LC_MESSAGES", "LANG")) {
        $val = [System.Environment]::GetEnvironmentVariable($var)
        if ($val) {
            $lang = $val
            break
        }
    }
    
    if ($lang) {
        $langCode = $lang.Split('.')[0]
        $langCode = $langCode.Split('@')[0]
        $mapped = $script:LANGUAGE_MAPPINGS[$langCode]
        if ($mapped) { return $mapped }
    }
    
    # 3. Check LANGUAGE environment variable
    if ($env:LANGUAGE) {
        $firstLang = $env:LANGUAGE.Split(':')[0]
        $mapped = $script:LANGUAGE_MAPPINGS[$firstLang]
        if ($mapped) { return $mapped }
    }
    
    # 4. Default to English
    return "en-US"
}

# ============================================
# Language strings (zh-CN / en-US / ja / ko)
# ============================================
$script:LANG = @{}

function Initialize-LanguageStrings {
    param([string]$Lang)
    
    switch ($Lang) {
        # ============================================
        # Chinese (Simplified) - zh-CN
        # ============================================
        "zh-CN" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "快速配置新电脑软件环境"
                
                "detecting_system" = "检测系统环境..."
                "system_info" = "系统"
                "package_manager" = "包管理器"
                "unsupported_os" = "不支持的操作系统"
                
                "using_remote_config" = "使用远程配置"
                "using_custom_config" = "使用本地配置"
                "using_default_config" = "使用默认配置"
                "config_not_found" = "配置文件不存在"
                "config_invalid" = "配置文件格式无效"
                
                "select_profiles" = "选择安装套餐"
                "select_software" = "选择要安装的软件"
                "navigate" = "↑↓ 移动 | 回车 确认"
                "navigate_multi" = "↑↓ 移动 | 空格 选择 | 回车 确认"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "全选"
                "installed" = "已安装"
                
                "no_profile_selected" = "未选择任何套餐"
                "no_software_selected" = "未选择任何软件"
                "confirm_install" = "确认安装？[Y/n]"
                "cancelled" = "已取消"
                "start_installing" = "开始安装软件"
                "installing" = "安装"
                "install_success" = "安装完成"
                "install_failed" = "安装失败"
                "platform_not_supported" = "不支持的平台"
                "installation_complete" = "安装完成"
                "total_installed" = "共安装"
                
                "dev_mode" = "开发者模式：仅显示选择的软件，不实际安装"
                "fake_install_mode" = "假装安装模式：展示安装过程但不实际安装"
                "fake_installing" = "模拟安装"
                
                "checking_installation" = "正在检测安装情况..."
                "skipping_installed" = "已安装，跳过"
                "all_installed" = "所有软件均已安装，无需操作"
                
                "ask_continue" = "安装完成，是否继续安装其他套餐？"
                "continue_btn" = "继续安装"
                "exit_btn" = "退出"
                
                "title_select_profile" = "选择套餐"
                "title_select_software" = "选择软件"
                "title_installing" = "安装中"
                "title_ask_continue" = "是否继续安装"
                
                "lang_prompt" = "请选择语言"
                "help_lang" = "设置语言 (en, zh, ja, ko)"
                "noninteractive_error" = "非交互模式需要 --profile 参数"
                "profile_not_found" = "Profile 不存在"
                "npm_not_found" = "npm 未安装，正在安装..."
                "winget_not_found" = "winget 未找到，无法自动安装 npm"
                
                "help_usage" = "用法: quickstart.ps1 [选项]"
                "help_cfg_path" = "使用本地 profiles.json 文件"
                "help_cfg_url" = "使用远程 profiles.json URL"
                "help_dev" = "开发模式：显示选择的软件但不安装"
                "help_dry_run" = "假装安装：展示安装过程但不实际安装"
                "help_fake_install" = "同 --dry-run（已弃用）"
                "help_yes" = "自动确认所有提示"
                "help_verbose" = "显示详细调试信息"
                "help_log_file" = "将日志写入文件"
                "help_export_plan" = "导出安装计划到文件"
                "help_custom" = "自定义软件选择模式"
                "help_retry_failed" = "重试之前失败的软件"
                "help_list_software" = "列出所有可用软件"
                "help_show_software" = "显示指定软件详情"
                "help_search" = "搜索软件"
                "help_validate" = "校验配置文件"
                "help_report_json" = "导出 JSON 格式安装报告"
                "help_report_txt" = "导出 TXT 格式安装报告"
                "help_list_profiles" = "列出所有可用套餐"
                "help_show_profile" = "显示指定套餐详情"
                "help_skip" = "跳过指定软件（可多次使用）"
                "help_only" = "只安装指定软件（可多次使用）"
                "help_fail_fast" = "遇到错误时立即停止"
                "help_profile" = "直接指定安装套餐（跳过选择菜单）"
                "help_non_interactive" = "非交互模式（禁止所有 TUI/prompt）"
                "help_help" = "显示此帮助信息"
                
                "validating_config" = "正在校验配置文件..."
                "json_valid" = "JSON 语法有效"
                "json_invalid" = "JSON 语法无效"
                "profiles_count" = "配置文件"
                "software_count" = "软件条目"
                "validation_passed" = "校验通过"
                "validation_failed" = "校验失败"
                
                "search_results" = "搜索结果"
            }
        }
        
        # ============================================
        # Japanese - ja
        # ============================================
        "ja" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "新PCのソフトウェア環境を素早く設定"
                
                "detecting_system" = "システム環境を検出中..."
                "system_info" = "システム"
                "package_manager" = "パッケージマネージャー"
                "unsupported_os" = "サポートされていないOS"
                
                "using_remote_config" = "リモート設定を使用"
                "using_custom_config" = "ローカル設定を使用"
                "using_default_config" = "デフォルト設定を使用"
                "config_not_found" = "設定ファイルが見つかりません"
                "config_invalid" = "設定ファイルの形式が無効です"
                
                "select_profiles" = "インストールプロファイルを選択"
                "select_software" = "インストールするソフトウェアを選択"
                "navigate" = "↑↓ 移動 | Enter 確定"
                "navigate_multi" = "↑↓ 移動 | スペース 選択 | Enter 確定"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "全て選択"
                "installed" = "インストール済み"
                
                "no_profile_selected" = "プロファイルが選択されていません"
                "no_software_selected" = "ソフトウェアが選択されていません"
                "confirm_install" = "インストールを確定しますか？[Y/n]"
                "cancelled" = "キャンセルされました"
                "start_installing" = "ソフトウェアのインストールを開始"
                "installing" = "インストール中"
                "install_success" = "インストール完了"
                "install_failed" = "インストール失敗"
                "platform_not_supported" = "サポートされていないプラットフォーム"
                "installation_complete" = "インストール完了"
                "total_installed" = "合計インストール"
                
                "dev_mode" = "開発モード：選択したソフトウェアを表示但不インストール"
                "fake_install_mode" = "假装インストールモード：インストール过程を表示但不实际インストール"
                "fake_installing" = "インストールをシミュレート"
                
                "checking_installation" = "インストール狀態を確認中..."
                "skipping_installed" = "インストール済み、スキップ"
                "all_installed" = "全てのソフトウェアがインストール済み、操作不要"
                
                "ask_continue" = "インストール完了。其他プロファイルをインストールしますか？"
                "continue_btn" = "続ける"
                "exit_btn" = "終了"
                
                "title_select_profile" = "プロファイル選択"
                "title_select_software" = "ソフトウェア選択"
                "title_installing" = "インストール中"
                "title_ask_continue" = "インストールを続けますか？"
                
                "lang_prompt" = "言語を選択してください"
                "help_lang" = "言語を設定 (en, zh, ja, ko)"
                "noninteractive_error" = "非インタラクティブモードでは --profile パラメータが必要です"
                "profile_not_found" = "プロファイルが見つかりません"
                "npm_not_found" = "npm がありません、インストール中..."
                "winget_not_found" = "winget が見つかりません、npmを自動インストールできません"
                
                "help_usage" = "使用方法: quickstart.ps1 [オプション]"
                "help_cfg_path" = "ローカルの profiles.json を使用"
                "help_cfg_url" = "リモート profiles.json URL を使用"
                "help_dev" = "開発モード：選択したソフトを表示但不インストール"
                "help_dry_run" = "假装インストール：过程を表示但不实际インストール"
                "help_fake_install" = "--dry-run のエイリアス（廃止）"
                "help_yes" = "全てのプロンプトに自動同意"
                "help_verbose" = "詳細なデバッグ情報を表示"
                "help_log_file" = "ログをファイルに書き込む"
                "help_export_plan" = "インストール計画をエクスポート"
                "help_custom" = "カスタムソフトウェア選択モード"
                "help_retry_failed" = "以前に失敗したパッケージを再試行"
                "help_list_software" = "全ての利用可能なソフトウェアをリスト表示"
                "help_show_software" = "指定したソフトウェアの詳細を表示"
                "help_search" = "ソフトウェアを検索"
                "help_validate" = "設定ファイルを検証"
                "help_report_json" = "JSON 形式をインストールレポートをエクスポート"
                "help_report_txt" = "TXT 形式をインストールレポートをエクスポート"
                "help_list_profiles" = "全ての利用可能なプロファイルをリスト表示"
                "help_show_profile" = "指定したプロファイルの詳細を表示"
                "help_skip" = "指定したソフトウェアをスキップ（重复可能）"
                "help_only" = "指定したソフトウェアのみインストール（重复可能）"
                "help_fail_fast" = "最初のエラーで停止"
                "help_profile" = "プロファイルを直接指定（スキップメニュー）"
                "help_non_interactive" = "非インタラクティブモード（TUI/プロンプト全て無効）"
                "help_help" = "このヘルプを表示"
                
                "validating_config" = "設定ファイルを検証中..."
                "json_valid" = "JSON 構文有効"
                "json_invalid" = "JSON 構文無効"
                "profiles_count" = "プロファイル"
                "software_count" = "ソフトウェアエントリ"
                "validation_passed" = "検証成功"
                "validation_failed" = "検証失敗"
                
                "search_results" = "検索結果"
            }
        }
        
        # ============================================
        # Korean - ko
        # ============================================
        "ko" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "새 PC 소프트웨어 환경을 빠르게 설정"
                
                "detecting_system" = "시스템 환경 감지 중..."
                "system_info" = "시스템"
                "package_manager" = "패키지 관리자"
                "unsupported_os" = "지원되지 않는 OS"
                
                "using_remote_config" = "원격 구성 사용"
                "using_custom_config" = "로컬 구성 사용"
                "using_default_config" = "기본 구성 사용"
                "config_not_found" = "구성 파일을 찾을 수 없습니다"
                "config_invalid" = "구성 파일 형식이 유효하지 않습니다"
                
                "select_profiles" = "설치 프로필 선택"
                "select_software" = "설치할 소프트웨어 선택"
                "navigate" = "↑↓ 이동 | Enter 확인"
                "navigate_multi" = "↑↓ 이동 | 스페이스 선택 | Enter 확인"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "모두 선택"
                "installed" = "설치됨"
                
                "no_profile_selected" = "프로필이 선택되지 않았습니다"
                "no_software_selected" = "소프트웨어가 선택되지 않았습니다"
                "confirm_install" = "설치를 확인하시겠습니까? [Y/n]"
                "cancelled" = "취소됨"
                "start_installing" = "소프트웨어 설치 시작"
                "installing" = "설치 중"
                "install_success" = "설치 완료"
                "install_failed" = "설치 실패"
                "platform_not_supported" = "지원되지 않는 플랫폼"
                "installation_complete" = "설치 완료"
                "total_installed" = "총 설치"
                
                "dev_mode" = "개발 모드: 선택한 소프트웨어 표시但不설치"
                "fake_install_mode" = "흉내 설치 모드: 설치 과정 표시，但不실제 설치"
                "fake_installing" = "설치 시뮬레이션"
                
                "checking_installation" = "설치 상태 확인 중..."
                "skipping_installed" = "이미 설치됨, 건너뛰기"
                "all_installed" = "모든 소프트웨어가 이미 설치됨, 작업 없음"
                
                "ask_continue" = "설치 완료. 다른 프로필을 계속 설치하시겠습니까?"
                "continue_btn" = "계속"
                "exit_btn" = "종료"
                
                "title_select_profile" = "프로필 선택"
                "title_select_software" = "소프트웨어 선택"
                "title_installing" = "설치 중"
                "title_ask_continue" = "설치를 계속하시겠습니까?"
                
                "lang_prompt" = "언어를 선택해 주세요"
                "help_lang" = "언어 설정 (en, zh, ja, ko)"
                "noninteractive_error" = "비대화형 모드에서는 --profile 매개변수가 필요합니다"
                "profile_not_found" = "프로필을 찾을 수 없습니다"
                "npm_not_found" = "npm을 찾을 수 없습니다, 설치 중..."
                "winget_not_found" = "winget을 찾을 수 없습니다, npm을 자동 설치할 수 없습니다"
                
                "help_usage" = "사용법: quickstart.ps1 [옵션]"
                "help_cfg_path" = "로컬 profiles.json 사용"
                "help_cfg_url" = "원격 profiles.json URL 사용"
                "help_dev" = "개발 모드: 선택한 소프트웨어 표시他不설치"
                "help_dry_run" = "흉내 설치: 과정 표시，但不실제 설치"
                "help_fake_install" = "--dry-run의 별칭 (사용되지 않음)"
                "help_yes" = "모든 프롬프트에 자동 동의"
                "help_verbose" = "詳細な 디버그 정보 표시"
                "help_log_file" = "로그를 파일에 쓰기"
                "help_export_plan" = "설치 계획 내보내기"
                "help_custom" = "사용자 정의 소프트웨어 선택 모드"
                "help_retry_failed" = "이전에 실패한 패키지 재시도"
                "help_list_software" = "사용 가능한 모든 소프트웨어 나열"
                "help_show_software" = "지정된 소프트웨어 상세 정보 표시"
                "help_search" = "소프트웨어 검색"
                "help_validate" = "구성 파일 검증"
                "help_report_json" = "JSON 형식으로 설치 보고서 내보내기"
                "help_report_txt" = "TXT 형식으로 설치 보고서 내보내기"
                "help_list_profiles" = "사용 가능한 모든 프로필 나열"
                "help_show_profile" = "지정된 프로필 상세 정보 표시"
                "help_skip" = "지정된 소프트웨어 건너뛰기 (반복 가능)"
                "help_only" = "지정된 소프트웨어만 설치 (반복 가능)"
                "help_fail_fast" = "첫 번째 오류에서 중지"
                "help_profile" = "프로필 직접 선택 (메뉴 건너뛰기)"
                "help_non_interactive" = "비대화형 모드 (TUI/프롬프트 모두 비활성화)"
                "help_help" = "이 도움말 표시"
                
                "validating_config" = "구성 파일 검증 중..."
                "json_valid" = "JSON 구문 유효"
                "json_invalid" = "JSON 구문 유효하지 않음"
                "profiles_count" = "프로필"
                "software_count" = "소프트웨어 항목"
                "validation_passed" = "검증 통과"
                "validation_failed" = "검증 실패"
                
                "search_results" = "검색 결과"
            }
        }
        
        # ============================================
        # Traditional Chinese - zh-Hant
        # ============================================
        "zh-Hant" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "快速設定新電腦軟件環境"
                
                "detecting_system" = "偵測系統環境..."
                "system_info" = "系統"
                "package_manager" = "套件管理器"
                "unsupported_os" = "不支援的作業系統"
                
                "using_remote_config" = "使用遠程配置"
                "using_custom_config" = "使用本地配置"
                "using_default_config" = "使用預設配置"
                "config_not_found" = "配置文件不存在"
                "config_invalid" = "配置文件格式無效"
                
                "select_profiles" = "選擇安裝套餐"
                "select_software" = "選擇要安裝的軟件"
                "navigate" = "↑↓ 移動 | 確認"
                "navigate_multi" = "↑↓ 移動 | 空格 選擇 | 確認"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "全選"
                "installed" = "已安裝"
                
                "no_profile_selected" = "未選擇任何套餐"
                "no_software_selected" = "未選擇任何軟件"
                "confirm_install" = "確認安裝？[Y/n]"
                "cancelled" = "已取消"
                "start_installing" = "開始安裝軟件"
                "installing" = "安裝中"
                "install_success" = "安裝完成"
                "install_failed" = "安裝失敗"
                "platform_not_supported" = "不支援的平台"
                "installation_complete" = "安裝完成"
                "total_installed" = "共安裝"
                
                "dev_mode" = "開發模式：僅顯示選擇的軟件，不實際安裝"
                "fake_install_mode" = "模擬安裝模式：展示安裝過程但不實際安裝"
                "fake_installing" = "模擬安裝"
                
                "checking_installation" = "正在偵測安裝情況..."
                "skipping_installed" = "已安裝，跳過"
                "all_installed" = "所有軟件均已安裝，無需操作"
                
                "ask_continue" = "安裝完成，是否繼續安裝其他套餐？"
                "continue_btn" = "繼續安裝"
                "exit_btn" = "退出"
                
                "title_select_profile" = "選擇套餐"
                "title_select_software" = "選擇軟件"
                "title_installing" = "安裝中"
                "title_ask_continue" = "是否繼續安裝"
                
                "lang_prompt" = "請選擇語言"
                "help_lang" = "設定語言 (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "非互動模式需要 --profile 參數"
                "profile_not_found" = "Profile 不存在"
                "npm_not_found" = "npm 未安裝，正在安裝..."
                "winget_not_found" = "winget 未找到，無法自動安裝 npm"
                
                "help_usage" = "用法: quickstart.ps1 [選項]"
                "help_cfg_path" = "使用本地 profiles.json 文件"
                "help_cfg_url" = "使用遠程 profiles.json URL"
                "help_dev" = "開發模式：顯示選擇的軟件但不實際安裝"
                "help_dry_run" = "模擬安裝：展示安裝過程但不實際安裝"
                "help_fake_install" = "同 --dry-run（已棄用）"
                "help_yes" = "自動確認所有提示"
                "help_verbose" = "顯示詳細調試信息"
                "help_log_file" = "將日誌寫入文件"
                "help_export_plan" = "匯出安裝計劃到文件"
                "help_custom" = "自訂軟件選擇模式"
                "help_retry_failed" = "重試之前失敗的軟件"
                "help_list_software" = "列出所有可用軟件"
                "help_show_software" = "顯示指定軟件詳情"
                "help_search" = "搜尋軟件"
                "help_validate" = "驗證配置文件"
                "help_report_json" = "匯出 JSON 格式安裝報告"
                "help_report_txt" = "匯出 TXT 格式安裝報告"
                "help_list_profiles" = "列出所有可用套餐"
                "help_show_profile" = "顯示指定套餐詳情"
                "help_skip" = "跳過指定軟件（可多次使用）"
                "help_only" = "只安裝指定軟件（可多次使用）"
                "help_fail_fast" = "遇到錯誤時立即停止"
                "help_profile" = "直接指定安裝套餐（跳過選擇選單）"
                "help_non_interactive" = "非互動模式（禁止所有 TUI/prompt）"
                "help_help" = "顯示此幫助信息"
                
                "validating_config" = "正在驗證配置文件..."
                "json_valid" = "JSON 語法有效"
                "json_invalid" = "JSON 語法無效"
                "profiles_count" = "配置文件"
                "software_count" = "軟件條目"
                "validation_passed" = "驗證通過"
                "validation_failed" = "驗證失敗"
                
                "search_results" = "搜尋結果"
            }
        }
        
        # ============================================
        # German - de
        # ============================================
        "de" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "Schnelle Einrichtung für neue Computer"
                
                "detecting_system" = "Erkennung der Systemumgebung..."
                "system_info" = "System"
                "package_manager" = "Paketmanager"
                "unsupported_os" = "Nicht unterstütztes Betriebssystem"
                
                "using_remote_config" = "Verwendung der Remote-Konfiguration"
                "using_custom_config" = "Verwendung der lokalen Konfiguration"
                "using_default_config" = "Verwendung der Standardkonfiguration"
                "config_not_found" = "Konfigurationsdatei nicht gefunden"
                "config_invalid" = "Konfigurationsdateiformat ungültig"
                
                "select_profiles" = "Installationsprofile auswählen"
                "select_software" = "Software zum Installieren auswählen"
                "navigate" = "↑↓ Bewegen | ENTER Bestätigen"
                "navigate_multi" = "↑↓ Bewegen | LEERTASTE Auswählen | ENTER Bestätigen"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "Alle auswählen"
                "installed" = "installiert"
                
                "no_profile_selected" = "Kein Profil ausgewählt"
                "no_software_selected" = "Keine Software ausgewählt"
                "confirm_install" = "Installation bestätigen? [Y/n]"
                "cancelled" = "Abgebrochen"
                "start_installing" = "Software-Installation starten"
                "installing" = "Installiere"
                "install_success" = "erfolgreich installiert"
                "install_failed" = "Installation fehlgeschlagen"
                "platform_not_supported" = "Plattform nicht unterstützt"
                "installation_complete" = "Installation abgeschlossen"
                "total_installed" = "Gesamt installiert"
                
                "dev_mode" = "Entwicklermodus: Ausgewählte Software anzeigen ohne zu installieren"
                "fake_install_mode" = "Simulationsmodus: Installationsprozess anzeigen ohne tatsächlich zu installieren"
                "fake_installing" = "Installation simulieren"
                
                "checking_installation" = "Installationsstatus wird überprüft..."
                "skipping_installed" = "Bereits installiert, überspringen"
                "all_installed" = "Alle Software bereits installiert, nichts zu tun"
                
                "ask_continue" = "Installation abgeschlossen. Andere Profile weiter installieren?"
                "continue_btn" = "Weiter"
                "exit_btn" = "Beenden"
                
                "title_select_profile" = "Profil auswählen"
                "title_select_software" = "Software auswählen"
                "title_installing" = "Installiere"
                "title_ask_continue" = "Weiter installieren?"
                
                "lang_prompt" = "Bitte Sprache auswählen"
                "help_lang" = "Sprache festlegen (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "Nicht-interaktiver Modus erfordert --profile Parameter"
                "profile_not_found" = "Profil nicht gefunden"
                "npm_not_found" = "npm nicht gefunden, wird installiert..."
                "winget_not_found" = "winget nicht gefunden, kann npm nicht automatisch installieren"
                
                "help_usage" = "Verwendung: quickstart.ps1 [OPTIONEN]"
                "help_cfg_path" = "Lokale profiles.json verwenden"
                "help_cfg_url" = "Remote profiles.json URL verwenden"
                "help_dev" = "Entwicklermodus: Auswahl anzeigen ohne zu installieren"
                "help_dry_run" = "Simulation: Prozess anzeigen ohne zu installieren"
                "help_fake_install" = "Alias für --dry-run (veraltet)"
                "help_yes" = "Alle Prompts automatisch bestätigen"
                "help_verbose" = "Detaillierte Debug-Infos anzeigen"
                "help_log_file" = "Logs in Datei schreiben"
                "help_export_plan" = "Installationsplan exportieren"
                "help_custom" = "Benutzerdefinierte Software-Auswahl"
                "help_retry_failed" = "Zuerst fehlgeschlagene Pakete erneut versuchen"
                "help_list_software" = "Alle verfügbare Software auflisten"
                "help_show_software" = "Software-Details anzeigen"
                "help_search" = "Software suchen"
                "help_validate" = "Konfigurationsdatei validieren"
                "help_report_json" = "JSON-Installationsbericht exportieren"
                "help_report_txt" = "TXT-Installationsbericht exportieren"
                "help_list_profiles" = "Alle verfügbaren Profile auflisten"
                "help_show_profile" = "Profil-Details anzeigen"
                "help_skip" = "Software überspringen (wiederholbar)"
                "help_only" = "Nur angegebene Software installieren (wiederholbar)"
                "help_fail_fast" = "Bei erstem Fehler stoppen"
                "help_profile" = "Profil direkt auswählen (Menü überspringen)"
                "help_non_interactive" = "Nicht-interaktiver Modus (keine TUI/Prompts)"
                "help_help" = "Diese Hilfemeldung anzeigen"
                
                "validating_config" = "Konfiguration wird validiert..."
                "json_valid" = "JSON-Syntax gültig"
                "json_invalid" = "JSON-Syntax ungültig"
                "profiles_count" = "Profile"
                "software_count" = "Softwareeinträge"
                "validation_passed" = "Validierung erfolgreich"
                "validation_failed" = "Validierung fehlgeschlagen"
                
                "search_results" = "Suchergebnisse"
            }
        }
        
        # ============================================
        # French - fr
        # ============================================
        "fr" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "Configuration rapide pour nouveaux ordinateurs"
                
                "detecting_system" = "Détection de l'environnement système..."
                "system_info" = "Système"
                "package_manager" = "Gestionnaire de paquets"
                "unsupported_os" = "Système d'exploitation non pris en charge"
                
                "using_remote_config" = "Utilisation de la configuration distante"
                "using_custom_config" = "Utilisation de la configuration locale"
                "using_default_config" = "Utilisation de la configuration par défaut"
                "config_not_found" = "Fichier de configuration non trouvé"
                "config_invalid" = "Format du fichier de configuration invalide"
                
                "select_profiles" = "Sélectionner les profils d'installation"
                "select_software" = "Sélectionner les logiciels à installer"
                "navigate" = "↑↓ Déplacer | ENTRÉE Confirmer"
                "navigate_multi" = "↑↓ Déplacer | ESPACE Sélectionner | ENTRÉE Confirmer"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "Tout sélectionner"
                "installed" = "installé"
                
                "no_profile_selected" = "Aucun profil sélectionné"
                "no_software_selected" = "Aucun logiciel sélectionné"
                "confirm_install" = "Confirmer l'installation ? [Y/n]"
                "cancelled" = "Annulé"
                "start_installing" = "Démarrage de l'installation des logiciels"
                "installing" = "Installation"
                "install_success" = "installé avec succès"
                "install_failed" = "installation échouée"
                "platform_not_supported" = "Plateforme non prise en charge"
                "installation_complete" = "Installation terminée"
                "total_installed" = "Total installé"
                
                "dev_mode" = "Mode développement: afficher les logiciels sélectionnés sans installer"
                "fake_install_mode" = "Mode installation simulée: afficher le processus sans installer"
                "fake_installing" = "Installation simulée"
                
                "checking_installation" = "Vérification du statut d'installation..."
                "skipping_installed" = "Déjà installé, ignoré"
                "all_installed" = "Tous les logiciels déjà installés, rien à faire"
                
                "ask_continue" = "Installation terminée. Continuer l'installation d'autres profils ?"
                "continue_btn" = "Continuer"
                "exit_btn" = "Quitter"
                
                "title_select_profile" = "Sélectionner le profil"
                "title_select_software" = "Sélectionner les logiciels"
                "title_installing" = "Installation"
                "title_ask_continue" = "Continuer l'installation ?"
                
                "lang_prompt" = "Veuillez sélectionner la langue"
                "help_lang" = "Définir la langue (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "Le mode non interactif requiert le paramètre --profile"
                "profile_not_found" = "Profil non trouvé"
                "npm_not_found" = "npm non trouvé, installation..."
                "winget_not_found" = "winget non trouvé, impossible d'installer automatiquement npm"
                
                "help_usage" = "Utilisation: quickstart.ps1 [OPTIONS]"
                "help_cfg_path" = "Utiliser le fichier profiles.json local"
                "help_cfg_url" = "Utiliser l'URL profiles.json distante"
                "help_dev" = "Mode développement: afficher les sélections sans installer"
                "help_dry_run" = "Installation simulée: afficher le processus sans installer"
                "help_fake_install" = "Alias pour --dry-run (déprécié)"
                "help_yes" = "Confirmer automatiquement toutes les invites"
                "help_verbose" = "Afficher les infos de débogage détaillées"
                "help_log_file" = "Écrire les logs dans un fichier"
                "help_export_plan" = "Exporter le plan d'installation"
                "help_custom" = "Mode de sélection de logiciels personnalisé"
                "help_retry_failed" = "Réessayer les paquets précédemment échoués"
                "help_list_software" = "Lister tous les logiciels disponibles"
                "help_show_software" = "Afficher les détails du logiciel"
                "help_search" = "Rechercher un logiciel"
                "help_validate" = "Valider le fichier de configuration"
                "help_report_json" = "Exporter le rapport d'installation en JSON"
                "help_report_txt" = "Exporter le rapport d'installation en TXT"
                "help_list_profiles" = "Lister tous les profils disponibles"
                "help_show_profile" = "Afficher les détails du profil"
                "help_skip" = "Ignorer le logiciel spécifié (répétable)"
                "help_only" = "Installer uniquement le logiciel spécifié (répétable)"
                "help_fail_fast" = "Arrêter à la première erreur"
                "help_profile" = "Sélectionner le profil directement (passer le menu)"
                "help_non_interactive" = "Mode non interactif (pas de TUI/prompts)"
                "help_help" = "Afficher ce message d'aide"
                
                "validating_config" = "Validation de la configuration..."
                "json_valid" = "Syntaxe JSON valide"
                "json_invalid" = "Syntaxe JSON invalide"
                "profiles_count" = "Profils"
                "software_count" = "Entrées logicielles"
                "validation_passed" = "Validation réussie"
                "validation_failed" = "Validation échouée"
                
                "search_results" = "Résultats de recherche"
            }
        }
        
        # ============================================
        # Arabic - ar (LTR for terminal compatibility)
        # ============================================
        "ar" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "إعداد سريع لأجهزة الكمبيوتر الجديدة"
                
                "detecting_system" = "جاري اكتشاف بيئة النظام..."
                "system_info" = "النظام"
                "package_manager" = "مدير الحزم"
                "unsupported_os" = "نظام تشغيل غير مدعوم"
                
                "using_remote_config" = "استخدام التكوين البعيد"
                "using_custom_config" = "استخدام التكوين المحلي"
                "using_default_config" = "استخدام التكوين الافتراضي"
                "config_not_found" = "ملف التكوين غير موجود"
                "config_invalid" = "تنسيق ملف التكوين غير صالح"
                
                "select_profiles" = "اختيار ملفات التثبيت"
                "select_software" = "اختيار البرامج للتثبيت"
                "navigate" = "↑↓ تحريك | ENTER تأكيد"
                "navigate_multi" = "↑↓ تحريك | مسافة اختيار | ENTER تأكيد"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "تحديد الكل"
                "installed" = "مثبت"
                
                "no_profile_selected" = "لم يتم اختيار أي ملف شخصي"
                "no_software_selected" = "لم يتم اختيار أي برنامج"
                "confirm_install" = "تأكيد التثبيت؟ [Y/n]"
                "cancelled" = "تم الإلغاء"
                "start_installing" = "بدء تثبيت البرامج"
                "installing" = "جاري التثبيت"
                "install_success" = "تم التثبيت بنجاح"
                "install_failed" = "فشل التثبيت"
                "platform_not_supported" = "المنصة غير مدعومة"
                "installation_complete" = "اكتمل التثبيت"
                "total_installed" = "المجموع المثبت"
                
                "dev_mode" = "وضع التطوير: إظهار البرامج المحددة دون تثبيت"
                "fake_install_mode" = "وضع التثبيت الوهمي: إظهار عملية التثبيت دون التثبيت الفعلي"
                "fake_installing" = "محاكاة التثبيت"
                
                "checking_installation" = "التحقق من حالة التثبيت..."
                "skipping_installed" = "مثبت بالفعل، تخطي"
                "all_installed" = "جميع البرامج مثبتة بالفعل، لا شيء القيام به"
                
                "ask_continue" = "اكتمل التثبيت. متابعة تثبيت ملفات شخصية أخرى؟"
                "continue_btn" = "متابعة"
                "exit_btn" = "خروج"
                
                "title_select_profile" = "اختيار الملف الشخصي"
                "title_select_software" = "اختيار البرامج"
                "title_installing" = "التثبيت"
                "title_ask_continue" = "متابعة التثبيت؟"
                
                "lang_prompt" = "يرجى اختيار اللغة"
                "help_lang" = "تعيين اللغة (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "الوضع غير التفاعلي يتطلب معامل --profile"
                "profile_not_found" = "الملف الشخصي غير موجود"
                "npm_not_found" = "npm غير موجود، جاري التثبيت..."
                "winget_not_found" = "winget غير موجود، لا يمكن تثبيت npm تلقائياً"
                
                "help_usage" = "الاستخدام: quickstart.ps1 [الخيارات]"
                "help_cfg_path" = "استخدام ملف profiles.json المحلي"
                "help_cfg_url" = "استخدام عنوان profiles.json البعيد"
                "help_dev" = "وضع التطوير: إظهار التحديدات دون التثبيت"
                "help_dry_run" = "تثبيت وهمي: إظهار العملية دون التثبيت"
                "help_fake_install" = "اسم مستعار لـ --dry-run (مهمل)"
                "help_yes" = "تأكيد جميع الأسئلة تلقائياً"
                "help_verbose" = "إظهار معلومات التصحيح التفصيلية"
                "help_log_file" = "كتابة السجلات في ملف"
                "help_export_plan" = "تصدير خطة التثبيت"
                "help_custom" = "وضع اختيار البرامج المخصص"
                "help_retry_failed" = "إعادة المحاولة للحزم الفاشلة سابقاً"
                "help_list_software" = "سرد جميع البرامج المتاحة"
                "help_show_software" = "إظهار تفاصيل البرنامج"
                "help_search" = "البحث عن برنامج"
                "help_validate" = "التحقق من ملف التكوين"
                "help_report_json" = "تصدير تقرير التثبيت بـ JSON"
                "help_report_txt" = "تصدير تقرير التثبيت بـ TXT"
                "help_list_profiles" = "سرد جميع الملفات الشخصية المتاحة"
                "help_show_profile" = "إظهار تفاصيل الملف الشخصي"
                "help_skip" = "تخطي البرنامج المحدد (قابل للتكرار)"
                "help_only" = "تثبيت البرنامج المحدد فقط (قابل للتكرار)"
                "help_fail_fast" = "التوقف عند الخطأ الأول"
                "help_profile" = "تحديد الملف الشخصي مباشرة (تخطي القائمة)"
                "help_non_interactive" = "الوضع غير التفاعلي (لا TUI/مطالبات)"
                "help_help" = "إظهار رسالة المساعدة هذه"
                
                "validating_config" = "جاري التحقق من ملف التكوين..."
                "json_valid" = "صيغة JSON صالحة"
                "json_invalid" = "صيغة JSON غير صالحة"
                "profiles_count" = "الملفات الشخصية"
                "software_count" = "إدخالات البرامج"
                "validation_passed" = "التحقق نجح"
                "validation_failed" = "التحقق فشل"
                
                "search_results" = "نتائج البحث"
            }
        }
        
        # ============================================
        # Portuguese - pt
        # ============================================
        "pt" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "Configuração rápida para novos computadores"
                
                "detecting_system" = "Detectando ambiente do sistema..."
                "system_info" = "Sistema"
                "package_manager" = "Gerenciador de pacotes"
                "unsupported_os" = "Sistema operacional não suportado"
                
                "using_remote_config" = "Usando configuração remota"
                "using_custom_config" = "Usando configuração local"
                "using_default_config" = "Usando configuração padrão"
                "config_not_found" = "Arquivo de configuração não encontrado"
                "config_invalid" = "Formato do arquivo de configuração inválido"
                
                "select_profiles" = "Selecionar Perfis de Instalação"
                "select_software" = "Selecionar Software para Instalar"
                "navigate" = "↑↓ Mover | ENTER Confirmar"
                "navigate_multi" = "↑↓ Mover | ESPAÇO Selecionar | ENTER Confirmar"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "Selecionar Tudo"
                "installed" = "instalado"
                
                "no_profile_selected" = "Nenhum perfil selecionado"
                "no_software_selected" = "Nenhum software selecionado"
                "confirm_install" = "Confirmar instalação? [Y/n]"
                "cancelled" = "Cancelado"
                "start_installing" = "Iniciando instalação de software"
                "installing" = "Instalando"
                "install_success" = "instalado com sucesso"
                "install_failed" = "instalação falhou"
                "platform_not_supported" = "Plataforma não suportada"
                "installation_complete" = "Instalação Concluída"
                "total_installed" = "Total instalado"
                
                "dev_mode" = "Modo desenvolvimento: mostrar software selecionado sem instalar"
                "fake_install_mode" = "Modo instalação simulada: mostrar processo sem instalar"
                "fake_installing" = "Simulando instalação"
                
                "checking_installation" = "Verificando status da instalação..."
                "skipping_installed" = "Já instalado, pulando"
                "all_installed" = "Todo software já instalado, nada a fazer"
                
                "ask_continue" = "Instalação concluída. Continuar instalando outros perfis?"
                "continue_btn" = "Continuar"
                "exit_btn" = "Sair"
                
                "title_select_profile" = "Selecionar Perfil"
                "title_select_software" = "Selecionar Software"
                "title_installing" = "Instalando"
                "title_ask_continue" = "Continuar Instalação?"
                
                "lang_prompt" = "Por favor, selecione o idioma"
                "help_lang" = "Definir idioma (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "Modo não interativo requer parâmetro --profile"
                "profile_not_found" = "Perfil não encontrado"
                "npm_not_found" = "npm não encontrado, instalando..."
                "winget_not_found" = "winget não encontrado, não é possível instalar npm automaticamente"
                
                "help_usage" = "Uso: quickstart.ps1 [OPÇÕES]"
                "help_cfg_path" = "Usar arquivo profiles.json local"
                "help_cfg_url" = "Usar URL profiles.json remota"
                "help_dev" = "Modo desenvolvimento: mostrar escolhas sem instalar"
                "help_dry_run" = "Instalação simulada: mostrar processo sem instalar"
                "help_fake_install" = "Apelido para --dry-run (obsoleto)"
                "help_yes" = "Confirmar automaticamente todos os prompts"
                "help_verbose" = "Mostrar informações de debug detalhadas"
                "help_log_file" = "Escrever logs em arquivo"
                "help_export_plan" = "Exportar plano de instalação"
                "help_custom" = "Modo de seleção de software personalizado"
                "help_retry_failed" = "Tentar pacotes que falharam anteriormente"
                "help_list_software" = "Listar todos os softwares disponíveis"
                "help_show_software" = "Mostrar detalhes do software"
                "help_search" = "Pesquisar software"
                "help_validate" = "Validar arquivo de configuração"
                "help_report_json" = "Exportar relatório de instalação em JSON"
                "help_report_txt" = "Exportar relatório de instalação em TXT"
                "help_list_profiles" = "Listar todos os perfis disponíveis"
                "help_show_profile" = "Mostrar detalhes do perfil"
                "help_skip" = "Pular software especificado (repetível)"
                "help_only" = "Instalar apenas o software especificado (repetível)"
                "help_fail_fast" = "Parar no primeiro erro"
                "help_profile" = "Selecionar perfil diretamente (pular menu)"
                "help_non_interactive" = "Modo não interativo (sem TUI/prompts)"
                "help_help" = "Mostrar esta mensagem de ajuda"
                
                "validating_config" = "Validando configuração..."
                "json_valid" = "Sintaxe JSON válida"
                "json_invalid" = "Sintaxe JSON inválida"
                "profiles_count" = "Perfis"
                "software_count" = "Entradas de software"
                "validation_passed" = "Validação bem-sucedida"
                "validation_failed" = "Validação falhou"
                
                "search_results" = "Resultados da pesquisa"
            }
        }
        
        # ============================================
        # Italian - it
        # ============================================
        "it" {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "Configurazione rapida per nuovi computer"
                
                "detecting_system" = "Rilevamento ambiente sistema..."
                "system_info" = "Sistema"
                "package_manager" = "Gestore pacchetti"
                "unsupported_os" = "Sistema operativo non supportato"
                
                "using_remote_config" = "Utilizzo configurazione remota"
                "using_custom_config" = "Utilizzo configurazione locale"
                "using_default_config" = "Utilizzo configurazione predefinita"
                "config_not_found" = "File di configurazione non trovato"
                "config_invalid" = "Formato file di configurazione non valido"
                
                "select_profiles" = "Seleziona Profili di Installazione"
                "select_software" = "Seleziona Software da Installare"
                "navigate" = "↑↓ Muovi | INVIO Conferma"
                "navigate_multi" = "↑↓ Muovi | SPAZIO Seleziona | INVIO Conferma"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "Seleziona Tutto"
                "installed" = "installato"
                
                "no_profile_selected" = "Nessun profilo selezionato"
                "no_software_selected" = "Nessun software selezionato"
                "confirm_install" = "Confermare installazione? [Y/n]"
                "cancelled" = "Annullato"
                "start_installing" = "Avvio installazione software"
                "installing" = "Installazione"
                "install_success" = "installato con successo"
                "install_failed" = "installazione fallita"
                "platform_not_supported" = "Piattaforma non supportata"
                "installation_complete" = "Installazione Completata"
                "total_installed" = "Totale installato"
                
                "dev_mode" = "Modalità sviluppo: mostra software selezionato senza installare"
                "fake_install_mode" = "Modalità installazione simulata: mostra processo senza installare"
                "fake_installing" = "Simulazione installazione"
                
                "checking_installation" = "Verifica stato installazione..."
                "skipping_installed" = "Già installato, salto"
                "all_installed" = "Tutto il software già installato, niente da fare"
                
                "ask_continue" = "Installazione completata. Continuare installazione altri profili?"
                "continue_btn" = "Continua"
                "exit_btn" = "Esci"
                
                "title_select_profile" = "Seleziona Profilo"
                "title_select_software" = "Seleziona Software"
                "title_installing" = "Installazione"
                "title_ask_continue" = "Continuare Installazione?"
                
                "lang_prompt" = "Per favore, seleziona la lingua"
                "help_lang" = "Imposta lingua (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "Modalità non interattiva richiede parametro --profile"
                "profile_not_found" = "Profilo non trovato"
                "npm_not_found" = "npm non trovato, installazione..."
                "winget_not_found" = "winget non trovato, impossibile installare npm automaticamente"
                
                "help_usage" = "Utilizzo: quickstart.ps1 [OPZIONI]"
                "help_cfg_path" = "Usa file profiles.json locale"
                "help_cfg_url" = "Usa URL profiles.json remota"
                "help_dev" = "Modalità sviluppo: mostra selezioni senza installare"
                "help_dry_run" = "Installazione simulata: mostra processo senza installare"
                "help_fake_install" = "Alias per --dry-run (deprecato)"
                "help_yes" = "Conferma automaticamente tutti i prompt"
                "help_verbose" = "Mostra info di debug dettagliate"
                "help_log_file" = "Scrivi log su file"
                "help_export_plan" = "Esporta piano di installazione"
                "help_custom" = "Modalità selezione software personalizzata"
                "help_retry_failed" = "Riprova pacchetti precedentemente falliti"
                "help_list_software" = "Elenca tutto il software disponibile"
                "help_show_software" = "Mostra dettagli software"
                "help_search" = "Cerca software"
                "help_validate" = "Valida file di configurazione"
                "help_report_json" = "Esporta report installazione JSON"
                "help_report_txt" = "Esporta report installazione TXT"
                "help_list_profiles" = "Elenca tutti i profili disponibili"
                "help_show_profile" = "Mostra dettagli profilo"
                "help_skip" = "Salta software specificato (ripetibile)"
                "help_only" = "Installa solo software specificato (ripetibile)"
                "help_fail_fast" = "Ferma al primo errore"
                "help_profile" = "Seleziona profilo direttamente (salta menu)"
                "help_non_interactive" = "Modalità non interattiva (no TUI/prompt)"
                "help_help" = "Mostra questo messaggio di aiuto"
                
                "validating_config" = "Validazione configurazione..."
                "json_valid" = "Sintassi JSON valida"
                "json_invalid" = "Sintassi JSON non valida"
                "profiles_count" = "Profili"
                "software_count" = "Voci software"
                "validation_passed" = "Validazione superata"
                "validation_failed" = "Validazione fallita"
                
                "search_results" = "Risultati della ricerca"
            }
        }
        
        # ============================================
        # English (default) - en-US
        # ============================================
        default {
            $script:LANG = @{
                "banner_title" = "Quickstart-PC v$VERSION"
                "banner_desc" = "Quick setup for new computers"
                
                "detecting_system" = "Detecting system environment..."
                "system_info" = "System"
                "package_manager" = "Package Manager"
                "unsupported_os" = "Unsupported operating system"
                
                "using_remote_config" = "Using remote configuration"
                "using_custom_config" = "Using local configuration"
                "using_default_config" = "Using default configuration"
                "config_not_found" = "Configuration file not found"
                "config_invalid" = "Configuration file format invalid"
                
                "select_profiles" = "Select Installation Profiles"
                "select_software" = "Select Software to Install"
                "navigate" = "↑↓ Move | ENTER Confirm"
                "navigate_multi" = "↑↓ Move | SPACE Select | ENTER Confirm"
                "selected" = "[✓] "
                "not_selected" = "[  ] "
                "select_all" = "Select All"
                "installed" = "installed"
                
                "no_profile_selected" = "No profile selected"
                "no_software_selected" = "No software selected"
                "confirm_install" = "Confirm installation? [Y/n]"
                "cancelled" = "Cancelled"
                "start_installing" = "Starting software installation"
                "installing" = "Installing"
                "install_success" = "installed successfully"
                "install_failed" = "installation failed"
                "platform_not_supported" = "Platform not supported"
                "installation_complete" = "Installation Complete"
                "total_installed" = "Total installed"
                
                "dev_mode" = "Dev mode: Show selected software without installing"
                "fake_install_mode" = "Fake install mode: Show installation process without actually installing"
                "fake_installing" = "Simulating install"
                
                "checking_installation" = "Checking installation status..."
                "skipping_installed" = "Already installed, skipping"
                "all_installed" = "All software already installed, nothing to do"
                
                "ask_continue" = "Installation complete. Continue installing other profiles?"
                "continue_btn" = "Continue"
                "exit_btn" = "Exit"
                
                "title_select_profile" = "Select Profile"
                "title_select_software" = "Select Software"
                "title_installing" = "Installing"
                "title_ask_continue" = "Continue Installing?"
                
                "lang_prompt" = "Please select language"
                "help_lang" = "Set language (en, zh, zh-Hant, ja, ko, de, fr, ar, pt, it)"
                "noninteractive_error" = "Non-interactive mode requires --profile parameter"
                "profile_not_found" = "Profile not found"
                "npm_not_found" = "npm not found, installing..."
                "winget_not_found" = "winget not found, cannot auto-install npm"
                
                "help_usage" = "Usage: quickstart.ps1 [OPTIONS]"
                "help_cfg_path" = "Use local profiles.json file"
                "help_cfg_url" = "Use remote profiles.json URL"
                "help_dev" = "Dev mode"
                "help_dry_run" = "Fake install: show process without installing"
                "help_fake_install" = "Alias for --dry-run (deprecated)"
                "help_yes" = "Auto-confirm all prompts"
                "help_verbose" = "Show detailed debug info"
                "help_log_file" = "Write logs to file"
                "help_export_plan" = "Export installation plan to file"
                "help_custom" = "Custom software selection mode"
                "help_retry_failed" = "Retry previously failed packages"
                "help_list_software" = "List all available software"
                "help_show_software" = "Show software details"
                "help_search" = "Search software"
                "help_validate" = "Validate configuration file"
                "help_report_json" = "Export JSON installation report"
                "help_report_txt" = "Export TXT installation report"
                "help_list_profiles" = "List all available profiles"
                "help_show_profile" = "Show profile details"
                "help_skip" = "Skip specified software (repeatable)"
                "help_only" = "Only install specified software (repeatable)"
                "help_fail_fast" = "Stop on first error"
                "help_profile" = "Select profile directly (skip menu)"
                "help_non_interactive" = "Non-interactive mode (no TUI/prompts)"
                "help_help" = "Show this help message"
                
                "validating_config" = "Validating configuration..."
                "json_valid" = "JSON syntax valid"
                "json_invalid" = "JSON syntax invalid"
                "profiles_count" = "Profiles"
                "software_count" = "Software entries"
                "validation_passed" = "Validation passed"
                "validation_failed" = "Validation failed"
                
                "search_results" = "Search results"
            }
        }
    }
}

# ============================================
# Logging functions
# ============================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Level -eq "DEBUG" -and -not $debug) { return }
    
    $color = switch ($Level) {
        "DEBUG"   { "DarkGray" }
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "STEP"    { "Magenta" }
        default   { "White" }
    }
    
    if ($Level -eq "DEBUG") {
        Write-Host $logEntry -ForegroundColor $color
    } elseif ($Level -eq "ERROR") {
        Write-Host $logEntry -ForegroundColor $color 2>&1
    } else {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    if ($logFile) {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Log "" "INFO"
    Write-Log "===== $Title =====" "INFO"
    Write-Log "" "INFO"
}

function Debug-Log {
    param([string]$Message)
    if ($debug) {
        Write-Log $Message "DEBUG"
    }
}

# ============================================
# Helper functions
# ============================================
function Get-LangText {
    param([string]$Text)
    if ($script:DETECTED_LANG -eq "zh-CN") {
        if ($Text -match "^(.+)/(.+)$") { return $Matches[1] }
    }
    if ($Text -match "^(.+)/(.+)$") { return $Matches[2] }
    return $Text
}

function Get-CurrentOS {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) { return "windows" }
        if ($IsMacOS) { return "macos" }
        if ($IsLinux) { return "linux" }
    }
    if ($env:OS -eq "Windows_NT") { return "windows" }
    return "unknown"
}

function Get-SystemInfo {
    $os = Get-CurrentOS
    switch ($os) {
        "windows" { 
            $ver = [System.Environment]::OSVersion.Version
            return "Windows $($ver.Major).$($ver.Minor)" 
        }
        "macos" { 
            try {
                $ver = sw_vers -productVersion 2>$null
                return "macOS $ver"
            } catch {
                return "macOS"
            }
        }
        "linux" { return "Linux" }
        default { return "Unknown" }
    }
}

function Get-PackageManager {
    param([string]$OS)
    if ($OS -eq "windows") {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) { return "winget" }
        return "none"
    } elseif ($OS -eq "macos") {
        $brew = Get-Command brew -ErrorAction SilentlyContinue
        if ($brew) { return "brew" }
        return "none"
    } elseif ($OS -eq "linux") {
        $apt = Get-Command apt -ErrorAction SilentlyContinue
        if ($apt) { return "apt" }
        $dnf = Get-Command dnf -ErrorAction SilentlyContinue
        if ($dnf) { return "dnf" }
        $pacman = Get-Command pacman -ErrorAction SilentlyContinue
        if ($pacman) { return "pacman" }
        return "none"
    }
    return "none"
}

function Get-LinuxField {
    param([string]$PkgMgr)
    switch ($PkgMgr) {
        "apt" { return "linux" }
        "dnf" { return "linux_dnf" }
        "pacman" { return "linux_pacman" }
        default { return "linux" }
    }
}

# ============================================
# JSON parsing functions
# ============================================
function Test-JsonValid {
    param([string]$Path)
    try {
        $null = Get-Content $Path -Raw | ConvertFrom-Json
        return $true
    } catch {
        return $false
    }
}

function Get-JsonValue {
    param([string]$Path, [string]$Query)
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        $keys = $Query.TrimStart('.').Split('.')
        $result = $data
        foreach ($k in $keys) {
            if ($k -match '^\[(\d+)\]$') {
                $idx = [int]$Matches[1]
                if ($result -is [Array] -and $idx -lt $result.Count) {
                    $result = $result[$idx]
                } else {
                    return ""
                }
            } elseif ($result.PSObject.Properties.Name -contains $k) {
                $result = $result.$k
            } else {
                return ""
            }
        }
        if ($result -eq $null) { return "" }
        return $result
    } catch {
        return ""
    }
}

function Get-ProfileKeys {
    param([string]$Path)
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        return $data.profiles.PSObject.Properties.Name
    } catch {
        return @()
    }
}

function Get-SoftwareKeys {
    param([string]$Path)
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        return $data.software.PSObject.Properties.Name
    } catch {
        return @()
    }
}

function Get-ProfileIncludes {
    param([string]$Path, [string]$Key)
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        $includes = $data.profiles.$Key.includes
        if ($includes) { return @($includes) } else { return @() }
    } catch {
        return @()
    }
}

function Get-ProfileField {
    param([string]$Path, [string]$Key, [string]$Field)
    $raw = Get-JsonValue -Path $Path -Query ".profiles.$Key.$Field"
    return Get-LangText -Text $raw
}

function Get-SoftwareField {
    param([string]$Path, [string]$Key, [string]$Field)
    $raw = Get-JsonValue -Path $Path -Query ".software.$Key.$Field"
    if ($Field -eq "name" -or $Field -eq "desc") {
        return Get-LangText -Text $raw
    }
    return $raw
}

# ============================================
# Installation check
# ============================================
function Test-SoftwareInstalled {
    param([string]$Path, [string]$OS, [string]$Key)
    
    $checkField = "check_$OS"
    if ($OS -eq "windows") { $checkField = "check_win" }
    elseif ($OS -eq "macos") { $checkField = "check_mac" }
    elseif ($OS -eq "linux") {
        $pkgMgr = Get-PackageManager -OS "linux"
        switch ($pkgMgr) {
            "dnf" { $checkField = "check_linux_dnf" }
            "pacman" { $checkField = "check_linux_pacman" }
            default { $checkField = "check_linux" }
        }
    }
    
    $checkCmd = Get-SoftwareField -Path $Path -Key $Key -Field $checkField
    
    Debug-Log "is_installed: key=$Key os=$OS check_field=$checkField cmd=[$checkCmd]"
    
    if (-not $checkCmd) { return $false }
    
    try {
        $result = Invoke-Expression "$checkCmd 2>`$null" 2>&1
        if ($LASTEXITCODE -eq 0) { return $true }
        return $false
    } catch {
        return $false
    }
}

# ============================================
# TUI Functions
# ============================================
function Show-Banner {
    param([string]$Lang)
    
    $title = switch ($Lang) {
        "zh-CN" { "快速配置新电脑软件环境" }
        "zh-Hant" { "快速設定新電腦軟件環境" }
        "ja" { "新PCのソフトウェア環境を素早く設定" }
        "ko" { "새 PC 소프트웨어 환경을 빠르게 설정" }
        "de" { "Schnelle Einrichtung für neue Computer" }
        "fr" { "Configuration rapide pour nouveaux ordinateurs" }
        "ar" { "إعداد سريع لأجهزة الكمبيوتر الجديدة" }
        "pt" { "Configuração rápida para novos computadores" }
        "it" { "Configurazione rapida per nuovi computer" }
        default { "Quick setup for new computers" }
    }
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  ██████╗ ███████╗██████╗  ██████╗    ║" -ForegroundColor Cyan
    Write-Host "║ ██╔═══██╗██╔════╝██╔══██╗██╔════╝    ║" -ForegroundColor Cyan
    Write-Host "║ ██║   ██║███████╗██████╔╝██║         ║" -ForegroundColor Cyan
    Write-Host "║ ██║▄▄ ██║╚════██║██╔═══╝ ██║         ║" -ForegroundColor Cyan
    Write-Host "║ ╚██████╔╝███████║██║     ╚██████╗    ║" -ForegroundColor Cyan
    Write-Host "║  ╚══▀▀═╝ ╚══════╝╚═╝      ╚═════╝    ║" -ForegroundColor Cyan
    Write-Host "║          Quickstart-PC              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Select-Language {
    if ($lang) {
        $mapped = $script:LANGUAGE_MAPPINGS[$lang]
        if ($mapped) { return $mapped }
        if ($script:SUPPORTED_LANGUAGES[$lang]) { return $lang }
        return "en-US"
    }
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  ██████╗ ███████╗██████╗  ██████╗    ║" -ForegroundColor Cyan
    Write-Host "║ ██╔═══██╗██╔════╝██╔══██╗██╔════╝    ║" -ForegroundColor Cyan
    Write-Host "║ ██║   ██║███████╗██████╔╝██║         ║" -ForegroundColor Cyan
    Write-Host "║ ██║▄▄ ██║╚════██║██╔═══╝ ██║         ║" -ForegroundColor Cyan
    Write-Host "║ ╚██████╔╝███████║██║     ╚██████╗    ║" -ForegroundColor Cyan
    Write-Host "║  ╚══▀▀═╝ ╚══════╝╚═╝      ╚═════╝    ║" -ForegroundColor Cyan
    Write-Host "║          Quickstart-PC              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "$($script:LANG["lang_prompt"]):" -ForegroundColor White
    Write-Host ""
    
    $items = @()
    $langCodes = @()
    
    foreach ($code in @("en-US", "zh-CN", "zh-Hant", "ja", "ko", "de", "fr", "ar", "pt", "it")) {
        if ($script:SUPPORTED_LANGUAGES[$code]) {
            $langCodes += $code
            $items += $script:SUPPORTED_LANGUAGES[$code]
        }
    }
    
    $cursor = 0
    
    $oldVisible = Get-CursorVisible
    Set-CursorVisible -Visible $false
    
    try {
        while ($true) {
            for ($i = 0; $i -lt $items.Count; $i++) {
                [Console]::SetCursorPosition(0, [Console]::CursorTop - $items.Count + $i)
                Write-Host ("`r" + (" " * 60))
                [Console]::SetCursorPosition(0, [Console]::CursorTop - $items.Count + $i)
            }
            
            for ($i = 0; $i -lt $items.Count; $i++) {
                if ($i -eq $cursor) {
                    Write-Host "  ▶ $($items[$i])" -ForegroundColor Yellow
                } else {
                    Write-Host "    $($items[$i])"
                }
            }
            
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                "UpArrow" { $cursor--; if ($cursor -lt 0) { $cursor = $items.Count - 1 } }
                "DownArrow" { $cursor++; if ($cursor -ge $items.Count) { $cursor = 0 } }
                "Enter" { break }
            }
        }
    } finally {
        Set-CursorVisible -Visible $oldVisible
    }
    
    Write-Host ""
    
    return $langCodes[$cursor]
}

function Show-ProfileMenu {
    param([string]$Path)
    
    $profileKeys = Get-ProfileKeys -Path $Path
    if ($profileKeys.Count -eq 0) {
        Write-Log "No profiles found" "ERROR"
        return ""
    }
    
    $menuItems = @()
    $profileData = @()
    
    foreach ($key in $profileKeys) {
        $name = Get-ProfileField -Path $Path -Key $key -Field "name"
        $desc = Get-ProfileField -Path $Path -Key $key -Field "desc"
        $icon = Get-ProfileField -Path $Path -Key $key -Field "icon"
        
        $menuItems += "$icon $name - $desc"
        $profileData += @{ Key = $key; Name = $name; Desc = $desc; Icon = $icon }
    }
    
    Write-Host ""
    Write-Header ($script:LANG["select_profiles"])
    Write-Host "  $($script:LANG["navigate"])" -ForegroundColor Cyan
    Write-Host ""
    
    $cursor = 0
    $oldVisible = Get-CursorVisible
    Set-CursorVisible -Visible $false
    
    try {
        while ($true) {
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                if ($i -eq $cursor) {
                    Write-Host "  ▶ $($menuItems[$i])" -ForegroundColor Yellow
                } else {
                    Write-Host "    $($menuItems[$i])"
                }
            }
            
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                "UpArrow" { 
                    $cursor--; 
                    if ($cursor -lt 0) { $cursor = $menuItems.Count - 1 } 
                }
                "DownArrow" { 
                    $cursor++; 
                    if ($cursor -ge $menuItems.Count) { $cursor = 0 } 
                }
                "Enter" { break }
            }
            
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
                Write-Host ("`r" + (" " * 80))
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
            }
        }
    } finally {
        Set-CursorVisible -Visible $oldVisible
    }
    
    Write-Host ""
    return $profileData[$cursor].Key
}

function Show-SoftwareMenu {
    param([string]$Path, [string]$OS, [string]$ProfileKey)
    
    $includes = Get-ProfileIncludes -Path $Path -Key $ProfileKey
    if ($includes.Count -eq 0) {
        Write-Log "No software in profile" "WARN"
        return @()
    }
    
    $filtered = @()
    foreach ($sw in $includes) {
        if ($only.Count -gt 0 -and $only -notcontains $sw) { continue }
        if ($skip.Count -gt 0 -and $skip -contains $sw) { continue }
        $filtered += $sw
    }
    
    if ($filtered.Count -eq 0) {
        Write-Log "No software after filtering" "WARN"
        return @()
    }
    
    $menuItems = @()
    $swData = @()
    $checked = @()
    
    $menuItems += $script:LANG["select_all"]
    $swData += @{ Key = "__select_all__"; Name = $script:LANG["select_all"] }
    $checked += $false
    
    foreach ($sw in $filtered) {
        $name = Get-SoftwareField -Path $Path -Key $sw -Field "name"
        $desc = Get-SoftwareField -Path $Path -Key $sw -Field "desc"
        
        $installed = Test-SoftwareInstalled -Path $Path -Key $sw -OS $OS
        $displayName = if ($installed) { "$name - $desc [$($script:LANG["installed"])]" } else { "$name - $desc" }
        
        $menuItems += $displayName
        $swData += @{ Key = $sw; Name = $name; Desc = $desc; Installed = $installed }
        $checked += $false
    }
    
    Write-Host ""
    Write-Header ($script:LANG["select_software"])
    Write-Host "  $($script:LANG["navigate_multi"])" -ForegroundColor Cyan
    Write-Host ""
    
    $cursor = 0
    $oldVisible = Get-CursorVisible
    Set-CursorVisible -Visible $false
    
    try {
        while ($true) {
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                $prefix = if ($checked[$i]) { $script:LANG["selected"] } else { $script:LANG["not_selected"] }
                
                if ($i -eq 0) {
                    $prefix = if ($checked[$i]) { "[✓] " } else { "[  ] " }
                }
                
                if ($i -eq $cursor) {
                    if ($checked[$i]) {
                        Write-Host "  $($prefix)$($menuItems[$i])" -ForegroundColor Yellow -BackgroundColor DarkGray
                    } else {
                        Write-Host "  ▶ $($menuItems[$i])" -ForegroundColor Yellow
                    }
                } else {
                    if ($checked[$i]) {
                        Write-Host "  $($prefix)$($menuItems[$i])" -ForegroundColor Green
                    } else {
                        Write-Host "  $($prefix)$($menuItems[$i])"
                    }
                }
            }
            
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                "UpArrow" { 
                    $cursor--; 
                    if ($cursor -lt 0) { $cursor = $menuItems.Count - 1 } 
                }
                "DownArrow" { 
                    $cursor++; 
                    if ($cursor -ge $menuItems.Count) { $cursor = 0 } 
                }
                "Spacebar" { 
                    if ($cursor -eq 0) {
                        $newState = -not $checked[0]
                        for ($i = 0; $i -lt $checked.Count; $i++) {
                            $checked[$i] = $newState
                        }
                    } else {
                        $checked[$cursor] = -not $checked[$cursor]
                    }
                }
                "Enter" { break }
            }
            
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
                Write-Host ("`r" + (" " * 80))
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
            }
        }
    } finally {
        Set-CursorVisible -Visible $oldVisible
    }
    
    Write-Host ""
    
    $selected = @()
    for ($i = 1; $i -lt $swData.Count; $i++) {
        if ($checked[$i]) {
            $selected += $swData[$i].Key
        }
    }
    
    return $selected
}

function Select-Continue {
    param([string]$ContinueText, [string]$ExitText)
    
    $cursor = 0
    $oldVisible = Get-CursorVisible
    Set-CursorVisible -Visible $false
    
    try {
        while ($true) {
            Write-Host "`r" -NoNewline
            if ($cursor -eq 0) {
                Write-Host "  ▶ $ContinueText    $ExitText" -ForegroundColor Yellow
            } else {
                Write-Host "    $ContinueText    ▶ $ExitText" -ForegroundColor Yellow
            }
            
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                "LeftArrow" { $cursor = 0 }
                "RightArrow" { $cursor = 1 }
                "Enter" { 
                    Set-CursorVisible -Visible $oldVisible
                    Write-Host ""
                    return $cursor 
                }
            }
        }
    } finally {
        Set-CursorVisible -Visible $oldVisible
    }
}

# ============================================
# Installation functions
# ============================================
function Install-Software {
    param([string]$Path, [string]$OS, [string]$Key)
    
    $platform = switch ($OS) {
        "windows" { "win" }
        "macos" { "mac" }
        "linux" { 
            $pkgMgr = Get-PackageManager -OS "linux"
            switch ($pkgMgr) {
                "dnf" { "linux_dnf" }
                "pacman" { "linux_pacman" }
                default { "linux" }
            }
        }
        default { "" }
    }
    
    $cmd = Get-SoftwareField -Path $Path -Key $Key -Field $platform
    
    if (-not $cmd) {
        Write-Log "$($script:LANG["platform_not_supported"]): $Key" "WARN"
        return $false
    }
    
    if ($dryRun) {
        Write-Log "$($script:LANG["fake_installing"]): $Key" "STEP"
        Write-Host "  → Command: $cmd" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 500
        Write-Log "$Key $($script:LANG["install_success"]) (simulated)" "SUCCESS"
        return $true
    }
    
    Write-Log "$($script:LANG["installing"]): $Key" "STEP"
    
    try {
        Invoke-Expression $cmd 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$Key $($script:LANG["install_success"])" "SUCCESS"
            return $true
        } else {
            Write-Log "$Key $($script:LANG["install_failed"])" "ERROR"
            return $false
        }
    } catch {
        Write-Log "$Key $($script:LANG["install_failed"]): $_" "ERROR"
        return $false
    }
}

# ============================================
# npm auto-detection and installation
# ============================================
function Ensure-NpmInstalled {
    param([string]$OS)
    
    $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if ($npmCmd) { return $true }
    
    Write-Log $script:LANG["npm_not_found"] "INFO"
    
    switch ($OS) {
        "macos" {
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                Write-Log "Installing node via brew..." "INFO"
                brew install node 2>&1 | Out-Null
            }
        }
        "linux" {
            switch ($script:PKG_MANAGER) {
                "apt" {
                    Write-Log "Installing npm via apt..." "INFO"
                    sudo apt install -y npm 2>&1 | Out-Null
                }
                "dnf" {
                    Write-Log "Installing npm via dnf..." "INFO"
                    sudo dnf install -y npm 2>&1 | Out-Null
                }
                "pacman" {
                    Write-Log "Installing npm via pacman..." "INFO"
                    sudo pacman -S npm --noconfirm 2>&1 | Out-Null
                }
            }
        }
        "windows" {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-Log "Installing Node.js via winget..." "INFO"
                winget install OpenJS.NodeJS --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            } else {
                Write-Log $script:LANG["winget_not_found"] "WARN"
            }
        }
    }
    
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    return (Get-Command npm -ErrorAction SilentlyContinue) -ne $null
}

# ============================================
# Help functions
# ============================================
function Show-Help {
    param([string]$Lang)
    
    $helpLang = $Lang
    if ($Lang -eq "en-US" -or $Lang -eq "default") { $helpLang = "en" }
    elseif ($Lang -eq "zh-CN") { $helpLang = "zh" }
    
    Initialize-LanguageStrings -Lang $Lang
    
    $h = $script:LANG
    
    Write-Host @"

Quickstart-PC - One-click computer setup

$($h["help_usage"])

$($h["help_lang"])
  --cfg-path PATH    $($h["help_cfg_path"])
  --cfg-url URL      $($h["help_cfg_url"])
  --dev              $($h["help_dev"])
  --dry-run          $($h["help_dry_run"])
  --fake-install     $($h["help_fake_install"])
  --yes, -y         $($h["help_yes"])
  --verbose, -v      $($h["help_verbose"])
  --log-file FILE    $($h["help_log_file"])
  --export-plan FILE $($h["help_export_plan"])
  --custom           $($h["help_custom"])
  --retry-failed     $($h["help_retry_failed"])
  --list-software    $($h["help_list_software"])
  --show-software ID $($h["help_show_software"])
  --search KEYWORD   $($h["help_search"])
  --validate         $($h["help_validate"])
  --report-json FILE $($h["help_report_json"])
  --report-txt FILE  $($h["help_report_txt"])
  --list-profiles    $($h["help_list_profiles"])
  --show-profile KEY $($h["help_show_profile"])
  --skip SW          $($h["help_skip"])
  --only SW          $($h["help_only"])
  --fail-fast        $($h["help_fail_fast"])
  --profile NAME     $($h["help_profile"])
  --non-interactive  $($h["help_non_interactive"])
  --help             $($h["help_help"])

"@ -ForegroundColor White
    
    exit 0
}

# ============================================
# Config file functions
# ============================================
function Get-ConfigFile {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
    
    if ($cfgUrl) {
        Write-Log "$($h["using_remote_config"]): $cfgUrl" "INFO"
        try {
            Invoke-WebRequest -Uri $cfgUrl -OutFile $tempFile -TimeoutSec 30 -ErrorAction Stop
            if (Test-JsonValid -Path $tempFile) {
                return $tempFile
            } else {
                Write-Log "$($h["config_invalid"]): $cfgUrl" "ERROR"
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                exit 1
            }
        } catch {
            Write-Log "$($h["config_not_found"]): $cfgUrl" "ERROR"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            exit 1
        }
    }
    
    if ($cfgPath) {
        if (Test-Path $cfgPath) {
            if (Test-JsonValid -Path $cfgPath) {
                Write-Log "$($h["using_custom_config"]): $cfgPath" "INFO"
                Copy-Item $cfgPath $tempFile -Force
                return $tempFile
            } else {
                Write-Log "$($h["config_invalid"]): $cfgPath" "ERROR"
                exit 1
            }
        } else {
            Write-Log "$($h["config_not_found"]): $cfgPath" "ERROR"
            exit 1
        }
    }
    
    Write-Log "$($h["using_default_config"])" "INFO"
    try {
        Invoke-WebRequest -Uri $DEFAULT_CFG_URL -OutFile $tempFile -TimeoutSec 30 -ErrorAction Stop
        if (Test-JsonValid -Path $tempFile) {
            return $tempFile
        }
    } catch {
        Write-Log "$($h["config_not_found"])" "ERROR"
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    Write-Log "$($h["config_not_found"])" "ERROR"
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    exit 1
}

# ============================================
# List/Show profiles
# ============================================
function Show-ListProfiles {
    $configFile = Get-ConfigFile
    $profileKeys = Get-ProfileKeys -Path $configFile
    
    Write-Host ""
    Write-Host "Available profiles:" -ForegroundColor White
    Write-Host ""
    
    foreach ($key in $profileKeys) {
        $name = Get-ProfileField -Path $configFile -Key $key -Field "name"
        $desc = Get-ProfileField -Path $configFile -Key $key -Field "desc"
        $icon = Get-ProfileField -Path $configFile -Key $key -Field "icon"
        Write-Host "  $icon $key - $name : $desc" -ForegroundColor White
    }
    
    Write-Host ""
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    exit 0
}

function Show-ShowProfile {
    param([string]$Key)
    
    $configFile = Get-ConfigFile
    $profileKeys = Get-ProfileKeys -Path $configFile
    
    if ($profileKeys -notcontains $Key) {
        Write-Log "Profile '$Key' not found" "ERROR"
        Remove-Item $configFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    $os = Get-CurrentOS
    $name = Get-ProfileField -Path $configFile -Key $Key -Field "name"
    $desc = Get-ProfileField -Path $configFile -Key $Key -Field "desc"
    $icon = Get-ProfileField -Path $configFile -Key $Key -Field "icon"
    $includes = Get-ProfileIncludes -Path $configFile -Key $Key
    
    Write-Host ""
    Write-Host "Profile: $icon $name" -ForegroundColor White
    Write-Host "Description: $desc" -ForegroundColor White
    Write-Host ""
    Write-Host "Included software:" -ForegroundColor White
    
    $supported = 0
    $unsupported = 0
    
    foreach ($sw in $includes) {
        $swName = Get-SoftwareField -Path $configFile -Key $sw -Field "name"
        $cmd = Get-SoftwareField -Path $configFile -Key $sw -Field $os
        
        if ($cmd) {
            Write-Host "  ✓ $swName" -ForegroundColor Green
            $supported++
        } else {
            Write-Host "  ✗ $swName (not supported on this platform)" -ForegroundColor Red
            $unsupported++
        }
    }
    
    Write-Host ""
    Write-Host "Summary: $supported supported, $unsupported unsupported on this platform" -ForegroundColor Cyan
    Write-Host ""
    
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# ============================================
# List/Show/Search software
# ============================================
function Show-ListSoftware {
    $configFile = Get-ConfigFile
    $softwareKeys = Get-SoftwareKeys -Path $configFile
    
    Write-Host ""
    Write-Host "Available software:" -ForegroundColor White
    Write-Host ""
    
    foreach ($key in $softwareKeys) {
        $name = Get-SoftwareField -Path $configFile -Key $key -Field "name"
        $desc = Get-SoftwareField -Path $configFile -Key $key -Field "desc"
        $tier = Get-SoftwareField -Path $configFile -Key $key -Field "tier"
        if (-not $tier) { $tier = "partial" }
        Write-Host "  $key - $name : $desc [$tier]" -ForegroundColor White
    }
    
    Write-Host ""
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    exit 0
}

function Show-ShowSoftware {
    param([string]$Key)
    
    $configFile = Get-ConfigFile
    
    $name = Get-SoftwareField -Path $configFile -Key $Key -Field "name"
    $desc = Get-SoftwareField -Path $configFile -Key $Key -Field "desc"
    
    if (-not $name) {
        Write-Log "Software '$Key' not found" "ERROR"
        Remove-Item $configFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    Write-Host ""
    Write-Host "Software: $name" -ForegroundColor White
    Write-Host "Description: $desc" -ForegroundColor White
    
    $tier = Get-SoftwareField -Path $configFile -Key $Key -Field "tier"
    if (-not $tier) { $tier = "partial" }
    Write-Host "Status: $tier" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Install commands:" -ForegroundColor White
    
    foreach ($osField in @("win", "mac", "linux", "linux_dnf", "linux_pacman")) {
        $cmd = Get-SoftwareField -Path $configFile -Key $Key -Field $osField
        if ($cmd) {
            Write-Host "  $osField : $cmd" -ForegroundColor Cyan
        }
    }
    Write-Host ""
    
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    exit 0
}

function Show-Search {
    param([string]$Keyword)
    
    $configFile = Get-ConfigFile
    $softwareKeys = Get-SoftwareKeys -Path $configFile
    
    Write-Host ""
    Write-Host "$($script:LANG["search_results"]) for '$Keyword':" -ForegroundColor White
    Write-Host ""
    
    foreach ($key in $softwareKeys) {
        $name = Get-SoftwareField -Path $configFile -Key $key -Field "name"
        $desc = Get-SoftwareField -Path $configFile -Key $key -Field "desc"
        
        if ("$key $name $desc" -match "(?i)$Keyword") {
            Write-Host "  $key - $name : $desc" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# ============================================
# Validate config
# ============================================
function Show-Validate {
    $configFile = Get-ConfigFile
    
    Write-Host ""
    Write-Host "$($script:LANG["validating_config"])" -ForegroundColor White
    Write-Host ""
    
    $errors = 0
    $warnings = 0
    
    if (Test-JsonValid -Path $configFile) {
        Write-Host "[✓] $($script:LANG["json_valid"])" -ForegroundColor Green
    } else {
        Write-Host "[✗] $($script:LANG["json_invalid"])" -ForegroundColor Red
        $errors++
    }
    
    $profileKeys = Get-ProfileKeys -Path $configFile
    $profileCount = $profileKeys.Count
    Write-Host "[✓] $($script:LANG["profiles_count"]): $profileCount" -ForegroundColor Green
    
    $softwareKeys = Get-SoftwareKeys -Path $configFile
    $softwareCount = $softwareKeys.Count
    Write-Host "[✓] $($script:LANG["software_count"]): $softwareCount" -ForegroundColor Green
    
    foreach ($pkey in $profileKeys) {
        $includes = Get-ProfileIncludes -Path $configFile -Key $pkey
        foreach ($sw in $includes) {
            if ($softwareKeys -notcontains $sw) {
                Write-Host "[✗] Profile '$pkey' references unknown software '$sw'" -ForegroundColor Red
                $errors++
            }
        }
    }
    
    $os = Get-CurrentOS
    foreach ($sw in $softwareKeys) {
        $hasPlatform = $false
        foreach ($platform in @("win", "mac", "linux", "linux_dnf", "linux_pacman")) {
            $cmd = Get-SoftwareField -Path $configFile -Key $sw -Field $platform
            if ($cmd) {
                $hasPlatform = $true
                break
            }
        }
        if (-not $hasPlatform) {
            Write-Host "[✗] Software '$sw' has no platform install commands" -ForegroundColor Red
            $errors++
        }
        
        $tier = Get-SoftwareField -Path $configFile -Key $sw -Field "tier"
        if ($tier -and @("stable", "partial", "experimental", "deprecated") -notcontains $tier) {
            Write-Host "[✗] Software '$sw' has invalid tier: '$tier'" -ForegroundColor Red
            $errors++
        }
    }
    
    Write-Host ""
    if ($errors -eq 0) {
        Write-Host "✓ $($script:LANG["validation_passed"]) ($softwareCount software, $profileCount profiles)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($script:LANG["validation_failed"]): $errors error(s), $warnings warning(s)" -ForegroundColor Red
    }
    
    Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# ============================================
# Export reports
# ============================================
function Export-Report {
    param(
        [string]$JsonPath,
        [string]$TxtPath,
        [array]$Installed,
        [array]$Skipped,
        [array]$Failed
    )
    
    $reportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $os = Get-CurrentOS
    $systemInfo = Get-SystemInfo
    
    if ($TxtPath) {
        $content = @"
=== Quickstart-PC Installation Report ===
Time: $reportTime
Platform: $os ($systemInfo)
Profile: $($script:SELECTED_PROFILES -join ', ')

Installed ($($Installed.Count)):
"@
        foreach ($item in $Installed) {
            $content += "`n  + $item"
        }
        $content += "`n`nSkipped ($($Skipped.Count)):"
        foreach ($item in $Skipped) {
            $content += "`n  ~ $item"
        }
        $content += "`n`nFailed ($($Failed.Count)):"
        foreach ($item in $Failed) {
            $content += "`n  - $item"
        }
        $content += "`n`nTotal: $($Installed.Count) installed, $($Skipped.Count) skipped, $($Failed.Count) failed"
        
        Set-Content -Path $TxtPath -Value $content -Encoding UTF8
        Write-Log "Text report exported to $TxtPath" "INFO"
    }
    
    if ($JsonPath) {
        $jsonObj = @{
            time = $reportTime
            platform = $os
            system_info = $systemInfo
            profiles = @($script:SELECTED_PROFILES)
            installed = $Installed
            skipped = $Skipped
            failed = $Failed
            summary = @{
                installed = $Installed.Count
                skipped = $Skipped.Count
                failed = $Failed.Count
            }
        }
        
        $jsonStr = $jsonObj | ConvertTo-Json -Depth 10
        Set-Content -Path $JsonPath -Value $jsonStr -Encoding UTF8
        Write-Log "JSON report exported to $JsonPath" "INFO"
    }
}

# ============================================
# Main execution
# ============================================
function Main {
    $script:LANG_OVERRIDE = $lang
    
    if ($help) {
        $helpLang = if ($lang) { 
            $mapped = $script:LANGUAGE_MAPPINGS[$lang]
            if ($mapped) { $mapped } else { "en-US" }
        } else { "en-US" }
        Initialize-LanguageStrings -Lang $helpLang
        Show-Help -Lang $helpLang
    }
    
    if ($listProfiles) {
        Show-ListProfiles
    }
    
    if ($showProfile) {
        Show-ShowProfile -Key $showProfile
    }
    
    if ($listSoftware) {
        Show-ListSoftware
    }
    
    if ($showSoftware) {
        Show-ShowSoftware -Key $showSoftware
    }
    
    if ($search) {
        Show-Search -Keyword $search
    }
    
    if ($validate) {
        Show-Validate
    }
    
    $script:DETECTED_LANG = Select-Language
    Initialize-LanguageStrings -Lang $script:DETECTED_LANG
    
    $h = $script:LANG
    
    trap {
        if ($script:CONFIG_FILE -and (Test-Path $script:CONFIG_FILE)) {
            Remove-Item $script:CONFIG_FILE -Force -ErrorAction SilentlyContinue
        }
        Set-WindowTitle -Title ""
        try { Set-CursorVisible -Visible $true } catch {}
    }
    
    while ($true) {
        Clear-Host
        try { Set-CursorVisible -Visible $false } catch {}
        
        Show-Banner -Lang $script:DETECTED_LANG
        
        if ($dev) { Write-Log $h["dev_mode"] "WARN"; Write-Host "" }
        if ($dryRun) { Write-Log $h["fake_install_mode"] "WARN"; Write-Host "" }
        
        Write-Log $h["detecting_system"] "INFO"
        $os = Get-CurrentOS
        $systemInfo = Get-SystemInfo
        $script:PKG_MANAGER = Get-PackageManager -OS $os
        
        Write-Log "$($h["system_info"]): $systemInfo" "INFO"
        
        $displayPm = $script:PKG_MANAGER
        if (Ensure-NpmInstalled -OS $os) {
            $displayPm += ", npm"
        }
        
        Write-Log "$($h["package_manager"]): $displayPm" "INFO"
        
        if ($os -eq "unknown") {
            Write-Log $h["unsupported_os"] "ERROR"
            exit 1
        }
        
        $script:CONFIG_FILE = Get-ConfigFile
        
        if ($nonInteractive) {
            if (-not $profile) {
                Write-Log $h["noninteractive_error"] "ERROR"
                exit 1
            }
            
            $profileKeys = Get-ProfileKeys -Path $script:CONFIG_FILE
            if ($profileKeys -notcontains $profile) {
                Write-Log "$($h["profile_not_found"]): $profile" "ERROR"
                exit 1
            }
            
            $script:SELECTED_PROFILES = @($profile)
            
            $includes = Get-ProfileIncludes -Path $script:CONFIG_FILE -Key $profile
            $script:SELECTED_SOFTWARE = @()
            foreach ($sw in $includes) {
                if ($only.Count -gt 0 -and $only -notcontains $sw) { continue }
                if ($skip.Count -gt 0 -and $skip -contains $sw) { continue }
                $script:SELECTED_SOFTWARE += $sw
            }
        }
        elseif ($profile) {
            $profileKeys = Get-ProfileKeys -Path $script:CONFIG_FILE
            if ($profileKeys -notcontains $profile) {
                Write-Log "$($h["profile_not_found"]): $profile" "ERROR"
                exit 1
            }
            
            $script:SELECTED_PROFILES = @($profile)
            $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $profile -Field "name"
            Set-WindowTitle -Title "QSPC | $profileName | $($h["title_select_software"])"
            $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $profile
        }
        else {
            Set-WindowTitle -Title "QSPC | $($h["title_select_profile"])"
            $script:SELECTED_PROFILES = @(Show-ProfileMenu -Path $script:CONFIG_FILE)
            
            if ($script:SELECTED_PROFILES.Count -eq 0) {
                Write-Log $h["no_profile_selected"] "WARN"
                exit 0
            }
            
            $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $script:SELECTED_PROFILES[0] -Field "name"
            Set-WindowTitle -Title "QSPC | $profileName | $($h["title_select_software"])"
            $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $script:SELECTED_PROFILES[0]
        }
        
        if ($script:SELECTED_SOFTWARE.Count -eq 0) {
            Write-Log $h["no_software_selected"] "WARN"
            
            if ($nonInteractive) {
                exit 0
            }
            
            Write-Host ""
            Write-Log $h["ask_continue"] "INFO"
            $continue = Select-Continue -ContinueText $h["continue_btn"] -ExitText $h["exit_btn"]
            if ($continue -eq 1) { exit 0 }
            continue
        }
        
        Write-Host ""
        Write-Log "Selected: $($script:SELECTED_SOFTWARE -join ', ')" "INFO"
        Write-Host ""
        
        if ($exportPlan) {
            $planContent = @"
# Quickstart-PC Installation Plan

**Platform:** $os ($(Get-SystemInfo))
**Profile:** $($script:SELECTED_PROFILES -join ', ')
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Software to Install ($($script:SELECTED_SOFTWARE.Count) total)

"@
            foreach ($sw in $script:SELECTED_SOFTWARE) {
                $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
                $swDesc = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "desc"
                $cmd = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "win"
                $isInstalled = Test-SoftwareInstalled -Path $script:CONFIG_FILE -OS $os -Key $sw
                if ($isInstalled) {
                    $planContent += "- ~~$swName~~ ($swDesc) - Already installed`n"
                } else {
                    $planContent += "- **$swName** ($swDesc)`n"
                    if ($cmd) {
                        $planContent += "  ``````powershell`n  $cmd`n  ```````n"
                    }
                }
            }
            $planContent += @"

## Summary
- Total selected: $($script:SELECTED_SOFTWARE.Count)
"@
            $installedCount = 0
            $toInstallCount = 0
            foreach ($sw in $script:SELECTED_SOFTWARE) {
                if (Test-SoftwareInstalled -Path $script:CONFIG_FILE -OS $os -Key $sw) {
                    $installedCount++
                } else {
                    $toInstallCount++
                }
            }
            $planContent += "- Already installed: $installedCount`n"
            $planContent += "- To install: $toInstallCount`n"
            
            Set-Content -Path $exportPlan -Value $planContent -Encoding UTF8
            Write-Log "Installation plan exported to $exportPlan" "INFO"
            if ($nonInteractive) { exit 0 }
        }
        
        if ($dev) {
            Write-Log "Dev mode: Done" "INFO"
            exit 0
        }
        
        if (-not $yes -and -not $nonInteractive) {
            Write-Host -NoNewline "$($h["confirm_install"]) "
            $confirm = [Console]::ReadKey($true)
            Write-Host ""
            
            if ($confirm.Key -eq "N" -or $confirm.Key -eq "n") {
                Write-Log $h["cancelled"] "INFO"
                Write-Host ""
                Write-Log $h["ask_continue"] "INFO"
                $continue = Select-Continue -ContinueText $h["continue_btn"] -ExitText $h["exit_btn"]
                if ($continue -eq 1) { exit 0 }
                continue
            }
        }
        
        Write-Log $h["checking_installation"] "INFO"
        
        $toInstall = @()
        $alreadyInstalled = @()
        
        foreach ($sw in $script:SELECTED_SOFTWARE) {
            $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
            
            if (Test-SoftwareInstalled -Path $script:CONFIG_FILE -OS $os -Key $sw) {
                Write-Host "  $($h["selected"])$swName - $($h["skipping_installed"])" -ForegroundColor Green
                $alreadyInstalled += $swName
            } else {
                Write-Host "  [→] $swName - $($h["installing"])" -ForegroundColor Cyan
                $toInstall += $sw
            }
        }
        Write-Host ""
        
        if ($toInstall.Count -eq 0) {
            Write-Log $h["all_installed"] "INFO"
            
            if ($nonInteractive) {
                exit 0
            }
            
            Write-Host ""
            Write-Log $h["ask_continue"] "INFO"
            $continue = Select-Continue -ContinueText $h["continue_btn"] -ExitText $h["exit_btn"]
            if ($continue -eq 1) { exit 0 }
            continue
        }
        
        Set-WindowTitle -Title "QSPC | $($h["title_installing"])"
        Write-Header $h["start_installing"]
        
        $total = $toInstall.Count
        $current = 0
        $installedList = @()
        $failedList = @()
        
        foreach ($sw in $toInstall) {
            $current++
            $percent = [math]::Round(($current * 100) / $total)
            $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
            Write-Host "`r$($h["installing"]) [$($percent.ToString("D3"))%] $swName" -NoNewline -ForegroundColor Cyan
            
            $result = Install-Software -Path $script:CONFIG_FILE -OS $os -Key $sw
            
            if ($result) {
                $installedList += $swName
            } else {
                $failedList += $swName
                if ($failFast) {
                    Write-Host ""
                    Write-Log "Fail-fast: stopping at $swName" "ERROR"
                    break
                }
            }
        }
        Write-Host ""
        
        $skippedList = $alreadyInstalled
        
        Write-Header $h["installation_complete"]
        Write-Host ""
        
        Write-Host "Installed:" -ForegroundColor Green
        Write-Log "Installed:" "INFO"
        if ($installedList.Count -eq 0) {
            Write-Host "  (none)" -ForegroundColor Gray
            Write-Log "  (none)" "INFO"
        } else {
            foreach ($item in $installedList) {
                Write-Host "  - $item" -ForegroundColor Green
                Write-Log "  - $item" "INFO"
            }
        }
        
        Write-Host ""
        Write-Host "Skipped:" -ForegroundColor Cyan
        Write-Log "" "INFO"
        Write-Log "Skipped:" "INFO"
        if ($skippedList.Count -eq 0) {
            Write-Host "  (none)" -ForegroundColor Gray
            Write-Log "  (none)" "INFO"
        } else {
            foreach ($item in $skippedList) {
                Write-Host "  - $item" -ForegroundColor Cyan
                Write-Log "  - $item" "INFO"
            }
        }
        
        Write-Host ""
        Write-Host "Failed:" -ForegroundColor Red
        Write-Log "" "INFO"
        Write-Log "Failed:" "INFO"
        if ($failedList.Count -eq 0) {
            Write-Host "  (none)" -ForegroundColor Gray
            Write-Log "  (none)" "INFO"
        } else {
            foreach ($item in $failedList) {
                Write-Host "  - $item" -ForegroundColor Red
                Write-Log "  - $item" "INFO"
            }
        }
        
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        Write-Log "" "INFO"
        Write-Log "Warnings:" "INFO"
        Write-Host "  (none)" -ForegroundColor Gray
        Write-Log "  (none)" "INFO"
        
        Write-Host ""
        Write-Log "$($h["total_installed"]) $($installedList.Count) / $total" "SUCCESS"
        
        if ($failedList.Count -gt 0) {
            if ($retryFailed -or $yes) {
                Write-Host ""
                Write-Log "Retrying $($failedList.Count) failed package(s)..." "INFO"
            } else {
                Write-Host ""
                $retry = Read-Host "Retry failed packages? [Y/n]"
                if ($retry -match "^[Nn]") {
                    Write-Log "Skipping retry" "INFO"
                } else {
                    $retryFailed = $true
                }
            }
            
            if ($retryFailed) {
                $retryInstalled = @()
                $retryFailedList = @()
                $retryTotal = $failedList.Count
                $retryCurrent = 0
                
                foreach ($item in $failedList) {
                    $retryCurrent++
                    $swKey = ""
                    foreach ($sw in $script:SELECTED_SOFTWARE) {
                        $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
                        if ($swName -eq $item) {
                            $swKey = $sw
                            break
                        }
                    }
                    if (-not $swKey) { continue }
                    
                    Write-Host "`r[Retry $($retryCurrent * 100 / $retryTotal)%] Installing $item" -NoNewline
                    
                    if (Install-Software -Path $script:CONFIG_FILE -OS $os -Key $swKey) {
                        $retryInstalled += $item
                    } else {
                        $retryFailedList += $item
                    }
                }
                Write-Host ""
                
                if ($retryInstalled.Count -gt 0) {
                    Write-Host ""
                    Write-Host "Retry succeeded:" -ForegroundColor Green
                    foreach ($item in $retryInstalled) {
                        Write-Host "  - $item" -ForegroundColor Green
                    }
                }
                if ($retryFailedList.Count -gt 0) {
                    Write-Host ""
                    Write-Host "Retry still failed:" -ForegroundColor Red
                    foreach ($item in $retryFailedList) {
                        Write-Host "  - $item" -ForegroundColor Red
                    }
                    $failedList = $retryFailedList
                } else {
                    $failedList = @()
                }
            }
        }
        
        if ($reportJson -or $reportTxt) {
            Export-Report -JsonPath $reportJson -TxtPath $reportTxt -Installed $installedList -Skipped $skippedList -Failed $failedList
        }
        
        if ($nonInteractive) {
            Set-WindowTitle -Title "QSPC"
            exit 0
        }
        
        Set-WindowTitle -Title "QSPC | $($h["title_ask_continue"])"
        Write-Host ""
        Write-Log $h["ask_continue"] "INFO"
        $continue = Select-Continue -ContinueText $h["continue_btn"] -ExitText $h["exit_btn"]
        if ($continue -eq 1) { exit 0 }
        
        continue
    }
}

Main
