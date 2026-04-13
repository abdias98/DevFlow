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

# ── Locate uninstall.sh (local repo first, then download) ───────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localSh   = Join-Path $scriptDir "uninstall.sh"

if ($scriptDir -and (Test-Path $localSh)) {
    Write-Host "  Using local uninstall.sh from repo..." -ForegroundColor DarkGray
    Copy-Item $localSh $tempFile -Force
} else {
    Write-Host "  Downloading uninstaller..." -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri $uninstallUrl -OutFile $tempFile -UseBasicParsing
    } catch {
        Write-Host "  [ERROR] Failed to download uninstall.sh" -ForegroundColor Red
        Write-Host "  Check your internet connection and try again." -ForegroundColor Yellow
        exit 1
    }
}

# ── Locate Git Bash ──────────────────────────────────────────────────────────
# IMPORTANT: WindowsApps\bash.exe is WSL, NOT Git Bash.
# WSL bash cannot understand Windows paths (C:/...) — it needs /mnt/c/...
# We must find Git for Windows' bash.exe specifically.
$bashPath = $null

# 1) Check PATH — but EXCLUDE WSL bash (WindowsApps) and System32
$bashCmd = Get-Command bash.exe -ErrorAction SilentlyContinue
if ($bashCmd) {
    $candidate = $bashCmd.Source
    if ($candidate -notmatch 'WindowsApps|System32') {
        $bashPath = $candidate
    }
}

# 2) Search common Git for Windows install locations
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
    Write-Host "  DevFlow requires Git for Windows (not WSL)." -ForegroundColor Yellow
    Write-Host "  Download it from: https://gitforwindows.org/" -ForegroundColor Yellow
    Write-Host ""
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "  Found Git Bash: $bashPath" -ForegroundColor DarkGray
Write-Host ""

# ── Execute uninstall.sh via Git Bash ────────────────────────────────────────
# Convert Windows backslash path to forward slashes so bash can find the file.
# Git Bash translates C:/Users/... to /c/Users/... internally.
$tempFilePosix = $tempFile -replace '\\', '/'
try {
    & $bashPath --noprofile --norc "$tempFilePosix"
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}
