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
  [switch]$fix,
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
  [switch]$verifyConfig,
  [string]$proxy,
  [switch]$help,
  [switch]$showVersion
)

$VERSION = "1.0.0-beta3-build4"
if ($VERSION -eq "1.0.0-beta3-build4") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $versionFile = Join-Path $scriptDir "..\VERSION"
    if (Test-Path $versionFile) {
        $VERSION = (Get-Content $versionFile -Raw).Trim()
    } else {
        $versionFile = Join-Path $scriptDir "VERSION"
        if (Test-Path $versionFile) {
            $VERSION = (Get-Content $versionFile -Raw).Trim()
        } else {
            $VERSION = "0.0.0"
        }
    }
}
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$DEFAULT_CFG_URL = "https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/config/profiles.json"

# Apply proxy settings
if ($proxy) {
    if ($proxy -like "socks5://*") {
        $script:ProxyUrl = $proxy
        $env:ALL_PROXY = $proxy
    } else {
        $script:ProxyUrl = $proxy
        $env:http_proxy = $proxy
        $env:https_proxy = $proxy
    }
} else {
    $script:ProxyUrl = $null
}

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

function Invoke-WebRequestWithProxy {
param([string]$Uri, [string]$OutFile, [int]$TimeoutSec = 30, [switch]$UseBasicParsing, [System.Management.Automation.ActionPreference]$ErrorAction = [System.Management.Automation.ActionPreference]::Stop)
    $params = @{
        Uri = $Uri
        TimeoutSec = $TimeoutSec
        ErrorAction = $ErrorAction
    }
    if ($OutFile) { $params.OutFile = $OutFile }
    if ($UseBasicParsing) { $params.UseBasicParsing = $true }
    if ($script:ProxyUrl) { $params.Proxy = $script:ProxyUrl }
    Invoke-WebRequest @params
}

# Script variables
$script:CONFIG_FILE = ""
$script:SELECTED_PROFILES = @()
$script:SELECTED_SOFTWARE = @()
$script:DETECTED_LANG = "en-US"
$script:PKG_MANAGER = "none"
$script:DEBUG = $debug
$script:INSTALL_LAST_ERROR = ""
$script:IN_ALT_SCREEN = $false
$script:HAS_ERROR = $false
$script:ERROR_MESSAGES = @()

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

function Exit-Script {
    param([int]$Code = 0)
    if ($Code -ne 0) {
        $script:HAS_ERROR = $true
        if ($script:IN_ALT_SCREEN) {
            Exit-AlternateScreen
            Show-Banner -Lang $script:DETECTED_LANG
            foreach ($msg in $script:ERROR_MESSAGES) {
                Write-Host $msg
            }
        }
        $script:IN_ALT_SCREEN = $false
    }
    exit $Code
}

function Enter-AlternateScreen {
    $script:IN_ALT_SCREEN = $true
    try { [Console]::Write("`e[?1049h") } catch {}
}

function Exit-AlternateScreen {
    $script:IN_ALT_SCREEN = $false
    try { [Console]::Write("`e[?1049l") } catch {}
}

