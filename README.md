# awk-videoplayer

A little experiment I wrote during the 2020 christmas holidays

This will play (to some extent) any video files in raw RGB8, RGB565 and RGB24 formats.

The `play` wrapper script utilizes `ffmpeg` to do the conversion from whatever format to the raw desired format, plus handle scaling to a smaller format, the size of your terminal.

Audio will most likely be out of sync or stutter, since that is handled by `ffmpeg` and the video by the `awk-videoplayer`.

With the help of e36freak on #awk (Freenode) I got a version together which can handle streaming input, so there is no need to first convert and then play, but input can be streamed directly from `ffmpeg` stdout to the player

Usage: `play <any_video_file> ["rgb8"|"rgb565"|"rgb24"] [<nr of threads>]`

The video will be resized to the size of your terminal.
You can modify the either the `w` and `h` manually or set the `size` variable in the `play` script to change your needs.

Only the even frames are displayed to come close to real-time video playback.
On my hardware 24fps results in about 50% playback speed. Displaying only the even frames (~12fps) is around real-time playback speed
It uses a modified `draw()` function from my `awk-glib` (see: https://github.com/patsie75/awk-glib )

During new years weekend of 2021 the code has been revamped to try and improve performance by making use of multithreading/processing with less than great results.
It looks like most performance is lost in drawing the actual displayed picture and not in calculating the data, so multithreading this part has not increased performance that much.

This script is currently in a testing phase. don't expect too much from it

Example video can be seen here: https://youtu.be/QVQkG5bBcOo

Example screenshots in 8, 16 and 24 bits:<br>
![8 bits](/screenshots/rgb8.png)<br>
![16 bits](/screenshots/rgb565.png)<br>
![24 bits](/screenshots/rgb24.png)<br>
