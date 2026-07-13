#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

API_BASE_URL="${API_BASE_URL:-https://apis.beautytrust.ru}"
EXPORT_OPTIONS="$ROOT_DIR/ios/ExportOptions.plist"

echo "Building Beauty Trust IPA for TestFlight"
echo "  API_BASE_URL=$API_BASE_URL"
echo "  Bundle ID: ru.beautytrust.app"
echo

flutter pub get
flutter build ipa --release \
	--dart-define=API_BASE_URL="$API_BASE_URL" \
	--export-options-plist="$EXPORT_OPTIONS"

IPA_PATH="$(find "$ROOT_DIR/build/ios/ipa" -name '*.ipa' -type f | head -n 1)"
if [[ -z "$IPA_PATH" ]]; then
	echo "IPA not found in build/ios/ipa" >&2
	exit 1
fi

echo
echo "IPA ready: $IPA_PATH"
echo
echo "Next steps:"
echo "  1. App Store Connect → создать приложение с Bundle ID ru.beautytrust.app"
echo "  2. Открыть IPA в Transporter и загрузить"
echo "     или: open -a Transporter \"$IPA_PATH\""
echo "  3. TestFlight → дождаться обработки → Internal/External Testing"
echo
echo "Перед следующей загрузкой увеличьте build в pubspec.yaml (например 1.0.0+2 → 1.0.0+3)."
