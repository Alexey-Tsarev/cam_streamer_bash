#!/bin/bash

# $1 message
# $2 (default true) print date time
# $3 (default true) print new line
log() {
    local LOG=${LOG_FILE/DT_FRMT/`date "$LOG_FILE_DT_FRMT"`}

    if [ "$2" == false ]; then
        local MSG="$1"
    else
        local MSG="`date "$LOG_LINE_DT_FRMT"` [$LOG_PREFIX] $1"
    fi

    if [ "$LOG_ECHO" == true ]; then
        if [ "$3" == false ]; then
            echo -n "$MSG"
        else
            echo    "$MSG"
        fi
    fi

    if [ "$LOG_WRITE" == true ]; then

        if [ ! -d "$LOG_DIR" ]; then
            mkdir -p "$LOG_DIR"
        fi

        if [ "$3" == false ]; then
            echo -n "$MSG" >> "$LOG_DIR/$LOG"
        else
            echo    "$MSG" >> "$LOG_DIR/$LOG"
        fi
    fi
}

bg_runner() {
    if [ -n "$1" ]; then
        nohup $1 > /dev/null 2>&1 &
        local PID=$!

        if [ -n "$2" ]; then
            echo "$PID" > $2
        fi

        log "Ran command in background: '$1'. PID: $PID"
    fi
}

killer() {
    if [ -n "$1" ] ; then
        log "Kill PID: $1"

        pkill -TERM -P $1 > /dev/null 2>&1
        sleep 1s
        pkill -KILL -P $1 > /dev/null 2>&1

        kill $1    > /dev/null 2>&1
        sleep 1s
        kill -9 $1 > /dev/null 2>&1
    fi
}

get_usb_bus_dev() {
    if [ -n "$1" ] ; then
        local UDEV_DATA=`udevadm info -a --name $1`

        BUSNUM=`echo "$UDEV_DATA" | grep -m 1 busnum | cut -d '"' -f 2`
        DEVNUM=`echo "$UDEV_DATA" | grep -m 1 devnum | cut -d '"' -f 2`
    fi
}
