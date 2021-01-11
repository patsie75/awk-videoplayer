#!/usr/bin/gawk -f

## modified draw function used from awk-glib for displaying data
## awk-glib source: https://github.com/patsie75/awk-glib
@include "src/draw.gawk"
@include "src/decode.gawk"

## horizontal sync, call for each (scan)line update
function hsync(vid)
{
  vid["scanline"]++

  ## if current scanline is the height of the video
  if (vid["scanline"] == vid["height"])
  {
    # reset the scanline and increase the frame number
    vid["scanline"] = 0
    vid["frame"]++

    # increase framecount and update timer
    vid["framecnt"]++
    vid["now"] = timex()
    vid["time"] = sprintf("%02dh%02dm%04.1fs", (vid["now"]-vid["start"])/3600, ((vid["now"]-vid["start"])/60)%60, (vid["now"]-vid["start"])%60 )

    # update fps every 0.5 seconds
    if ( (vid["now"] - vid["then"]) >= 0.5 )
    {
      vid["curfps"] = vid["framecnt"] / (vid["now"] - vid["then"])
      vid["avgfps"] = vid["frame"] / (vid["now"] - vid["start"])
      vid["framecnt"] = 0
      vid["then"] = vid["now"]
    }
    return 1
  }
  return 0
}


## initialize video player
BEGIN {
  # define bits per pixel for pixel formats
  bpp["gray"]          = 8
  bpp["rgb8"]          = 8
  bpp["rgb565"]        = 16
  bpp["rgb24"]         = 24
  bpp["uyvy422"]       = 16
  bpp["yuyv422"]       = 16
  bpp["yvyu422"]       = 16

  # set video details
  vid["width"]         = width   ? width   : 192
  vid["height"]        = height  ? height  : 108
  vid["pix_fmt"]       = pix_fmt ? pix_fmt : "rgb24"
  vid["threads"]       = length(threads) ? threads : 2

  # set bits and bytes per pixel for configured pixel format
  if (! (vid["pix_fmt"] in bpp))
  {
    printf("ERR: Unknown pixel format: \"%s\"\nUse one of:", vid["pix_fmt"])
    for (fmt in bpp) printf(" \"%s\"", fmt)
    printf("\n\n")
    exit 1
  }

  vid["bpp"]           = bpp[vid["pix_fmt"]]
  vid["bytes_per_pix"] = int(vid["bpp"] / 8)
  vid["start"]         = vid["then"] = vid["now"] = timex()

  clear(vid, "0;0;0")

  # set RS to "bytes_per_pixel" times the width of the video
  # each pixel contains "bpp" bits of data, so each line "width" x "bytes_per_pixel"
  # this RS "hack" will make it possible to stream the data line by line
  RS = ".{" vid["width"] * vid["bytes_per_pix"] "}"

  # create sub-processes to offload decoding data
  for (i=0; i<vid["threads"]; i++)
    thread[i] = sprintf("gawk -b -v thread=%d -v width=%d -f codecs/%s.codec", i, vid["width"], vid["pix_fmt"])

  # turn cursor off
  cursor("off")
}


## skip lines for every odd frame
(vid["frame"] % 2) {
  # still handle scanlines/hsync, but ignore data
  hsync(vid)
  next
}


## no threading
(vid["threads"] == 0) {

  # with our RS "hack", RT contains our line data
  len = split(RT, data, "")

  if (len != (vid["width"] * vid["bytes_per_pix"]) )
  {
    printf("ERR: Premature end of data\nNeeded %d bytes, got %d\n", vid["width"] * vid["bytes_per_pix"], len)
    exit 1
  }

  # decode the line of video data
  decode(vid, data)

  ## if this is the last line (hsync) then draw the frame
  if (hsync(vid))
  {
    draw(vid)
    printf("\033[Hsize (%dx%d) %s, %s, frame: %6s, fps: %4.1f cur/%4.1f avg", vid["width"], vid["height"], vid["pix_fmt"], vid["time"], vid["frame"], vid["curfps"], vid["avgfps"])
  }
}


## multi-threaded
(vid["threads"] > 0) {
  # thread number to pass data to
  threadnr = ((NR-1) % vid["height"] % vid["threads"])

  # send data to thread
  printf("%s", RT) |& thread[threadnr]

  # if this is the last line (hsync) then draw the frame
  if (hsync(vid))
  {
    # threads need data and time to process. delay reading with one frame
    if (vid["frame"] > 1)
    {
      # thread data returns newline separated
      RS = "\n"

      # read data from all threads
      for (threadnr=0; threadnr<vid["threads"]; threadnr++)
      {
        # read all lines of data from thread
        for (linenr=threadnr; linenr<vid["height"]; linenr+=vid["threads"])
        {
          linepos = linenr * vid["width"]

          # read and split data and put it in vid[] array
          thread[threadnr] |& getline line
          split(line, data)
          for (x=0; x<vid["width"]; x++)
            vid[linepos+x] = data[x+1]
        }
      }

      # set magic RS again
      RS = ".{" vid["width"] * vid["bytes_per_pix"] "}"
    }

    # display frame and stats
    draw(vid)
    printf("\033[Hsize (%dx%d) %s, %s, frame: %6s, fps: %4.1f cur/%4.1f avg", vid["width"], vid["height"], vid["pix_fmt"], vid["time"], vid["frame"], vid["curfps"], vid["avgfps"])
  }
}

END {
  # reenable cursor
  cursor("on")

  # close running threads
  for (i=0; i<vid["threads"]; i++)
    close(thread[i])

  # reset colors and print newline
  printf("\033[0m\n")
}

