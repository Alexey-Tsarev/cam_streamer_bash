#!/bin/bash

OLD_PWD=`pwd`
trap "cd ${OLD_PWD}" EXIT
cd `dirname $0`

. shared_conf.sh
. shared_func.sh

LOG_PREFIX="rest all"
log "Start"

while true; do
    ./cam_restarter.sh

    # Make sure stream server is ready to return data (poller in a loop)
    CAM_TO_CHECK=("${CAM_NAME[@]}")
    CAM_OK=false
    CAM_TIMEOUT=false
    START_TS=`date +%s`

    while true; do
        for i in "${!CAM_TO_CHECK[@]}"
        do
            log "Checking ${CAM_NAME[$i]}... ${CAP_URL[$i]} " true false
            STATUS_CODE=`wget -q -S --spider ${CAP_URL[$i]} 2>&1 | head -n 1 | awk '{print $2}'`

            if [ -n "$STATUS_CODE" ] && [ "$STATUS_CODE" -eq "200" ]; then
                log "$STATUS_CODE OK" false
                unset CAM_TO_CHECK[${i}]
            else
                # Check max start time
                CUR_TS=`date +%s`
                DELTA_TS=$(($CUR_TS - $START_TS))

                log "$STATUS_CODE $DELTA_TS/${CAM_MAX_START_SEC[$i]}" false

                if [ "$DELTA_TS" -gt "${CAM_MAX_START_SEC[$i]}" ]; then
                    CAM_TIMEOUT=true
                    CAM_TIMEOUT_i=${i}
                    break
                fi
                # end
            fi
        done

        if [ "$CAM_TIMEOUT" == true ]; then
            break
        fi

        if [ "${#CAM_TO_CHECK[@]}" -eq "0" ]; then
            CAM_OK=true
            break;
        fi
    done
    # end

    # Reset of a failed cam
    if [ "$CAM_TIMEOUT" == true ]; then
        log "${CAM_NAME[$i]} timeout to start"

        unset BUSNUM
        unset DEVNUM
        get_usb_bus_dev /dev/v4l/${CAM_SEEK[$CAM_TIMEOUT_i]}

        if [ -n "$BUSNUM" ] && [ -n "$DEVNUM" ]; then
            CMD="${CAM_RESET_CMD[$CAM_TIMEOUT_i]} ${BUSNUM} ${DEVNUM}"
            log "Running reset command: $CMD"
            eval "${CMD}"
        else
            log "Failed to get bus/dev for the cam. Reset skipped"
        fi

        log "Start from the beginning"
        continue
    fi
    # end

    ./cam_capturer.sh
    EC=$?
    log "Finished with the exit code: $EC"

    if [ "$EC" -eq "0" ]; then
        break
    else
        log "Non zero exit code. Run again"
    fi
done

log "Finish"
