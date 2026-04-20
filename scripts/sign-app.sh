#!/usr/bin/env bash
# Sign a macOS .app bundle with Developer ID + hardened runtime.
# Usage: sign-app.sh <path-to-.app>
#
# Required env vars:
#   MACOS_DEVELOPER_ID_APPLICATION  e.g. "Developer ID Application: Name (TEAMID)"

set -euo pipefail

APP="${1:?usage: $0 <path-to-.app>}"

if [[ ! -d "$APP" ]]; then
    echo "sign-app: app not found: $APP" >&2
    exit 1
fi

: "${MACOS_DEVELOPER_ID_APPLICATION:?required}"

ENTITLEMENTS="$(cd "$(dirname "$0")" && pwd)/entitlements.plist"

echo "sign-app: signing embedded bundles in $APP"
while IFS= read -r -d '' bundle; do
    codesign --force --options runtime --timestamp \
        --sign "$MACOS_DEVELOPER_ID_APPLICATION" "$bundle"
done < <(find "$APP/Contents" -type d \( -name '*.bundle' -o -name '*.framework' \) -print0)

echo "sign-app: signing $APP"
codesign --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$MACOS_DEVELOPER_ID_APPLICATION" \
    "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
echo "sign-app: done"
