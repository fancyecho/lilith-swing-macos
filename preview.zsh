#!/bin/zsh

set -eu

readonly SOURCE_ROOT="${0:A:h}"
readonly BUILD_DIR="${SOURCE_ROOT}/build"
readonly PREVIEW_TOOL="${BUILD_DIR}/render-skin-preview"
readonly PREVIEW_PATH="${BUILD_DIR}/mucha-preview.png"
readonly MODULE_CACHE="${SOURCE_ROOT}/module-cache"

/bin/mkdir -p "${BUILD_DIR}" "${MODULE_CACHE}"

/usr/bin/clang \
    -fobjc-arc \
    -O2 \
    -Wall \
    -Wextra \
    -framework AppKit \
    -I"${SOURCE_ROOT}" \
    -fmodules-cache-path="${MODULE_CACHE}" \
    "${SOURCE_ROOT}/Tools/render_skin_preview.m" \
    "${SOURCE_ROOT}/SkinEngine/SwingSkin.m" \
    "${SOURCE_ROOT}/Skins/Mucha/MuchaSkin.m" \
    -o "${PREVIEW_TOOL}"

"${PREVIEW_TOOL}" "${SOURCE_ROOT}/Skins/Mucha" "${PREVIEW_PATH}"
