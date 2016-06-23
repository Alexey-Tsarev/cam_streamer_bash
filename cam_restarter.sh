#!/bin/bash

OLD_PWD=`pwd`
trap "cd ${OLD_PWD}" EXIT
cd `dirname $0`

. shared_conf.sh
. shared_func.sh

LOG_PREFIX="restart "

log "Stop processes..."
for i in "${!CAM_NAME[@]}"
do
    if [ -f "${CAM_PID[$i]}" ]; then
        PID=`cat ${CAM_PID[$i]}`
        log "${CAM_NAME[$i]} PID=$PID"
        killer ${PID}
    else
        log "${CAM_NAME[$i]} PID file '${CAM_PID[$i]}' doesn't exist"
    fi
done
log "Finish"

sleep 1s

log "Start processes..."
for i in "${!CAM_NAME[@]}"
do
    bg_runner "${CAM_CMD[$i]} $i" "${CAM_PID[$i]}"
    sleep 1s
done
log "Finish"
