#!/bin/bash
set -e

echo "=== 1. Setting up Git safe directory ==="
git config --global --add safe.directory "*" || true

echo "=== 2. Downloading Official Flutter Linux SDK ==="
if [ ! -d "$HOME/flutter" ]; then
  curl -s -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$HOME"
  rm -f /tmp/flutter.tar.xz
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== 3. Checking Flutter Installation ==="
flutter --version

echo "=== 4. Enabling Web & Getting Packages ==="
flutter config --no-analytics
flutter config --enable-web
flutter pub get

echo "=== 5. Building Flutter Web Release ==="
flutter build web --release --no-tree-shake-icons

echo "=== 6. Build Completed Successfully in build/web ==="
