# Quickstart-PC - PowerShell Version
# One-click computer setup for Windows/macOS/Linux
# Supports: powershell -ExecutionPolicy Bypass -File quickstart.ps1
# Or: iwr https://.../quickstart.ps1 | iex

param(
    [string]$lang = "__NONE__",
    [string]$cfgPath,
    [string]$cfgUrl,
    [switch]$dev,
    [switch]$dryRun,
    [switch]$doctor,
    [switch]$yes,
    [switch]$verbose,
    [string]$logFile,
  [string]$exportPlan,
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
    [string]$localLang,
[switch]$resume,
  [switch]$noResume,
  [switch]$update,
  [switch]$checkUpdate,
  [switch]$allowHooks,
  [switch]$help,
  [switch]$showVersion
)

$VERSION = "0.80.5"
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



# Script variables
$script:CONFIG_FILE = ""
$script:SELECTED_PROFILES = @()
$script:SELECTED_SOFTWARE = @()
$script:DETECTED_LANG = "en-US"
$script:PKG_MANAGER = "none"
$script:DEBUG = $debug
$script:INSTALL_LAST_ERROR = ""

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
function Select-Language {
    if ($script:LANG_OVERRIDE -eq "SELECT") {
        $script:LANG_OVERRIDE = ""
    }
    if ($script:LANG_OVERRIDE) {
        $mapped = $script:LANGUAGE_MAPPINGS[$script:LANG_OVERRIDE]
        if ($mapped) { return $mapped }
        foreach ($code in @("en-US", "zh-CN", "zh-Hant", "ja", "ko", "de", "fr", "ar", "pt", "it")) {
            if ($script:LANG_OVERRIDE -eq $code) { return $code }
        }
        return "en-US"
    }
    if (-not $script:LANG_OVERRIDE) {
        $langKeys = @("en-US", "zh-CN", "zh-Hant", "ja", "ko", "de", "fr", "ar", "pt", "it")
        $langNames = @("English", "简体中文", "繁體中文", "日本語", "한국어", "Deutsch", "Français", "العربية", "Português", "Italiano")
        $numLangs = $langKeys.Length
        $cursor = 0
        $startRow = [Console]::CursorTop
        $oldCursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false

        try {
            while ($true) {
                [Console]::SetCursorPosition(0, $startRow)
                Write-Host ""
                for ($i = 0; $i -lt $numLangs; $i++) {
                    if ($i -eq $cursor) {
                        Write-Host "  > $($langNames[$i])" -ForegroundColor Cyan
                    } else {
                        Write-Host "    $($langNames[$i])" -ForegroundColor Gray
                    }
                }
                Write-Host ""
                Write-Host "  [↑↓] Select  [Enter] Confirm" -ForegroundColor DarkGray -NoNewline

                $key = [Console]::ReadKey($true)
                switch ($key.Key) {
                    UpArrow { $cursor--; if ($cursor -lt 0) { $cursor = $numLangs - 1 } }
                    DownArrow { $cursor++; if ($cursor -ge $numLangs) { $cursor = 0 } }
                }
                if ($key.Key -eq [ConsoleKey]::Enter) { break }
            }
        } finally {
            [Console]::CursorVisible = $oldCursorVisible
        }
        $totalLines = $numLangs + 3
        for ($i = 0; $i -lt $totalLines; $i++) {
            [Console]::SetCursorPosition(0, $startRow + $i)
            Write-Host (" " * [Console]::WindowWidth) -NoNewline
        }
        [Console]::SetCursorPosition(0, $startRow)
        return $langKeys[$cursor]
    }
    return Detect-SystemLanguage
}

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
                
                
                "custom_space_toggle" = "空格: 切换选择"
                "custom_enter_confirm" = "回车: 确认"
                "custom_a_select_all" = "A: 全选/全不选"
                "custom_selected" = "已选择 %d/%d"
                
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
                "dry_run_mode" = "预览模式：展示安装过程但不实际安装"
                "dry_run_installing" = "模拟安装"
                
"checking_installation" = "正在检测安装情况..."
"skipping_installed" = "已安装，跳过"
"all_installed" = "所有软件均已安装，无需操作"
"to_install" = "待安装"
"retrying" = "重试中"
                
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

"help_usage" = "用法：quickstart.ps1 [选项]"
"help_cfg_path" = "使用本地 profiles.json 文件"
"help_cfg_url" = "使用远程 profiles.json URL"
                "help_dev" = "开发模式：显示选择的软件但不安装"
                "help_dry_run" = "预览模式：展示安装过程但不实际安装"
                "help_doctor" = "运行 QC Doctor 环境诊断"
                "help_yes" = "自动确认所有提示"
                "help_verbose" = "显示详细调试信息"
                "help_log_file" = "将日志写入文件"
  "help_export_plan" = "导出安装计划到文件"
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
                "help_version" = "显示版本信息"
                "help_help" = "显示此帮助信息"
                
                "validating_config" = "正在校验配置文件..."
                "json_valid" = "JSON 语法有效"
                "json_invalid" = "JSON 语法无效"
                "profiles_count" = "配置文件"
                "software_count" = "软件条目"
                "validation_passed" = "校验通过"
                "validation_failed" = "校验失败"
                
"search_results" = "搜索结果"
"error_detail" = "错误详情"
    "network_timeout" = "网络连接超时，请检查网络设置"
    "network_error" = "网络错误: {0}"
    "check_network" = "建议: 检查网络连接或设置代理"
    "permission_denied" = "权限不足: {0}"
    "permission_suggestion" = "建议: 使用 sudo 运行或联系管理员"
    "need_sudo" = "此操作需要管理员权限"
    "need_admin" = "请以管理员身份运行"
    "time_seconds" = "秒"
    "time_total" = "总耗时"
    "disk_space_low" = "磁盘空间不足: 可用 {0}GB，建议至少 {1}GB"
    "disk_space_warning" = "⚠ 磁盘空间较低，安装可能失败"
"disk_checking" = "检查磁盘空间..."
"resume_found" = "发现未完成的安装，是否继续？[Y/n]"
"resuming" = "从上次中断处继续安装..."
"checkpoint_saved" = "安装进度已保存"
"install_complete_state" = "安装完成，清理临时文件"
"update_checking" = "检查更新..."
"update_available" = "发现新版本: {0} (当前: {1})"
"update_latest" = "已是最新版本"
"update_downloading" = "下载更新..."
"update_success" = "更新成功！请重新运行脚本"
"update_failed" = "更新失败: {0}"
    "update_prompt" = "是否更新到新版本？[Y/n]"

"hook_running" = "执行钩子: {0}"
"hook_success" = "钩子执行完成"
"hook_failed" = "钩子执行失败: {0}"
"hooks_disabled" = "钩子脚本已禁用，使用 --allow-hooks 启用"
"hooks_enabled" = "钩子脚本已启用"
"batch_installing" = "批量安装 {0} 个软件..."
"batch_success" = "批量安装完成: {0}/{1} 成功"
"batch_failed" = "批量安装部分失败，回退逐个安装..."
}
}

# ============================================
# Japanese - ja
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
                
                
                "custom_space_toggle" = "スペース: 選択切替"
                "custom_enter_confirm" = "Enter: 確認"
                "custom_a_select_all" = "A: 全選択/全解除"
                "custom_selected" = "選択済み %d/%d"
                
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
                "dry_run_mode" = "プレビューモード：インストール過程を表示但不实际インストール"
                "dry_run_installing" = "インストールをシミュレート"
                
"checking_installation" = "インストール狀態を確認中..."
"skipping_installed" = "インストール済み、スキップ"
"all_installed" = "全てのソフトウェアがインストール済み、操作不要"
"to_install" = "インストール予定"
"retrying" = "再試行中"
                
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
                "help_dry_run" = "プレビューモード：インストール過程を表示但不实际インストール"
                "help_doctor" = "QC Doctor 環境診断を実行"
                "help_yes" = "全てのプロンプトに自動同意"
                "help_verbose" = "詳細なデバッグ情報を表示"
                "help_log_file" = "ログをファイルに書き込む"
  "help_export_plan" = "インストール計画をエクスポート"
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
                "help_version" = "バージョン情報を表示"
                "help_help" = "このヘルプを表示"
                
                "validating_config" = "設定ファイルを検証中..."
                "json_valid" = "JSON 構文有効"
                "json_invalid" = "JSON 構文無効"
                "profiles_count" = "プロファイル"
                "software_count" = "ソフトウェアエントリ"
                "validation_passed" = "検証成功"
                "validation_failed" = "検証失敗"
                
"search_results" = "検索結果"
"error_detail" = "エラー詳細"
    "network_timeout" = "ネットワーク接続がタイムアウトしました。ネットワーク設定を確認してください"
    "network_error" = "ネットワークエラー: {0}"
    "check_network" = "提案: ネットワーク接続を確認するかプロキシを設定してください"
    "permission_denied" = "権限がありません: {0}"
    "permission_suggestion" = "提案: sudo で実行するか管理者に連絡してください"
    "need_sudo" = "この操作には管理者権限が必要です"
    "need_admin" = "管理者として実行してください"
    "time_seconds" = "秒"
    "time_total" = "合計時間"
    "disk_space_low" = "ディスク容量不足: 利用可能 {0}GB、最低 {1}GB 推奨"
    "disk_space_warning" = "⚠ ディスク容量が少ないため、インストールに失敗する可能性があります"
"disk_checking" = "ディスク容量を確認中..."
"resume_found" = "未完了のインストールが見つかりました。続行しますか？[Y/n]"
"resuming" = "前回のチェックポイントから再開..."
"checkpoint_saved" = "インストール進捗が保存されました"
"install_complete_state" = "インストール完了、一時ファイルをクリーンアップ"
"update_checking" = "アップデートを確認中..."
"update_available" = "新しいバージョンがあります: {0} (現在: {1})"
"update_latest" = "最新バージョンです"
"update_downloading" = "アップデートをダウンロード中..."
"update_success" = "アップデート成功！スクリプトを再起動してください"
"update_failed" = "アップデート失敗: {0}"
    "update_prompt" = "新しいバージョンに更新しますか？[Y/n]"

