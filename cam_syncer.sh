#!/bin/bash

if [ -z "$1" ]; then
    echo "First parameter - source file - didn't provided. Exit"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Second parameter - cam name - didn't provided. Exit"
    exit 1
fi

OLD_PWD=`pwd`
trap "cd ${OLD_PWD}" EXIT
cd `dirname $0`

. shared_conf.sh
. shared_func.sh

LOG_PREFIX=" syncer "
log "Start"

FILE="$1"
CAM="$2"
RM="$3"
FILE_NAME=`basename ${FILE}`

# Replace CAM_NAME
REMOTE_DIR=${REMOTE_DIR//CAM_NAME/${CAM}}
COPY_CMD=${COPY_CMD//CAM_NAME/${CAM}}
FFMPEG_CMD=${FFMPEG_CMD//CAM_NAME/${CAM}}
MOVE_CMD=${MOVE_CMD//CAM_NAME/${CAM}}
RM_CMD=${RM_CMD//CAM_NAME/${CAM}}
# end

CMD=${COPY_CMD}
CMD=${CMD//SRC_FILE_NAME/${FILE_NAME}}
CMD=${CMD//SRC_FILE/${FILE}}
log "Copy the file '$FILE', run: $CMD"
eval "${CMD}"

if [ "$?" -ne "0" ]; then
    log "Copy failed"
else
    CMD=${FFMPEG_CMD}
    CMD=${CMD//SRC_FILE_NAME/${FILE_NAME}}
    CMD=${CMD//SRC_FILE/${FILE}}
    log "Run ffmpeg: $CMD"
    eval "${CMD}"

    if [ "$?" -ne "0" ]; then
        log "ffmpeg failed"
    else
        CMD=${MOVE_CMD}
        CMD=${CMD//SRC_FILE_NAME/${FILE_NAME}}
        CMD=${CMD//SRC_FILE/${FILE}}
        log "Run move: $CMD"
        eval "${CMD}"

        if [ "$?" -ne "0" ]; then
            log "move failed"
        else
            if [ "$RM" == true ]; then
                CMD=${RM_CMD}
                CMD=${CMD//SRC_FILE_NAME/${FILE_NAME}}
                CMD=${CMD//SRC_FILE/${FILE}}
                log "Run rm: $CMD"
                eval "${CMD}"
            fi
        fi
    fi
fi

log "Finish"
