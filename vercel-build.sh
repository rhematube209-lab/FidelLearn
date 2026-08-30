#!/bin/bash
set -e

echo "=========================================="
echo "Installing Official Flutter Linux SDK..."
echo "=========================================="

git config --global --add safe.directory "*" || true

if [ ! -d "$HOME/flutter" ]; then
  echo "Downloading pre-compiled Flutter Linux release (fast download)..."
  curl -C - -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
  tar xf flutter_linux_3.24.5-stable.tar.xz -C "$HOME"
  rm -f flutter_linux_3.24.5-stable.tar.xz
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "Checking Flutter SDK..."
flutter --version

echo "Fetching dependencies & building web release..."
flutter config --no-analytics
flutter config --enable-web
flutter pub get
flutter build web --release --no-tree-shake-icons

echo "=========================================="
echo "FidelLearn Web Build Complete -> build/web"
echo "=========================================="