"hook_running" = "フックを実行: {0}"
"hook_success" = "フックの実行が完了しました"
"hook_failed" = "フックの実行に失敗しました: {0}"
"hooks_disabled" = "フックスクリプトは無効です、--allow-hooks を使用して有効にしてください"
"hooks_enabled" = "フックスクリプトが有効になりました"
"batch_installing" = "{0} 個のパッケージを一括インストール中..."
"batch_success" = "一括インストール完了: {0}/{1} 成功"
"batch_failed" = "一括インストールが一部失敗しました、個別インストールにフォールバック..."
}
}

# ============================================
# Korean - ko
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
"not_selected" = "[ ] "
"select_all" = "모두 선택"
                "installed" = "설치됨"
                
                
                "custom_space_toggle" = "스페이스: 선택 전환"
                "custom_enter_confirm" = "Enter: 확인"
                "custom_a_select_all" = "A: 모두 선택/해제"
                "custom_selected" = "선택됨 %d/%d"
                
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
"dry_run_mode" = "미리보기 모드: 설치 과정 표시하지만 실제 설치하지 않음"
"dry_run_installing" = "설치 시뮬레이션"

"checking_installation" = "설치 상태 확인 중..."
"skipping_installed" = "이미 설치됨, 건너뛰기"
"all_installed" = "모든 소프트웨어가 이미 설치됨, 작업 없음"
"to_install" = "설치 예정"
"retrying" = "재시도 중"

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
"profile_not_found" = "프로필이 존재하지 않습니다"
"npm_not_found" = "npm을 찾을 수 없습니다, 설치 중..."
"winget_not_found" = "winget을 찾을 수 없습니다, npm을 자동 설치할 수 없습니다"

"help_usage" = "사용법: quickstart.ps1 [옵션]"
"help_cfg_path" = "로컬 profiles.json 파일 사용"
"help_cfg_url" = "원격 profiles.json URL 사용"
"help_dev" = "개발 모드: 선택한 소프트웨어 표시但不설치"
"help_dry_run" = "미리보기 모드: 설치 과정 표시但不실제 설치"
"help_doctor" = "QC Doctor 환경 진단 실행"
"help_yes" = "모든 프롬프트에 자동 동의"
"help_verbose" = "詳細한 디버그 정보 표시"
"help_log_file" = "로그를 파일에 쓰기"
  "help_export_plan" = "설치 계획을 파일로 내보내기"
  "help_retry_failed" = "이전에 실패한 패키지 재시도"
"help_list_software" = "사용 가능한 모든 소프트웨어 나열"
"help_show_software" = "지정한 소프트웨어 상세 정보 표시"
"help_search" = "소프트웨어 검색"
"help_validate" = "구성 파일 검증"
"help_report_json" = "JSON 형식으로 설치 보고서 내보내기"
"help_report_txt" = "TXT 형식으로 설치 보고서 내보내기"
"help_list_profiles" = "사용 가능한 모든 프로필 나열"
"help_show_profile" = "지정한 프로필 상세 정보 표시"
"help_skip" = "지정한 소프트웨어 건너뛰기 (반복 가능)"
"help_only" = "지정한 소프트웨어만 설치 (반복 가능)"
"help_fail_fast" = "첫 번째 오류에서 중지"
"help_profile" = "프로필 직접 선택 (메뉴 건너뛰기)"
"help_non_interactive" = "비대화형 모드 (TUI/프롬프트 모두 비활성화)"
"help_version" = "버전 정보 표시"
                "help_help" = "이 도움말 표시"

"validating_config" = "구성 파일 검증 중..."
"json_valid" = "JSON 구문 유효함"
"json_invalid" = "JSON 구문 유효하지 않음"
"profiles_count" = "프로필"
"software_count" = "소프트웨어 항목"
"validation_passed" = "검증 통과"
"validation_failed" = "검증 실패"

"search_results" = "검색 결과"
"error_detail" = "오류 상세"
    "network_timeout" = "네트워크 연결 시간 초과, 네트워크 설정을 확인하세요"
    "network_error" = "네트워크 오류: {0}"
    "check_network" = "제안: 네트워크 연결을 확인하거나 프록시를 설정하세요"
    "permission_denied" = "권한이 없습니다: {0}"
    "permission_suggestion" = "제안: sudo로 실행하거나 관리자에게 문의하세요"
    "need_sudo" = "이 작업에는 관리자 권한이 필요합니다"
    "need_admin" = "관리자로 실행해 주세요"
    "time_seconds" = "초"
    "time_total" = "총 소요 시간"
    "disk_space_low" = "디스크 공간 부족: 사용 가능 {0}GB, 최소 {1}GB 권장"
    "disk_space_warning" = "⚠ 디스크 공간이 부족하여 설치가 실패할 수 있습니다"
"disk_checking" = "디스크 공간 확인 중..."
"resume_found" = "미완료된 설치가 발견되었습니다. 계속하시겠습니까？[Y/n]"
"resuming" = "이전 체크포인트에서 재개..."
"checkpoint_saved" = "설치 진행 상태가 저장되었습니다"
"install_complete_state" = "설치 완료, 임시 파일 정리"
"update_checking" = "업데이트 확인 중..."
"update_available" = "새 버전 사용 가능: {0} (현재: {1})"
"update_latest" = "최신 버전입니다"
"update_downloading" = "업데이트 다운로드 중..."
"update_success" = "업데이트 성공! 스크립트를 다시 실행하세요"
"update_failed" = "업데이트 실패: {0}"
    "update_prompt" = "새 버전으로 업데이트하시겠습니까？[Y/n]"

"hook_running" = "후크 실행: {0}"
"hook_success" = "후크 실행 완료"
"hook_failed" = "후크 실행 실패: {0}"
"hooks_disabled" = "후크 스크립트가 비활성화되었습니다, --allow-hooks를 사용하여 활성화하세요"
"hooks_enabled" = "후크 스크립트가 활성화되었습니다"
"batch_installing" = "{0}개 패키지 일괄 설치 중..."
"batch_success" = "일괄 설치 완료: {0}/{1} 성공"
"batch_failed" = "일괄 설치가 부분적으로 실패했습니다, 개별 설치로 폴백..."
}
}

# ============================================
# Traditional Chinese - zh-Hant
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
                "dry_run_mode" = "預覽模式：展示安裝過程但不實際安裝"
                "dry_run_installing" = "模擬安裝"
                
"checking_installation" = "正在偵測安裝情況..."
"skipping_installed" = "已安裝，跳過"
"all_installed" = "所有軟件均已安裝，無需操作"
"to_install" = "待安裝"
"retrying" = "重試中"
                
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
                "help_dry_run" = "預覽模式：展示安裝過程但不實際安裝"
                "help_doctor" = "執行 QC Doctor 環境診斷"
                "help_yes" = "自動確認所有提示"
                "help_verbose" = "顯示詳細調試信息"
                "help_log_file" = "將日誌寫入文件"
  "help_export_plan" = "匯出安裝計劃到文件"
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
                "help_version" = "顯示版本信息"
                "help_help" = "顯示此幫助信息"
                
                "validating_config" = "正在驗證配置文件..."
                "json_valid" = "JSON 語法有效"
                "json_invalid" = "JSON 語法無效"
                "profiles_count" = "配置文件"
                "software_count" = "軟件條目"
                "validation_passed" = "驗證通過"
                "validation_failed" = "驗證失敗"
                
"search_results" = "搜尋結果"
"error_detail" = "錯誤詳情"
    "network_timeout" = "網路連線逾時，請檢查網路設定"
    "network_error" = "網路錯誤: {0}"
    "check_network" = "建議: 檢查網路連線或設定代理"
    "permission_denied" = "權限不足: {0}"
    "permission_suggestion" = "建議: 使用 sudo 執行或聯絡管理員"
    "need_sudo" = "此操作需要管理員權限"
    "need_admin" = "請以管理員身份執行"
    "time_seconds" = "秒"
    "time_total" = "總耗時"
    "disk_space_low" = "磁碟空間不足: 可用 {0}GB，建議至少 {1}GB"
    "disk_space_warning" = "⚠ 磁碟空間較低，安裝可能失敗"
"disk_checking" = "檢查磁碟空間..."

"custom_space_toggle" = "空格: 切換選擇"
"custom_enter_confirm" = "回車: 確認"
"custom_a_select_all" = "A: 全選/全不選"
"custom_selected" = "已選擇 %d/%d"
"resume_found" = "發現未完成的安裝，是否繼續？[Y/n]"
"resuming" = "從上次中斷處繼續安裝..."
"checkpoint_saved" = "安裝進度已儲存"
"install_complete_state" = "安裝完成，清理暫存檔"
"update_checking" = "檢查更新..."
"update_available" = "發現新版本: {0} (目前: {1})"
"update_latest" = "已是最新版本"
"update_downloading" = "下載更新..."
"update_success" = "更新成功！請重新執行腳本"
"update_failed" = "更新失敗: {0}"
    "update_prompt" = "是否更新到新版本？[Y/n]"

"hook_running" = "執行鉤子: {0}"
"hook_success" = "鉤子執行完成"
"hook_failed" = "鉤子執行失敗: {0}"
"hooks_disabled" = "鉤子腳本已禁用，使用 --allow-hooks 啟用"
"hooks_enabled" = "鉤子腳本已啟用"
"batch_installing" = "批量安裝 {0} 個軟體..."
"batch_success" = "批量安裝完成: {0}/{1} 成功"
"batch_failed" = "批量安裝部分失敗，回退逐個安裝..."
}
}

# ============================================
# German - de
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
                "dry_run_mode" = "Vorschau-Modus: Installationsprozess anzeigen ohne tatsächliche Installation"
                "dry_run_installing" = "Installation simulieren"
                
"checking_installation" = "Installationsstatus wird überprüft..."
"skipping_installed" = "Bereits installiert, überspringen"
"all_installed" = "Alle Software bereits installiert, nichts zu tun"
"to_install" = "zu installieren"
"retrying" = "Erneuter Versuch"
                
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
                "help_dry_run" = "Vorschau-Modus: Installationsprozess anzeigen ohne tatsächliche Installation"
                "help_doctor" = "QC Doctor Umgebungsdiagnose ausführen"
                "help_yes" = "Alle Prompts automatisch bestätigen"
                "help_verbose" = "Detaillierte Debug-Infos anzeigen"
                "help_log_file" = "Logs in Datei schreiben"
  "help_export_plan" = "Installationsplan exportieren"
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
                "help_version" = "Versionsinfo anzeigen"
                "help_help" = "Diese Hilfemeldung anzeigen"
                
                "validating_config" = "Konfiguration wird validiert..."
                "json_valid" = "JSON-Syntax gültig"
                "json_invalid" = "JSON-Syntax ungültig"
                "profiles_count" = "Profile"
                "software_count" = "Softwareeinträge"
                "validation_passed" = "Validierung erfolgreich"
                "validation_failed" = "Validierung fehlgeschlagen"
                
