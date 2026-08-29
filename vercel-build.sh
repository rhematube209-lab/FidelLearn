#!/bin/bash
set -e

echo "=========================================="
echo "Installing Flutter SDK on Vercel..."
echo "=========================================="

if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

echo "Checking Flutter installation..."
flutter --version

echo "Building FidelLearn Web Release..."
flutter config --enable-web
flutter pub get
flutter build web --release --no-tree-shake-icons

echo "=========================================="
echo "FidelLearn Web Build Complete -> build/web"
echo "=========================================="
