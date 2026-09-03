#!/bin/zsh

set -eu

readonly SOURCE_ROOT="${0:A:h}"
readonly USER_HOME_DIR="${HOME}"
readonly APP_PATH="${USER_HOME_DIR}/Applications/莉莉丝秋千.app"
readonly LABEL="com.fancyecho.lilith-swing"
readonly AGENT_PATH="${USER_HOME_DIR}/Library/LaunchAgents/${LABEL}.plist"
readonly USER_ID_VALUE="$(/usr/bin/id -u)"
readonly TEMPLATE_PATH="${SOURCE_ROOT}/com.fancyecho.lilith-swing.plist"
readonly STAGING_DIR="$(/usr/bin/mktemp -d /private/tmp/lilith-swing-install.XXXXXX)"
readonly GENERATED_PLIST="${STAGING_DIR}/${LABEL}.plist"
readonly BACKUP_ROOT="${USER_HOME_DIR}/Library/Application Support/LilithSwing/Backups"

cleanup() {
    /bin/rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

LILITH_SWING_OUTPUT_DIR="${STAGING_DIR}" /bin/zsh "${SOURCE_ROOT}/build.zsh"

/bin/mkdir -p "${USER_HOME_DIR}/Applications" \
              "${USER_HOME_DIR}/Library/LaunchAgents" \
              "${USER_HOME_DIR}/Library/Logs/LilithSwing" \
              "${BACKUP_ROOT}"

/usr/bin/codesign --verify --deep --strict "${STAGING_DIR}/莉莉丝秋千.app"

/bin/launchctl bootout "gui/${USER_ID_VALUE}" "${AGENT_PATH}" 2>/dev/null || true
# Replace the bundle instead of merging it: obsolete resources from an older
# version would otherwise remain and invalidate the new resource signature.
PREVIOUS_APP_DIR=""
if [[ -e "${APP_PATH}" ]]; then
    PREVIOUS_APP_DIR="$(/usr/bin/mktemp -d "${BACKUP_ROOT}/install.XXXXXX")"
    /bin/mv "${APP_PATH}" "${PREVIOUS_APP_DIR}/莉莉丝秋千.app"
fi
if ! /bin/mv "${STAGING_DIR}/莉莉丝秋千.app" "${APP_PATH}"; then
    if [[ -n "${PREVIOUS_APP_DIR}" ]]; then
        /bin/mv "${PREVIOUS_APP_DIR}/莉莉丝秋千.app" "${APP_PATH}"
        /bin/launchctl bootstrap "gui/${USER_ID_VALUE}" "${AGENT_PATH}" 2>/dev/null || true
    fi
    exit 1
fi
/usr/bin/codesign --verify --deep --strict "${APP_PATH}"
/usr/bin/sed "s|__USER_HOME__|${USER_HOME_DIR}|g" "${TEMPLATE_PATH}" > "${GENERATED_PLIST}"
/usr/bin/install -m 644 "${GENERATED_PLIST}" "${AGENT_PATH}"
/bin/launchctl bootstrap "gui/${USER_ID_VALUE}" "${AGENT_PATH}"
/bin/launchctl kickstart -k "gui/${USER_ID_VALUE}/${LABEL}"

/usr/bin/printf '莉莉丝秋千已安装并启动。\n'
if [[ -n "${PREVIOUS_APP_DIR}" ]]; then
    /usr/bin/printf '上一版本保留在：%s\n' "${PREVIOUS_APP_DIR}"
fi