"search_results" = "Suchergebnisse"
"error_detail" = "Fehlerdetail"
    "network_timeout" = "Netzwerkverbindung zeitüberschreitung, bitte überprüfen Sie Ihre Netzwerkeinstellungen"
    "network_error" = "Netzwerkfehler: {0}"
    "check_network" = "Vorschlag: Überprüfen Sie die Netzwerkverbindung oder richten Sie einen Proxy ein"
    "permission_denied" = "Berechtigung verweigert: {0}"
    "permission_suggestion" = "Vorschlag: Mit sudo ausführen oder Administrator kontaktieren"
    "need_sudo" = "Dieser Vorgang erfordert Administratorrechte"
    "need_admin" = "Bitte als Administrator ausführen"
    "time_seconds" = "s"
    "time_total" = "Gesamtzeit"
    "disk_space_low" = "Wenig Speicherplatz: {0}GB verfügbar, mindestens {1}GB empfohlen"
    "disk_space_warning" = "⚠ Wenig Speicherplatz, Installation könnte fehlschlagen"
"disk_checking" = "Speicherplatz wird überprüft..."

"custom_space_toggle" = "Leertaste: umschalten"
"custom_enter_confirm" = "Enter: bestätigen"
"custom_a_select_all" = "A: alle auswählen/abwählen"
"custom_selected" = "Ausgewählt %d/%d"
"resume_found" = "Unvollständige Installation gefunden. Fortsetzen? [Y/n]"
"resuming" = "Fortsetzung vom letzten Checkpoint..."
"checkpoint_saved" = "Installationsfortschritt gespeichert"
"install_complete_state" = "Installation abgeschlossen, temporäre Dateien werden bereinigt"
"update_checking" = "Suche nach Updates..."
"update_available" = "Neue Version verfügbar: {0} (aktuell: {1})"
"update_latest" = "Bereits auf der neuesten Version"
"update_downloading" = "Update wird heruntergeladen..."
"update_success" = "Update erfolgreich! Bitte starten Sie das Skript neu"
"update_failed" = "Update fehlgeschlagen: {0}"
    "update_prompt" = "Auf neue Version aktualisieren? [Y/n]"

"hook_running" = "Hook wird ausgeführt: {0}"
"hook_success" = "Hook abgeschlossen"
"hook_failed" = "Hook fehlgeschlagen: {0}"
"hooks_disabled" = "Hooks deaktiviert, verwenden Sie --allow-hooks zum Aktivieren"
"hooks_enabled" = "Hooks aktiviert"
"batch_installing" = "Batch-Installation von {0} Paketen..."
"batch_success" = "Batch-Installation abgeschlossen: {0}/{1} erfolgreich"
"batch_failed" = "Batch-Installation teilweise fehlgeschlagen, Rückgriff auf Einzelinstallation..."
}
}

# ============================================
# French - fr
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
                "dry_run_mode" = "Mode aperçu : afficher le processus sans installer"
                "dry_run_installing" = "Simulation en cours"
                
"checking_installation" = "Vérification du statut d'installation..."
"skipping_installed" = "Déjà installé, ignoré"
"all_installed" = "Tous les logiciels déjà installés, rien à faire"
"to_install" = "à installer"
"retrying" = "Nouvelle tentative"
                
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
                "help_dev" = "Mode développement: afficher les selections sans installer"
                "help_dry_run" = "Mode aperçu : afficher le processus sans installer"
                "help_doctor" = "Exécuter les diagnostics QC Doctor"
                "help_yes" = "Confirmer automatiquement toutes les invites"
                "help_verbose" = "Afficher les infos de débogage détaillées"
                "help_log_file" = "Écrire les logs dans un fichier"
  "help_export_plan" = "Exporter le plan d'installation"
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
                "help_version" = "Afficher les infos de version"
                "help_help" = "Afficher ce message d'aide"
                
                "validating_config" = "Validation de la configuration..."
                "json_valid" = "Syntaxe JSON valide"
                "json_invalid" = "Syntaxe JSON invalide"
                "profiles_count" = "Profils"
                "software_count" = "Entrées logicielles"
                "validation_passed" = "Validation réussie"
                "validation_failed" = "Validation échouée"
                
"search_results" = "Résultats de recherche"
"error_detail" = "Détail de l'erreur"
    "network_timeout" = "Délai de connexion réseau dépassé, veuillez vérifier vos paramètres réseau"
    "network_error" = "Erreur réseau : {0}"
    "check_network" = "Suggestion : Vérifiez la connexion réseau ou configurez un proxy"
    "permission_denied" = "Permission refusée : {0}"
    "permission_suggestion" = "Suggestion : Exécutez avec sudo ou contactez votre administrateur"
    "need_sudo" = "Cette opération nécessite des privilèges d'administrateur"
    "need_admin" = "Veuillez exécuter en tant qu'administrateur"
    "time_seconds" = "s"
    "time_total" = "Temps total"
    "disk_space_low" = "Espace disque insuffisant : {0}GB disponible, au moins {1}GB recommandé"
    "disk_space_warning" = "⚠ Espace disque faible, l'installation peut échouer"
"disk_checking" = "Vérification de l'espace disque..."

"custom_space_toggle" = "Espace: basculer"
"custom_enter_confirm" = "Entrée: confirmer"
"custom_a_select_all" = "A: tout sélectionner/désélectionner"
"custom_selected" = "Sélectionné %d/%d"
"resume_found" = "Installation incomplète trouvée. Reprendre ? [Y/n]"
"resuming" = "Reprise depuis le dernier point de contrôle..."
"checkpoint_saved" = "Progression de l'installation sauvegardée"
"install_complete_state" = "Installation terminée, nettoyage des fichiers temporaires"
"update_checking" = "Vérification des mises à jour..."
"update_available" = "Nouvelle version disponible : {0} (actuelle : {1})"
"update_latest" = "Déjà sur la dernière version"
"update_downloading" = "Téléchargement de la mise à jour..."
"update_success" = "Mise à jour réussie ! Veuillez redémarrer le script"
"update_failed" = "Échec de la mise à jour : {0}"
    "update_prompt" = "Mettre à jour vers la nouvelle version ? [Y/n]"

"hook_running" = "Exécution du hook : {0}"
"hook_success" = "Hook terminé"
"hook_failed" = "Échec du hook : {0}"
"hooks_disabled" = "Hooks désactivés, utilisez --allow-hooks pour activer"
"hooks_enabled" = "Hooks activés"
"batch_installing" = "Installation groupée de {0} paquets..."
"batch_success" = "Installation groupée terminée : {0}/{1} réussis"
"batch_failed" = "Installation groupée partiellement échouée, retour à l'installation individuelle..."
}
}

# ============================================
# Arabic - ar (LTR for terminal compatibility)
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
                "dry_run_mode" = "وضع المعاينة: عرض عملية التثبيت بدون تثبيت فعلي"
                "dry_run_installing" = "جاري المحاكاة"
                
"checking_installation" = "التحقق من حالة التثبيت..."
"skipping_installed" = "مثبت بالفعل، تخطي"
"all_installed" = "جميع البرامج مثبتة بالفعل، لا شيء القيام به"
"to_install" = "للتثبيت"
"retrying" = "إعادة المحاولة"
                
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
                "help_dry_run" = "وضع المعاينة: عرض عملية التثبيت بدون تثبيت فعلي"
                "help_doctor" = "تشغيل تشخيص بيئة QC Doctor"
                "help_yes" = "تأكيد جميع الأسئلة تلقائياً"
                "help_verbose" = "إظهار معلومات التصحيح التفصيلية"
                "help_log_file" = "كتابة السجلات في ملف"
  "help_export_plan" = "تصدير خطة التثبيت"
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
                "help_version" = "عرض معلومات الإصدار"
                "help_help" = "إظهار رسالة المساعدة هذه"
                
                "validating_config" = "جاري التحقق من ملف التكوين..."
                "json_valid" = "صيغة JSON صالحة"
                "json_invalid" = "صيغة JSON غير صالحة"
                "profiles_count" = "الملفات الشخصية"
                "software_count" = "إدخالات البرامج"
                "validation_passed" = "التحقق نجح"
                "validation_failed" = "التحقق فشل"
                
"search_results" = "نتائج البحث"
"error_detail" = "تفاصيل الخطأ"
    "network_timeout" = "انتهت مهلة اتصال الشبكة، يرجى التحقق من إعدادات الشبكة"
    "network_error" = "خطأ في الشبكة: {0}"
    "check_network" = "اقتراح: تحقق من اتصال الشبكة أو قم بإعداد وكيل"
    "permission_denied" = "تم رفض الإذن: {0}"
    "permission_suggestion" = "اقتراح: تشغيل مع sudo أو الاتصال بالمسؤول"
    "need_sudo" = "تتطلب هذه العملية امتيازات المسؤول"
    "need_admin" = "يرجى التشغيل كمسؤول"
    "time_seconds" = "ث"
    "time_total" = "الوقت الإجمالي"
    "disk_space_low" = "مساحة قرص غير كافية: {0}GB متاح، يوصى بـ {1}GB على الأقل"
    "disk_space_warning" = "⚠ مساحة القرص منخفضة، قد يفشل التثبيت"
"disk_checking" = "جاري التحقق من مساحة القرص..."

"custom_space_toggle" = "مسافة: تبديل"
"custom_enter_confirm" = "Enter: تأكيد"
"custom_a_select_all" = "A: تحديد/إلغاء تحديد الكل"
"custom_selected" = "تم الاختيار %d/%d"
"resume_found" = "تم العثور على تثبيت غير مكتمل. المتابعة؟ [Y/n]"
"resuming" = "استئناف من آخر نقطة تحقق..."
"checkpoint_saved" = "تم حفظ تقدم التثبيت"
"install_complete_state" = "اكتمل التثبيت، تنظيف الملفات المؤقتة"
"update_checking" = "التحقق من التحديثات..."
"update_available" = "يتوفر إصدار جديد: {0} (الحالي: {1})"
"update_latest" = "أنت على أحدث إصدار"
"update_downloading" = "تحميل التحديث..."
"update_success" = "تم التحديث بنجاح! يرجى إعادة تشغيل البرنامج النصي"
"update_failed" = "فشل التحديث: {0}"
    "update_prompt" = "هل تريد التحديث إلى الإصدار الجديد؟ [Y/n]"

