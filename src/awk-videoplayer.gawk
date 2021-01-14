#!/usr/bin/gawk -f

## modified draw function used from awk-glib for displaying data
## awk-glib source: https://github.com/patsie75/awk-glib
@include "src/draw.gawk"
@include "src/hsync.gawk"
@include "src/decfnc.gawk"
@include "src/config.gawk"

## initialize video player
BEGIN {
  # load configuration
  load_cfg(cfg, "awk-videoplayer.cfg")

  # set video pixelformat
  vid["pix_fmt"]       = pix_fmt ? pix_fmt : "rgb24"

  # check if pixelformat has a known configuration
  if ( !(vid["pix_fmt"] in cfg) )
  {
    printf("ERR: Unknown pixel format: \"%s\"\nUse one of:", vid["pix_fmt"])
    for (fmt in cfg) printf(" \"%s\"", fmt)
    printf("\n\n")
    exit 1
  }

  # set rest of video parameters
  vid["width"]           = width           ? width   : 192
  vid["height"]          = height          ? height  : 108
  vid["threads"]         = length(threads) ? threads : 2
  vid["bpp"]             = cfg[vid["pix_fmt"]]["bpp"]
  vid["bytes_per_pix"]   = int(vid["bpp"] / 8)
  vid["macro_pix"]       = cfg[vid["pix_fmt"]]["macro_pix"] ? cfg[vid["pix_fmt"]]["macro_pix"] : 1
  vid["codec"]           = cfg[vid["pix_fmt"]]["codec"]     ? cfg[vid["pix_fmt"]]["codec"]     : "generic"
  vid["decfnc"] = decfnc = cfg[vid["pix_fmt"]]["decfnc"]    ? "dec_" cfg[vid["pix_fmt"]]["decfnc"] : "dec_" vid["pix_fmt"]
  vid["offset"]          = cfg[vid["pix_fmt"]]["offset"]    ? cfg[vid["pix_fmt"]]["offset"] : ""
  vid["byte_inc"]        = vid["bytes_per_pix"] * vid["macro_pix"]

  # clear video screen
  clear(vid, "0;0;0")

  # split offset into array
  n = split(vid["offset"], arr, ",")
  for (i=0; i<n; i++)
    offs[arr[i+1]] = i

  # set RS to "bytes_per_pixel" times the width of the video
  # each pixel contains "bpp" bits of data, so each line "width" x "bytes_per_pixel"
  # this RS "hack" will make it possible to stream the data line by line
  RS = ".{" vid["width"] * vid["bytes_per_pix"] "}"

  # create sub-processes to offload decoding data
  for (i=0; i<vid["threads"]; i++)
    thread[i] = sprintf("gawk -b -v thread=%d -v width=%d -v bytes_per_pix=%d -v macro_pix=%d -v decfnc=\"%s\" -v offset=\"%s\" -f codecs/%s.codec", i, vid["width"], vid["bytes_per_pix"], vid["macro_pix"], vid["decfnc"], vid["offset"], vid["codec"])

  # turn cursor off
  cursor("off")

  # start measuring duration
  vid["start"] = vid["then"] = vid["now"] = timex()
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

  byte = 1
  linepos = vid["scanline"] * vid["width"]

  # decode video data
  for (x=0; x<width; x+=vid["macro_pix"])
  {
    n = split(@decfnc(data, byte, offs), pixels)
    for (i=0; i<n; i++)
      vid[linepos+x+i] = pixels[i+1]
    byte += vid["byte_inc"]
  }

  ## if this is the last line (hsync) then draw the frame
  if (hsync(vid))
  {
    draw(vid)
    printf("\033[Hsize (%dx%d) %s/%s, %s, frame: %6s, fps: %4.1f cur/%4.1f avg", vid["width"], vid["height"], vid["pix_fmt"], decfnc, vid["time"], vid["frame"], vid["curfps"], vid["avgfps"])
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
    printf("\033[Hsize (%dx%d) %s/%s/%s, %s, frame: %6s, fps: %4.1f cur/%4.1f avg", vid["width"], vid["height"], vid["pix_fmt"], vid["codec"], decfnc, vid["time"], vid["frame"], vid["curfps"], vid["avgfps"])
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

