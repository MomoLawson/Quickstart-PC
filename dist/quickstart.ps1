# Quickstart-PC - PowerShell Version
# One-click computer setup for Windows
# Supports: powershell -ExecutionPolicy Bypass -File quickstart.ps1
# Or: iwr https://.../quickstart.ps1 | iex

param(
    [string]$lang,
    [string]$cfgPath,
    [string]$cfgUrl,
    [switch]$dev,
    [switch]$dryRun,
    [switch]$fakeInstall,  # deprecated alias
    [switch]$yes,
    [switch]$verbose,
    [string]$logFile,
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

# Default configuration URL
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

# ============================================
# Language strings (zh-CN / en-US)
# ============================================
$script:LANG = @{}

function Initialize-LanguageStrings {
    param([string]$Lang)
    
    $script:LANG = @{
        # Banner
        "banner_title" = "Quickstart-PC v0.10.0"
        "banner_desc" = if ($Lang -eq "zh-CN") { "快速配置新电脑软件环境" } else { "Quick setup for new computers" }
        
        # System
        "detecting_system" = if ($Lang -eq "zh-CN") { "检测系统环境..." } else { "Detecting system environment..." }
        "system_info" = if ($Lang -eq "zh-CN") { "系统" } else { "System" }
        "package_manager" = if ($Lang -eq "zh-CN") { "包管理器" } else { "Package Manager" }
        "unsupported_os" = if ($Lang -eq "zh-CN") { "不支持的操作系统" } else { "Unsupported operating system" }
        
        # Config
        "using_remote_config" = if ($Lang -eq "zh-CN") { "使用远程配置" } else { "Using remote configuration" }
        "using_custom_config" = if ($Lang -eq "zh-CN") { "使用本地配置" } else { "Using local configuration" }
        "using_default_config" = if ($Lang -eq "zh-CN") { "使用默认配置" } else { "Using default configuration" }
        "config_not_found" = if ($Lang -eq "zh-CN") { "配置文件不存在" } else { "Configuration file not found" }
        "config_invalid" = if ($Lang -eq "zh-CN") { "配置文件格式无效" } else { "Configuration file format invalid" }
        
        # Menu
        "select_profiles" = if ($Lang -eq "zh-CN") { "选择安装套餐" } else { "Select Installation Profiles" }
        "select_software" = if ($Lang -eq "zh-CN") { "选择要安装的软件" } else { "Select Software to Install" }
        "navigate" = if ($Lang -eq "zh-CN") { "↑↓ 移动 | 回车 确认" } else { "↑↓ Move | ENTER Confirm" }
        "navigate_multi" = if ($Lang -eq "zh-CN") { "↑↓ 移动 | 空格 选择 | 回车 确认" } else { "↑↓ Move | SPACE Select | ENTER Confirm" }
        "selected" = "[✓] "
        "not_selected" = "[  ] "
        "select_all" = if ($Lang -eq "zh-CN") { "全选" } else { "Select All" }
        
        # Messages
        "no_profile_selected" = if ($Lang -eq "zh-CN") { "未选择任何套餐" } else { "No profile selected" }
        "no_software_selected" = if ($Lang -eq "zh-CN") { "未选择任何软件" } else { "No software selected" }
        "confirm_install" = if ($Lang -eq "zh-CN") { "确认安装？[Y/n]" } else { "Confirm installation? [Y/n]" }
        "cancelled" = if ($Lang -eq "zh-CN") { "已取消" } else { "Cancelled" }
        "start_installing" = if ($Lang -eq "zh-CN") { "开始安装软件" } else { "Starting software installation" }
        "installing" = if ($Lang -eq "zh-CN") { "安装" } else { "Installing" }
        "install_success" = if ($Lang -eq "zh-CN") { "安装完成" } else { "installed successfully" }
        "install_failed" = if ($Lang -eq "zh-CN") { "安装失败" } else { "installation failed" }
        "platform_not_supported" = if ($Lang -eq "zh-CN") { "不支持的平台" } else { "Platform not supported" }
        "installation_complete" = if ($Lang -eq "zh-CN") { "安装完成" } else { "Installation Complete" }
        "total_installed" = if ($Lang -eq "zh-CN") { "共安装" } else { "Total installed" }
        
        # Modes
        "dev_mode" = if ($Lang -eq "zh-CN") { "开发者模式：仅显示选择的软件，不实际安装" } else { "Dev mode: Show selected software without installing" }
        "fake_install_mode" = if ($Lang -eq "zh-CN") { "假装安装模式：展示安装过程但不实际安装" } else { "Fake install mode: Show installation process without actually installing" }
        "fake_installing" = if ($Lang -eq "zh-CN") { "模拟安装" } else { "Simulating install" }
        
        # Installation check
        "checking_installation" = if ($Lang -eq "zh-CN") { "正在检测安装情况..." } else { "Checking installation status..." }
        "skipping_installed" = if ($Lang -eq "zh-CN") { "已安装，跳过" } else { "Already installed, skipping" }
        "all_installed" = if ($Lang -eq "zh-CN") { "所有软件均已安装，无需操作" } else { "All software already installed, nothing to do" }
        
        # Continue/Exit
        "ask_continue" = if ($Lang -eq "zh-CN") { "安装完成，是否继续安装其他套餐？" } else { "Installation complete. Continue installing other profiles?" }
        "continue_btn" = if ($Lang -eq "zh-CN") { "继续安装" } else { "Continue" }
        "exit_btn" = if ($Lang -eq "zh-CN") { "退出" } else { "Exit" }
        
        # Help
        "help_usage" = if ($Lang -eq "zh-CN") { "用法: quickstart.ps1 [选项]" } else { "Usage: quickstart.ps1 [OPTIONS]" }
        "help_lang" = if ($Lang -eq "zh-CN") { "设置语言 (en, zh)" } else { "Set language (en, zh)" }
        "help_cfg_path" = if ($Lang -eq "zh-CN") { "使用本地 profiles.json 文件" } else { "Use local profiles.json file" }
        "help_cfg_url" = if ($Lang -eq "zh-CN") { "使用远程 profiles.json URL" } else { "Use remote profiles.json URL" }
        "help_dev" = if ($Lang -eq "zh-CN") { "开发模式：显示选择的软件但不安装" } else { "Dev mode" }
        "help_dry_run" = if ($Lang -eq "zh-CN") { "假装安装：展示安装过程但不实际安装" } else { "Fake install: show process without installing" }
        "help_yes" = if ($Lang -eq "zh-CN") { "自动确认所有提示" } else { "Auto-confirm all prompts" }
        "help_verbose" = if ($Lang -eq "zh-CN") { "显示详细调试信息" } else { "Show detailed debug info" }
        "help_log_file" = if ($Lang -eq "zh-CN") { "将日志写入文件" } else { "Write logs to file" }
        "help_list_profiles" = if ($Lang -eq "zh-CN") { "列出所有可用套餐" } else { "List all available profiles" }
        "help_show_profile" = if ($Lang -eq "zh-CN") { "显示指定套餐详情" } else { "Show profile details" }
        "help_skip" = if ($Lang -eq "zh-CN") { "跳过指定软件（可多次使用）" } else { "Skip specified software (repeatable)" }
        "help_only" = if ($Lang -eq "zh-CN") { "只安装指定软件（可多次使用）" } else { "Only install specified software (repeatable)" }
        "help_fail_fast" = if ($Lang -eq "zh-CN") { "遇到错误时立即停止" } else { "Stop on first error" }
        "help_profile" = if ($Lang -eq "zh-CN") { "直接指定安装套餐（跳过选择菜单）" } else { "Select profile directly (skip menu)" }
        "help_non_interactive" = if ($Lang -eq "zh-CN") { "非交互模式（禁止所有 TUI/prompt）" } else { "Non-interactive mode (no TUI/prompts)" }
        "help_help" = if ($Lang -eq "zh-CN") { "显示此帮助信息" } else { "Show this help message" }
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
    # PowerShell 5.1 fallback
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
            return "macOS" 
        }
        "linux" { 
            return "Linux" 
        }
        default { return "Unknown" }
    }
}

