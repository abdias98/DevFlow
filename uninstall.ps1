<#
.SYNOPSIS
  Uninstalls the DevFlow multi-agent framework on Windows.

.DESCRIPTION
  PowerShell wrapper that downloads uninstall.sh and executes it via Git Bash.
  All uninstallation logic lives in uninstall.sh — this script is a thin launcher.

.EXAMPLE
  irm https://raw.githubusercontent.com/abdias98/DevFlow/main/uninstall.ps1 | iex
#>

$ErrorActionPreference = "Stop"

$devflowRepo  = "https://raw.githubusercontent.com/abdias98/DevFlow/main"
$uninstallUrl = "$devflowRepo/uninstall.sh"
$tempFile     = Join-Path $env:TEMP "devflow_uninstall.sh"

Write-Host ""
Write-Host "  DevFlow Framework — Windows Uninstaller" -ForegroundColor Cyan
Write-Host ""

# ── Download uninstall.sh ────────────────────────────────────────────────────
Write-Host "  Downloading uninstaller..." -ForegroundColor DarkGray
try {
    Invoke-WebRequest -Uri $uninstallUrl -OutFile $tempFile -UseBasicParsing
} catch {
    Write-Host "  [ERROR] Failed to download uninstall.sh" -ForegroundColor Red
    Write-Host "  Check your internet connection and try again." -ForegroundColor Yellow
    exit 1
}

# ── Locate Git Bash ──────────────────────────────────────────────────────────
$bashPath = $null

# 1) Check PATH first
$bashCmd = Get-Command bash.exe -ErrorAction SilentlyContinue
if ($bashCmd) {
    $bashPath = $bashCmd.Source
}

# 2) Fallback: common Git for Windows install locations
if (-not $bashPath) {
    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "$env:ProgramFiles\Git\usr\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\usr\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $bashPath = $c
            break
        }
    }
}

if (-not $bashPath) {
    Write-Host "  [ERROR] Git Bash not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "  DevFlow requires Git for Windows." -ForegroundColor Yellow
    Write-Host "  Download it from: https://gitforwindows.org/" -ForegroundColor Yellow
    Write-Host ""
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "  Found Git Bash: $bashPath" -ForegroundColor DarkGray
Write-Host ""

# ── Execute uninstall.sh via Git Bash ────────────────────────────────────────
try {
    & $bashPath --login -i $tempFile
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}
