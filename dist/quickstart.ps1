#!/usr/bin/env pwsh
#Requires -Version 5.1

param(
    [string]$lang,
    [string]$cfgPath,
    [string]$cfgUrl,
    [switch]$dev,
    [switch]$help
)

# Show help function
function Show-Help {
    $langForHelp = if ($lang) { $lang } else { "en" }
    
    if ($langForHelp -eq "zh" -or $langForHelp -eq "zh-CN") {
        Write-Host @"
Quickstart-PC - 一键配置新电脑

用法: quickstart.ps1 [选项]

选项:
  -lang LANG        设置语言 (en, zh)
  -cfg-path PATH    使用本地 profiles.yaml 文件
  -cfg-url URL      使用远程 profiles.yaml URL
  -dev              开发模式：显示选择的软件但不安装
  -help             显示此帮助信息

示例:
  quickstart.ps1 -lang zh
  quickstart.ps1 -cfg-path C:\path\to\profiles.yaml
  quickstart.ps1 -cfg-url https://example.com/profiles.yaml
  quickstart.ps1 -lang zh -dev
"@
    } else {
        Write-Host @"
Quickstart-PC - One-click computer setup

Usage: quickstart.ps1 [OPTIONS]

Options:
  -lang LANG        Set language (en, zh)
  -cfg-path PATH    Use local profiles.yaml file
  -cfg-url URL      Use remote profiles.yaml URL
  -dev              Dev mode: show selected software without installing
  -help             Show this help message

Examples:
  quickstart.ps1 -lang en
  quickstart.ps1 -cfg-path C:\path\to\profiles.yaml
  quickstart.ps1 -cfg-url https://example.com/profiles.yaml
  quickstart.ps1 -lang zh -dev
"@
    }
    exit 0
}

if ($help) { Show-Help }

# TUI Helper Functions
function Show-Menu {
    param(
        [string[]]$Items,
        [int]$Cursor,
        [bool]$MultiSelect = $false,
        [bool[]]$Checked = @()
    )
    
    for ($i = 0; $i -lt $Items.Count; $i++) {
        [Console]::SetCursorPosition(0, [Console]::CursorTop)
        [Console]::Write("                                        ")
        [Console]::SetCursorPosition(0, [Console]::CursorTop)
        
        if ($i -eq $Cursor) {
            [Console]::BackgroundColor = [ConsoleColor]::DarkCyan
            [Console]::ForegroundColor = [ConsoleColor]::White
            if ($MultiSelect) {
                if ($Checked[$i]) {
                    Write-Host "  [✓] $($Items[$i])" -NoNewline
                } else {
                    Write-Host "  [  ] $($Items[$i])" -NoNewline
                }
            } else {
                Write-Host "  ▶ $($Items[$i])" -NoNewline
            }
            [Console]::ResetColor()
            Write-Host ""
        } else {
            if ($MultiSelect) {
                if ($Checked[$i]) {
                    Write-Host "  [✓] $($Items[$i])" -ForegroundColor Green
                } else {
                    Write-Host "  [  ] $($Items[$i])"
                }
            } else {
                Write-Host "    $($Items[$i])"
            }
        }
    }
}

function Invoke-InteractiveMenu {
    param(
        [string]$Title,
        [string[]]$Items,
        [bool]$MultiSelect = $false
    )
    
    $cursor = 0
    $checked = @($false) * $Items.Count
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  ↑↓ Move | SPACE Select | ENTER Confirm" -ForegroundColor Cyan
    Write-Host ""
    
    $startLine = [Console]::CursorTop
    
    Show-Menu -Items $Items -Cursor $cursor -MultiSelect $MultiSelect -Checked $checked
    
    while ($true) {
        [Console]::SetCursorPosition(0, $startLine)
        Show-Menu -Items $Items -Cursor $cursor -MultiSelect $MultiSelect -Checked $checked
        
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            'UpArrow' {
                $cursor--
                if ($cursor -lt 0) { $cursor = $Items.Count - 1 }
            }
            'DownArrow' {
                $cursor++
                if ($cursor -ge $Items.Count) { $cursor = 0 }
            }
            'Spacebar' {
                if ($MultiSelect) {
                    $checked[$cursor] = -not $checked[$cursor]
                }
            }
            'Enter' {
                break
            }
        }
    }
    
    if ($MultiSelect) {
        $result = @()
        for ($i = 0; $i -lt $Items.Count; $i++) {
            if ($checked[$i]) { $result += $i }
        }
        return $result
    } else {
        return @($cursor)
    }
}

