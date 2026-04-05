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
# Language strings (zh-CN / en-US)
# ============================================
$script:LANG = @{}

function Initialize-LanguageStrings {
    param([string]$Lang)
    
    if ($Lang -eq "zh-CN") {
        $script:LANG = @{
            # Banner
            "banner_title" = "Quickstart-PC v$VERSION"
            "banner_desc" = "快速配置新电脑软件环境"
            
            # System
            "detecting_system" = "检测系统环境..."
            "system_info" = "系统"
            "package_manager" = "包管理器"
            "unsupported_os" = "不支持的操作系统"
            
            # Config
            "using_remote_config" = "使用远程配置"
            "using_custom_config" = "使用本地配置"
            "using_default_config" = "使用默认配置"
            "config_not_found" = "配置文件不存在"
            "config_invalid" = "配置文件格式无效"
            
            # Menu
            "select_profiles" = "选择安装套餐"
            "select_software" = "选择要安装的软件"
            "navigate" = "↑↓ 移动 | 回车 确认"
            "navigate_multi" = "↑↓ 移动 | 空格 选择 | 回车 确认"
            "selected" = "[✓] "
            "not_selected" = "[  ] "
            "select_all" = "全选"
            "installed" = "已安装"
            
            # Messages
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
            
            # Modes
            "dev_mode" = "开发者模式：仅显示选择的软件，不实际安装"
            "fake_install_mode" = "假装安装模式：展示安装过程但不实际安装"
            "fake_installing" = "模拟安装"
            
            # Installation check
            "checking_installation" = "正在检测安装情况..."
            "skipping_installed" = "已安装，跳过"
            "all_installed" = "所有软件均已安装，无需操作"
            
            # Continue/Exit
            "ask_continue" = "安装完成，是否继续安装其他套餐？"
            "continue_btn" = "继续安装"
            "exit_btn" = "退出"
            
            # Window titles
            "title_select_profile" = "选择套餐"
            "title_select_software" = "选择软件"
            "title_installing" = "安装中"
            "title_ask_continue" = "是否继续安装"
            
            # Help
            "help_usage" = "用法: quickstart.ps1 [选项]"
            "help_lang" = "设置语言 (en, zh)"
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
            
            # Validation
            "validating_config" = "正在校验配置文件..."
            "json_valid" = "JSON 语法有效"
            "json_invalid" = "JSON 语法无效"
            "profiles_count" = "配置文件"
            "software_count" = "软件条目"
            "validation_passed" = "校验通过"
            "validation_failed" = "校验失败"
            
            # Search
            "search_results" = "搜索结果"
        }
    } else {
        $script:LANG = @{
            # Banner
            "banner_title" = "Quickstart-PC v$VERSION"
            "banner_desc" = "Quick setup for new computers"
            
            # System
            "detecting_system" = "Detecting system environment..."
            "system_info" = "System"
            "package_manager" = "Package Manager"
            "unsupported_os" = "Unsupported operating system"
            
            # Config
            "using_remote_config" = "Using remote configuration"
            "using_custom_config" = "Using local configuration"
            "using_default_config" = "Using default configuration"
            "config_not_found" = "Configuration file not found"
            "config_invalid" = "Configuration file format invalid"
            
            # Menu
            "select_profiles" = "Select Installation Profiles"
            "select_software" = "Select Software to Install"
            "navigate" = "↑↓ Move | ENTER Confirm"
            "navigate_multi" = "↑↓ Move | SPACE Select | ENTER Confirm"
            "selected" = "[✓] "
            "not_selected" = "[  ] "
            "select_all" = "Select All"
            "installed" = "installed"
            
            # Messages
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
            
            # Modes
            "dev_mode" = "Dev mode: Show selected software without installing"
            "fake_install_mode" = "Fake install mode: Show installation process without actually installing"
            "fake_installing" = "Simulating install"
            
            # Installation check
            "checking_installation" = "Checking installation status..."
            "skipping_installed" = "Already installed, skipping"
            "all_installed" = "All software already installed, nothing to do"
            
            # Continue/Exit
            "ask_continue" = "Installation complete. Continue installing other profiles?"
            "continue_btn" = "Continue"
            "exit_btn" = "Exit"
            
            # Window titles
            "title_select_profile" = "Select Profile"
            "title_select_software" = "Select Software"
            "title_installing" = "Installing"
            "title_ask_continue" = "Continue Installing?"
            
            # Help
            "help_usage" = "Usage: quickstart.ps1 [OPTIONS]"
            "help_lang" = "Set language (en, zh)"
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
            
            # Validation
            "validating_config" = "Validating configuration..."
            "json_valid" = "JSON syntax valid"
            "json_invalid" = "JSON syntax invalid"
            "profiles_count" = "Profiles"
            "software_count" = "Software entries"
            "validation_passed" = "Validation passed"
            "validation_failed" = "Validation failed"
            
            # Search
            "search_results" = "Search results"
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
    
    $title = if ($Lang -eq "zh-CN") { "快速配置新电脑软件环境" } else { "Quick setup for new computers" }
    
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
        switch ($lang) {
            "zh" { return "zh-CN" }
            "zh-CN" { return "zh-CN" }
            "zh_CN" { return "zh-CN" }
            default { return "en-US" }
        }
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
    Write-Host "Please select language / 请选择语言:" -ForegroundColor White
    Write-Host ""
    
    $items = @("English", "简体中文")
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
    
    switch ($cursor) {
        0 { return "en-US" }
        1 { return "zh-CN" }
        default { return "en-US" }
    }
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
    
    Write-Log "npm not found, installing..." "INFO"
    
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
                Write-Log "winget not found, cannot auto-install npm" "WARN"
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
    
    if ($Lang -eq "zh-CN") {
        Write-Host @"

Quickstart-PC - 一键配置新电脑

用法: quickstart.ps1 [选项]

选项:
  --lang LANG        $($script:LANG["help_lang"])
  --cfg-path PATH    $($script:LANG["help_cfg_path"])
  --cfg-url URL      $($script:LANG["help_cfg_url"])
  --dev              $($script:LANG["help_dev"])
  --dry-run          $($script:LANG["help_dry_run"])
  --fake-install     $($script:LANG["help_fake_install"])
  --yes, -y         $($script:LANG["help_yes"])
  --verbose, -v      $($script:LANG["help_verbose"])
  --log-file FILE    $($script:LANG["help_log_file"])
  --export-plan FILE $($script:LANG["help_export_plan"])
  --custom           $($script:LANG["help_custom"])
  --retry-failed     $($script:LANG["help_retry_failed"])
  --list-software    $($script:LANG["help_list_software"])
  --show-software ID $($script:LANG["help_show_software"])
  --search KEYWORD   $($script:LANG["help_search"])
  --validate         $($script:LANG["help_validate"])
  --report-json FILE $($script:LANG["help_report_json"])
  --report-txt FILE  $($script:LANG["help_report_txt"])
  --list-profiles    $($script:LANG["help_list_profiles"])
  --show-profile KEY $($script:LANG["help_show_profile"])
  --skip SW          $($script:LANG["help_skip"])
  --only SW          $($script:LANG["help_only"])
  --fail-fast        $($script:LANG["help_fail_fast"])
  --profile NAME     $($script:LANG["help_profile"])
  --non-interactive  $($script:LANG["help_non_interactive"])
  --help             $($script:LANG["help_help"])

"@ -ForegroundColor White
    } else {
        Write-Host @"

Quickstart-PC - One-click computer setup

Usage: quickstart.ps1 [OPTIONS]

Options:
  --lang LANG        $($script:LANG["help_lang"])
  --cfg-path PATH    $($script:LANG["help_cfg_path"])
  --cfg-url URL      $($script:LANG["help_cfg_url"])
  --dev              $($script:LANG["help_dev"])
  --dry-run          $($script:LANG["help_dry_run"])
  --fake-install     $($script:LANG["help_fake_install"])
  --yes, -y         $($script:LANG["help_yes"])
  --verbose, -v      $($script:LANG["help_verbose"])
  --log-file FILE    $($script:LANG["help_log_file"])
  --export-plan FILE $($script:LANG["help_export_plan"])
  --custom           $($script:LANG["help_custom"])
  --retry-failed     $($script:LANG["help_retry_failed"])
  --list-software    $($script:LANG["help_list_software"])
  --show-software ID $($script:LANG["help_show_software"])
  --search KEYWORD   $($script:LANG["help_search"])
  --validate         $($script:LANG["help_validate"])
  --report-json FILE $($script:LANG["help_report_json"])
  --report-txt FILE  $($script:LANG["help_report_txt"])
  --list-profiles    $($script:LANG["help_list_profiles"])
  --show-profile KEY $($script:LANG["help_show_profile"])
  --skip SW          $($script:LANG["help_skip"])
  --only SW          $($script:LANG["help_only"])
  --fail-fast        $($script:LANG["help_fail_fast"])
  --profile NAME     $($script:LANG["help_profile"])
  --non-interactive  $($script:LANG["help_non_interactive"])
  --help             $($script:LANG["help_help"])

"@ -ForegroundColor White
    }
    
    exit 0
}

# ============================================
# Config file functions
# ============================================
function Get-ConfigFile {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
    
    if ($cfgUrl) {
        Write-Log "$($script:LANG["using_remote_config"]): $cfgUrl" "INFO"
        try {
            Invoke-WebRequest -Uri $cfgUrl -OutFile $tempFile -TimeoutSec 30 -ErrorAction Stop
            if (Test-JsonValid -Path $tempFile) {
                return $tempFile
            } else {
                Write-Log "$($script:LANG["config_invalid"]): $cfgUrl" "ERROR"
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                exit 1
            }
        } catch {
            Write-Log "$($script:LANG["config_not_found"]): $cfgUrl" "ERROR"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            exit 1
        }
    }
    
    if ($cfgPath) {
        if (Test-Path $cfgPath) {
            if (Test-JsonValid -Path $cfgPath) {
                Write-Log "$($script:LANG["using_custom_config"]): $cfgPath" "INFO"
                Copy-Item $cfgPath $tempFile -Force
                return $tempFile
            } else {
                Write-Log "$($script:LANG["config_invalid"]): $cfgPath" "ERROR"
                exit 1
            }
        } else {
            Write-Log "$($script:LANG["config_not_found"]): $cfgPath" "ERROR"
            exit 1
        }
    }
    
    Write-Log "$($script:LANG["using_default_config"])" "INFO"
    try {
        Invoke-WebRequest -Uri $DEFAULT_CFG_URL -OutFile $tempFile -TimeoutSec 30 -ErrorAction Stop
        if (Test-JsonValid -Path $tempFile) {
            return $tempFile
        }
    } catch {
        Write-Log "$($script:LANG["config_not_found"])" "ERROR"
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    
    Write-Log "$($script:LANG["config_not_found"])" "ERROR"
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
    # Handle --help first
    if ($help) {
        $helpLang = if ($lang) { 
            switch ($lang) { "zh" { "zh-CN" } "zh-CN" { "zh-CN" } "zh_CN" { "zh-CN" } default { "en-US" } }
        } else { "en-US" }
        Initialize-LanguageStrings -Lang $helpLang
        Show-Help -Lang $helpLang
    }
    
    # --list-profiles before language selection (English output)
    if ($listProfiles) {
        Show-ListProfiles
    }
    
    # --show-profile before language selection (English output)
    if ($showProfile) {
        Show-ShowProfile -Key $showProfile
    }
    
    # --list-software before language selection
    if ($listSoftware) {
        Show-ListSoftware
    }
    
    # --show-software before language selection
    if ($showSoftware) {
        Show-ShowSoftware -Key $showSoftware
    }
    
    # --search before language selection
    if ($search) {
        Show-Search -Keyword $search
    }
    
    # --validate before language selection
    if ($validate) {
        Show-Validate
    }
    
    # Detect language
    $script:DETECTED_LANG = Select-Language
    Initialize-LanguageStrings -Lang $script:DETECTED_LANG
    
    # Setup cleanup trap
    trap {
        if ($script:CONFIG_FILE -and (Test-Path $script:CONFIG_FILE)) {
            Remove-Item $script:CONFIG_FILE -Force -ErrorAction SilentlyContinue
        }
        Set-WindowTitle -Title ""
        try { Set-CursorVisible -Visible $true } catch {}
    }
    
    # Main loop
    while ($true) {
        Clear-Host
        try { Set-CursorVisible -Visible $false } catch {}
        
        Show-Banner -Lang $script:DETECTED_LANG
        
        if ($dev) { Write-Log $script:LANG["dev_mode"] "WARN"; Write-Host "" }
        if ($dryRun) { Write-Log $script:LANG["fake_install_mode"] "WARN"; Write-Host "" }
        
        Write-Log $script:LANG["detecting_system"] "INFO"
        $os = Get-CurrentOS
        $systemInfo = Get-SystemInfo
        $script:PKG_MANAGER = Get-PackageManager -OS $os
        
        Write-Log "$($script:LANG["system_info"]): $systemInfo" "INFO"
        
        # npm auto-detection and installation
        $displayPm = $script:PKG_MANAGER
        if (Ensure-NpmInstalled -OS $os) {
            $displayPm += ", npm"
        }
        Write-Log "$($script:LANG["package_manager"]): $displayPm" "INFO"
        
        if ($os -eq "unknown") {
            Write-Log $script:LANG["unsupported_os"] "ERROR"
            exit 1
        }
        
        # Load config
        $script:CONFIG_FILE = Get-ConfigFile
        
        # --non-interactive mode
        if ($nonInteractive) {
            if (-not $profile) {
                Write-Log "非交互模式需要 --profile 参数" "ERROR"
                exit 1
            }
            
            $profileKeys = Get-ProfileKeys -Path $script:CONFIG_FILE
            if ($profileKeys -notcontains $profile) {
                Write-Log "Profile '$profile' 不存在" "ERROR"
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
                Write-Log "Profile '$profile' 不存在" "ERROR"
                exit 1
            }
            
            $script:SELECTED_PROFILES = @($profile)
            $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $profile -Field "name"
            Set-WindowTitle -Title "QSPC | $profileName | $($script:LANG["title_select_software"])"
            $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $profile
        }
        else {
            Set-WindowTitle -Title "QSPC | $($script:LANG["title_select_profile"])"
            $script:SELECTED_PROFILES = @(Show-ProfileMenu -Path $script:CONFIG_FILE)
            
            if ($script:SELECTED_PROFILES.Count -eq 0) {
                Write-Log $script:LANG["no_profile_selected"] "WARN"
                exit 0
            }
            
            $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $script:SELECTED_PROFILES[0] -Field "name"
            Set-WindowTitle -Title "QSPC | $profileName | $($script:LANG["title_select_software"])"
            $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $script:SELECTED_PROFILES[0]
        }
        
        if ($script:SELECTED_SOFTWARE.Count -eq 0) {
            Write-Log $script:LANG["no_software_selected"] "WARN"
            
            if ($nonInteractive) {
                exit 0
            }
            
            Write-Host ""
            Write-Log $script:LANG["ask_continue"] "INFO"
            $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
            if ($continue -eq 1) { exit 0 }
            continue
        }
        
        Write-Host ""
        Write-Log "Selected: $($script:SELECTED_SOFTWARE -join ', ')" "INFO"
        Write-Host ""
        
        # Export installation plan
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
        
        # Confirm installation
        if (-not $yes -and -not $nonInteractive) {
            Write-Host -NoNewline "$($script:LANG["confirm_install"]) "
            $confirm = [Console]::ReadKey($true)
            Write-Host ""
            
            if ($confirm.Key -eq "N" -or $confirm.Key -eq "n") {
                Write-Log $script:LANG["cancelled"] "INFO"
                Write-Host ""
                Write-Log $script:LANG["ask_continue"] "INFO"
                $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
                if ($continue -eq 1) { exit 0 }
                continue
            }
        }
        
        Write-Log $script:LANG["checking_installation"] "INFO"
        
        $toInstall = @()
        $alreadyInstalled = @()
        
        foreach ($sw in $script:SELECTED_SOFTWARE) {
            $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
            
            if (Test-SoftwareInstalled -Path $script:CONFIG_FILE -OS $os -Key $sw) {
                Write-Host "  $($script:LANG["selected"])$swName - $($script:LANG["skipping_installed"])" -ForegroundColor Green
                $alreadyInstalled += $swName
            } else {
                Write-Host "  [→] $swName - $($script:LANG["installing"])" -ForegroundColor Cyan
                $toInstall += $sw
            }
        }
        Write-Host ""
        
        if ($toInstall.Count -eq 0) {
            Write-Log $script:LANG["all_installed"] "INFO"
            
            if ($nonInteractive) {
                exit 0
            }
            
            Write-Host ""
            Write-Log $script:LANG["ask_continue"] "INFO"
            $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
            if ($continue -eq 1) { exit 0 }
            continue
        }
        
        Set-WindowTitle -Title "QSPC | $($script:LANG["title_installing"])"
        Write-Header $script:LANG["start_installing"]
        
        $total = $toInstall.Count
        $current = 0
        $installedList = @()
        $failedList = @()
        
        foreach ($sw in $toInstall) {
            $current++
            $percent = [math]::Round(($current * 100) / $total)
            $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
            Write-Host "`r$($script:LANG["installing"]) [$($percent.ToString("D3"))%] $swName" -NoNewline -ForegroundColor Cyan
            
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
        
        Write-Header $script:LANG["installation_complete"]
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
        Write-Log "$($script:LANG["total_installed"]) $($installedList.Count) / $total" "SUCCESS"
        
        # Retry failed packages
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
        
        # Export reports
        if ($reportJson -or $reportTxt) {
            Export-Report -JsonPath $reportJson -TxtPath $reportTxt -Installed $installedList -Skipped $skippedList -Failed $failedList
        }
        
        if ($nonInteractive) {
            Set-WindowTitle -Title "QSPC"
            exit 0
        }
        
        Set-WindowTitle -Title "QSPC | $($script:LANG["title_ask_continue"])"
        Write-Host ""
        Write-Log $script:LANG["ask_continue"] "INFO"
        $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
        if ($continue -eq 1) { exit 0 }
        
        continue
    }
}

# Start main function
Main
