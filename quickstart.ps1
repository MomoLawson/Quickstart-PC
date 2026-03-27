#!/usr/bin/env pwsh

# Quickstart-PC Windows Installer
# PowerShell script for Windows installation

#Requires -Version 5.1

param(
    [switch]$NoMenu,
    [string[]]$Profiles = @()
)

# ===== 配置 =====
$CONFIG_URL = ""  # 云端配置链接，留空则使用本地配置
# 示例: $CONFIG_URL = "https://raw.githubusercontent.com/user/repo/main/config/profiles.yaml"

$ErrorActionPreference = "Stop"

# Import modules
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$ScriptDir\utils\log.ps1"
. "$ScriptDir\scripts\detect.ps1"
. "$ScriptDir\scripts\menu.ps1"
. "$ScriptDir\scripts\install.ps1"

function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         " -ForegroundColor Cyan -NoNewline
    Write-Host "Quickstart-PC v1.0" -ForegroundColor White -BackgroundColor Cyan -NoNewline
    Write-Host "             ║" -ForegroundColor Cyan
    Write-Host "║    快速配置新电脑软件环境              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Load-Config {
    $configFile = "$ScriptDir\config\profiles.yaml"
    
    # 如果指定了云端配置链接，优先从云端获取
    if ($CONFIG_URL) {
        Write-Info "正在从云端获取配置..."
        $tmpConfig = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.yaml'
        
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($CONFIG_URL, $tmpConfig)
            
            # 验证文件是否是有效的 YAML（简单检查）
            $content = Get-Content $tmpConfig -Raw -ErrorAction SilentlyContinue
            if ($content -match "profiles:" -and $content -match "software:") {
                Write-Success "云端配置加载成功"
                return $tmpConfig
            } else {
                Write-Warn "云端配置格式无效，使用本地配置"
                Remove-Item $tmpConfig -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Warn "云端配置获取失败: $_"
            Remove-Item $tmpConfig -Force -ErrorAction SilentlyContinue
        }
    }
    
    # 使用本地配置
    if (Test-Path $configFile) {
        Write-Info "使用本地配置: $configFile"
        return $configFile
    } else {
        Write-Error "配置文件不存在: $configFile"
        return $null
    }
}

function main {
    Show-Banner
    
    Write-Info "检测系统环境..."
    $os = Detect-OS
    $systemInfo = Get-SystemInfo
    $pkgManager = Check-PackageManager -OS $os
    
    Write-Info "系统: $systemInfo"
    Write-Info "包管理器: $pkgManager"
    
    if ($os -eq "unknown") {
        Write-Error "不支持的操作系统"
        exit 1
    }
    
    if ($pkgManager -eq "none") {
        Write-Warn "未检测到包管理器"
        Write-Host ""
        $installMgr = Read-Host "是否自动安装包管理器？[Y/n]"
        if ($installMgr -notmatch '^[Nn]') {
            if (Install-PackageManager -OS $os -PackageManager "scoop") {
                $pkgManager = Check-PackageManager -OS $os
                Write-Info "包管理器已更新为: $pkgManager"
            } else {
                Write-Error "包管理器安装失败，部分软件可能无法自动安装"
            }
        }
    }
    
    # 加载配置（云端或本地）
    $configFile = Load-Config
    if (-not $configFile) {
        exit 1
    }
    
    # 如果是临时文件，退出时清理
    $isTempFile = $configFile -ne "$ScriptDir\config\profiles.yaml"
    if ($isTempFile) {
        try { Register-EngineEvent PowerShell.Exiting -Action { Remove-Item $configFile -Force -ErrorAction SilentlyContinue } | Out-Null } catch {}
    }
    
    if ($NoMenu) {
        if ($Profiles.Count -eq 0) {
            Write-Error "未指定安装套餐"
            exit 1
        }
        $selectedProfiles = $Profiles
    } else {
        $selectedProfiles = Show-Menu -ProfilesYaml $configFile
    }
    
    if ($selectedProfiles.Count -eq 0) {
        Write-Warn "未选择任何套餐"
        exit 0
    }
    
    Write-Info "选择的套餐: $($selectedProfiles -join ', ')"
    
    Write-Host ""
    $confirm = Read-Host "确认安装？[Y/n]"
    if ($confirm -match '^[Nn]') {
        Write-Info "已取消"
        exit 0
    }
    
    $softwareList = Resolve-SoftwareList -OS $os -Profiles $selectedProfiles
    
    if ($softwareList.Count -eq 0) {
        Write-Warn "没有软件需要安装"
        exit 0
    }
    
    Write-Host ""
    Write-Header "开始安装软件"
    
    $total = $softwareList.Count
    $current = 0
    
    foreach ($sw in $softwareList) {
        $current++
        $percent = [math]::Round($current * 100 / $total)
        Write-Host "`r[$percent%] 安装 $sw" -ForegroundColor Cyan -NoNewline
        Install-Software -OS $os -SoftwareKey $sw
    }
    
    Write-Host ""
    Write-Header "安装完成"
    Write-Success "共安装 $total 个软件"
    
    # 清理临时文件
    if ($isTempFile) {
        Remove-Item $configFile -Force -ErrorAction SilentlyContinue
    }
}

main