# Language selection
function Select-Language {
    if ($lang) {
        switch ($lang) {
            'zh' { return 'zh-CN' }
            'zh-CN' { return 'zh-CN' }
            'en' { return 'en-US' }
            'en-US' { return 'en-US' }
            default { return 'en-US' }
        }
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         " -ForegroundColor Cyan -NoNewline
    Write-Host "Quickstart-PC v0.12.0" -ForegroundColor White -BackgroundColor Cyan -NoNewline
    [Console]::ResetColor()
    Write-Host "             ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Please select language / 请选择语言:"
    Write-Host ""
    
    $langItems = @("English", "简体中文")
    $result = Invoke-InteractiveMenu -Title "Language" -Items $langItems
    
    switch ($result[0]) {
        0 { return 'en-US' }
        1 { return 'zh-CN' }
        default { return 'en-US' }
    }
}

$DETECTED_LANG = Select-Language

# Load language strings
if ($DETECTED_LANG -eq "zh-CN") {
    $LANG = @{
        BANNER_TITLE = "Quickstart-PC v0.12.0"
        BANNER_DESC = "快速配置新电脑软件环境"
        DETECTING_SYSTEM = "检测系统环境..."
        SYSTEM_INFO = "系统"
        PACKAGE_MANAGER = "包管理器"
        UNSUPPORTED_OS = "不支持的操作系统"
        NO_PACKAGE_MANAGER = "未检测到包管理器"
        INSTALL_PACKAGE_MANAGER = "是否自动安装包管理器？[Y/n]"
        PACKAGE_MANAGER_UPDATED = "包管理器已更新为"
        PACKAGE_MANAGER_FAILED = "包管理器安装失败"
        USING_CUSTOM_CONFIG = "使用自定义配置"
        USING_REMOTE_CONFIG = "使用远程配置"
        USING_EMBEDDED_CONFIG = "使用内嵌配置"
        CONFIG_NOT_FOUND = "配置文件不存在"
        CONFIG_INVALID = "配置文件格式无效"
        SELECT_PROFILES = "选择安装套餐"
        SELECT_SOFTWARE = "选择要安装的软件"
        NO_PROFILE_SELECTED = "未选择任何套餐"
        NO_SOFTWARE_SELECTED = "未选择任何软件"
        SELECTED_PROFILES = "选择的套餐"
        SELECTED_SOFTWARE = "已选择的软件"
        CONFIRM_INSTALL = "确认安装？[Y/n]"
        CANCELLED = "已取消"
        START_INSTALLING = "开始安装软件"
        INSTALLING = "安装"
        INSTALL_SUCCESS = "安装完成"
        INSTALL_FAILED = "安装失败"
        PLATFORM_NOT_SUPPORTED = "不支持的平台"
        INSTALLATION_COMPLETE = "安装完成"
        TOTAL_INSTALLED = "共安装"
        DEV_MODE = "开发者模式：仅显示选择的软件，不实际安装"
    }
    
    $EMBEDDED_CONFIG = @"
profiles:
  recommended:
    name: "推荐套餐"
    desc: "综合均衡，适合大多数用户"
    icon: "⭐"
    includes:
      - browser.chrome
      - devtools.vscode
      - devtools.git
      - devtools.nodejs
      - devtools.python
      - office.wps
  ai:
    name: "AI 赋能"
    desc: "AI CLI 工具、智能 IDE"
    icon: "🤖"
    includes:
      - ai.cursor
      - ai.ollama
  office:
    name: "办公套件"
    desc: "文档、协作工具"
    icon: "📊"
    includes:
      - office.wps
      - office.obsidian
  developer:
    name: "开发者套餐"
    desc: "IDE、版本控制、运行时"
    icon: "💻"
    includes:
      - devtools.vscode
      - devtools.git
      - devtools.nodejs
      - devtools.python
  media:
    name: "媒体创作"
    desc: "音视频处理工具"
    icon: "🎬"
    includes:
      - media.vlc
      - media.ffmpeg
software:
  browser.chrome:
    name: "Chrome"
    desc: "Google Chrome 浏览器"
    win: "winget install Google.Chrome"
  devtools.vscode:
    name: "VS Code"
    desc: "Visual Studio Code 编辑器"
    win: "winget install Microsoft.VisualStudioCode"
  devtools.git:
    name: "Git"
    desc: "分布式版本控制系统"
    win: "winget install Git.Git"
  devtools.nodejs:
    name: "Node.js"
    desc: "JavaScript 运行时"
    win: "winget install OpenJS.NodeJS.LTS"
  devtools.python:
    name: "Python"
    desc: "Python 编程语言"
    win: "winget install Python.Python.3.12"
  ai.cursor:
    name: "Cursor"
    desc: "AI 代码编辑器"
    win: "winget install Cursor.Cursor"
  ai.ollama:
    name: "Ollama"
    desc: "本地大语言模型"
    win: "winget install Ollama.Ollama"
  office.wps:
    name: "WPS Office"
    desc: "办公套件"
    win: "winget install Kingsoft.WPSOffice"
  office.obsidian:
    name: "Obsidian"
    desc: "知识管理工具"
    win: "winget install Obsidian.Obsidian"
  media.vlc:
    name: "VLC"
    desc: "多媒体播放器"
    win: "winget install VideoLAN.VLC"
  media.ffmpeg:
    name: "FFmpeg"
    desc: "音视频处理工具"
    win: "winget install FFmpeg"
"@
} else {
    $LANG = @{
        BANNER_TITLE = "Quickstart-PC v0.12.0"
        BANNER_DESC = "Quick setup for new computers"
        DETECTING_SYSTEM = "Detecting system environment..."
        SYSTEM_INFO = "System"
        PACKAGE_MANAGER = "Package Manager"
        UNSUPPORTED_OS = "Unsupported operating system"
        NO_PACKAGE_MANAGER = "No package manager detected"
        INSTALL_PACKAGE_MANAGER = "Install package manager? [Y/n]"
        PACKAGE_MANAGER_UPDATED = "Package manager updated to"
        PACKAGE_MANAGER_FAILED = "Failed to install package manager"
        USING_CUSTOM_CONFIG = "Using custom configuration"
        USING_REMOTE_CONFIG = "Using remote configuration"
        USING_EMBEDDED_CONFIG = "Using embedded configuration"
        CONFIG_NOT_FOUND = "Configuration file not found"
        CONFIG_INVALID = "Configuration file format invalid"
        SELECT_PROFILES = "Select Installation Profiles"
        SELECT_SOFTWARE = "Select Software to Install"
        NO_PROFILE_SELECTED = "No profile selected"
        NO_SOFTWARE_SELECTED = "No software selected"
        SELECTED_PROFILES = "Selected profiles"
        SELECTED_SOFTWARE = "Selected software"
        CONFIRM_INSTALL = "Confirm installation? [Y/n]"
        CANCELLED = "Cancelled"
        START_INSTALLING = "Starting software installation"
        INSTALLING = "Installing"
        INSTALL_SUCCESS = "installed successfully"
        INSTALL_FAILED = "installation failed"
        PLATFORM_NOT_SUPPORTED = "Platform not supported"
        INSTALLATION_COMPLETE = "Installation Complete"
        TOTAL_INSTALLED = "Total installed"
        DEV_MODE = "Dev mode: Show selected software without installing"
    }
    
    $EMBEDDED_CONFIG = @"
profiles:
  recommended:
    name: "Recommended"
    desc: "Balanced, suitable for most users"
    icon: "⭐"
    includes:
      - browser.chrome
      - devtools.vscode
      - devtools.git
      - devtools.nodejs
      - devtools.python
      - office.wps
  ai:
    name: "AI Powered"
    desc: "AI CLI tools, intelligent IDEs"
    icon: "🤖"
    includes:
      - ai.cursor
      - ai.ollama
  office:
    name: "Office Suite"
    desc: "Documents, collaboration tools"
    icon: "📊"
    includes:
      - office.wps
      - office.obsidian
  developer:
    name: "Developer"
    desc: "IDEs, version control, runtimes"
    icon: "💻"
    includes:
      - devtools.vscode
      - devtools.git
      - devtools.nodejs
      - devtools.python
  media:
    name: "Media Creation"
    desc: "Audio/video processing tools"
    icon: "🎬"
    includes:
      - media.vlc
      - media.ffmpeg
software:
  browser.chrome:
    name: "Chrome"
    desc: "Google Chrome browser"
    win: "winget install Google.Chrome"
  devtools.vscode:
    name: "VS Code"
    desc: "Visual Studio Code editor"
    win: "winget install Microsoft.VisualStudioCode"
  devtools.git:
    name: "Git"
    desc: "Distributed version control system"
    win: "winget install Git.Git"
  devtools.nodejs:
    name: "Node.js"
    desc: "JavaScript runtime"
    win: "winget install OpenJS.NodeJS.LTS"
  devtools.python:
    name: "Python"
    desc: "Python programming language"
    win: "winget install Python.Python.3.12"
  ai.cursor:
    name: "Cursor"
    desc: "AI code editor"
    win: "winget install Cursor.Cursor"
  ai.ollama:
    name: "Ollama"
    desc: "Local LLM runner"
    win: "winget install Ollama.Ollama"
  office.wps:
    name: "WPS Office"
    desc: "Office suite"
    win: "winget install Kingsoft.WPSOffice"
  office.obsidian:
    name: "Obsidian"
    desc: "Knowledge management tool"
    win: "winget install Obsidian.Obsidian"
  media.vlc:
    name: "VLC"
    desc: "Multimedia player"
    win: "winget install VideoLAN.VLC"
  media.ffmpeg:
    name: "FFmpeg"
    desc: "Audio/video processing tool"
    win: "winget install FFmpeg"
"@
}

# Logging functions
function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Blue }
function Write-Success { param([string]$Msg) Write-Host "[✓] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "[!] $Msg" -ForegroundColor Yellow }
function Write-Error { param([string]$Msg) Write-Host "[✗] $Msg" -ForegroundColor Red }
function Write-Step { param([string]$Msg) Write-Host "[→] $Msg" -ForegroundColor Cyan }
function Write-Header { param([string]$Msg) Write-Host ""; Write-Host "========================================"; Write-Host "  $Msg"; Write-Host "========================================" }

# System detection
function Get-SystemInfo { return "Windows $([Environment]::OSVersion.Version)" }
function Get-PackageManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return "winget" }
    if (Get-Command scoop -ErrorAction SilentlyContinue) { return "scoop" }
    return "none"
}

