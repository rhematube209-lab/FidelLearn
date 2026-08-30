#!/bin/bash
set -e
set -x

echo "=== STEP 1: Git Safe Directory ==="
git config --global --add safe.directory "*" || true

echo "=== STEP 2: Clone Flutter Stable SDK ==="
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

echo "=== STEP 3: Configure Flutter Web ==="
flutter config --no-analytics
flutter config --enable-web

echo "=== STEP 4: Install Dependencies ==="
flutter pub get

echo "=== STEP 5: Compile Web Release ==="
flutter build web --release --no-tree-shake-icons

echo "=== STEP 6: Verify Output in build/web ==="
ls -la build/web

echo "=== BUILD COMPLETE ==="
