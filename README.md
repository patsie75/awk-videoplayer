# awk-videoplayer

A little experiment I wrote during the 2020 christmas holidays

This will play (to some extent) any video files in raw RGB565 format. (no audio)

The `play` wrapper script utilizes `ffmpeg` to do the converstion from whatever format to the raw rgb565 format, plus handle scaling to a smaller format which will still fit in most terminals (currently 192x108, a tenth of FullHD 1920x1080)

With the help of e36freak on #awk (Freenode) I got a version together which can handle streaming input, so there is no need to first convert and then play, but input can be streamed directly from `ffmpeg` stdout to the player

Usage: `play <any_video_file>`

Your terminal needs to be at least 192x54 in size to properly display all the output

Currently only the even frames are displayed to come close to real-time video playback.
On my hardware 24fps results in about 50% playback speed. Displaying only the even frames (~12fps) is around real-time playback speed

This script is currently in a realy testing phase. don't expect too much from it

