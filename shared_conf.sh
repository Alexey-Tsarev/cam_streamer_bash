#!/bin/bash

# shared
LOG_DIR=log
LOG_ECHO=true
# LOG_ECHO=false
LOG_WRITE=true
LOG_FILE=DT_FRMT.log
LOG_FILE_DT_FRMT=+%Y-%m-%d
LOG_LINE_DT_FRMT="+%Y-%m-%d %H:%M:%S,%3N %Z"
# end

# CAM / CAP arrays
CAM_NAME=(
cam1
cam2
# cam3
)

CAM_CMD=(
./cam1_streamer.sh
./cam2_streamer.sh
./cam3_streamer.sh
)

# Path for search cam: /dev/v4l/, /dev/snd/
CAM_SEEK=(
by-id/usb-046d_09a4_C9469E20-*                        # (1) 046d:09a4 Logitech, Inc. QuickCam E 3500  (Logitech E3500)
by-id/usb-Sonix_Technology_Co.__Ltd._USB_2.0_Camera-* # (2) 0c45:6340 Microdia                        (Canyon CNE-CWC3)
by-id/usb-Etron_Technology__Inc._USB2.0_Camera-*      # (3) 1e4e:0102 Cubeternet GL-UPC822 UVC WebCam (No name China cam)
)

CAM_RESET_CMD=(
"sudo ./usb_reset.sh"
"sudo ./usb_reset.sh"
"sudo ./usb_reset.sh"
)

CAM_PID=(
cam1_streamer.pid
cam2_streamer.pid
cam3_streamer.pid
)

CAM_MAX_START_SEC=(
30
30
30
)

CAP_URL=(
http://127.0.0.1:8081/cam/cam1/mpeg.2ts
http://127.0.0.1:8081/cam/cam2/mpeg.2ts
http://127.0.0.1:8081/cam/cam3/mpeg.2ts
)

CAP_PID=(
cam1_capturer.pid
cam2_capturer.pid
cam3_capturer.pid
)
# end

# cam_capturer
CAP_DIR=/mnt/sdcard_p3/cam
CAP_WAIT=10s

CAP_FILE=CAM_NAME_DT_FRMT
CAP_FILE_DT_FRMT=+%Y-%m-%d
CAP_FILE_IF_EXISTS=CAM_NAME_DT_FRMT
CAP_FILE_IF_EXISTS_DT_FRMT=+%Y-%m-%d_%H-%M-%S
CAP_FMASK="CAM_NAME_*"
CAP_MOVER_CMD="flock -n cam_syncer.flock ./cam_syncer.sh" # Use: cam_syncer.sh SRC_FILE CAM_NAME REMOVE_FLAG=false|true
# end

# cam_mover
REMOTE_USER="example-user"
REMOTE_HOST="example-host"
REMOTE_DIR="/storage/cam/CAM_NAME"
TMP_FILE_EXT="tmp"
COPY_CMD="sudo rsync -av --progress --timeout=600 --bwlimit=10240K SRC_FILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/SRC_FILE_NAME.$TMP_FILE_EXT"
FFMPEG_CMD="sudo ssh $REMOTE_USER@$REMOTE_HOST /usr/local/sbin/ffmpeg -y -analyzeduration 1000000000000 -i $REMOTE_DIR/SRC_FILE_NAME.$TMP_FILE_EXT -vcodec copy -acodec copy -f matroska -flags +global_header $REMOTE_DIR/SRC_FILE_NAME.$TMP_FILE_EXT.$TMP_FILE_EXT"
MOVE_CMD="sudo ssh $REMOTE_USER@$REMOTE_HOST mv $REMOTE_DIR/SRC_FILE_NAME.$TMP_FILE_EXT.$TMP_FILE_EXT $REMOTE_DIR/SRC_FILE_NAME.mkv"
RM_CMD="rm SRC_FILE; sudo ssh $REMOTE_USER@$REMOTE_HOST rm $REMOTE_DIR/SRC_FILE_NAME.$TMP_FILE_EXT"
# end
