#!/bin/zsh

set -u

readonly USER_HOME_DIR="${HOME}"
readonly LABEL="com.fancyecho.lilith-swing"
readonly USER_ID_VALUE="$(/usr/bin/id -u)"
readonly AGENT_PATH="${USER_HOME_DIR}/Library/LaunchAgents/${LABEL}.plist"
readonly APP_PATH="${USER_HOME_DIR}/Applications/莉莉丝秋千.app"
readonly APP_EXEC="${APP_PATH}/Contents/MacOS/LilithSwing"
readonly TRASH_SUFFIX="$(/bin/date '+%Y%m%d-%H%M%S')"

/bin/launchctl bootout "gui/${USER_ID_VALUE}" "${AGENT_PATH}" 2>/dev/null || true

typeset app_pids
app_pids="$(/usr/bin/pgrep -f "^${APP_EXEC}$" 2>/dev/null || true)"
if [[ -n "${app_pids}" ]]; then
    /bin/kill -TERM ${=app_pids} 2>/dev/null || true
fi

if [[ -e "${AGENT_PATH}" ]]; then
    /bin/mv "${AGENT_PATH}" "${USER_HOME_DIR}/.Trash/${LABEL}-${TRASH_SUFFIX}.plist"
fi

if [[ -d "${APP_PATH}" ]]; then
    /bin/mv "${APP_PATH}" "${USER_HOME_DIR}/.Trash/莉莉丝秋千-${TRASH_SUFFIX}.app"
fi

/usr/bin/printf '莉莉丝秋千已卸载；文件已移到废纸篓。\n'