function Read-KeySafe {
    param([bool]$Intercept = $true)
    if ([Console]::IsInputRedirected -or $script:NON_INTERACTIVE) {
        # In non-interactive mode, wait for Enter key from stdin
        $null = [Console]::ReadLine()
        return [PSCustomObject]@{ Key = [ConsoleKey]::Enter; Modifiers = [ConsoleModifiers]::None; VirtualKeyCode = 13 }
    }
    return [Console]::ReadKey($Intercept)
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

                $key = Read-KeySafe -Intercept $true
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
            [Console]::Write("`r{0}" -f (" " * [Console]::WindowWidth))
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
# Language strings (dynamic loading from JSON)
# ============================================
$script:LANG = @{}

function Initialize-LanguageStrings {
    param([string]$Lang)
    
    # Map short codes to full codes
    $langMap = @{
        "zh" = "zh-CN"; "zh_CN" = "zh-CN"
        "zh-Hant" = "zh-Hant"; "zh-TW" = "zh-Hant"; "zh-HK" = "zh-Hant"
        "ja" = "ja"; "ja-JP" = "ja"
        "ko" = "ko"; "ko-KR" = "ko"
        "de" = "de"; "de-DE" = "de"
        "fr" = "fr"; "fr-FR" = "fr"
        "ar" = "ar"; "ar-SA" = "ar"
        "pt" = "pt"; "pt-BR" = "pt"
        "it" = "it"; "it-IT" = "it"
        "en" = "en-US"
    }
    
    $mapped = $langMap[$Lang]
    if ($mapped) { $Lang = $mapped }
    
    $loaded = $false
    
    # 1. Try local lang path if --local-lang is set
    if ($localLang) {
        $jsonFile = Join-Path $localLang "$Lang.json"
        if (Test-Path $jsonFile) {
            $script:LANG = Get-Content $jsonFile -Raw | ConvertFrom-Json -AsHashtable
            $loaded = $true
        }
    }
    
    # 2. Try embedded lang files (for local/offline use)
    if (-not $loaded) {
        $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
        if (-not $scriptDir) { $scriptDir = Split-Path -Parent $PSCommandPath }
        if ($scriptDir) {
            $jsonFile = Join-Path $scriptDir "lang\$Lang.json"
            if (Test-Path $jsonFile) {
                $script:LANG = Get-Content $jsonFile -Raw | ConvertFrom-Json -AsHashtable
                $loaded = $true
            }
        }
    }
    
    # 3. Try remote loading from GitHub
    if (-not $loaded) {
        try {
            $remoteUrl = "https://raw.githubusercontent.com/MomoLawson/Quickstart-PC/main/dist/lang/$Lang.json"
            $json = Invoke-RestMethod -Uri $remoteUrl -TimeoutSec 10 -ErrorAction Stop
            $script:LANG = $json
            $loaded = $true
        } catch {}
    }
    
    # 4. Fallback: if requested lang is not en-US, try en-US
    if (-not $loaded -and $Lang -ne "en-US") {
        Initialize-LanguageStrings -Lang "en-US"
        return
    }
    
    # 5. Last resort: embedded minimal English strings
    if (-not $loaded) {
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
            "help_usage" = "Usage: quickstart.ps1 [OPTIONS]"
            "help_lang" = "Set language (en, zh)"
            "help_cfg_path" = "Use local profiles.json file"
            "help_cfg_url" = "Use remote profiles.json URL"
            "help_dev" = "Dev mode: show selections without installing"
            "help_dry_run" = "Fake install: show process without installing"
            "help_doctor" = "Run QC Doctor environment diagnostics"
            "help_fix" = "Auto-fix missing dependencies"
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
            "help_help" = "Show this help message"
            "help_version" = "Show version information"
            "help_update" = "Update script to latest version"
            "help_check_update" = "Check for updates without installing"
            "help_allow_hooks" = "Enable hook scripts execution"
            "hook_running" = "Running hook: {0}"
            "hook_success" = "Hook completed"
            "hook_failed" = "Hook failed: {0}"
            "hooks_disabled" = "Hooks disabled, use --allow-hooks to enable"
            "hooks_enabled" = "Hooks enabled"
            "update_checking" = "Checking for updates..."
            "update_available" = "New version available: {0} (current: {1})"
            "update_latest" = "Already on the latest version"
            "update_downloading" = "Downloading update..."
            "update_success" = "Update successful! Please restart the script"
            "update_failed" = "Update failed: {0}"
            "update_prompt" = "Update to new version? [Y/n]"
            "update_ctrl_u" = "New version {0} available. Press Ctrl+U to update"
            "validating_config" = "Validating configuration..."
            "json_valid" = "JSON syntax valid"
            "json_invalid" = "JSON syntax invalid"
            "profiles_count" = "profiles"
            "software_count" = "software entries"
            "config_valid" = "Configuration is valid"
            "config_invalid_detail" = "Configuration has errors"
            "report_json_saved" = "JSON report saved to: {0}"
            "report_txt_saved" = "TXT report saved to: {0}"
            "disk_checking" = "Checking disk space..."
            "disk_space_low" = "Low disk space: {0}GB available, at least {1}GB recommended"
            "disk_space_warning" = "Low disk space, installation may fail"
            "network_timeout" = "Network connection timed out, please check your network"
            "network_error" = "Network error: {0}"
            "check_network" = "Suggestion: Check network connection or set proxy"
            "permission_denied" = "Permission denied: {0}"
            "permission_suggestion" = "Suggestion: Run with sudo or contact your administrator"
            "need_sudo" = "This operation requires administrator privileges"
            "need_admin" = "Please run as Administrator"
            "resume_found" = "Incomplete installation found. Resume? [Y/n]"
            "resuming" = "Resuming from last checkpoint..."
            "checkpoint_saved" = "Installation progress saved"
            "install_complete_state" = "Installation complete, cleaning up"
            "batch_installing" = "Batch installing {0} packages..."
            "batch_success" = "Batch install complete: {0}/{1} succeeded"
            "batch_failed" = "Batch install partially failed, falling back to individual install..."
            "custom_title" = "Custom Software Selection"
            "custom_space_toggle" = "Space: toggle"
            "custom_enter_confirm" = "Enter: confirm"
            "custom_a_select_all" = "A: select/deselect all"
            "custom_selected" = "Selected {0}/{1}"
            "time_seconds" = "s"
            "time_total" = "Total time"
            "retry_prompt" = "Retry? [Y/n]"
            "retrying" = "Retrying"
            "error_detail" = "Error detail"
            "exit_btn" = "Exit"
            "continue_btn" = "Continue"
            "title_select_profile" = "Select Profile"
            "title_select_software" = "Select Software"
            "title_installing" = "Installing"
            "title_ask_continue" = "Continue Installing?"
            "back_to_profiles" = "← Back to Profiles"
            "installed_label" = "(installed)"
            "skipping_installed" = "Already installed, skipping"
            "all_installed" = "All software already installed, nothing to do"
            "ask_continue" = "Installation complete. Continue installing other profiles?"
            "config_verify_failed" = "Config verification failed"
            "config_checksum_not_found" = "Checksum file not found"
            "config_checksum_mismatch" = "Checksum mismatch"
            "config_verify_success" = "Config verification passed"
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
    if ($script:IN_ALT_SCREEN -and ($Level -eq "ERROR" -or $Level -eq "INFO" -or $Level -eq "WARN")) {
        $script:ERROR_MESSAGES += $logEntry
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
        Write-Log "$($script:LANG['platform_not_supported']): $Key" "WARN"
        return $false
    }
    
    if ($dryRun) {
        Write-Log "$($script:LANG['dry_run_installing']): $Key" "STEP"
        Write-Log "CMD: $cmd" "INFO"
        Start-Sleep -Seconds 1
        Write-Log "$Key $($script:LANG['install_success']) (simulated)" "SUCCESS"
        return $true
    }
    
    Write-Log "$($script:LANG['installing']): $Key" "STEP"
    $errorOutput = ""
    try {
        $errorOutput = Invoke-Expression $cmd 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$Key $($script:LANG['install_success'])" "SUCCESS"
            $script:INSTALL_LAST_ERROR = ""
            return $true
        } else {
            Write-Log "$Key $($script:LANG['install_failed']) (exit $LASTEXITCODE): $errorOutput" "ERROR"
            $script:INSTALL_LAST_ERROR = $errorOutput
            return $false
        }
    } catch {
        Write-Log "$Key $($script:LANG['install_failed']): $($_.Exception.Message)" "ERROR"
        $script:INSTALL_LAST_ERROR = $_.Exception.Message
        return $false
    }
}

function Select-Continue {
    param([string]$ContinueText, [string]$ExitText)
    
    $options = @($ContinueText, $ExitText)
    $cursor = 0
    $startRow = [Console]::CursorTop
    
    while ($true) {
        [Console]::SetCursorPosition(0, $startRow)
        for ($i = 0; $i -lt $options.Count; $i++) {
            if ($i -eq $cursor) {
                Write-Host " > $($options[$i])" -NoNewline -BackgroundColor White -ForegroundColor Black
            } else {
                Write-Host "   $($options[$i])" -NoNewline
            }
            Write-Host ""
        }
        
        $key = Read-KeySafe -Intercept $true
        switch ($key.Key) {
            "UpArrow" { $cursor = [Math]::Max(0, $cursor - 1) }
            "DownArrow" { $cursor = [Math]::Min($options.Count - 1, $cursor + 1) }
            "Enter" { return $cursor }
        }
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
    "winget" { $batchCmd = "winget install $($packages -join ' ') --accept-package-agreements --accept-source-agreements" }
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

$($script:LANG["help_usage"])

$($script:LANG["help_lang"])
  --cfg-path PATH    $($script:LANG["help_cfg_path"])
  --cfg-url URL      $($script:LANG["help_cfg_url"])
  --dev              $($script:LANG["help_dev"])
  --dry-run $($script:LANG["help_dry_run"])
  doctor              $($script:LANG["help_doctor"])
  doctor --fix        $($script:LANG["help_fix"])
  --yes, -y $($script:LANG["help_yes"])
  --verbose          $($script:LANG["help_verbose"])
  --version, -v      $($script:LANG["help_version"])
  --log-file FILE    $($script:LANG["help_log_file"])
  --export-plan FILE $($script:LANG["help_export_plan"])
  --retry-failed $($script:LANG["help_retry_failed"])
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
    
    try { [Console]::CursorVisible = $true } catch {}
    Exit-Script -Code 0
}

function Show-Version {
    Write-Host "Quickstart-PC" -ForegroundColor Blue -NoNewline
    Write-Host " v$VERSION"
    Exit-Script -Code 0
}

function Show-Banner {
    param([string]$Lang)
    Write-Host ""
    Write-Host "  ██████╗ ██╗   ██╗████╗ ██████╗██╗  ▄██╗███████╗████████╗ █████╗ ██████╗ ████████╗      ██████╗  ██████╗" -ForegroundColor Blue
    Write-Host " ██╔═══██╗██║   ██║╚██╔╝██╔════╝██║▄██▀╔╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝      ██╔══██╗██╔════╝" -ForegroundColor Blue
    Write-Host " ██║   ██║██║   ██║ ██║ ██║     █████╔═╝ ███████╗   ██║   ███████║██████╔╝   ██║   █████╗██████╔╝██║     " -ForegroundColor Blue
    Write-Host " ██║▄▄ ██║██║   ██║ ██║ ██║     ██╠▀██▄  ╚════██║   ██║   ██╔══██║██╔══██╗   ██║   ╚════╝██╔═══╝ ██║     " -ForegroundColor Blue
    Write-Host " ╚██████╔╝╚██████╔╝████╗╚██████╗██║ ╚▀██╗███████║   ██║   ██║  ██║██║  ██║   ██║         ██║     ╚██████╗" -ForegroundColor Blue
    Write-Host "  ╚══▀▀═╝  ╚═════╝ ╚═══╝ ╚═════╝╚═╝   ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝         ╚═╝      ╚═════╝" -ForegroundColor Blue
    Write-Host ""
}

# ============================================
# Config file functions
# ============================================
function Test-ConfigChecksum {
param([string]$Path, [string]$Url)
    if ($Url -eq $DEFAULT_CFG_URL) {
        $sha256Url = "https://github.com/MomoLawson/Quickstart-PC/releases/download/v${VERSION}/profiles.json.sha256"
    } else {
        $sha256Url = "${Url}.sha256"
    }
    try {
        $expectedHash = (Invoke-WebRequestWithProxy -Uri $sha256Url -TimeoutSec 30 -ErrorAction Stop).Content.Trim()
        $actualHash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
        if ($expectedHash -ne $actualHash) {
            Write-Log "$($script:LANG["config_checksum_mismatch"])" "ERROR"
            Write-Log "  Expected: $expectedHash" "ERROR"
            Write-Log "  Actual:   $actualHash" "ERROR"
            return $false
        }
        Write-Log "$($script:LANG["config_verify_success"])" "INFO"
        return $true
    } catch {
        Write-Log "$($script:LANG["config_checksum_not_found"]): $sha256Url" "ERROR"
        return $false
    }
}

function Get-ConfigFile {
    $guid = [System.Guid]::NewGuid().ToString('N').Substring(0,8)
    $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "quickstart-config-${guid}.json")
    
    if ($cfgUrl) {
        Write-Log "$($script:LANG["using_remote_config"]): $cfgUrl" "INFO"
        try {
            Invoke-WebRequestWithProxy -Uri $cfgUrl -OutFile $tempFile -TimeoutSec 30 -ErrorAction Stop
            if (Test-JsonValid -Path $tempFile) {
                if ($verifyConfig) {
                    if (-not (Test-ConfigChecksum -Path $tempFile -Url $cfgUrl)) {
                        Write-Log "$($script:LANG["config_verify_failed"])" "ERROR"
                        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                        Exit-Script -Code 1
                    }
                }
                return $tempFile
            } else {
                Write-Log "$($script:LANG["config_invalid"]): $cfgUrl" "ERROR"
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                Exit-Script -Code 1
            }
        } catch {
            Write-Log "$($script:LANG["config_not_found"]): $cfgUrl" "ERROR"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            Exit-Script -Code 1
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
                Exit-Script -Code 1
            }
        } else {
            Write-Log "$($script:LANG["config_not_found"]): $cfgPath" "ERROR"
            Exit-Script -Code 1
        }
    }
    
    Write-Log "$($script:LANG["using_default_config"])" "INFO"
    try {
        Invoke-WebRequestWithProxy -Uri $DEFAULT_CFG_URL -OutFile $tempFile -TimeoutSec 30 -ErrorAction Stop
        if (Test-JsonValid -Path $tempFile) {
            if ($verifyConfig) {
                if (-not (Test-ConfigChecksum -Path $tempFile -Url $DEFAULT_CFG_URL)) {
                    Write-Log "$($script:LANG["config_verify_failed"])" "ERROR"
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    Exit-Script -Code 1
                }
            }
            return $tempFile
        }
    } catch {
        Write-Log "$($script:LANG["config_not_found"])" "ERROR"
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        Exit-Script -Code 1
    }
    
    Write-Log "$($script:LANG["config_not_found"])" "ERROR"
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Exit-Script -Code 1
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
    Exit-Script -Code 0
}

