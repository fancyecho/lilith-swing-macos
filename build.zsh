#!/bin/zsh

set -eu

readonly SOURCE_ROOT="${0:A:h}"
readonly OUTPUT_DIR="${LILITH_SWING_OUTPUT_DIR:-${SOURCE_ROOT}/build}"
readonly APP_ROOT="${OUTPUT_DIR}/莉莉丝秋千.app"
readonly CONTENTS_DIR="${APP_ROOT}/Contents"
readonly MACOS_DIR="${CONTENTS_DIR}/MacOS"
readonly MODULE_CACHE="${SOURCE_ROOT}/module-cache"

/bin/mkdir -p "${MACOS_DIR}" "${MODULE_CACHE}"

/usr/bin/clang \
    -fobjc-arc \
    -O2 \
    -Wall \
    -Wextra \
    -framework AppKit \
    -fmodules-cache-path="${MODULE_CACHE}" \
    "${SOURCE_ROOT}/main.m" \
    -o "${MACOS_DIR}/LilithSwing"

/usr/bin/install -m 644 "${SOURCE_ROOT}/Info.plist" "${CONTENTS_DIR}/Info.plist"
/usr/bin/xattr -d com.apple.FinderInfo "${APP_ROOT}" 2>/dev/null || true
/usr/bin/xattr -d 'com.apple.fileprovider.fpfs#P' "${APP_ROOT}" 2>/dev/null || true
/usr/bin/xattr -cr "${APP_ROOT}"
/usr/bin/codesign --force --sign - "${APP_ROOT}"
/usr/bin/xattr -cr "${APP_ROOT}"
/usr/bin/printf 'Built %s\n' "${APP_ROOT}"
