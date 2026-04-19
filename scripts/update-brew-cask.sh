#!/usr/bin/env bash
# Render Casks/idler.rb for the homebrew-tap repo and push it.
# Expects Idler-${VERSION}.dmg + checksums.txt in $ARTIFACTS_DIR.
#
# Required env vars:
#   VERSION             e.g. 0.1.0 (no leading "v")
#   ARTIFACTS_DIR       directory containing Idler-${VERSION}.dmg and checksums.txt
#   TAP_REPO            e.g. dmtrkzntsv/homebrew-tap
#   TAP_GITHUB_TOKEN    PAT with contents:write on TAP_REPO
#   GITHUB_REPOSITORY   e.g. dmtrkzntsv/idler2 (used to build download URLs)

set -euo pipefail

: "${VERSION:?required}"
: "${ARTIFACTS_DIR:?required}"
: "${TAP_REPO:?required}"
: "${TAP_GITHUB_TOKEN:?required}"
: "${GITHUB_REPOSITORY:?required}"

cd "$ARTIFACTS_DIR"

DMG="Idler-${VERSION}.dmg"
if [[ ! -f "$DMG" ]]; then
    echo "missing dmg: $DMG" >&2
    exit 1
fi

SHA_DMG=$(awk -v f="$DMG" '$2 == f { print $1 }' checksums.txt)
if [[ -z "$SHA_DMG" ]]; then
    echo "no checksum for $DMG in checksums.txt" >&2
    exit 1
fi

BASE_URL="https://github.com/${GITHUB_REPOSITORY}/releases/download/v${VERSION}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git clone "https://x-access-token:${TAP_GITHUB_TOKEN}@github.com/${TAP_REPO}.git" "$WORK/tap"
mkdir -p "$WORK/tap/Casks"

cat > "$WORK/tap/Casks/idler.rb" <<EOF
cask "idler" do
  version "${VERSION}"
  sha256 "${SHA_DMG}"

  url "${BASE_URL}/Idler-#{version}.dmg"
  name "Idler"
  desc "Menu bar app that keeps your Mac awake"
  homepage "https://github.com/${GITHUB_REPOSITORY}"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "Idler.app"

  zap trash: [
    "~/Library/Preferences/com.malikov.idler.plist",
    "~/Library/Saved Application State/com.malikov.idler.savedState",
  ]
end
EOF

cd "$WORK/tap"
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add Casks/idler.rb
if git diff --cached --quiet; then
    echo "update-brew-cask: no changes to cask, skipping push"
    exit 0
fi
git commit -m "idler ${VERSION}"
git push origin HEAD

echo "update-brew-cask: pushed Casks/idler.rb to ${TAP_REPO}"
