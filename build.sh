#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Enabling Flutter Web ==="
flutter config --enable-web

echo "=== Getting Dependencies ==="
flutter pub get

echo "=== Building for Web (Release) ==="
flutter build web --release

echo "=== Build Complete ==="
