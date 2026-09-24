@echo off
setlocal
cd /d "%~dp0"

echo ========================================================
echo   HealthSync AI - Backend Server Runner (Windows)
echo ========================================================

if exist ".venv\Scripts\python.exe" (
    set PYTHON=.venv\Scripts\python.exe
) else (
    set PYTHON=python
)

echo ==> Applying migrations...
%PYTHON% backend\manage.py migrate

echo ==> Configuring ADB reverse port 8000...
where adb >nul 2>nul
if %ERRORLEVEL% equ 0 (
    adb reverse tcp:8000 tcp:8000 2>nul
    echo ==> ADB reverse active: phone can reach http://127.0.0.1:8000
) else if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000 2>nul
    echo ==> ADB reverse active: phone can reach http://127.0.0.1:8000
)

echo ==> Starting Django backend on http://0.0.0.0:8000...
echo     - Desktop / USB ADB: http://127.0.0.1:8000
echo     - API Docs:          http://127.0.0.1:8000/api/docs/
%PYTHON% backend\manage.py runserver 0.0.0.0:8000
