$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$scriptDir"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  HealthSync AI - Backend Server Runner (PowerShell)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$python = "python"
if (Test-Path "$scriptDir\.venv\Scripts\python.exe") {
    $python = "$scriptDir\.venv\Scripts\python.exe"
}

Write-Host "==> Applying database migrations..." -ForegroundColor Cyan
& $python backend\manage.py migrate

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
}

$localIp = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*'
    } | Select-Object -First 1 -ExpandProperty IPAddress

Write-Host "==> Starting backend server on http://0.0.0.0:8000..." -ForegroundColor Green
Write-Host "    - Desktop / USB ADB: http://127.0.0.1:8000"
if ($localIp) {
    Write-Host "    - Local Network:     http://$localIp`:8000"
}
Write-Host "    - API Docs:          http://127.0.0.1:8000/api/docs/"
& $python backend\manage.py runserver 0.0.0.0:8000