"hook_running" = "تشغيل البرنامج النصي: {0}"
"hook_success" = "اكتمل البرنامج النصي"
"hook_failed" = "فشل البرنامج النصي: {0}"
"hooks_disabled" = "البرامج النصية معطلة، استخدم --allow-hooks للتمكين"
"hooks_enabled" = "البرامج النصية ممكنة"
"batch_installing" = "تثبيت {0} حزمة دفعة واحدة..."
"batch_success" = "اكتمل التثبيت الدفعي: {0}/{1} نجح"
"batch_failed" = "فشل التثبيت الدفعي جزئياً، الرجوع إلى التثبيت الفردي..."
}
}

# ============================================
# Portuguese - pt
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
                "dry_run_mode" = "Modo visualização: mostrar processo sem instalar"
                "dry_run_installing" = "Simulando instalação"
                
"checking_installation" = "Verificando status da instalação..."
"skipping_installed" = "Já instalado, pulando"
"all_installed" = "Todo software já instalado, nada a fazer"
"to_install" = "a instalar"
"retrying" = "Tentando novamente"
                
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
                "help_dry_run" = "Modo visualização: mostrar processo sem instalar"
                "help_doctor" = "Executar diagnósticos QC Doctor"
                "help_yes" = "Confirmar automaticamente todos os prompts"
                "help_verbose" = "Mostrar informações de debug detalhadas"
                "help_log_file" = "Escrever logs em arquivo"
  "help_export_plan" = "Exportar plano de instalação"
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
                "help_version" = "Mostrar informações da versão"
                "help_help" = "Mostrar esta mensagem de ajuda"
                
                "validating_config" = "Validando configuração..."
                "json_valid" = "Sintaxe JSON válida"
                "json_invalid" = "Sintaxe JSON inválida"
                "profiles_count" = "Perfis"
                "software_count" = "Entradas de software"
                "validation_passed" = "Validação bem-sucedida"
                "validation_failed" = "Validação falhou"
                
"search_results" = "Resultados da pesquisa"
"error_detail" = "Detalhe do erro"
    "network_timeout" = "Tempo limite de conexão de rede esgotado, verifique suas configurações de rede"
    "network_error" = "Erro de rede: {0}"
    "check_network" = "Sugestão: Verifique a conexão de rede ou configure um proxy"
    "permission_denied" = "Permissão negada: {0}"
    "permission_suggestion" = "Sugestão: Execute com sudo ou contate o administrador"
    "need_sudo" = "Esta operação requer privilégios de administrador"
    "need_admin" = "Por favor, execute como Administrador"
    "time_seconds" = "s"
    "time_total" = "Tempo total"
    "disk_space_low" = "Espaço em disco insuficiente: {0}GB disponível, pelo menos {1}GB recomendado"
    "disk_space_warning" = "⚠ Espaço em disco baixo, a instalação pode falhar"
"disk_checking" = "Verificando espaço em disco..."

"custom_space_toggle" = "Espaço: alternar"
"custom_enter_confirm" = "Enter: confirmar"
"custom_a_select_all" = "A: selecionar/deselecionar tudo"
"custom_selected" = "Selecionado %d/%d"
"resume_found" = "Instalação incompleta encontrada. Continuar? [Y/n]"
"resuming" = "Retomando do último ponto de verificação..."
"checkpoint_saved" = "Progresso da instalação salvo"
"install_complete_state" = "Instalação concluída, limpando arquivos temporários"
"update_checking" = "Verificando atualizações..."
"update_available" = "Nova versão disponível: {0} (atual: {1})"
"update_latest" = "Já está na versão mais recente"
"update_downloading" = "Baixando atualização..."
"update_success" = "Atualização bem-sucedida! Por favor, reinicie o script"
"update_failed" = "Falha na atualização: {0}"
    "update_prompt" = "Atualizar para a nova versão? [Y/n]"

"hook_running" = "Executando hook: {0}"
"hook_success" = "Hook concluído"
"hook_failed" = "Falha no hook: {0}"
"hooks_disabled" = "Hooks desativados, use --allow-hooks para ativar"
"hooks_enabled" = "Hooks ativados"
"batch_installing" = "Instalação em lote de {0} pacotes..."
"batch_success" = "Instalação em lote concluída: {0}/{1} sucedidos"
"batch_failed" = "Instalação em lote parcialmente falhou, voltando à instalação individual..."
}
}

# ============================================
# Italian - it
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
                "dry_run_mode" = "Modalità anteprima: mostra processo senza installare"
                "dry_run_installing" = "Simulazione in corso"
                
"checking_installation" = "Verifica stato installazione..."
"skipping_installed" = "Già installato, salto"
"all_installed" = "Tutto il software già installato, niente da fare"
"to_install" = "da installare"
"retrying" = "Nuovo tentativo"
                
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
                "help_dry_run" = "Modalità anteprima: mostra processo senza installare"
                "help_doctor" = "Esegui diagnosi ambiente QC Doctor"
                "help_yes" = "Conferma automaticamente tutti i prompt"
                "help_verbose" = "Mostra info di debug dettagliate"
                "help_log_file" = "Scrivi log su file"
  "help_export_plan" = "Esporta piano di installazione"
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
                "help_version" = "Mostra informazioni versione"
                "help_help" = "Mostra questo messaggio di aiuto"
                
                "validating_config" = "Validazione configurazione..."
                "json_valid" = "Sintassi JSON valida"
                "json_invalid" = "Sintassi JSON non valida"
                "profiles_count" = "Profili"
                "software_count" = "Voci software"
                "validation_passed" = "Validazione superata"
                "validation_failed" = "Validazione fallita"
                
"search_results" = "Risultati della ricerca"
"error_detail" = "Dettaglio errore"
    "network_timeout" = "Timeout di connessione di rete, controllare le impostazioni di rete"
    "network_error" = "Errore di rete: {0}"
    "check_network" = "Suggerimento: Controllare la connessione di rete o impostare un proxy"
    "permission_denied" = "Permesso negato: {0}"
    "permission_suggestion" = "Suggerimento: Eseguire con sudo o contattare l'amministratore"
    "need_sudo" = "Questa operazione richiede privilegi di amministratore"
    "need_admin" = "Eseguire come amministratore"
    "time_seconds" = "s"
    "time_total" = "Tempo totale"
    "disk_space_low" = "Spazio su disco insufficiente: {0}GB disponibile, almeno {1}GB consigliato"
    "disk_space_warning" = "⚠ Spazio su disco insufficiente, l'installazione potrebbe fallire"
"disk_checking" = "Verifica dello spazio su disco..."

"custom_space_toggle" = "Spazio: alterna"
"custom_enter_confirm" = "Invio: conferma"
"custom_a_select_all" = "A: seleziona/deseleziona tutto"
"custom_selected" = "Selezionato %d/%d"
"resume_found" = "Installazione incompleta trovata. Riprendere? [Y/n]"
"resuming" = "Ripresa dall'ultimo checkpoint..."
"checkpoint_saved" = "Progresso dell'installazione salvato"
"install_complete_state" = "Installazione completata, pulizia file temporanei"
"update_checking" = "Verifica aggiornamenti..."
"update_available" = "Nuova versione disponibile: {0} (attuale: {1})"
"update_latest" = "Già sull'ultima versione"
"update_downloading" = "Download aggiornamento..."
"update_success" = "Aggiornamento riuscito! Riavviare lo script"
"update_failed" = "Aggiornamento fallito: {0}"
    "update_prompt" = "Aggiornare alla nuova versione? [Y/n]"

"hook_running" = "Esecuzione hook: {0}"
"hook_success" = "Hook completato"
"hook_failed" = "Hook fallito: {0}"
"hooks_disabled" = "Hook disabilitati, usa --allow-hooks per abilitare"
"hooks_enabled" = "Hook abilitati"
"batch_installing" = "Installazione batch di {0} pacchetti..."
"batch_success" = "Installazione batch completata: {0}/{1} riusciti"
"batch_failed" = "Installazione batch parzialmente fallita, ritorno all'installazione individuale..."
}
}

# ============================================
# English (default) - en-US
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
                "dry_run_mode" = "Preview mode: Show process without installing"
                "dry_run_installing" = "Simulating install"
                
"checking_installation" = "Checking installation status..."
"skipping_installed" = "Already installed, skipping"
"all_installed" = "All software already installed, nothing to do"
"to_install" = "to install"
"retrying" = "Retrying"
                
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
                "help_dry_run" = "Preview mode: Show process without installing"
                "help_doctor" = "Run QC Doctor environment diagnostics"
                "help_yes" = "Auto-confirm all prompts"
                "help_verbose" = "Show detailed debug info"
                "help_log_file" = "Write logs to file"
  "help_export_plan" = "Export installation plan to file"
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
                "help_version" = "Show version information"
                "help_help" = "Show this help message"
                
                "validating_config" = "Validating configuration..."
                "json_valid" = "JSON syntax valid"
                "json_invalid" = "JSON syntax invalid"
                "profiles_count" = "Profiles"
                "software_count" = "Software entries"
                "validation_passed" = "Validation passed"
                "validation_failed" = "Validation failed"
                
"search_results" = "Search results"
"error_detail" = "Error detail"
    "network_timeout" = "Network connection timed out, please check your network"
    "network_error" = "Network error: {0}"
    "check_network" = "Suggestion: Check network connection or set proxy"
    "permission_denied" = "Permission denied: {0}"
    "permission_suggestion" = "Suggestion: Run with sudo or contact your administrator"
    "need_sudo" = "This operation requires administrator privileges"
    "need_admin" = "Please run as Administrator"
    "time_seconds" = "s"
    "time_total" = "Total time"
    "disk_space_low" = "Low disk space: {0}GB available, at least {1}GB recommended"
    "disk_space_warning" = "⚠ Low disk space, installation may fail"
"disk_checking" = "Checking disk space..."