function Get-PackageManager {
    param([string]$OS)
    if ($OS -eq "windows") {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if ($winget) { return "winget" }
        return "none"
    }
    return "none"
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

function Get-ProfileIncludes {
    param([string]$Path, [string]$Key)
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        $includes = $data.profiles.$Key.includes
        if ($includes) { return $includes } else { return @() }
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
    # Only apply lang_text for name/desc fields
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
    elseif ($OS -eq "linux") { $checkField = "check_linux" }
    
    $checkCmd = Get-SoftwareField -Path $Path -Key $Key -Field $checkField
    
    if ($debug) {
        Write-Log "DEBUG: is_installed: key=$Key os=$OS check_field=$checkField cmd=[$checkCmd]" "DEBUG"
    }
    
    if (-not $checkCmd) { return $false }
    
    try {
        if ($OS -eq "windows") {
            $result = Invoke-Expression "$checkCmd 2>&1"
            if ($LASTEXITCODE -eq 0) { return $true }
            return $false
        } else {
            $result = Invoke-Expression "$checkCmd 2>`$null" 2>&1
            if ($LASTEXITCODE -eq 0) { return $true }
            return $false
        }
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
            "zh" -or "zh-CN" -or "zh_CN" { return "zh-CN" }
            default { return "en-US" }
        }
    }
    
    # Interactive language selection
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
    
    # Save cursor position
    $oldVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    
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
        [Console]::CursorVisible = $oldVisible
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
    $oldVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    
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
            
            # Move cursor up and redraw
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
                Write-Host ("`r" + (" " * 80))
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
            }
        }
    } finally {
        [Console]::CursorVisible = $oldVisible
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
    
    # Filter by --only and --skip
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
    
    # Build menu items
    $menuItems = @()
    $swData = @()
    $checked = @()
    
    # "Select All" option
    $menuItems += $script:LANG["select_all"]
    $swData += @{ Key = "__select_all__"; Name = $script:LANG["select_all"] }
    $checked += $false
    
    foreach ($sw in $filtered) {
        $name = Get-SoftwareField -Path $Path -Key $sw -Field "name"
        $desc = Get-SoftwareField -Path $Path -Key $sw -Field "desc"
        
        $installed = Test-SoftwareInstalled -Path $Path -Key $sw -OS $OS
        $displayName = if ($installed) { "$name - $desc [$($script:LANG["skipping_installed"])]" } else { "$name - $desc" }
        
        $menuItems += $displayName
        $swData += @{ Key = $sw; Name = $name; Desc = $desc; Installed = $installed }
        $checked += $false
    }
    
    Write-Host ""
    Write-Header ($script:LANG["select_software"])
    Write-Host "  $($script:LANG["navigate_multi"])" -ForegroundColor Cyan
    Write-Host ""
    
    $cursor = 0
    $oldVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    
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
                        # Select All toggle
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
            
            # Move cursor up and redraw
            for ($i = 0; $i -lt $menuItems.Count; $i++) {
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
                Write-Host ("`r" + (" " * 80))
                [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
            }
        }
    } finally {
        [Console]::CursorVisible = $oldVisible
    }
    
    Write-Host ""
    
    # Collect selected software (skip Select All and already installed)
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
    $oldVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    
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
                    [Console]::CursorVisible = $oldVisible
                    Write-Host ""
                    return $cursor 
                }
            }
        }
    } finally {
        [Console]::CursorVisible = $oldVisible
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
        "linux" { "linux" }
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
        if ($OS -eq "windows") {
            Invoke-Expression $cmd 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$Key $($script:LANG["install_success"])" "SUCCESS"
                return $true
            } else {
                Write-Log "$Key $($script:LANG["install_failed"])" "ERROR"
                return $false
            }
        } else {
            Invoke-Expression $cmd 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "$Key $($script:LANG["install_success"])" "SUCCESS"
                return $true
            } else {
                Write-Log "$Key $($script:LANG["install_failed"])" "ERROR"
                return $false
            }
        }
    } catch {
        Write-Log "$Key $($script:LANG["install_failed"]): $_" "ERROR"
        return $false
    }
}

