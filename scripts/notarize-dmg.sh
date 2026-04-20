#!/usr/bin/env bash
# Sign, notarize, and staple a macOS .dmg.
# Usage: notarize-dmg.sh <path-to-.dmg>
#
# Required env vars:
#   MACOS_DEVELOPER_ID_APPLICATION  e.g. "Developer ID Application: Name (TEAMID)"
#   NOTARY_APPLE_ID                 Apple ID email
#   NOTARY_TEAM_ID                  10-char Team ID
#   NOTARY_PASSWORD                 app-specific password from appleid.apple.com

set -euo pipefail

DMG="${1:?usage: $0 <path-to-.dmg>}"

if [[ ! -f "$DMG" ]]; then
    echo "notarize-dmg: dmg not found: $DMG" >&2
    exit 1
fi

: "${MACOS_DEVELOPER_ID_APPLICATION:?required}"
: "${NOTARY_APPLE_ID:?required}"
: "${NOTARY_TEAM_ID:?required}"
: "${NOTARY_PASSWORD:?required}"

echo "notarize-dmg: codesign $DMG"
codesign --force --timestamp --sign "$MACOS_DEVELOPER_ID_APPLICATION" "$DMG"

echo "notarize-dmg: submitting to Apple notary"
xcrun notarytool submit "$DMG" \
    --apple-id "$NOTARY_APPLE_ID" \
    --team-id "$NOTARY_TEAM_ID" \
    --password "$NOTARY_PASSWORD" \
    --wait

echo "notarize-dmg: stapling"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo "notarize-dmg: done"