"custom_space_toggle" = "Space: toggle"
"custom_enter_confirm" = "Enter: confirm"
"custom_a_select_all" = "A: select/deselect all"
"custom_selected" = "Selected %d/%d"
"resume_found" = "Incomplete installation found. Resume? [Y/n]"
"resuming" = "Resuming from last checkpoint..."
"checkpoint_saved" = "Installation progress saved"
"install_complete_state" = "Installation complete, cleaning up"
"update_checking" = "Checking for updates..."
"update_available" = "New version available: {0} (current: {1})"
"update_latest" = "Already on the latest version"
"update_downloading" = "Downloading update..."
"update_success" = "Update successful! Please restart the script"
"update_failed" = "Update failed: {0}"
    "update_prompt" = "Update to new version? [Y/n]"

"hook_running" = "Running hook: {0}"
"hook_success" = "Hook completed"
"hook_failed" = "Hook failed: {0}"
"hooks_disabled" = "Hooks disabled, use --allow-hooks to enable"
"hooks_enabled" = "Hooks enabled"
"batch_installing" = "Batch installing {0} packages..."
"batch_success" = "Batch install complete: {0}/{1} succeeded"
"batch_failed" = "Batch install partially failed, falling back to individual install..."
        }
    }
}


# ============================================
# Main script logic
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

function Install-Batch {
  param([string]$Path, [string]$OS, [string]$Manager, [string[]]$Keys)

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

  $packages = @()
  $batchable = $true

  foreach ($key in $Keys) {
    $cmd = Get-SoftwareField -Path $Path -Key $key -Field $platform
    $pkgName = ""
    switch ($Manager) {
      "apt" {
        $pkgName = ($cmd -replace 'sudo apt install[^ ]* ', '') -split ' ' | Select-Object -First 1
      }
      "brew" {
        $pkgName = ($cmd -split ' ') | Select-Object -Last 1
      }
      "winget" {
        $pkgName = ($cmd -replace 'winget install ', '') -split ' ' | Select-Object -First 1
      }
      "npm" {
        $pkgName = ($cmd -replace 'npm install[^ ]* ', '') -split ' ' | Select-Object -First 1
      }
      "dnf" {
        $pkgName = ($cmd -replace 'sudo dnf install[^ ]* ', '') -split ' ' | Select-Object -First 1
      }
      "pacman" {
        $pkgName = ($cmd -replace 'sudo pacman[^ ]* ', '') -split ' ' | Select-Object -First 1
      }
      default {
        $batchable = $false
        break
      }
    }
    if ($pkgName) {
      $packages += $pkgName
    }
  }

  if (-not $batchable -or $packages.Count -le 1) {
    foreach ($key in $Keys) {
      Install-Software -Path $Path -OS $OS -Key $key
    }
    return
  }

  Write-Log ($script:LANG["batch_installing"] -f $packages.Count) "INFO"

  $batchCmd = ""
  switch ($Manager) {
    "apt" { $batchCmd = "sudo apt install -y $($packages -join ' ')" }
    "brew" { $batchCmd = "brew install $($packages -join ' ')" }
    "winget" { $batchCmd = "winget install $($packages -join ' ')" }
    "npm" { $batchCmd = "npm install -g $($packages -join ' ')" }
    "dnf" { $batchCmd = "sudo dnf install -y $($packages -join ' ')" }
    "pacman" { $batchCmd = "sudo pacman -S --noconfirm $($packages -join ' ')" }
  }

  $errorOutput = ""
  try {
    $errorOutput = Invoke-Expression $batchCmd 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
      Write-Log ($script:LANG["batch_success"] -f $packages.Count, $packages.Count) "SUCCESS"
      foreach ($key in $Keys) {
        $script:installedList += $key
      }
    } else {
      Write-Log $script:LANG["batch_failed"] "WARN"
      foreach ($key in $Keys) {
        Install-Software -Path $Path -OS $OS -Key $key
      }
    }
  } catch {
    Write-Log $script:LANG["batch_failed"] "WARN"
    foreach ($key in $Keys) {
      Install-Software -Path $Path -OS $OS -Key $key
    }
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
--dry-run $($h["help_dry_run"])
--doctor $($h["help_doctor"])
--yes, -y $($h["help_yes"])
  --verbose          $($h["help_verbose"])
  --version, -v      $($h["help_version"])
  --log-file FILE    $($h["help_log_file"])
  --export-plan FILE $($h["help_export_plan"])
  --retry-failed $($h["help_retry_failed"])
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
    
    try { [Console]::CursorVisible = $true } catch {}
    exit 0
}

function Show-Version {
    Write-Host "Quickstart-PC" -ForegroundColor Blue -NoNewline
    Write-Host " v$VERSION"
    exit 0
}

function Show-Banner {
    param([string]$Lang)
    Write-Host ""
    Write-Host "  ██████╗ ██╗   ██╗████╗ ██████╗██   ▄██╗███████╗████████╗ █████╗ ██████╗ ████████╗      ██████╗  ██████╗" -ForegroundColor Blue
    Write-Host " ██╔═══██╗██║   ██║╚██╔╝██╔════╝██ ▄██▀╔╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝      ██╔══██╗██╔════╝" -ForegroundColor Blue
    Write-Host " ██║   ██║██║   ██║ ██║ ██║     █████╔═╝ ███████╗   ██║   ███████║██████╔╝   ██║   █████╗██████╔╝██║     " -ForegroundColor Blue
    Write-Host " ██║▄▄ ██║██║   ██║ ██║ ██║     ██╗▀██▄  ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ╚════╝██╔═══╝ ██║     " -ForegroundColor Blue
    Write-Host " ╚██████╔╝╚██████╔╝████╗╚██████╗██║  ▀██╗███████║   ██║   ██║  ██║██║  ██║   ██║         ██║     ╚██████╗" -ForegroundColor Blue
    Write-Host "  ╚══▀▀═╝  ╚═════╝ ╚═══╝ ╚═════╝╚═╝   ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝         ╚═╝      ╚═════╝" -ForegroundColor Blue
    Write-Host ""
}

# ============================================
# Config file functions
# ============================================
function Get-ConfigFile {
    $guid = [System.Guid]::NewGuid().ToString('N').Substring(0,8)
    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "quickstart-config-${guid}.json")
    
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
# QC Doctor - Environment Diagnostics
# ============================================
function Show-Doctor {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗"
    Write-Host "║ 🔧 QC Doctor                                                ║"
    Write-Host "║         Quickstart-PC Environment Diagnostics              ║"
    Write-Host "╚════════════════════════════════════════════════════════════╝"
    Write-Host ""
    
    $passed = 0
    $warnings = 0
    $failed = 0
    $osName = (Get-CurrentOS).OS
    
    # 1. System Information
    Write-Host "━━━ System Information ━━━"
    Write-Host " OS: $osName"
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    Write-Host " Arch: $arch"
    if ($osName -eq "Windows") {
        $osVersion = [System.Environment]::OSVersion.VersionString
        Write-Host " Version: $osVersion"
    } elseif ($osName -eq "macOS") {
        try {
            $osVersion = sw_vers -productVersion 2>&1 | Select-Object -First 1
            Write-Host " Version: $osVersion"
        } catch {}
    } elseif ($osName -eq "Linux") {
        try {
            $distro = Get-Content /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2
            Write-Host " Distro: ${distro}"
        } catch {}
    }
    Write-Host ""
    $passed++
    
    # 2. Package Manager
    Write-Host "━━━ Package Manager ━━━"
    if ($osName -eq "Windows") {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host " [✓] winget" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [!] winget not found (optional on Windows)" -ForegroundColor Yellow
            $warnings++
        }
    } elseif ($osName -eq "macOS") {
        if (Get-Command brew -ErrorAction SilentlyContinue) {
            $brewVer = brew --version 2>&1 | Select-Object -First 1
            Write-Host " [✓] Homebrew: $brewVer" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [✗] Homebrew not found" -ForegroundColor Red
            Write-Host "     → Install: /bin/bash -c `"`$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)`""
            $failed++
        }
    } elseif ($osName -eq "Linux") {
        if (Get-Command apt -ErrorAction SilentlyContinue) {
            Write-Host " [✓] apt (Debian/Ubuntu)" -ForegroundColor Green
            $passed++
        } elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
            Write-Host " [✓] dnf (Fedora/RHEL)" -ForegroundColor Green
            $passed++
        } elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
            Write-Host " [✓] pacman (Arch)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [✗] No supported package manager found" -ForegroundColor Red
            $failed++
        }
    }
    Write-Host ""
    
    # 3. Required Tools
    Write-Host "━━━ Required Tools ━━━"
    if (Get-Command jq -ErrorAction SilentlyContinue) {
        $jqVer = jq --version 2>&1
        Write-Host " [✓] jq: $jqVer" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " [✗] jq not found (JSON parser required)" -ForegroundColor Red
        Write-Host "     → Install: brew install jq (macOS) or apt install jq (Linux)"
        $failed++
    }
    
    if (Get-Command curl -ErrorAction SilentlyContinue) {
        Write-Host " [✓] curl: available" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " [✗] curl not found" -ForegroundColor Red
        $failed++
    }
    Write-Host ""
    
    # 4. Network Connectivity
    Write-Host "━━━ Network Connectivity ━━━"
    try {
        $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -TimeoutSec 10 -UseBasicParsing 2>&1
        if ($response.StatusCode -eq 200) {
            Write-Host " [✓] GitHub raw content: reachable" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [✗] GitHub raw content: unreachable" -ForegroundColor Red
            Write-Host "     → Check network connection or proxy settings"
            $failed++
        }
    } catch {
        Write-Host " [✗] GitHub raw content: unreachable" -ForegroundColor Red
        Write-Host "     → Check network connection or proxy settings"
        $failed++
    }
    
    try {
        $response = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 10 -UseBasicParsing 2>&1
        if ($response.StatusCode -eq 200) {
            Write-Host " [✓] GitHub: reachable" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [!] GitHub: unreachable (may be temporary)" -ForegroundColor Yellow
            $warnings++
        }
    } catch {
        Write-Host " [!] GitHub: unreachable (may be temporary)" -ForegroundColor Yellow
        $warnings++
    }
    Write-Host ""
    
    # 5. Disk Space
    Write-Host "━━━ Disk Space ━━━"
    try {
        $disk = Get-PSDrive -Name (Split-Path $env:TEMP -PathRoot) -ErrorAction Stop
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        if ($freeGB -gt 1) {
            Write-Host " [✓] Available: ${freeGB}GB" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [!] Available: ${freeGB}GB (recommend >1GB)" -ForegroundColor Yellow
            $warnings++
        }
    } catch {
        Write-Host " [!] Could not determine disk space" -ForegroundColor Yellow
        $warnings++
    }
    Write-Host ""
    
    # 6. Temp Directory
    Write-Host "━━━ Temp Directory ━━━"
    $tmpDir = $env:TEMP ?? "/tmp"
    if (Test-Path $tmpDir) {
        try {
            $testFile = Join-Path $tmpDir "qc-test-$(Get-Random)"
            [System.IO.File]::WriteAllText($testFile, "test")
            [System.IO.File]::Delete($testFile)
            Write-Host " [✓] $tmpDir : writable" -ForegroundColor Green
            $passed++
        } catch {
            Write-Host " [✗] $tmpDir : not writable" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host " [✗] $tmpDir : does not exist" -ForegroundColor Red
        $failed++
    }
    Write-Host ""
    
    # 7. Configuration
    Write-Host "━━━ Configuration ━━━"
    try {
        $configFile = Get-ConfigFile
        if (Test-JsonValid -Path $configFile) {
            $profileCount = (Get-ProfileKeys -Path $configFile).Count
            $swCount = (Get-SoftwareKeys -Path $configFile).Count
            Write-Host " [✓] profiles.json: valid ($swCount software, $profileCount profiles)" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [✗] profiles.json: invalid JSON" -ForegroundColor Red
            $failed++
        }
        Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host " [!] Could not download profiles.json (network issue?)" -ForegroundColor Yellow
        $warnings++
    }
    Write-Host ""
    
    # Summary
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host " Summary: $passed passed, $warnings warnings, $failed failed"
    if ($failed -eq 0) {
        Write-Host " Status: ✅ Environment ready for Quickstart-PC" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    } else {
        Write-Host " Status: ⚠️  Some issues need attention before installation" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    }
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
# Progress bar function
# ============================================
function Draw-ProgressBar {
    param([int]$Current, [int]$Total, [int]$Width = 20)
    $filled = if ($Total -gt 0) { [math]::Floor($Current * $Width / $Total) } else { 0 }
    $empty = $Width - $filled
  $bar = ("█" * $filled) + ("░" * $empty)
  return $bar
}

function Test-DiskSpace {
  param([int]$MinGB = 5)
  try {
    if ($script:OS -eq "windows") {
      $driveName = Split-Path $env:TEMP -PathRoot
      $disk = Get-PSDrive -Name $driveName -ErrorAction Stop
      $availableGB = [math]::Round($disk.Free / 1GB)
    } else {
      $dfResult = & df -g / 2>$null | Select-Object -Last 1
      $availableGB = if ($dfResult) { ($dfResult -split '\s+')[3] -as [int] } else { $null }
    }
    if ($null -eq $availableGB) {
      return $true
    }
    if ($availableGB -lt $MinGB) {
      Write-Host " $($script:LANG["disk_space_low"] -f $availableGB, $MinGB)" -ForegroundColor Yellow
      Write-Host " $($script:LANG["disk_space_warning"])" -ForegroundColor Yellow
      return $false
    }
    return $true
  } catch {
    return $true
  }
}

$script:STATE_FILE = if ($IsWindows -or $env:OS -eq "Windows_NT") {
  "$env:USERPROFILE\.config\quickstart-pc\state.json"
} elseif ($IsMacOS) {
  "$HOME/.config/quickstart-pc/state.json"
} else {
  "$HOME/.config/quickstart-pc/state.json"
}

function Save-InstallState {
  $stateDir = Split-Path $script:STATE_FILE
  if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
  }
  $remaining = @()
  foreach ($key in $script:toInstall) {
    if ($key -notin $script:installedList) {
      $remaining += $key
    }
  }
  $state = @{
    profile = $selectedProfile
    total = $script:toInstall.Count
    remaining = $remaining
    installed = $script:installedList
    failed = $script:failedList
    timestamp = (Get-Date).ToString("o")
  }
  $state | ConvertTo-Json -Depth 3 | Set-Content $script:STATE_FILE
  Write-Host " $($script:LANG["checkpoint_saved"])" -ForegroundColor Green
}

