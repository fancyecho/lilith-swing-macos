#!/bin/zsh
set -eu

readonly SOURCE_ROOT="${0:A:h}"
readonly DEPLOYMENT_TARGET="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "${SOURCE_ROOT}/Info.plist")"
readonly TEST_DIR="$(/usr/bin/mktemp -d /private/tmp/lilith-swing-tests.XXXXXX)"
cleanup() { /bin/rm -rf "${TEST_DIR}"; }
trap cleanup EXIT

/usr/bin/clang -fobjc-arc -O2 -Wall -Wextra -framework AppKit \
    -mmacosx-version-min="${DEPLOYMENT_TARGET}" \
    -I"${SOURCE_ROOT}" -fmodules-cache-path="${TEST_DIR}/module-cache" \
    "${SOURCE_ROOT}/Tests/window_policy_tests.m" \
    "${SOURCE_ROOT}/WindowEngine/SwingWindowPolicy.m" \
    "${SOURCE_ROOT}/WindowEngine/SwingSupportGeometry.m" \
    "${SOURCE_ROOT}/SkinEngine/SwingSkin.m" \
    "${SOURCE_ROOT}/SkinEngine/SwingSkinRegistry.m" \
    "${SOURCE_ROOT}/Skins/Mucha/MuchaSkin.m" \
    -o "${TEST_DIR}/window-policy-tests"
LILITH_SWING_TEST_RESOURCE_ROOT="${SOURCE_ROOT}/Skins/Mucha" "${TEST_DIR}/window-policy-tests" "$@"
