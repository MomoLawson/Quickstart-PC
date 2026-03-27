#!/usr/bin/env bash
# 系统检测模块

detect_os() {
    local os_name
    local os_version
    
    case "$OSTYPE" in
        msys*|mingw*|cygwin*|win*)
            echo "windows"
            ;;
        darwin*)
            echo "macos"
            ;;
        linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID"
    else
        echo "unknown"
    fi
}

get_system_info() {
    local os=$(detect_os)
    
    case "$os" in
        windows)
            echo "Windows"
            ;;
        macos)
            local version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            echo "macOS $version"
            ;;
        linux)
            local distro=$(detect_linux_distro)
            echo "Linux ($distro)"
            ;;
        *)
            echo "Unknown OS"
            ;;
    esac
}

check_package_manager() {
    local os=$1
    
    case "$os" in
        windows)
            if command -v winget &>/dev/null; then
                echo "winget"
            elif command -v scoop &>/dev/null; then
                echo "scoop"
            elif command -v choco &>/dev/null; then
                echo "choco"
            else
                echo "none"
            fi
            ;;
        macos)
            if command -v brew &>/dev/null; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        linux)
            if command -v apt &>/dev/null; then
                echo "apt"
            elif command -v yum &>/dev/null; then
                echo "yum"
            elif command -v dnf &>/dev/null; then
                echo "dnf"
            elif command -v pacman &>/dev/null; then
                echo "pacman"
            elif command -v zypper &>/dev/null; then
                echo "zypper"
            else
                echo "none"
            fi
            ;;
    esac
}

install_package_manager() {
    local os=$1
    local pkg_manager=$2
    
    case "$os" in
        windows)
            if [[ "$pkg_manager" == "none" ]]; then
                pkg_manager="scoop"
            fi
            
            if [[ "$pkg_manager" == "scoop" ]]; then
                log_info "安装 Scoop 包管理器..."
                powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh'))"
                if command -v scoop &>/dev/null; then
                    log_success "Scoop 安装成功"
                    return 0
                else
                    log_error "Scoop 安装失败"
                    return 1
                fi
            elif [[ "$pkg_manager" == "winget" ]]; then
                log_info "请从 Microsoft Store 安装 '应用安装程序' (App Installer) 来获取 winget"
                return 1
            elif [[ "$pkg_manager" == "choco" ]]; then
                log_info "安装 Chocolatey 包管理器..."
                powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
                if command -v choco &>/dev/null; then
                    log_success "Chocolatey 安装成功"
                    return 0
                else
                    log_error "Chocolatey 安装失败"
                    return 1
                fi
            fi
            ;;
        macos)
            if [[ "$pkg_manager" == "none" ]]; then
                log_info "安装 Homebrew 包管理器..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if command -v brew &>/dev/null; then
                    log_success "Homebrew 安装成功"
                    return 0
                else
                    log_error "Homebrew 安装失败"
                    return 1
                fi
            fi
            ;;
        linux)
            if [[ "$pkg_manager" == "none" ]]; then
                local distro=$(detect_linux_distro)
                case "$distro" in
                    ubuntu|debian)
                        log_info "包管理器已安装: apt"
                        return 0
                        ;;
                    centos|rhel|fedora)
                        if command -v dnf &>/dev/null; then
                            log_info "包管理器已安装: dnf"
                        elif command -v yum &>/dev/null; then
                            log_info "包管理器已安装: yum"
                        else
                            log_error "无法确定包管理器"
                            return 1
                        fi
                        ;;
                    arch|manjaro)
                        if command -v pacman &>/dev/null; then
                            log_info "包管理器已安装: pacman"
                        else
                            log_error "无法确定包管理器"
                            return 1
                        fi
                        ;;
                    *)
                        log_error "无法为 $distro 安装包管理器"
                        return 1
                        ;;
                esac
            fi
            ;;
    esac
}
