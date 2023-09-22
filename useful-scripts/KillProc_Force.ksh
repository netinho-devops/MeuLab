#!/usr/bin/env ksh
TARGET_USER=$1
TARGET_PROC="$2"

if [ $# -ne 2 ]; then
	echo "Usage: $(basename $)) user_name process_name"
	exit 1
fi

pkill -U ${TARGET_USER} -f "${TARGET_PROC}" 2> /dev/null
sleep 5
pgrep -U ${TARGET_USER} -f "${TARGET_PROC}" | xargs kill -9 2> /dev/null

exit 0