function Show-ShowProfile {
    param([string]$Key)
    
    $configFile = Get-ConfigFile
    $profileKeys = Get-ProfileKeys -Path $configFile
    
    if ($profileKeys -notcontains $Key) {
        Write-Log "Profile '$Key' not found" "ERROR"
        Remove-Item $configFile -Force -ErrorAction SilentlyContinue
        Exit-Script -Code 1
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
    Exit-Script -Code 0
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
    Exit-Script -Code 0
}

function Show-ShowSoftware {
    param([string]$Key)
    
    $configFile = Get-ConfigFile
    
    $name = Get-SoftwareField -Path $configFile -Key $Key -Field "name"
    $desc = Get-SoftwareField -Path $configFile -Key $Key -Field "desc"
    
    if (-not $name) {
        Write-Log "Software '$Key' not found" "ERROR"
        Remove-Item $configFile -Force -ErrorAction SilentlyContinue
        Exit-Script -Code 1
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
    Exit-Script -Code 0
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
    Exit-Script -Code 0
}

# ============================================
# QC Doctor - Environment Diagnostics
# ============================================
function Show-Doctor {
    function Hint-Cmd { param([string]$Text); Write-Host "      $Text" -ForegroundColor DarkGray -BackgroundColor Black }
    $script:fixCmds = @()
    function Collect-Fix { param([string]$Cmd); $script:fixCmds += $Cmd }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗"
    Write-Host "║ 🔧 QC Doctor                                               ║"
    Write-Host "║         Quickstart-PC Environment Diagnostics              ║"
    Write-Host "╚════════════════════════════════════════════════════════════╝"
    Write-Host ""
    
    $passed = 0
    $warnings = 0
    $failed = 0
    $osName = Get-CurrentOS
    
    # 1. System Information
    Write-Host "━━━ System Information ━━━"
    Write-Host " OS: $osName"
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    Write-Host " Arch: $arch"
    if ($osName -eq "windows") {
        $osVersion = [System.Environment]::OSVersion.VersionString
        Write-Host " Version: $osVersion"
    } elseif ($osName -eq "macos") {
        try {
            $osVersion = sw_vers -productVersion 2>&1 | Select-Object -First 1
            Write-Host " Version: $osVersion"
        } catch {}
    } elseif ($osName -eq "linux") {
        try {
            $osRelease = Get-Content /etc/os-release -ErrorAction Stop
            $prettyName = ($osRelease | Where-Object { $_ -match 'PRETTY_NAME=' }) -replace 'PRETTY_NAME="', '' -replace '"', ''
            Write-Host " Distro: $prettyName"
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
            Hint-Cmd "/bin/bash -c `"`$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)`""
            Collect-Fix "brew --version || /bin/bash -c `"`$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)`""
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
        Hint-Cmd "brew install jq (macOS) | apt install jq (Linux)"
        if ($osName -eq "macOS") { Collect-Fix "brew install jq" }
        elseif ($osName -eq "Linux") { Collect-Fix "sudo apt install -y jq" }
        $failed++
    }
    
    if (Get-Command curl -ErrorAction SilentlyContinue) {
        Write-Host " [✓] curl: available" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " [✗] curl not found" -ForegroundColor Red
        Hint-Cmd "brew install curl (macOS) | apt install curl (Linux)"
        if ($osName -eq "macOS") { Collect-Fix "brew install curl" }
        elseif ($osName -eq "Linux") { Collect-Fix "sudo apt install -y curl" }
        $failed++
    }
    
    if (Get-Command python3 -ErrorAction SilentlyContinue -or Get-Command python -ErrorAction SilentlyContinue) {
        $pyVer = python3 --version 2>&1
        Write-Host " [✓] python3: $pyVer (optional)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " [!] python3 not found (optional, fallback JSON parser)" -ForegroundColor Yellow
        Hint-Cmd "brew install python3 (macOS) | apt install python3 (Linux)"
        $warnings++
    }
    Write-Host ""
    
    # 4. Network Connectivity
    Write-Host "━━━ Network Connectivity ━━━"
    try {
        $response = Invoke-WebRequestWithProxy -Uri "https://raw.githubusercontent.com" -TimeoutSec 10 -UseBasicParsing 2>&1
        if ($response.StatusCode -eq 200) {
            Write-Host " [✓] GitHub raw content: reachable" -ForegroundColor Green
            $passed++
        } else {
            Write-Host " [✗] GitHub raw content: unreachable" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host " [✗] GitHub raw content: unreachable" -ForegroundColor Red
        $failed++
    }
    
    try {
        $response = Invoke-WebRequestWithProxy -Uri "https://github.com" -TimeoutSec 10 -UseBasicParsing 2>&1
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
        $tempPath = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
        $driveLetter = if ($osName -eq "windows") { Split-Path $tempPath -Qualifier } else { "/" }
        $disk = Get-PSDrive -Name ($driveLetter -replace ':', '') -ErrorAction Stop
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
    $tmpDir = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
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
        Exit-Script -Code 0
    } elseif ($fix -and $fixCmds.Count -gt 0) {
        Write-Host " Status: 🔧 Fixing $failed issue(s)..." -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Host ""
        foreach ($cmd in $fixCmds) {
            Write-Host "  → Running: $cmd"
            try { Invoke-Expression $cmd; Write-Host "  ✓ Done" -ForegroundColor Green }
            catch { Write-Host "  ✗ Failed: $cmd" -ForegroundColor Red }
        }
        Write-Host ""
        Write-Host " Status: ✅ Fix complete" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } else {
        Write-Host " Status: ⚠️  Some issues need attention before installation" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Host ""
        Write-Host "  Run: doctor -fix  (auto-install missing dependencies)"
        Write-Host ""
    }
    Exit-Script -Code 1
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
    Exit-Script -Code 0
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
        [array]$Failed,
        [array]$Details = @()
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
            $d = $Details | Where-Object { $_.key -eq $item } | Select-Object -First 1
            $elapsed = if ($d) { "$($d.elapsed)s" } else { "" }
            $name = if ($d) { "$($d.name)" } else { $item }
            $content += "`n  + $name ($elapsed)"
        }
        $content += "`n`nSkipped ($($Skipped.Count)):"
        foreach ($item in $Skipped) {
            $content += "`n  ~ $item"
        }
        $content += "`n`nFailed ($($Failed.Count)):"
        foreach ($item in $Failed) {
            $d = $Details | Where-Object { $_.key -eq $item } | Select-Object -First 1
            $elapsed = if ($d) { " ($($d.elapsed)s)" } else { "" }
            $name = if ($d) { $d.name } else { $item }
            $content += "`n  - $name$elapsed"
        }
        $content += "`n`nTotal: $($Installed.Count) installed, $($Skipped.Count) skipped, $($Failed.Count) failed"
        
        Set-Content -Path $TxtPath -Value $content -Encoding UTF8
        Write-Log "Text report exported to $TxtPath" "INFO"
    }
    
    if ($JsonPath) {
        $detailsArray = @()
        foreach ($d in $Details) {
            $detailsArray += @{
                key = $d.key
                name = $d.name
                elapsed_seconds = $d.elapsed
                status = $d.status
                command = $d.command
            }
        }
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
            details = $detailsArray
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
    $tempPath = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
    $osName = Get-CurrentOS
    if ($osName -eq "windows") {
      $driveLetter = Split-Path $tempPath -Qualifier
      $disk = Get-PSDrive -Name ($driveLetter -replace ':', '') -ErrorAction Stop
      $availableGB = [math]::Round($disk.Free / 1GB)
    } else {
      $disk = Get-PSDrive -Name "/" -ErrorAction Stop
      $availableGB = [math]::Round($disk.Free / 1GB)
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
    profile = if ($script:SELECTED_PROFILES.Count -gt 0) { $script:SELECTED_PROFILES[0] } else { "" }
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
  param([string]$CurrentProfile)
  if (Test-Path $script:STATE_FILE) {
    try {
      $state = Get-Content $script:STATE_FILE | ConvertFrom-Json
      if ($CurrentProfile -and $state.profile -and $CurrentProfile -ne $state.profile) {
        Write-Log "State file profile ($($state.profile)) doesn't match current profile ($CurrentProfile)" "WARN"
        return $null
      }
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
  $hookScript = ""
  try {
    $config = Get-Content $script:CONFIG_FILE -Raw | ConvertFrom-Json
    $hookScript = $config.hooks.$HookType
  } catch {}
  if (-not $hookScript) { return }
  if (-not $allowHooks) {
    Write-Host " $($script:LANG["hooks_disabled"])" -ForegroundColor DarkGray
    return
  }
  Write-Host " $($script:LANG["hook_running"] -f $HookType)" -ForegroundColor Cyan
  try {
    if (Test-Path $hookScript -ErrorAction SilentlyContinue) {
      # It's a file path
      & $hookScript
    } else {
      # It's script content
      Invoke-Expression $hookScript
    }
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
  Invoke-WebRequestWithProxy -Uri `$url -OutFile `$tmpFile -TimeoutSec 60
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
    $pwshCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process -FilePath $pwshCmd -ArgumentList "-NoProfile", "-File", $updateScriptPath -Wait -NoNewWindow
    Remove-Item -Path $updateScriptPath -Force -ErrorAction SilentlyContinue
    return 0
  } catch {
    Write-Host " $($script:LANG["update_failed"] -f $_.Exception.Message)" -ForegroundColor Red
    return 1
    }
}

function Test-OneLiner {
    return ($MyInvocation.ScriptName -eq "" -or $MyInvocation.ScriptName -match "^(bash|sh)$")
}

function Start-AutoCheckUpdate {
    if (Test-OneLiner) { return }
    $script:autoUpdateLatest = $null
    $script:autoCheckJob = Start-Job -ScriptBlock {
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/MomoLawson/Quickstart-PC/releases/latest" -TimeoutSec 10 -ErrorAction Stop
            $latest = $release.tag_name -replace '^v',''
            $current = $using:VERSION
            if ($latest -and $current -ne $latest) { return $latest }
        } catch {}
        return $null
    }
}

function Get-AutoCheckResult {
    if (-not $script:autoCheckJob) { return }
    if ($script:autoCheckJob.State -ne "Completed") { return }
    $result = Receive-Job -Job $script:autoCheckJob -ErrorAction SilentlyContinue
    Remove-Job -Job $script:autoCheckJob -Force -ErrorAction SilentlyContinue
    $script:autoCheckJob = $null
    if ($result) { $script:autoUpdateLatest = $result }
}

function Show-UpdateHint {
    Get-AutoCheckResult
    if ($script:autoUpdateLatest) {
        $msg = $script:LANG["update_ctrl_u"] -f $script:autoUpdateLatest
        Write-Host "  $msg" -ForegroundColor Yellow
    }
}

function Invoke-CtrlUUpdate {
    if (-not $script:autoUpdateLatest) { return $false }
    Write-Host ""
    Update-Self
    Exit-Script -Code $LASTEXITCODE
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
    Write-Log $script:LANG["select_profiles"] "INFO"
    Write-Host ""
    Write-Host " $($script:LANG["navigate"])" -ForegroundColor Cyan
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
        $key = Read-KeySafe -Intercept $true

        if ($key.Key -eq [ConsoleKey]::U -and ($key.Modifiers -band [ConsoleModifiers]::Control)) {
            if (Invoke-CtrlUUpdate) { continue }
        }

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
        [Console]::Write("`r{0}" -f (" " * [Console]::WindowWidth))
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
$menuNames = @("← $($script:LANG["back_to_profiles"])", $script:LANG["select_all"])
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
$menuNames += "$displayName - $desc $($script:LANG["installed"])"
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
Write-Log $script:LANG["title_select_software"] "INFO"
Write-Host ""
Write-Host " $($script:LANG["custom_space_toggle"]) | $($script:LANG["custom_enter_confirm"]) | $($script:LANG["custom_a_select_all"])" -ForegroundColor Cyan
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
$prefix = if ($checked[$i] -eq 1) { $script:LANG["selected"] } else { $script:LANG["not_selected"] }
if ($i -eq $CursorPos) {
Write-Host " $prefix$itemText" -NoNewline -BackgroundColor White -ForegroundColor DarkYellow
} else {
Write-Host " $prefix$itemText" -NoNewline -ForegroundColor DarkYellow
}
} else {
# Software items - checkbox, gray if installed
$prefix = if ($checked[$i] -eq 1) { $script:LANG["selected"] } else { $script:LANG["not_selected"] }
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
$countText = $script:LANG["custom_selected"] -f $SelectedCount, ($numItems - 2)
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
$key = Read-KeySafe -Intercept $true

if ($key.Key -eq [ConsoleKey]::U -and ($key.Modifiers -band [ConsoleModifiers]::Control)) {
    if (Invoke-CtrlUUpdate) { continue }
}

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
[Console]::Write("`r{0}" -f (" " * [Console]::WindowWidth))
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
    trap { if ($script:IN_ALT_SCREEN) { Exit-AlternateScreen }; try { Set-CursorVisible -Visible $true } catch {} }
    if ($checkUpdate) {
        Show-Banner -Lang $updateLang
        $result = Check-Update
        Exit-Script -Code $result
    }
    if ($update) {
        Show-Banner -Lang $updateLang
        $result = Update-Self
        Exit-Script -Code $result
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
        if ($script:IN_ALT_SCREEN) { Exit-AlternateScreen }
        try { Set-CursorVisible -Visible $true } catch {}
        if ($LASTEXITCODE -eq 0 -and -not $script:HAS_ERROR) {
            Write-Host ""
            Write-Host $script:LANG["bye"]
        }
    }
    Start-AutoCheckUpdate
    $script:NON_INTERACTIVE = $nonInteractive
    if (-not $nonInteractive) {
        try {
            if ($null -eq $Host.UI.RawUI -or [Console]::IsOutputRedirected) {
                $nonInteractive = $true
            }
        } catch {
            $nonInteractive = $true
        }
    }
    if (-not $nonInteractive) { Enter-AlternateScreen }
    
    while ($true) {
        Clear-Host
        try { Set-CursorVisible -Visible $false } catch {}
        
        Show-Banner -Lang $script:DETECTED_LANG
        Show-UpdateHint
        
        if ($dev) { Write-Log $script:LANG["dev_mode"] "WARN"; Write-Host "" }
        if ($dryRun) { Write-Log $script:LANG["dry_run_mode"] "WARN"; Write-Host "" }
        
        Write-Log $script:LANG["detecting_system"] "INFO"
        $os = Get-CurrentOS
        $systemInfo = Get-SystemInfo
        $script:PKG_MANAGER = Get-PackageManager -OS $os
        
        Write-Log "$($script:LANG["system_info"]): $systemInfo" "INFO"
        
        $displayPm = $script:PKG_MANAGER
        if (Ensure-NpmInstalled -OS $os) {
            $displayPm += ", npm"
        }
        
        Write-Log "$($script:LANG["package_manager"]): $displayPm" "INFO"
        
        if ($os -eq "unknown") {
            Write-Log $script:LANG["unsupported_os"] "ERROR"
            Exit-Script -Code 1
        }
        
        $script:CONFIG_FILE = Get-ConfigFile
        
if ($nonInteractive) {
    if (-not $profile) {
        Write-Log $script:LANG["noninteractive_error"] "ERROR"
        Exit-Script -Code 1
    }

    $profileKeys = Get-ProfileKeys -Path $script:CONFIG_FILE
    if ($profileKeys -notcontains $profile) {
        Write-Log "$($script:LANG["profile_not_found"]): $profile" "ERROR"
        Exit-Script -Code 1
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
      Write-Log "$($script:LANG["profile_not_found"]): $profile" "ERROR"
      Exit-Script -Code 1
    }

    $script:SELECTED_PROFILES = @($profile)
    $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $profile -Field "name"

    while ($true) {
      Set-WindowTitle -Title "QSPC | $profileName | $($script:LANG["title_select_software"])"
      $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $profile

      if ($null -ne $script:SELECTED_SOFTWARE) {
        break # Normal confirm, proceed
      }
      # $null means back was pressed, re-show profile menu
      Set-WindowTitle -Title "QSPC | $($script:LANG["title_select_profile"])"
      $selectedProfile = Show-ProfileMenu -Path $script:CONFIG_FILE

      if (-not $selectedProfile) {
        Write-Log $script:LANG["no_profile_selected"] "WARN"
        Exit-Script -Code 0
      }

      $script:SELECTED_PROFILES = @($selectedProfile)
      $profile = $selectedProfile
      $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $selectedProfile -Field "name"
    }
  }
  else {
    while ($true) {
      Set-WindowTitle -Title "QSPC | $($script:LANG["title_select_profile"])"
      $selectedProfile = Show-ProfileMenu -Path $script:CONFIG_FILE

      if (-not $selectedProfile) {
        Write-Log $script:LANG["no_profile_selected"] "WARN"
        Exit-Script -Code 0
      }

      $script:SELECTED_PROFILES = @($selectedProfile)
      $profileName = Get-ProfileField -Path $script:CONFIG_FILE -Key $selectedProfile -Field "name"

      Set-WindowTitle -Title "QSPC | $profileName | $($script:LANG["title_select_software"])"
      $script:SELECTED_SOFTWARE = Show-SoftwareMenu -Path $script:CONFIG_FILE -OS $os -ProfileKey $selectedProfile

    if ($null -ne $script:SELECTED_SOFTWARE) {
      break # Normal confirm, proceed
    }
    # $null means back was pressed, loop to re-show profile menu
  }
}

if ($script:SELECTED_SOFTWARE.Count -eq 0) {
            Write-Log $script:LANG["no_software_selected"] "WARN"
            
            if ($nonInteractive) {
                Exit-Script -Code 0
            }
            
            Write-Host ""
            Write-Log $script:LANG["ask_continue"] "INFO"
            $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
            if ($continue -eq 1) { Exit-Script -Code 0 }
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
            if ($nonInteractive) { Exit-Script -Code 0 }
        }
        
        if ($dev) {
            Write-Log "Dev mode: Done" "INFO"
            Exit-Script -Code 0
        }
        
if (-not $yes -and -not $nonInteractive) {
    Write-Host "$($script:LANG["confirm_install"])" -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host " "
    if ($confirm -match "^[Nn]") {
                Write-Log $script:LANG["cancelled"] "INFO"
                Write-Host ""
                Write-Log $script:LANG["ask_continue"] "INFO"
                $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
                if ($continue -eq 1) { Exit-Script -Code 0 }
                continue
            }
        }
        
        Write-Log $script:LANG["checking_installation"] "INFO"
        
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
Write-Host " $detBar $installedCount/$($installedCount + $toInstallCount) $($script:LANG["installed"]), $toInstallCount $($script:LANG["to_install"])" -ForegroundColor Cyan

# Show already-installed in gray
foreach ($sw in $alreadyInstalled) {
    $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
    $swIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "icon"
    $swDisplay = if ($swIcon) { "$swIcon $swName" } else { $swName }
    Write-Host " [✓] $swDisplay - $($script:LANG["skipping_installed"])" -ForegroundColor Gray
}
Write-Host ""
        
        if ($toInstall.Count -eq 0) {
            Write-Log $script:LANG["all_installed"] "INFO"
            
            if ($nonInteractive) {
                Exit-Script -Code 0
            }
            
            Write-Host ""
            Write-Log $script:LANG["ask_continue"] "INFO"
            $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
  if ($continue -eq 1) { Exit-Script -Code 0 }
  continue
}

Write-Host " $($script:LANG["disk_checking"])" -ForegroundColor Cyan
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
    $currentProfile = if ($script:SELECTED_PROFILES.Count -gt 0) { $script:SELECTED_PROFILES[0] } else { "" }
    $savedRemaining = Load-InstallState -CurrentProfile $currentProfile
    if ($savedRemaining) {
      if ($resume -or $nonInteractive) {
        Write-Host " $($script:LANG["resuming"])" -ForegroundColor Cyan
        $script:toInstall = $savedRemaining
      } else {
Write-Host " $($script:LANG["resume_found"])" -ForegroundColor Yellow -NoNewline
    $resumeAnswer = Read-Host " "
        if ([string]::IsNullOrWhiteSpace($resumeAnswer) -or $resumeAnswer -match "^[Yy]") {
          Write-Host " $($script:LANG["resuming"])" -ForegroundColor Cyan
          $script:toInstall = $savedRemaining
        } else {
          Clear-InstallState
        }
      }
    }
  }

Set-WindowTitle -Title "QSPC | $($script:LANG["title_installing"])"
Write-Header $script:LANG["start_installing"]

$script:toInstall = $toInstall
$total = $toInstall.Count
$current = 0
$script:current = 0
$script:total = $total
$script:installedList = @()
$script:failedList = @()
$script:installDetails = @()
$installStartTime = Get-Date

  Invoke-HookScript -HookType "pre_install"

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

  if ($dryRun) {
    foreach ($sw in $toInstall) {
      $current++
      $swName = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "name"
      $swIcon = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field "icon"
      $swDisplay = if ($swIcon) { "$swIcon $swName" } else { $swName }
      $bar = Draw-ProgressBar -Current $current -Total $total
      Write-Host "`r $bar $current/$total $swDisplay - $($script:LANG["installing"])..." -NoNewline -ForegroundColor Cyan

      $env:SOFTWARE_KEY = $sw
      $env:SOFTWARE_NAME = $swName
      Invoke-HookScript -HookType "pre_software"

      $swStart = Get-Date
      $result = Install-Software -Path $script:CONFIG_FILE -OS $os -Key $sw
      $swEnd = Get-Date
      $swElapsed = [math]::Round(($swEnd - $swStart).TotalSeconds)
      $swCmd = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field $platform
      $detail = @{ key = $sw; name = $swName; elapsed = $swElapsed; status = "skipped"; command = $swCmd }

      if ($result) {
        Write-Host "`r $bar $current/$total $swDisplay - " -NoNewline
        Write-Host "$($script:LANG["install_success"]) ($swElapsed$($script:LANG["time_seconds"]))" -ForegroundColor Green
        $detail.status = "installed"
        $script:installedList += $sw
      } else {
        Write-Host "`r $bar $current/$total $swDisplay - " -NoNewline
        Write-Host "$($script:LANG["install_failed"]) ($swElapsed$($script:LANG["time_seconds"]))" -ForegroundColor Red
        $detail.status = "failed"
        $script:failedList += $sw
        if ($failFast) {
          Write-Host ""
          Write-Log "Fail-fast: stopping at $swName" "ERROR"
          Save-InstallState
          break
        }
      }
      $script:installDetails += $detail
      Invoke-HookScript -HookType "post_software"
      Save-InstallState
    }
  } else {
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
        Write-Host "`r $bar $script:current/$script:total $swDisplay - $($script:LANG["installing"])..." -NoNewline -ForegroundColor Cyan

        $env:SOFTWARE_KEY = $sw
        $env:SOFTWARE_NAME = $swName
        Invoke-HookScript -HookType "pre_software"

        $swStart = Get-Date
        $result = Install-Software -Path $script:CONFIG_FILE -OS $os -Key $sw
        $swEnd = Get-Date
        $swElapsed = [math]::Round(($swEnd - $swStart).TotalSeconds)
        $swCmd = Get-SoftwareField -Path $script:CONFIG_FILE -Key $sw -Field $platform
        $detail = @{ key = $sw; name = $swName; elapsed = $swElapsed; status = "skipped"; command = $swCmd }

        if ($result) {
          Write-Host "`r $bar $script:current/$script:total $swDisplay - " -NoNewline
          Write-Host "$($script:LANG["install_success"]) ($swElapsed$($script:LANG["time_seconds"]))" -ForegroundColor Green
          $detail.status = "installed"
          $script:installedList += $sw
        } else {
          Write-Host "`r $bar $script:current/$script:total $swDisplay - " -NoNewline
          Write-Host "$($script:LANG["install_failed"]) ($swElapsed$($script:LANG["time_seconds"]))" -ForegroundColor Red
          $detail.status = "failed"
          $script:failedList += $sw
          if ($failFast) {
            Write-Host ""
            Write-Log "Fail-fast: stopping at $swName" "ERROR"
            Save-InstallState
            return
          }
        }
        $script:installDetails += $detail
        Invoke-HookScript -HookType "post_software"
        Save-InstallState
      } else {
        Install-Batch -Path $script:CONFIG_FILE -OS $os -Manager $Manager -Keys $Keys
        $script:current += $Keys.Count
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
Write-Host "$($script:LANG["time_total"]): $totalElapsed$($script:LANG["time_seconds"])" -ForegroundColor Cyan
Write-Host ""
        
        $skippedList = $alreadyInstalled
        
        Write-Header $script:LANG["installation_complete"]
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
        Export-Report -JsonPath $reportJson -TxtPath $reportTxt -Installed $script:installedList -Skipped $skippedList -Failed $script:failedList -Details $script:installDetails
  }

  # Clear state on successful completion
  Clear-InstallState

  if ($nonInteractive) {
    Set-WindowTitle -Title "QSPC"
    Exit-Script -Code 0
  }
        
        Set-WindowTitle -Title "QSPC | $($script:LANG["title_ask_continue"])"
        Write-Host ""
        Write-Log $script:LANG["ask_continue"] "INFO"
        $continue = Select-Continue -ContinueText $script:LANG["continue_btn"] -ExitText $script:LANG["exit_btn"]
        if ($continue -eq 1) { Exit-Script -Code 0 }
        
        continue
    }

Main
