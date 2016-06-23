#!/bin/bash

OLD_PWD=`pwd`
trap "cd ${OLD_PWD}" EXIT
cd `dirname $0`

. shared_conf.sh
. shared_func.sh

LOG_PREFIX="capturer"
log "Start"

# Cases
# PID_EXISTS n | CAP_FILE_EXISTS n  # first run and passed many time
#   new capturer
#   move all, copy current
#
# PID_EXISTS n | CAP_FILE_EXISTS y  # reboot happened
#   rename CAP_FILE
#   new capturer
#   move all, copy current
#
# PID_EXISTS y | CAP_FILE_EXISTS n  # new date came
#   new capturer
#   wait, stop previous capturer <- another loops
#   move all, copy current
#
# PID_EXISTS y | CAP_FILE_EXISTS y  # usual case
#   move all, copy current
# end cases


get_status() {
    if [ -n "$1" ]; then

        local i=$1

        # PID_EXISTS
        if [ -f "${CAP_PID[$i]}" ]; then
            PID=`cat ${CAP_PID[$i]}`
            ps -p ${PID} > /dev/null
            PID_EXISTS=$?
        else
            PID_EXISTS=1
        fi
        # end

        # CAP_FILE_EXISTS
        CAM_CAP_FILE=${CAP_DIR}/${CAP_FILE}
        CAM_CAP_FILE=${CAM_CAP_FILE/CAM_NAME/${CAM_NAME[$i]}}
        CAM_CAP_FILE=${CAM_CAP_FILE/DT_FRMT/`date ${CAP_FILE_DT_FRMT}`}
        test -f "${CAM_CAP_FILE}"
        CAP_FILE_EXISTS=$?
        # end
    fi
}


for i in "${!CAM_NAME[@]}"
do
    get_status ${i}

    # (case) rename CAP_FILE
    if [ "$PID_EXISTS" -ne "0" ] && [ "$CAP_FILE_EXISTS" -eq "0" ]; then
        T=${CAP_DIR}/${CAP_FILE_IF_EXISTS}
        T=${T/CAM_NAME/${CAM_NAME[$i]}}
        T=${T/DT_FRMT/`date ${CAP_FILE_IF_EXISTS_DT_FRMT}`}
        log "Move the file '$CAM_CAP_FILE' to the '$T'"
        mv "$CAM_CAP_FILE" "$T"
    fi
    # end


    # (case) run new capturer
    if ! { [ "$PID_EXISTS" -eq "0" ] && [ "$CAP_FILE_EXISTS" -eq "0" ]; }; then
        log "Start new capturer for the ${CAM_NAME[$i]}"
        CMD="wget ${CAP_URL[$i]} -O $CAM_CAP_FILE"
        bg_runner "$CMD" "${CAP_PID[$i]}"

        sleep 1s

        CAP_FILE_SIZE=`du -b ${CAM_CAP_FILE} | cut -f 1`
        log "Captured file size: $CAP_FILE_SIZE"

        if [ "$CAP_FILE_SIZE" -lt "1000" ]; then
            log "${CAM_NAME[$i]} issue. Remove file and exit 1"
            killer ${PID}
            rm "$CAM_CAP_FILE"
            exit 1
        fi
    fi
    # end
done


# (case) is a delay necessary?
DELAY=false

for i in "${!CAM_NAME[@]}"
do
    get_status ${i}

    if [ "$PID_EXISTS" -eq "0" ] && [ "$CAP_FILE_EXISTS" -ne "0" ]; then
        log "Make delay before stop previous capturer"
        sleep ${CAP_WAIT}
        DELAY=true
        break;
    fi
done
# end


# (case) stop previous capturer
if [ "$DELAY" == true ]; then
    for i in "${!CAM_NAME[@]}"
    do
        get_status ${i}

        if [ "$PID_EXISTS" -eq "0" ] && [ "$CAP_FILE_EXISTS" -ne "0" ]; then
            log "Previous capturer is still running. PID: '$PID'. Stopping"
            killer ${PID}
        fi
    done
fi
# end


# (case) move all, copy current
for i in "${!CAM_NAME[@]}"
do
    get_status ${i}

    # Get file names
    MASK=${CAP_DIR}/${CAP_FMASK}
    MASK=${MASK/CAM_NAME/${CAM_NAME[$i]}}
    CAP_FILES=(`ls ${MASK} 2> /dev/null`)
    log "Found file(s) with the mask $MASK: ${CAP_FILES[*]}"
    # End

    for FILE in "${CAP_FILES[@]}"
    do
        # move all, copy current
        if [ "$CAM_CAP_FILE" == "$FILE" ]; then
            CMD="$CAP_MOVER_CMD ${FILE} ${CAM_NAME[$i]} false"
            log "Copy the file. Run: $CMD"
            eval "${CMD}"
        else
            CMD="$CAP_MOVER_CMD ${FILE} ${CAM_NAME[$i]} true"
            log "Move the file. Run: $CMD"
            eval "${CMD}"
        fi
        # end
    done
done
# end

log "Finish"
