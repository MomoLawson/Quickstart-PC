# Detect system and package manager

function Detect-OS {
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        return "windows"
    } elseif ($IsMacOS) {
        return "macos"
    } elseif ($IsLinux) {
        return "linux"
    } else {
        # Legacy Windows check
        if ($env:PROCESSOR_ARCHITECTURE -match "64" -or $env:PROCESSOR_ARCHITEW6432 -match "64") {
            return "windows"
        }
        return "unknown"
    }
}

function Get-SystemInfo {
    $os = Detect-OS
    switch ($os) {
        "windows" {
            $version = (Get-WmiObject -class Win32_OperatingSystem).Caption
            return "Windows $version"
        }
        "macos" {
            $version = (sw_vers -productVersion 2>$null) ?? "unknown"
            return "macOS $version"
        }
        "linux" {
            $distro = Get-LinuxDistro
            return "Linux ($distro)"
        }
        default {
            return "Unknown OS"
        }
    }
}

function Get-LinuxDistro {
    if (Test-Path "/etc/os-release") {
        $content = Get-Content "/etc/os-release"
        foreach ($line in $content) {
            if ($line -match "^ID=(.+)$") {
                return $matches[1].Trim('"')
            }
        }
    } elseif (Test-Path "/etc/lsb-release") {
        $content = Get-Content "/etc/lsb-release"
        foreach ($line in $content) {
            if ($line -match "^DISTRIB_ID=(.+)$") {
                return $matches[1].Trim('"')
            }
        }
    }
    return "unknown"
}

function Check-PackageManager {
    param([string]$OS)
    
    switch ($OS) {
        "windows" {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                return "winget"
            } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
                return "scoop"
            } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
                return "choco"
            } else {
                return "none"
            }
        }
        "macos" {
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                return "brew"
            } else {
                return "none"
            }
        }
        "linux" {
            if (Get-Command apt -ErrorAction SilentlyContinue) {
                return "apt"
            } elseif (Get-Command yum -ErrorAction SilentlyContinue) {
                return "yum"
            } elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
                return "dnf"
            } elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
                return "pacman"
            } elseif (Get-Command zypper -ErrorAction SilentlyContinue) {
                return "zypper"
            } else {
                return "none"
            }
        }
        default {
            return "none"
        }
    }
}

function Install-PackageManager {
    param(
        [string]$OS,
        [string]$PackageManager
    )
    
    switch ($OS) {
        "windows" {
            if ($PackageManager -eq "none") {
                $PackageManager = "scoop"
            }
            
            if ($PackageManager -eq "scoop") {
                Write-Info "安装 Scoop 包管理器..."
                try {
                    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
                    if (Get-Command scoop -ErrorAction SilentlyContinue) {
                        Write-Success "Scoop 安装成功"
                        return $true
                    } else {
                        Write-Error "Scoop 安装失败"
                        return $false
                    }
                } catch {
                    Write-Error "Scoop 安装失败: $_"
                    return $false
                }
            } elseif ($PackageManager -eq "winget") {
                Write-Info "请从 Microsoft Store 安装 '应用安装程序' (App Installer) 来获取 winget"
                return $false
            } elseif ($PackageManager -eq "choco") {
                Write-Info "安装 Chocolatey 包管理器..."
                try {
                    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
                    if (Get-Command choco -ErrorAction SilentlyContinue) {
                        Write-Success "Chocolatey 安装成功"
                        return $true
                    } else {
                        Write-Error "Chocolatey 安装失败"
                        return $false
                    }
                } catch {
                    Write-Error "Chocolatey 安装失败: $_"
                    return $false
                }
            }
        }
        "macos" {
            Write-Info "请在 macOS 终端中运行安装 Homebrew: /bin/bash -c `"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)`""
            return $false
        }
        "linux" {
            Write-Info "请根据您的 Linux 发行版使用相应的包管理器"
            return $false
        }
    }
    
    return $false
}
