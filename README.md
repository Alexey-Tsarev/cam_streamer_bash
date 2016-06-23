# cam_streamer
This is a bundle of scripts to capture and stream from web cameras.
It tested, works on Raspberry Pi 2, 3.

Gstreamer uses for video/audio capture and for streaming.
Video encoding forced by Raspberry hardware acceleration - OpenMAX:
https://jan.newmarch.name/LinuxSound/Diversions/RaspberryPiOpenMAX/

All Gstreamer's pipelines are in the files:
cam*_streamer.sh
and you can easily change them for you needs.

Main config file is in the file:
shared_conf.sh

By default Gstreamer streams to Nimble server
(yes it works on Raspberry Pi and it free):
https://wmspanel.com/nimble
via rtmp in flv format: h264 video, aac audio.
At the same time script gets streams using wget - http downloading to
local file system (usually to a sdcard).

Because of limit space on sdcard, script uses file syncing with a
remote file system. It uses rsync over ssh (key authentication).

Sync script runs using cron, for instance:
*/30   *   *   *   *   cam_capturer.sh
Every 30 minutes it syncs files to a remote file system and runs ffmpeg
for captured files recovering. When a new day has come, script syncing,
recovering data and then remove files from a local file system for a
previous day.

Nimble server allows to restream captured data via rtsp.
In this case it easy to add all capturing streams to Ivideon service
(Ivideon server needed in this case):
https://ivideon.com
and get low-cost cloud video surveillance.


Author: Alexey Tsarev.
