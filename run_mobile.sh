#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

ADB_PATH="$HOME/Android/Sdk/platform-tools/adb"
if [ -x "$ADB_PATH" ]; then
    echo "==> Configuring ADB reverse port 8000..."
    "$ADB_PATH" reverse tcp:8000 tcp:8000 2>/dev/null || true
fi

echo "==> Finding connected device..."
DEVICE_ID=$("$HOME/flutter/bin/flutter" devices --machine 2>/dev/null | grep -o '"id":"[^"]*"' | grep -v 'linux' | head -n 1 | cut -d'"' -f4)

if [ -n "$DEVICE_ID" ]; then
    echo "==> Running Flutter on device: $DEVICE_ID"
    exec "$HOME/flutter/bin/flutter" run -d "$DEVICE_ID"
else
    echo "==> Running Flutter on default device..."
    exec "$HOME/flutter/bin/flutter" run
fi
