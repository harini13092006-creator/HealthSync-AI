#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -d ".venv" ]; then
    PYTHON="$SCRIPT_DIR/.venv/bin/python"
else
    PYTHON="python3"
fi

echo "==> HealthSync AI Backend"
echo "==> Running migrations..."
"$PYTHON" backend/manage.py migrate

echo "==> Setting up ADB reverse port forwarding (if device connected)..."
ADB_PATH="$HOME/Android/Sdk/platform-tools/adb"
if [ -x "$ADB_PATH" ]; then
    "$ADB_PATH" reverse tcp:8000 tcp:8000 2>/dev/null && echo "==> ADB reverse active: mobile phone can access http://127.0.0.1:8000" || true
fi

echo "==> Starting backend server on http://0.0.0.0:8000..."
echo "    - Desktop / USB ADB: http://127.0.0.1:8000"
echo "    - Local Network:     http://10.24.207.60:8000"
echo "    - API Docs:          http://127.0.0.1:8000/api/docs/"
exec "$PYTHON" backend/manage.py runserver 0.0.0.0:8000
