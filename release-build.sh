#!/bin/bash
set -e

CONFIG="config.dev.json"
KEYSTORE="$HOME/local_release.keystore"
KEY_ALIAS="release"
KEYSTORE_PASSWORD="devrelease"
KEY_PASSWORD="devrelease"

if [ ! -f "$CONFIG" ]; then
  echo "Error: $CONFIG not found."
  echo 'Create it with: {"OPENROUTER_API_KEY":"..."}'
  exit 1
fi

if [ ! -f "$KEYSTORE" ]; then
  echo "==> Creating local release keystore at $KEYSTORE"
  keytool -genkey -v -keystore "$KEYSTORE" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Dev, OU=Dev, O=AgenticTodo, L=City, ST=State, C=US"
  echo "==> Keystore created. Add this SHA-1 to Firebase Console:"
  keytool -list -v -keystore "$KEYSTORE" -alias "$KEY_ALIAS" -storepass "$KEYSTORE_PASSWORD" 2>/dev/null | grep -i "SHA1:"
  echo ""
fi

export KEYSTORE_PATH="$KEYSTORE"
export STORE_PASSWORD="$KEYSTORE_PASSWORD"
export KEY_ALIAS="$KEY_ALIAS"
export KEY_PASSWORD="$KEY_PASSWORD"

echo "==> flutter analyze"
flutter analyze

echo ""
echo "==> flutter test"
flutter test

echo ""
echo "==> flutter build apk --release --split-per-abi"
flutter build apk --release --split-per-abi --dart-define-from-file="$CONFIG"

echo ""
echo "=========================================="
echo "  BUILD COMPLETE"
echo "=========================================="
echo ""
echo "Install on device:"
echo "  adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo ""
echo "If Google sign-in fails, add this SHA-1 to Firebase Console:"
keytool -list -v -keystore "$KEYSTORE" -alias "$KEY_ALIAS" -storepass "$KEYSTORE_PASSWORD" 2>/dev/null | grep -i "SHA1:"
echo ""
echo "Firebase Console → Project Settings → Add Fingerprint"
