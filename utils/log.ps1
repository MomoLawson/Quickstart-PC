# Log utilities for PowerShell

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Write-Step {
    param([string]$Message)
    Write-Host "[→] $Message" -ForegroundColor Cyan
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    Write-Host "  $Message" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor White
}

function Write-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Message
    )
    $percent = [math]::Round($Current * 100 / $Total)
    Write-Host "`r[$percent%] $Message" -ForegroundColor Cyan -NoNewline
}

function Write-Divider {
    Write-Host "----------------------------------------"
}
