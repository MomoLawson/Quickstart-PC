# Menu system for PowerShell

function Show-Menu {
    param([string]$ProfilesYaml)
    
    $selected = @()
    
    if (-not (Test-Path $ProfilesYaml)) {
        Write-Error "配置文件不存在: $ProfilesYaml"
        return $selected
    }
    
    $content = Get-Content $ProfilesYaml -Raw
    if (-not $content) {
        Write-Error "无法读取配置文件"
        return $selected
    }
    
    # Simple YAML parsing for profiles
    $inProfiles = $false
    $currentKey = ""
    $profiles = @{}
    
    foreach ($line in $content -split "`n") {
        $line = $line.TrimEnd()
        
        if ($line -match '^profiles:') {
            $inProfiles = $true
            continue
        }
        
        if ($line -match '^software:') {
            $inProfiles = $false
            continue
        }
        
        if ($inProfiles -and $line -match '^\s{2}([a-z_][a-z0-9_]*):\s*$') {
            $currentKey = $matches[1]
            $profiles[$currentKey] = @{
                name = ""
                desc = ""
                icon = ""
            }
        } elseif ($inProfiles -and $currentKey) {
            if ($line -match '^\s+name:\s*"([^"]+)"') {
                $profiles[$currentKey].name = $matches[1]
            } elseif ($line -match '^\s+desc:\s*"([^"]+)"') {
                $profiles[$currentKey].desc = $matches[1]
            } elseif ($line -match '^\s+icon:\s*"([^"]+)"') {
                $profiles[$currentKey].icon = $matches[1]
            }
        }
    }
    
    Write-Host ""
    Write-Header "选择安装套餐"
    Write-Host ""
    
    $keys = $profiles.Keys | Sort-Object
    for ($i = 0; $i -lt $keys.Count; $i++) {
        $key = $keys[$i]
        $p = $profiles[$key]
        Write-Host "  [$($i+1)] $($p.icon) $($p.name)"
        Write-Host "      $($p.desc)"
        Write-Host ""
    }
    
    Write-Host "  [0] 开始安装"
    Write-Host ""
    
    $input = Read-Host "输入选项（空格分隔，如 1 2 4）"
    $choices = $input -split '\s+' | Where-Object { $_ -match '^\d+$' }
    
    foreach ($choice in $choices) {
        if ($choice -ge 1 -and $choice -le $keys.Count) {
            $selected += $keys[$choice - 1]
        }
    }
    
    return $selected
}