# Config parsing
function Get-ConfigValue {
    param([string]$Config, [string]$Key, [string]$Platform)
    
    $inSoftware = $false
    $inTarget = $false
    $currentKey = ""
    
    foreach ($line in $Config -split "`n") {
        $line = $line.TrimEnd()
        
        if ($line -eq "software:") {
            $inSoftware = $true
            continue
        }
        
        if ($inSoftware) {
            if ($line -match '^\s{2}([a-z.]+):') {
                $currentKey = $matches[1]
                $inTarget = ($currentKey -eq $Key)
            }
            
            if ($inTarget -and $line -match "^\s{4}$Platform:\s*`"(.+)`"") {
                return $matches[1]
            }
        }
    }
    return $null
}

# Profile menu
function Show-ProfileMenu {
    param([string]$Config)
    
    $inProfiles = $false
    $profileKeys = @()
    $profileNames = @()
    $profileIcons = @()
    $profileDescs = @()
    
    foreach ($line in $Config -split "`n") {
        $line = $line.TrimEnd()
        
        if ($line -eq "profiles:") { $inProfiles = $true; continue }
        if ($line -eq "software:") { $inProfiles = $false; continue }
        
        if ($inProfiles) {
            if ($line -match '^\s{2}([a-z_]+):') {
                $profileKeys += $matches[1]
            }
            if ($line -match 'name:\s*"([^"]+)"') { $profileNames += $matches[1] }
            if ($line -match 'icon:\s*"([^"]+)"') { $profileIcons += $matches[1] }
            if ($line -match 'desc:\s*"([^"]+)"') { $profileDescs += $matches[1] }
        }
    }
    
    $menuItems = @()
    for ($i = 0; $i -lt $profileKeys.Count; $i++) {
        $menuItems += "$($profileIcons[$i]) $($profileNames[$i]) - $($profileDescs[$i])"
    }
    
    $result = Invoke-InteractiveMenu -Title $LANG.SELECT_PROFILES -Items $menuItems
    
    $selected = @()
    foreach ($idx in $result) {
        $selected += $profileKeys[$idx]
    }
    return $selected
}

# Software menu
function Show-SoftwareMenu {
    param([string]$Config, [string[]]$Profiles)
    
    $swKeys = @()
    $swNames = @()
    $swDescs = @()
    
    foreach ($profile in $Profiles) {
        $inProfile = $false
        $inIncludes = $false
        
        foreach ($line in $Config -split "`n") {
            $line = $line.TrimEnd()
            
            if ($line -match "^\s{2}$profile`:") { $inProfile = $true; continue }
            if ($inProfile -and $line -match "includes:") { $inIncludes = $true; continue }
            if ($inProfile -and $inIncludes -and $line -match '^\s{6}-\s+(.+)') {
                $swKey = $matches[1]
                if ($swKey -notin $swKeys) { $swKeys += $swKey }
            }
            if ($inProfile -and $line -match '^\s{2}[a-z]' -and $line -notmatch "includes:") {
                $inProfile = $false
                $inIncludes = $false
            }
        }
    }
    
    foreach ($key in $swKeys) {
        $inSw = $false
        foreach ($line in $Config -split "`n") {
            $line = $line.TrimEnd()
            if ($line -match "^\s{2}$key`:") { $inSw = $true; continue }
            if ($inSw -and $line -match 'name:\s*"([^"]+)"') { $swNames += $matches[1] }
            if ($inSw -and $line -match 'desc:\s*"([^"]+)"') { $swDescs += $matches[1]; $inSw = $false }
        }
    }
    
    $menuItems = @()
    for ($i = 0; $i -lt $swKeys.Count; $i++) {
        $menuItems += "$($swNames[$i]) - $($swDescs[$i])"
    }
    
    $result = Invoke-InteractiveMenu -Title $LANG.SELECT_SOFTWARE -Items $menuItems -MultiSelect $true
    
    $selected = @()
    foreach ($idx in $result) {
        $selected += $swKeys[$idx]
    }
    return $selected
}

# Install software
function Install-Software {
    param([string]$Key, [string]$Config)
    
    $cmd = Get-ConfigValue -Config $Config -Key $Key -Platform "win"
    
    if (-not $cmd) {
        Write-Warn "$($LANG.PLATFORM_NOT_SUPPORTED): $Key"
        return $false
    }
    
    Write-Step "$($LANG.INSTALLING): $Key"
    try {
        Invoke-Expression $cmd 2>$null
        Write-Success "$Key $($LANG.INSTALL_SUCCESS)"
        return $true
    } catch {
        Write-Error "$Key $($LANG.INSTALL_FAILED)"
        return $false
    }
}

# Load config
function Get-Config {
    # Priority 1: Local file path
    if ($cfgPath) {
        if (Test-Path $cfgPath) {
            $content = Get-Content $cfgPath -Raw
            if ($content -match "profiles:" -and $content -match "software:") {
                Write-Info "$($LANG.USING_CUSTOM_CONFIG): $cfgPath"
                return $content
            } else {
                Write-Error "$($LANG.CONFIG_INVALID): $cfgPath"
                exit 1
            }
        } else {
            Write-Error "$($LANG.CONFIG_NOT_FOUND): $cfgPath"
            exit 1
        }
    }
    
    # Priority 2: Remote URL
    if ($cfgUrl) {
        Write-Info "$($LANG.USING_REMOTE_CONFIG): $cfgUrl"
        try {
            $content = (New-Object System.Net.WebClient).DownloadString($cfgUrl)
            if ($content -match "profiles:" -and $content -match "software:") {
                return $content
            } else {
                Write-Error "$($LANG.CONFIG_INVALID): $cfgUrl"
                exit 1
            }
        } catch {
            Write-Error "$($LANG.CONFIG_NOT_FOUND): $cfgUrl"
            exit 1
        }
    }
    
    # Priority 3: Embedded config
    Write-Info $LANG.USING_EMBEDDED_CONFIG
    return $EMBEDDED_CONFIG
}

# Main
function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         " -ForegroundColor Cyan -NoNewline
    Write-Host "$($LANG.BANNER_TITLE)" -ForegroundColor White -BackgroundColor Cyan -NoNewline
    [Console]::ResetColor()
    Write-Host "             ║" -ForegroundColor Cyan
    Write-Host "║    $($LANG.BANNER_DESC)" -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if ($dev) {
        Write-Warn $LANG.DEV_MODE
        Write-Host ""
    }
    
    Write-Info $LANG.DETECTING_SYSTEM
    $systemInfo = Get-SystemInfo
    $pkgManager = Get-PackageManager
    
    Write-Info "$($LANG.SYSTEM_INFO): $systemInfo"
    Write-Info "$($LANG.PACKAGE_MANAGER): $pkgManager"
    
    $config = Get-Config
    $selectedProfiles = Show-ProfileMenu -Config $config
    
    if ($selectedProfiles.Count -eq 0) {
        Write-Warn $LANG.NO_PROFILE_SELECTED
        exit 0
    }
    
    Write-Info "$($LANG.SELECTED_PROFILES): $($selectedProfiles -join ', ')"
    
    $selectedSoftware = Show-SoftwareMenu -Config $config -Profiles $selectedProfiles
    
    if ($selectedSoftware.Count -eq 0) {
        Write-Warn $LANG.NO_SOFTWARE_SELECTED
        exit 0
    }
    
    Write-Host ""
    Write-Info "$($LANG.SELECTED_SOFTWARE): $($selectedSoftware -join ', ')"
    Write-Host ""
    
    if ($dev) {
        Write-Info "Dev mode: Skipping installation"
        exit 0
    }
    
    $confirm = Read-Host $LANG.CONFIRM_INSTALL
    if ($confirm -match '^[Nn]') {
        Write-Info $LANG.CANCELLED
        exit 0
    }
    
    Write-Header $LANG.START_INSTALLING
    
    $total = $selectedSoftware.Count
    $current = 0
    
    foreach ($sw in $selectedSoftware) {
        $current++
        $percent = [math]::Round($current * 100 / $total)
        Write-Host "`r[$percent%] $($LANG.INSTALLING) $sw" -ForegroundColor Cyan -NoNewline
        Install-Software -Key $sw -Config $config
    }
    Write-Host ""
    
    Write-Header $LANG.INSTALLATION_COMPLETE
    Write-Success "$($LANG.TOTAL_INSTALLED) $total"
}

Main
