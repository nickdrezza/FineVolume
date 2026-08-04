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
ICONSET_DIR="${PACKAGE_DIR}/AppIcon.iconset"

cleanup() {
    rm -rf "${PACKAGE_DIR}"
}
trap cleanup EXIT

cd "${PROJECT_DIR}"

ARM64_SCRATCH_DIR="${PACKAGE_DIR}/build-arm64"
X86_64_SCRATCH_DIR="${PACKAGE_DIR}/build-x86_64"

swift build \
    -c release \
    --product FineVolume \
    --arch arm64 \
    --scratch-path "${ARM64_SCRATCH_DIR}"
swift build \
    -c release \
    --product FineVolume \
    --arch x86_64 \
    --scratch-path "${X86_64_SCRATCH_DIR}"

ARM64_BINARY="$(find "${ARM64_SCRATCH_DIR}" -type f -name FineVolume -not -path '*/dSYM/*' -print -quit)"
X86_64_BINARY="$(find "${X86_64_SCRATCH_DIR}" -type f -name FineVolume -not -path '*/dSYM/*' -print -quit)"
test -n "${ARM64_BINARY}"
test -n "${X86_64_BINARY}"

mkdir -p "${CONTENTS_DIR}/MacOS"
lipo -create \
    "${ARM64_BINARY}" \
    "${X86_64_BINARY}" \
    -output "${CONTENTS_DIR}/MacOS/FineVolume"
cp "${PROJECT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

mkdir -p "${CONTENTS_DIR}/Resources" "${ICONSET_DIR}"
typeset -a ICON_SIZES=(
    "16 icon_16x16.png"
    "32 icon_16x16@2x.png"
    "32 icon_32x32.png"
    "64 icon_32x32@2x.png"
    "128 icon_128x128.png"
    "256 icon_128x128@2x.png"
    "256 icon_256x256.png"
    "512 icon_256x256@2x.png"
    "512 icon_512x512.png"
    "1024 icon_512x512@2x.png"
)
for icon_size in "${ICON_SIZES[@]}"; do
    size="${icon_size%% *}"
    filename="${icon_size#* }"
    sips -z "${size}" "${size}" \
        "${PROJECT_DIR}/Resources/AppIcon.png" \
        --out "${ICONSET_DIR}/${filename}" >/dev/null
done
iconutil -c icns "${ICONSET_DIR}" -o "${CONTENTS_DIR}/Resources/AppIcon.icns"

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
