#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
APP_DIR="${DIST_DIR}/FineVolume.app"
ZIP_PATH="${DIST_DIR}/FineVolume.zip"
PACKAGE_DIR="$(mktemp -d /tmp/FineVolume-package.XXXXXX)"
PACKAGE_APP_DIR="${PACKAGE_DIR}/FineVolume.app"
CONTENTS_DIR="${PACKAGE_APP_DIR}/Contents"

cleanup() {
    rm -rf "${PACKAGE_DIR}"
}
trap cleanup EXIT

cd "${PROJECT_DIR}"
swift build -c release --product FineVolume --arch arm64 --arch x86_64

mkdir -p "${CONTENTS_DIR}/MacOS"
cp "${PROJECT_DIR}/.build/release/FineVolume" "${CONTENTS_DIR}/MacOS/FineVolume"
cp "${PROJECT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

xattr -cr "${PACKAGE_APP_DIR}"
codesign --force --deep --sign - "${PACKAGE_APP_DIR}"
codesign --verify --deep --strict "${PACKAGE_APP_DIR}"

ditto -c -k --keepParent --norsrc --noextattr --noqtn --noacl \
    "${PACKAGE_APP_DIR}" "${PACKAGE_DIR}/FineVolume.zip"

mkdir -p "${DIST_DIR}"
if [[ -d "${APP_DIR}" ]]; then
    rm -rf "${APP_DIR}"
fi
rm -f "${ZIP_PATH}"
ditto --norsrc --noextattr --noqtn --noacl "${PACKAGE_APP_DIR}" "${APP_DIR}"
cp "${PACKAGE_DIR}/FineVolume.zip" "${ZIP_PATH}"
xattr -cr "${APP_DIR}"

echo "Created ${APP_DIR}"
echo "Created ${ZIP_PATH}"
