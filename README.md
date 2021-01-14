# awk-videoplayer

A little experiment I wrote during the 2020 christmas holidays

This will play (to some extent) many video files in raw RGB, BGR, YUV and GRAY pixel formats.

The `play` wrapper script utilizes `ffmpeg` to do the conversion from whatever format to the raw desired format, plus handle scaling to a smaller format, the size of your terminal.

Audio will most likely be out of sync or stutter, since that is handled by `ffmpeg` and the video by the `awk-videoplayer`.

With the help of e36freak on #awk (Freenode) I got a version together which can handle streaming input, so there is no need to first convert and then play, but input can be streamed directly from `ffmpeg` stdout to the player

Usage: `play <any_video_file> <pixel format> [<nr of threads>]`

Example pixelformats are: gray, rgb8, rgb565, rgb24, yuyv422. For all supported pixel formats see `awk-videoplayer.cfg`

You can modify the either the `w` and `h` manually or set the `size` variable in the `play` script to change your needs.

Only the even frames are displayed to come close to real-time video playback.
On my hardware 24fps results in about 50% playback speed. Displaying only the even frames (~12fps) is around real-time playback speed
It uses an optimized `draw()` function from my `awk-glib` (see: https://github.com/patsie75/awk-glib )

During new years weekend of 2021 the code has been revamped to try and improve performance by making use of multithreading/processing with less than great results.
It looks like most performance is lost in drawing the actual displayed picture and not in calculating the data, so multithreading this part has not increased performance that much.
The default thread count is 2, meaning the player will spawn 2 decoding threads/processes next to the main player.
If multithreading is not working properly for you, set the <nr of threads> to 0 (zero)

This script is currently in a testing phase. Don't expect too much from it. If this breaks anything, you'll get to keep all the pieces.

Example video can be seen here: https://youtu.be/QVQkG5bBcOo

Example screenshots in 8, 16 and 24 bits:<br>
![8 bits](/screenshots/rgb8.png)<br>
![16 bits](/screenshots/rgb565.png)<br>
![24 bits](/screenshots/rgb24.png)<br>