function Load-InstallState {
  if (Test-Path $script:STATE_FILE) {
    try {
      $state = Get-Content $script:STATE_FILE | ConvertFrom-Json
      return $state.remaining
    } catch {
      return $null
    }
  }
  return $null
}

function Clear-InstallState {
  if (Test-Path $script:STATE_FILE) {
    Remove-Item $script:STATE_FILE -Force
  }
  Write-Host " $($script:LANG["install_complete_state"])" -ForegroundColor Green
}

function Invoke-HookScript {
  param([string]$HookType)
  $hookScript = jq -r ".hooks.${HookType} // empty" $script:CONFIG_FILE 2>$null
  if (-not $hookScript) { return }
  if (-not $allowHooks) {
    Write-Host " $($script:LANG["hooks_disabled"])" -ForegroundColor DarkGray
    return
  }
  Write-Host " $($script:LANG["hook_running"] -f $HookType)" -ForegroundColor Cyan
  try {
    & $hookScript
    Write-Host " $($script:LANG["hook_success"])" -ForegroundColor Green
  } catch {
    Write-Warning "$($script:LANG["hook_failed"] -f $HookType)"
  }
}

function Check-Update {
  Write-Host " $($script:LANG["update_checking"])" -ForegroundColor Cyan
  try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/MomoLawson/Quickstart-PC/releases/latest" -TimeoutSec 10 -ErrorAction Stop
    $latestVersion = $release.tag_name -replace '^v',''
    $currentVersion = $VERSION
    if ($currentVersion -eq $latestVersion) {
      Write-Host " $($script:LANG["update_latest"])" -ForegroundColor Green
      return 0
    }
    Write-Host " $($script:LANG["update_available"] -f $latestVersion, $currentVersion)" -ForegroundColor Yellow
    return 2
  } catch {
    Write-Host " $($script:LANG["update_failed"] -f $_.Exception.Message)" -ForegroundColor Red
    return 1
  }
}

function Update-Self {
  $checkResult = Check-Update
  if ($checkResult -eq 0) { return 0 }
  if ($checkResult -eq 1) { return 1 }
  if (-not $nonInteractive -and -not $yes) {
    Write-Host " $($script:LANG["update_prompt"])" -ForegroundColor Yellow -NoNewline
    $answer = Read-Host " "
    if (-not [string]::IsNullOrWhiteSpace($answer) -and $answer -notmatch "^[Yy]") { return 0 }
  }
  Write-Host " $($script:LANG["update_downloading"])" -ForegroundColor Cyan
  try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/MomoLawson/Quickstart-PC/releases/latest" -TimeoutSec 10
    $latestVersion = $release.tag_name -replace '^v',''
    $downloadUrl = "https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/v${latestVersion}/dist/quickstart.ps1"
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = $MyInvocation.PSCommandPath }
    $updateScript = @"
`$url = "$downloadUrl"
`$target = "$scriptPath"
`$tmpFile = "`$env:TEMP\quickstart-update.ps1"
try {
  Invoke-WebRequest -Uri `$url -OutFile `$tmpFile -TimeoutSec 60
  Copy-Item -Path `$tmpFile -Destination `$target -Force
  Remove-Item -Path `$tmpFile -Force -ErrorAction SilentlyContinue
  Write-Host "Update successful!" -ForegroundColor Green
} catch {
  Write-Host "Update failed: `$_" -ForegroundColor Red
}
"@
    $updateScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
    Set-Content -Path $updateScriptPath -Value $updateScript
    Write-Host " $($script:LANG["update_success"])" -ForegroundColor Green
    Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile", "-File", $updateScriptPath -Wait -NoNewWindow
    Remove-Item -Path $updateScriptPath -Force -ErrorAction SilentlyContinue
    return 0
  } catch {
    Write-Host " $($script:LANG["update_failed"] -f $_.Exception.Message)" -ForegroundColor Red
    return 1
    }
}

# ============================================
# Profile Menu (TUI)
# ============================================
function Show-ProfileMenu {
    param([string]$Path)

    $h = $script:LANG

    # Get profile data
    $profileKeys = Get-ProfileKeys -Path $Path
    if ($profileKeys.Count -eq 0) { return $null }

    $profileNames = @()
    $profileIcons = @()
    $profileDescs = @()

    foreach ($key in $profileKeys) {
        $profileNames += Get-ProfileField -Path $Path -Key $key -Field "name"
        $profileIcons += Get-ProfileField -Path $Path -Key $key -Field "icon"
        $profileDescs += Get-ProfileField -Path $Path -Key $key -Field "desc"
    }

    $numProfiles = $profileKeys.Count
    $menuNames = @()
    for ($i = 0; $i -lt $numProfiles; $i++) {
        $icon = $profileIcons[$i]
        $name = $profileNames[$i]
        $desc = $profileDescs[$i]
        if ($icon) {
            $menuNames += "$icon $name - $desc"
        } else {
            $menuNames += "$name - $desc"
        }
    }

    $cursor = 0
    $oldCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    Write-Host ""
    Write-Log $h["select_profiles"] "INFO"
    Write-Host ""
    Write-Host " $($h["navigate"])" -ForegroundColor Cyan
    Write-Host ""

    $startRow = [Console]::CursorTop

    function Draw-ProfileMenu {
        param([int]$CursorPos)
        for ($i = 0; $i -lt $numProfiles; $i++) {
            [Console]::SetCursorPosition(0, $startRow + $i)
            if ($i -eq $CursorPos) {
                Write-Host " ▶ $($menuNames[$i])" -NoNewline -BackgroundColor White -ForegroundColor Black
            } else {
                Write-Host "   $($menuNames[$i])" -NoNewline
            }
            Write-Host ""  # Clear rest of line
        }
    }

    Draw-ProfileMenu -CursorPos $cursor

    $running = $true
    while ($running) {
        $key = [Console]::ReadKey($true)

        switch ($key.VirtualKeyCode) {
            38 { # Up arrow
                $cursor--
                if ($cursor -lt 0) { $cursor = $numProfiles - 1 }
                Draw-ProfileMenu -CursorPos $cursor
            }
            40 { # Down arrow
                $cursor++
                if ($cursor -ge $numProfiles) { $cursor = 0 }
                Draw-ProfileMenu -CursorPos $cursor
            }
            13 { # Enter
                $running = $false
            }
        }
    }

    [Console]::CursorVisible = $oldCursorVisible

    # Clear menu area
    for ($i = 0; $i -lt $numProfiles; $i++) {
        [Console]::SetCursorPosition(0, $startRow + $i)
        Write-Host (" " * [Console]::WindowWidth) -NoNewline
    }
    [Console]::SetCursorPosition(0, $startRow)

    return $profileKeys[$cursor]
}