# ============================================
# Main functions
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
  --fake-install     $($script:LANG["help_dry_run"]) (已弃用)
  --yes, -y         $($script:LANG["help_yes"])
  --verbose, -v     $($script:LANG["help_verbose"])
  --log-file FILE    $($script:LANG["help_log_file"])
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
  --fake-install     Alias for --dry-run (deprecated)
  --yes, -y         $($script:LANG["help_yes"])
  --verbose, -v     $($script:LANG["help_verbose"])
  --log-file FILE    $($script:LANG["help_log_file"])
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
# Main execution
# ============================================
function Main {
    # Handle --help first
    if ($help) {
        $helpLang = if ($lang) { 
            switch ($lang) { "zh" -or "zh-CN" -or "zh_CN" { "zh-CN" } default { "en-US" } }
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
    
    # Detect language
    $script:DETECTED_LANG = Select-Language
    Initialize-LanguageStrings -Lang $script:DETECTED_LANG
    
    # Setup cleanup trap
    trap {
        if ($script:CONFIG_FILE -and (Test-Path $script:CONFIG_FILE)) {
            Remove-Item $script:CONFIG_FILE -Force -ErrorAction SilentlyContinue
        }
        [Console]::CursorVisible = $true
    }
    
    # Main loop
    while ($true) {
        Clear-Host
        [Console]::CursorVisible = $false
        
        Show-Banner -Lang $script:DETECTED_LANG
        
        if ($dev) { Write-Log $script:LANG["dev_mode"] "WARN"; Write-Host "" }
        if ($dryRun) { Write-Log $script:LANG["fake_install_mode"] "WARN"; Write-Host "" }
        
        Write-Log $script:LANG["detecting_system"] "INFO"
        $os = Get-CurrentOS
        $systemInfo = Get-SystemInfo
        $pkgManager = Get-PackageManager -OS $os
        
        Write-Log "$($script:LANG["system_info"]): $systemInfo" "INFO"
        Write-Log "$($script:LANG["package_manager"]): $pkgManager" "INFO"
        
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
            
            # Get all software in profile (filter by --only/--skip)
            $includes = Get-ProfileIncludes -Path $script:CONFIG_FILE -Key $profile
            $script:SELECTED_SOFTWARE = @()
            foreach ($sw in $includes) {
                if ($only.Count -gt 0 -and $only -notcontains $sw) { continue }
                if ($skip.Count -gt 0 -and $skip -contains $sw) { continue }
                $script:SELECTED_SOFTWARE += $sw
            }
        }
        # --profile parameter (skip menu but show software selection)
        elseif ($profile) {
            $profileKeys = Get-ProfileKeys -Path $script:CONFIG_FILE
            if ($profileKeys -notcontains $profile) {
                Write-Log "Profile '$profile' 不存在" "ERROR"
                exit 1
            }
            
            $script:SELECTED_PROFILES = @($profile)
            $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $profile
        }
        # Interactive mode - show profile menu
        else {
            $script:SELECTED_PROFILES = @(Show-ProfileMenu -Path $script:CONFIG_FILE)
            
            if ($script:SELECTED_PROFILES.Count -eq 0) {
                Write-Log $script:LANG["no_profile_selected"] "WARN"
                exit 0
            }
            
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
        
        # Check what's already installed
        $toInstall = @()
        $alreadyInstalled = @()
        
        foreach ($sw in $script:SELECTED_SOFTWARE) {
            $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
            
            if (Test-SoftwareInstalled -Path $script:CONFIG_FILE -Key $sw -OS $os) {
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
        
        # Merge skipped software
        $skippedList = $alreadyInstalled
        
        # Summary
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
        
        # Non-interactive mode exit
        if ($nonInteractive) {
            exit 0
        }
        
        # Ask to continue
        Write-Host ""
        Write-Log $script:LANG["ask_continue"] "INFO"
        $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
        if ($continue -eq 1) { exit 0 }
        
        # Cleanup and loop
        if ($script:CONFIG_FILE -and (Test-Path $script:CONFIG_FILE)) {
            Remove-Item $script:CONFIG_FILE -Force -ErrorAction SilentlyContinue
        }
        $script:CONFIG_FILE = ""
    }
}

# Run main function
Main
