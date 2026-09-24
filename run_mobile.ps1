$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$scriptDir\frontend"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HealthSync AI - Mobile App Runner (Windows PowerShell)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$adb = Get-Command adb -ErrorAction SilentlyContinue
$adbPath = $null
if ($adb) {
    $adbPath = "adb"
} elseif (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe") {
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}

if ($adbPath) {
    Write-Host "==> Configuring ADB reverse port 8000..." -ForegroundColor Cyan
    & $adbPath reverse tcp:8000 tcp:8000 2>$null
    Write-Host "==> ADB reverse active: phone can reach http://127.0.0.1:8000" -ForegroundColor Green
} else {
    Write-Host "[!] ADB not detected in PATH or LOCALAPPDATA SDK." -ForegroundColor Yellow
}

Write-Host "==> Launching Flutter on connected mobile device..." -ForegroundColor Cyan
flutter run
