@echo off
setlocal
cd /d "%~dp0frontend"

echo ========================================================
echo   HealthSync AI - Mobile App Runner (Windows)
echo ========================================================

echo ==> Configuring ADB reverse port 8000...
where adb >nul 2>nul
if %ERRORLEVEL% equ 0 (
    adb reverse tcp:8000 tcp:8000
    echo ==> ADB reverse active: phone can reach http://127.0.0.1:8000
) else if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
    echo ==> ADB reverse active: phone can reach http://127.0.0.1:8000
) else (
    echo [!] ADB not found in PATH or standard Android SDK folder.
    echo     If your phone is on the same Wi-Fi, you can connect via your PC's IP.
)

echo ==> Starting Flutter application...
flutter run