# ============================================
# Software Selection (TUI with checkboxes)
# ============================================
function Show-SoftwareMenu {
param([string]$Path, [string]$OS, [string]$ProfileKey)

$h = $script:LANG

# Get software keys from profile
$swKeys = Get-ProfileIncludes -Path $Path -Key $ProfileKey
if ($swKeys.Count -eq 0) { return @() }

# Build menu items - back_to_profiles first, then select_all
$menuKeys = @("back_to_profiles", "select_all")
$menuNames = @("← $($h["back_to_profiles"])", $h["select_all"])
$checked = @(0, 0)
$isInstalled = @($false, $false)

foreach ($key in $swKeys) {
$name = Get-SoftwareField -Path $Path -Key $key -Field "name"
$desc = Get-SoftwareField -Path $Path -Key $key -Field "desc"
$swIcon = Get-SoftwareField -Path $Path -Key $key -Field "icon"

$displayName = $name
if ($swIcon) { $displayName = "$swIcon $name" }

$menuKeys += $key
$installed = Test-SoftwareInstalled -Path $Path -OS $OS -Key $key
$isInstalled += $installed

if ($installed) {
$menuNames += "$displayName - $desc $($h["installed"])"
} else {
$menuNames += "$displayName - $desc"
}
$checked += 0
}

$numItems = $menuNames.Count
$cursor = 1 # Start at select_all (index 1)
$oldCursorVisible = [Console]::CursorVisible
[Console]::CursorVisible = $false

Write-Host ""
Write-Log $h["title_select_software"] "INFO"
Write-Host ""
Write-Host " $($h["custom_space_toggle"]) | $($h["custom_enter_confirm"]) | $($h["custom_a_select_all"])" -ForegroundColor Cyan
Write-Host ""

$startRow = [Console]::CursorTop

function Draw-SoftwareMenu {
param([int]$CursorPos, [int]$SelectedCount)

for ($i = 0; $i -lt $numItems; $i++) {
[Console]::SetCursorPosition(0, $startRow + $i)

$itemText = $menuNames[$i]

if ($i -eq 0) {
# Back to profiles - no checkbox, red color
if ($i -eq $CursorPos) {
Write-Host " $itemText" -NoNewline -BackgroundColor White -ForegroundColor Red
} else {
Write-Host " $itemText" -NoNewline -ForegroundColor DarkRed
}
} elseif ($i -eq 1) {
# Select all - checkbox, orange color
$prefix = if ($checked[$i] -eq 1) { $h["selected"] } else { $h["not_selected"] }
if ($i -eq $CursorPos) {
Write-Host " $prefix$itemText" -NoNewline -BackgroundColor White -ForegroundColor DarkYellow
} else {
Write-Host " $prefix$itemText" -NoNewline -ForegroundColor DarkYellow
}
} else {
# Software items - checkbox, gray if installed
$prefix = if ($checked[$i] -eq 1) { $h["selected"] } else { $h["not_selected"] }
$installed = $isInstalled[$i]

if ($i -eq $CursorPos) {
if ($installed) {
# Installed items - gray text even when selected
Write-Host " $prefix$itemText" -NoNewline -BackgroundColor White -ForegroundColor Gray
} elseif ($checked[$i] -eq 1) {
Write-Host " $prefix$itemText" -NoNewline -BackgroundColor White -ForegroundColor Green
} else {
Write-Host " $prefix$itemText" -NoNewline -BackgroundColor White -ForegroundColor Black
}
} else {
if ($installed) {
Write-Host " $prefix$itemText" -NoNewline -ForegroundColor Gray
} elseif ($checked[$i] -eq 1) {
Write-Host " $prefix$itemText" -NoNewline -ForegroundColor Green
} else {
Write-Host " $prefix$itemText" -NoNewline
}
}
}
Write-Host "" # Clear rest of line
}

# Show selection count
[Console]::SetCursorPosition(0, $startRow + $numItems + 1)
$countText = $h["custom_selected"] -f $SelectedCount, ($numItems - 2)
Write-Host " $countText" -NoNewline
Write-Host "" # Clear rest of line
}

function Get-SelectedCount {
$count = 0
for ($i = 2; $i -lt $numItems; $i++) {
if ($checked[$i] -eq 1) { $count++ }
}
return $count
}

Draw-SoftwareMenu -CursorPos $cursor -SelectedCount (Get-SelectedCount)

$running = $true
while ($running) {
$key = [Console]::ReadKey($true)

switch ($key.VirtualKeyCode) {
38 { # Up arrow
$cursor--
if ($cursor -lt 0) { $cursor = $numItems - 1 }
Draw-SoftwareMenu -CursorPos $cursor -SelectedCount (Get-SelectedCount)
}
40 { # Down arrow
$cursor++
if ($cursor -ge $numItems) { $cursor = 0 }
Draw-SoftwareMenu -CursorPos $cursor -SelectedCount (Get-SelectedCount)
}
32 { # Space - toggle selection
if ($cursor -eq 0) {
# Back button - do nothing
} elseif ($cursor -eq 1) {
# Toggle all except installed items
$newState = if ($checked[1] -eq 1) { 0 } else { 1 }
$checked[1] = $newState
for ($i = 2; $i -lt $numItems; $i++) {
if (-not $isInstalled[$i]) {
$checked[$i] = $newState
}
}
} else {
# Only toggle if not installed
if (-not $isInstalled[$cursor]) {
$checked[$cursor] = if ($checked[$cursor] -eq 1) { 0 } else { 1 }
}
}
Draw-SoftwareMenu -CursorPos $cursor -SelectedCount (Get-SelectedCount)
}
65 { # 'A' key - select/deselect all (except installed)
$newState = if ($checked[1] -eq 1) { 0 } else { 1 }
$checked[1] = $newState
for ($i = 2; $i -lt $numItems; $i++) {
if (-not $isInstalled[$i]) {
$checked[$i] = $newState
}
}
Draw-SoftwareMenu -CursorPos $cursor -SelectedCount (Get-SelectedCount)
}
13 { # Enter - confirm
if ($cursor -eq 0) {
# Back button pressed - return $null to signal back
$running = $false
} else {
$running = $false
}
}
}
}

[Console]::CursorVisible = $oldCursorVisible

# Clear menu area
$totalLines = $numItems + 3
for ($i = 0; $i -lt $totalLines; $i++) {
[Console]::SetCursorPosition(0, $startRow + $i)
Write-Host (" " * [Console]::WindowWidth) -NoNewline
}
[Console]::SetCursorPosition(0, $startRow)

# If back was pressed, return $null
if ($cursor -eq 0) {
return $null
}

# Build result array
$result = @()
for ($i = 2; $i -lt $numItems; $i++) {
if ($checked[$i] -eq 1) {
$result += $menuKeys[$i]
}
}

return $result
}

