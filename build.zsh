#!/bin/zsh

set -eu

readonly SOURCE_ROOT="${0:A:h}"
readonly OUTPUT_DIR="${LILITH_SWING_OUTPUT_DIR:-${SOURCE_ROOT}/build}"
readonly APP_ROOT="${OUTPUT_DIR}/莉莉丝秋千.app"
readonly CONTENTS_DIR="${APP_ROOT}/Contents"
readonly MACOS_DIR="${CONTENTS_DIR}/MacOS"
readonly RESOURCES_DIR="${CONTENTS_DIR}/Resources"
readonly MODULE_CACHE="${SOURCE_ROOT}/module-cache"

/bin/rm -rf "${APP_ROOT}"
/bin/mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}" "${MODULE_CACHE}"

/usr/bin/clang \
    -fobjc-arc \
    -O2 \
    -Wall \
    -Wextra \
    -framework AppKit \
    -I"${SOURCE_ROOT}" \
    -fmodules-cache-path="${MODULE_CACHE}" \
    "${SOURCE_ROOT}/main.m" \
    "${SOURCE_ROOT}/SkinEngine/SwingSkin.m" \
    "${SOURCE_ROOT}/SkinEngine/SwingSkinRegistry.m" \
    "${SOURCE_ROOT}/Skins/Mucha/MuchaSkin.m" \
    -o "${MACOS_DIR}/LilithSwing"

/usr/bin/install -m 644 "${SOURCE_ROOT}/Info.plist" "${CONTENTS_DIR}/Info.plist"
/bin/mkdir -p "${RESOURCES_DIR}/Skins/Mucha"
/usr/bin/install -m 644 "${SOURCE_ROOT}/Skins/Mucha/skin.json" "${RESOURCES_DIR}/Skins/Mucha/skin.json"
/usr/bin/ditto "${SOURCE_ROOT}/Skins/Mucha/Assets" "${RESOURCES_DIR}/Skins/Mucha/Assets"
/usr/bin/xattr -cr "${APP_ROOT}"
/usr/bin/xattr -d com.apple.FinderInfo "${APP_ROOT}" 2>/dev/null || true
/usr/bin/xattr -d 'com.apple.fileprovider.fpfs#P' "${APP_ROOT}" 2>/dev/null || true
/usr/bin/codesign --force --sign - "${APP_ROOT}"
/usr/bin/xattr -cr "${APP_ROOT}"
/usr/bin/xattr -d com.apple.FinderInfo "${APP_ROOT}" 2>/dev/null || true
/usr/bin/xattr -d 'com.apple.fileprovider.fpfs#P' "${APP_ROOT}" 2>/dev/null || true
/usr/bin/printf 'Built %s\n' "${APP_ROOT}"
