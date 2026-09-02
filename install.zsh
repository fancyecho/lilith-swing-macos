#!/bin/zsh

set -eu

readonly SOURCE_ROOT="${0:A:h}"
readonly BUILD_DIR="${SOURCE_ROOT}/build"
readonly USER_HOME_DIR="${HOME}"
readonly APP_PATH="${USER_HOME_DIR}/Applications/莉莉丝秋千.app"
readonly LABEL="com.fancyecho.lilith-swing"
readonly AGENT_PATH="${USER_HOME_DIR}/Library/LaunchAgents/${LABEL}.plist"
readonly USER_ID_VALUE="$(/usr/bin/id -u)"
readonly TEMPLATE_PATH="${SOURCE_ROOT}/com.fancyecho.lilith-swing.plist"
readonly GENERATED_PLIST="${BUILD_DIR}/${LABEL}.plist"

LILITH_SWING_OUTPUT_DIR="${BUILD_DIR}" /bin/zsh "${SOURCE_ROOT}/build.zsh"

/bin/mkdir -p "${USER_HOME_DIR}/Applications" \
              "${USER_HOME_DIR}/Library/LaunchAgents" \
              "${USER_HOME_DIR}/Library/Logs/LilithSwing"

/bin/launchctl bootout "gui/${USER_ID_VALUE}" "${AGENT_PATH}" 2>/dev/null || true
/usr/bin/ditto "${BUILD_DIR}/莉莉丝秋千.app" "${APP_PATH}"
/usr/bin/sed "s|__USER_HOME__|${USER_HOME_DIR}|g" "${TEMPLATE_PATH}" > "${GENERATED_PLIST}"
/usr/bin/install -m 644 "${GENERATED_PLIST}" "${AGENT_PATH}"
/bin/launchctl bootstrap "gui/${USER_ID_VALUE}" "${AGENT_PATH}"
/bin/launchctl kickstart -k "gui/${USER_ID_VALUE}/${LABEL}"

/usr/bin/printf '莉莉丝秋千已安装并启动。\n'
