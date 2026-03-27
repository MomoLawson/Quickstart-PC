# Install functions for PowerShell

function Resolve-SoftwareList {
    param(
        [string]$OS,
        [string[]]$Profiles
    )
    
    $yamlFile = "$ScriptDir\config\profiles.yaml"
    if (-not (Test-Path $yamlFile)) {
        Write-Error "配置文件不存在: $yamlFile"
        return @()
    }
    
    $content = Get-Content $yamlFile -Raw
    if (-not $content) {
        Write-Error "无法读取配置文件"
        return @()
    }
    
    $inProfiles = $false
    $inTargetProfile = $false
    $inIncludes = $false
    $currentProfile = ""
    $swList = @()
    
    foreach ($line in $content -split "`n") {
        $line = $line.TrimEnd()
        
        if ($line -match '^profiles:') {
            $inProfiles = $true
            $inIncludes = $false
            continue
        }
        
        if ($line -match '^software:') {
            $inProfiles = $false
            $inIncludes = $false
            continue
        }
        
        if ($inProfiles) {
            if ($line -match '^\s{2}([a-z_][a-z0-9_]*):\s*$') {
                $currentProfile = $matches[1]
                $inTargetProfile = $Profiles -contains $currentProfile
                $inIncludes = $false
            } elseif ($inTargetProfile -and $line -match '^\s+includes:') {
                $inIncludes = $true
            } elseif ($inIncludes -and $line -match '^\s{6}-\s+([a-z0-9.]+)') {
                $swList += $matches[1]
            } elseif ($line -match '^\s{2}[a-z_][a-z0-9_]*:') {
                $inIncludes = $false
            }
        }
    }
    
    return $swList | Sort-Object -Unique
}

function Get-InstallCommand {
    param(
        [string]$SoftwareKey,
        [string]$Platform
    )
    
    $yamlFile = "$ScriptDir\config\profiles.yaml"
    if (-not (Test-Path $yamlFile)) {
        return $null
    }
    
    $content = Get-Content $yamlFile -Raw
    if (-not $content) {
        return $null
    }
    
    # Map platform names
    switch ($Platform) {
        "macos" { $platform = "mac" }
        "windows" { $platform = "win" }
        default { $platform = $Platform }
    }
    
    $inSoftware = $false
    $inTarget = $false
    
    foreach ($line in $content -split "`n") {
        $line = $line.TrimEnd()
        
        if ($line -match '^software:') {
            $inSoftware = $true
            continue
        }
        
        if ($inSoftware) {
            $key = ($line -split ':')[0].Trim()
            if ($key -eq $SoftwareKey) {
                $inTarget = $true
            } elseif ($key -in @("win", "mac", "linux")) {
                $inTarget = $false
            }
            
            if ($inTarget -and $line -match "^\s+$platform:\s*`"(.+)`"") {
                return $matches[1]
            }
        }
    }
    
    return $null
}

function Install-Software {
    param(
        [string]$OS,
        [string]$SoftwareKey
    )
    
    $installCmd = Get-InstallCommand -SoftwareKey $SoftwareKey -Platform $OS
    
    if (-not $installCmd) {
        Write-Warn "不支持的平台: $SoftwareKey"
        return $false
    }
    
    Write-Step "安装: $SoftwareKey"
    
    try {
        Invoke-Expression $installCmd 2>$null
        Write-Success "$SoftwareKey 安装完成"
        return $true
    } catch {
        Write-Error "$SoftwareKey 安装失败"
        return $false
    }
}