# ============================================
# Main execution
# ============================================
function Main {
  $script:LANG_OVERRIDE = $lang
  if ($lang -eq "__NONE__") {
    $script:LANG_OVERRIDE = ""  # Not provided - will auto-detect
  } elseif ($lang -eq "") {
    $script:LANG_OVERRIDE = "SELECT"  # Explicitly empty - show language menu
  }

if ($checkUpdate -or $update) {
    $updateLang = if ($lang -and $lang -ne "__NONE__" -and $lang -ne "") {
        $mapped = $script:LANGUAGE_MAPPINGS[$lang]
        if ($mapped) { $mapped } else { "en-US" }
    } else {
        "en-US"
    }
    Initialize-LanguageStrings -Lang $updateLang
    trap { try { Set-CursorVisible -Visible $true } catch {} }
    if ($checkUpdate) {
        Show-Banner -Lang $updateLang
        $result = Check-Update
        exit $result
    }
    if ($update) {
        Show-Banner -Lang $updateLang
        $result = Update-Self
        exit $result
    }
}

  if ($showVersion) {
        Show-Version
    }
    
    if ($help) {
    $helpLang = if ($lang -and $lang -ne "__NONE__") {
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

if ($doctor) {
    Show-Doctor
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
        if ($dryRun) { Write-Log $h["dry_run_mode"] "WARN"; Write-Host "" }
        
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

    while ($true) {
      Set-WindowTitle -Title "QSPC | $profileName | $($h["title_select_software"])"
      $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $profile

      if ($null -ne $script:SELECTED_SOFTWARE) {
        break # Normal confirm, proceed
      }
      # $null means back was pressed, re-show profile menu
      Set-WindowTitle -Title "QSPC | $($h["title_select_profile"])"
      $selectedProfile = Show-ProfileMenu -Path $script:CONFIG_FILE

      if (-not $selectedProfile) {
        Write-Log $h["no_profile_selected"] "WARN"
        exit 0
      }

      $script:SELECTED_PROFILES = @($selectedProfile)
      $profile = $selectedProfile
      $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $selectedProfile -Field "name"
    }
  }
  else {
    while ($true) {
      Set-WindowTitle -Title "QSPC | $($h["title_select_profile"])"
      $selectedProfile = Show-ProfileMenu -Path $script:CONFIG_FILE

      if (-not $selectedProfile) {
        Write-Log $h["no_profile_selected"] "WARN"
        exit 0
      }

      $script:SELECTED_PROFILES = @($selectedProfile)
      $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $selectedProfile -Field "name"

      Set-WindowTitle -Title "QSPC | $profileName | $($h["title_select_software"])"
      $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $selectedProfile

    if ($null -ne $script:SELECTED_SOFTWARE) {
      break # Normal confirm, proceed
    }
    # $null means back was pressed, loop to re-show profile menu
  }
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
    Write-Host "$($h["confirm_install"])" -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host " "
    if ($confirm -match "^[Nn]") {
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
    if (Test-SoftwareInstalled -Path $script:CONFIG_FILE -OS $os -Key $sw) {
        $alreadyInstalled += $sw
    } else {
        $toInstall += $sw
    }
}

# One-line summary
$installedCount = $alreadyInstalled.Count
$toInstallCount = $toInstall.Count
$detBar = Draw-ProgressBar -Current $installedCount -Total ($installedCount + $toInstallCount)
Write-Host " $detBar $installedCount/$($installedCount + $toInstallCount) $($h["installed"]), $toInstallCount $($h["to_install"])" -ForegroundColor Cyan

# Show already-installed in gray
foreach ($sw in $alreadyInstalled) {
    $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
    $swIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "icon"
    $swDisplay = if ($swIcon) { "$swIcon $swName" } else { $swName }
    Write-Host " [✓] $swDisplay - $($h["skipping_installed"])" -ForegroundColor Gray
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

Write-Host " $($h["disk_checking"])" -ForegroundColor Cyan
  Test-DiskSpace -MinGB 5 | Out-Null

  # Check Windows admin privileges
  if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
      Write-Host " $($script:LANG["need_admin"])" -ForegroundColor Yellow
    }
  }

  # Check for incomplete installation state
  if (-not $noResume) {
    $savedRemaining = Load-InstallState
    if ($savedRemaining) {
      if ($resume -or $nonInteractive) {
        Write-Host " $($h["resuming"])" -ForegroundColor Cyan
        $script:toInstall = $savedRemaining
      } else {
Write-Host " $($h["resume_found"])" -ForegroundColor Yellow -NoNewline
    $resumeAnswer = Read-Host " "
        if ([string]::IsNullOrWhiteSpace($resumeAnswer) -or $resumeAnswer -match "^[Yy]") {
          Write-Host " $($h["resuming"])" -ForegroundColor Cyan
          $script:toInstall = $savedRemaining
        } else {
          Clear-InstallState
        }
      }
    }
  }

Set-WindowTitle -Title "QSPC | $($h["title_installing"])"
Write-Header $h["start_installing"]

$script:toInstall = $toInstall
$total = $toInstall.Count
$current = 0
$script:installedList = @()
$script:failedList = @()
$installStartTime = Get-Date

  Invoke-HookScript -HookType "pre_install"

  if ($dryRun) {
    foreach ($sw in $toInstall) {
      $current++
      $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
      $swIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "icon"
      $swDisplay = if ($swIcon) { "$swIcon $swName" } else { $swName }
      $bar = Draw-ProgressBar -Current $current -Total $total
      Write-Host "`r $bar $current/$total $swDisplay - $($h["installing"])..." -NoNewline -ForegroundColor Cyan

      $env:SOFTWARE_KEY = $sw
      $env:SOFTWARE_NAME = $swName
      Invoke-HookScript -HookType "pre_software"

      $swStart = Get-Date
      $result = Install-Software -Path $script:CONFIG_FILE -OS $os -Key $sw
      $swEnd = Get-Date
      $swElapsed = [math]::Round(($swEnd - $swStart).TotalSeconds)

      if ($result) {
        Write-Host "`r $bar $current/$total $swDisplay - " -NoNewline
        Write-Host "$($h["install_success"]) ($swElapsed$($h["time_seconds"]))" -ForegroundColor Green
        $script:installedList += $sw
      } else {
        Write-Host "`r $bar $current/$total $swDisplay - " -NoNewline
        Write-Host "$($h["install_failed"]) ($swElapsed$($h["time_seconds"]))" -ForegroundColor Red
        $script:failedList += $sw
        if ($failFast) {
          Write-Host ""
          Write-Log "Fail-fast: stopping at $swName" "ERROR"
          Save-InstallState
          break
        }
      }
      Invoke-HookScript -HookType "post_software"
      Save-InstallState
    }
  } else {
    $platform = switch ($os) {
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
    }

    $aptPackages = @()
    $brewPackages = @()
    $wingetPackages = @()
    $npmPackages = @()
    $dnfPackages = @()
    $pacmanPackages = @()
    $otherPackages = @()

    foreach ($sw in $toInstall) {
      $cmd = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field $platform
      $firstWord = ($cmd -split ' ')[0]
      $manager = ""

      if ($firstWord -eq "sudo") {
        $secondWord = ($cmd -split ' ')[1]
        switch ($secondWord) {
          "apt" { $manager = "apt" }
          "dnf" { $manager = "dnf" }
          "pacman" { $manager = "pacman" }
          default { $manager = "other" }
        }
      } elseif ($firstWord -eq "brew") {
        $manager = "brew"
      } elseif ($firstWord -eq "winget") {
        $manager = "winget"
      } elseif ($firstWord -eq "npm") {
        $manager = "npm"
      } else {
        $manager = "other"
      }

      switch ($manager) {
        "apt" { $aptPackages += $sw }
        "brew" { $brewPackages += $sw }
        "winget" { $wingetPackages += $sw }
        "npm" { $npmPackages += $sw }
        "dnf" { $dnfPackages += $sw }
        "pacman" { $pacmanPackages += $sw }
        default { $otherPackages += $sw }
      }
    }

    function Process-BatchGroup {
      param([string]$Manager, [string[]]$Keys)
      if ($Keys.Count -eq 0) { return }

      if ($Keys.Count -eq 1) {
        $sw = $Keys[0]
        $script:current++
        $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
        $swIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "icon"
        $swDisplay = if ($swIcon) { "$swIcon $swName" } else { $swName }
        $bar = Draw-ProgressBar -Current $script:current -Total $script:total
        Write-Host "`r $bar $script:current/$script:total $swDisplay - $($h["installing"])..." -NoNewline -ForegroundColor Cyan

        $env:SOFTWARE_KEY = $sw
        $env:SOFTWARE_NAME = $swName
        Invoke-HookScript -HookType "pre_software"

        $swStart = Get-Date
        $result = Install-Software -Path $script:CONFIG_FILE -OS $os -Key $sw
        $swEnd = Get-Date
        $swElapsed = [math]::Round(($swEnd - $swStart).TotalSeconds)

        if ($result) {
          Write-Host "`r $bar $script:current/$script:total $swDisplay - " -NoNewline
          Write-Host "$($h["install_success"]) ($swElapsed$($h["time_seconds"]))" -ForegroundColor Green
          $script:installedList += $sw
        } else {
          Write-Host "`r $bar $script:current/$script:total $swDisplay - " -NoNewline
          Write-Host "$($h["install_failed"]) ($swElapsed$($h["time_seconds"]))" -ForegroundColor Red
          $script:failedList += $sw
          if ($failFast) {
            Write-Host ""
            Write-Log "Fail-fast: stopping at $swName" "ERROR"
            Save-InstallState
            return
          }
        }
        Invoke-HookScript -HookType "post_software"
        Save-InstallState
      } else {
        Install-Batch -Path $script:CONFIG_FILE -OS $os -Manager $Manager -Keys $Keys
        foreach ($sw in $Keys) {
          Invoke-HookScript -HookType "pre_software"
          Invoke-HookScript -HookType "post_software"
          Save-InstallState
        }
      }
    }

    Process-BatchGroup -Manager "apt" -Keys $aptPackages
    Process-BatchGroup -Manager "brew" -Keys $brewPackages
    Process-BatchGroup -Manager "winget" -Keys $wingetPackages
    Process-BatchGroup -Manager "npm" -Keys $npmPackages
    Process-BatchGroup -Manager "dnf" -Keys $dnfPackages
    Process-BatchGroup -Manager "pacman" -Keys $pacmanPackages
    Process-BatchGroup -Manager "other" -Keys $otherPackages
  }

  Invoke-HookScript -HookType "post_install"
  $installEndTime = Get-Date
$totalElapsed = [math]::Round(($installEndTime - $installStartTime).TotalSeconds)
Write-Host ""
Write-Host "$($h["time_total"]): $totalElapsed$($h["time_seconds"])" -ForegroundColor Cyan
Write-Host ""
        
        $skippedList = $alreadyInstalled
        
        Write-Header $h["installation_complete"]
        Write-Host ""
        
Write-Host "Installed:" -ForegroundColor Green
Write-Log "Installed:" "INFO"
if ($installedList.Count -eq 0) {
    Write-Host " (none)" -ForegroundColor Gray
    Write-Log " (none)" "INFO"
} else {
    foreach ($item in $installedList) {
        $displayName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $item -Field "name"
        $displayIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $item -Field "icon"
        $displayText = if ($displayIcon) { "$displayIcon $displayName" } else { $displayName }
        Write-Host " - $displayText" -ForegroundColor Green
        Write-Log " - $displayText" "INFO"
    }
}

Write-Host ""
Write-Host "Skipped:" -ForegroundColor Cyan
Write-Log "" "INFO"
Write-Log "Skipped:" "INFO"
if ($skippedList.Count -eq 0) {
    Write-Host " (none)" -ForegroundColor Gray
    Write-Log " (none)" "INFO"
} else {
    foreach ($item in $skippedList) {
        $displayName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $item -Field "name"
        $displayIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $item -Field "icon"
        $displayText = if ($displayIcon) { "$displayIcon $displayName" } else { $displayName }
        Write-Host " - $displayText" -ForegroundColor Cyan
        Write-Log " - $displayText" "INFO"
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
                $displayName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $item -Field "name"
                $displayIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $item -Field "icon"
                $displayText = if ($displayIcon) { "$displayIcon $displayName" } else { $displayName }
                Write-Host "  - $displayText" -ForegroundColor Red
                Write-Log "  - $displayText" "INFO"
            }
      # Check if any failures were network-related
      if ($script:INSTALL_LAST_ERROR -match "timed out|timeout|Connection timed|could not resolve|Connection refused|Network is unreachable|No route to host|超时|逾時|名前解決|시간 초과|接続を拒否|연결 거부") {
        Write-Host ""
        Write-Host " $($script:LANG["network_timeout"])" -ForegroundColor Yellow
        Write-Host " $($script:LANG["check_network"])" -ForegroundColor Yellow
      }
      # Check if any failures were permission-related
      if ($script:INSTALL_LAST_ERROR -match "Permission denied|not allowed|Operation not permitted|EACCES|権限がありません|권한이 없습니다|Berechtigung verweigert|Permission refusée|权限不足|權限不足") {
        Write-Host ""
            $permMsg = $script:LANG["permission_denied"] -f $script:INSTALL_LAST_ERROR
            Write-Host " $permMsg" -ForegroundColor Yellow
            Write-Host " $($script:LANG["permission_suggestion"])" -ForegroundColor Yellow
            }
        }
    }
        
if ($reportJson -or $reportTxt) {
    Export-Report -JsonPath $reportJson -TxtPath $reportTxt -Installed $script:installedList -Skipped $skippedList -Failed $script:failedList
  }

  # Clear state on successful completion
  Clear-InstallState

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
