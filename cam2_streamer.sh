#!/bin/bash

OLD_PWD=`pwd`
trap 'log "Trapping"; cd ${OLD_PWD}; kill `jobs -p`; log "Trapped"' EXIT # Maybe -9 and/or other events
cd `dirname $0`

. shared_conf.sh
. shared_func.sh

if [ -n "$1" ]; then
    INDEX=$1
else
    INDEX=1 # Index at the CAM_NAME array
    echo "First parameter - CAM_INDEX - didn't provided. Let CAM_INDEX=$INDEX"
fi

NAME=${CAM_NAME[$INDEX]}
SEEK=${CAM_SEEK[$INDEX]}
LOG_PREFIX="  $NAME  "

while true; do
    log "Start $NAME streamer"

    # set -x
    gst-launch-1.0 \
        v4l2src device=`ls /dev/v4l/${SEEK}` \
            ! videorate \
            ! video/x-raw,framerate=5/1 \
            ! clockoverlay time-format="$NAME %Y-%m-%d %H:%M:%S" xpad=0 ypad=0 font-desc="Lucida Console Bold 38" auto-resize=0 shaded-background=1 \
            ! omxh264enc target-bitrate=128000 control-rate=1 \
            ! h264parse \
            ! queue \
            ! mux. \
        alsasrc device=hw:`readlink /dev/snd/${SEEK} | sed 's/[^0-9]*//g'` \
            ! audioconvert \
            ! rgvolume pre-amp=6.0 headroom=10.0 \
            ! rglimiter \
            ! audioconvert \
            ! audioresample \
            ! audio/x-raw,rate=22050,channels=1 \
            ! queue \
            ! voaacenc bitrate=8000 \
            ! aacparse \
            ! queue \
            ! mux. \
        flvmux name=mux \
            ! rtmpsink location="rtmp://127.0.0.1/cam/$NAME"
    # set +x

    log "$NAME streamer exited with the code=$?"
done
