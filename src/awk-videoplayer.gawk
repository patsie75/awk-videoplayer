#!/usr/bin/gawk -f

## modified draw function used from awk-glib for displaying data
## awk-glib source: https://github.com/patsie75/awk-glib
@include "src/draw.gawk"
@include "src/hsync.gawk"
@include "src/decfnc.gawk"
@include "src/config.gawk"
@include "src/delay.gawk"
@include "src/glib2.awk"

## convert seconds to human readable time
function durationtotime(duration) {
  return  sprintf("%02dh%02dm%03.1fs", duration / 3600, (duration/60)%60, duration%60)
}

## show a status information bar top-left
function status(vid) {
  printf("\033[H%dx%d@%d (%s), %s/%s %5.1f%% \033[97;44m%s\033[0m frame: %6s (dropped: %d), fps: %4.1f cur/%4.1f avg", vid["width"], vid["height"], vid["fps"], vid["pix_fmt"], vid["time"], durationtotime(vid["duration"]), vid["frame"]*100/vid["frames"], bar(vid["frame"], vid["frames"], 10), vid["frame"], vid["skipped"], vid["curfps"], vid["avgfps"])
}

## draw progress bar
function bar(val, max, barsize,    str, len, full, part, i) {
  str = ""
  len = length(bargraph) - 1

  full = int(val*barsize/max)
  part = (val*barsize/max) % 1

  while (i < full)    { str = str sprintf("%s", bargraph[8]); i++ }
  if (part >= 1/len)  { str = str sprintf("%s", bargraph[int(part*len)]); i++ }
  while (i < barsize) { str = str sprintf("%s", bargraph[0]); i++ }

  return str
}

## initialize video player
BEGIN {
  # progress bar graphics
  bargraph[0] = " "
  bargraph[1] = "▏"
  bargraph[2] = "▎"
  bargraph[3] = "▍"
  bargraph[4] = "▌"
  bargraph[5] = "▋"
  bargraph[6] = "▊"
  bargraph[7] = "▉"
  bargraph[8] = "█"

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

  if (split(meta, a) == 7) {
    vid["orgwidth"]      = int(a[1])
    vid["orgheight"]     = int(a[2])
    vid["aspectwidth"]   = int(a[3])
    vid["aspectheight"]  = int(a[4])
    vid["frames"]        = int(a[5])
    vid["duration"]      = a[6]
    vid["fps"]           = int(a[7] + 0.5)
  } else {
    printf("Not enough arguments (7) for meta: \"%s\"\n", meta)
    exit 0
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
  #vid["start"] = vid["then"] = vid["now"] = timex()
  vid["start"] = vid["then"] = vid["now"] = gettimeofday()

  #prev = now = timex()
  prev = now = gettimeofday()
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

  # if this is the last line (hsync) then draw the frame
  if (hsync(vid)) {
    if ((skip += delay(vid["fps"])) > 0) {
      skip--
      vid["skipped"]++
    #} else draw(vid)
    } else drawhi(vid)

    if ( !(vid["frame"] % 13) )
      status(vid)
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
            #vid[linepos+x] = data[x+1]
            vid[x,linenr] = data[x+1]
        }
      }

      # set magic RS again
      RS = ".{" vid["width"] * vid["bytes_per_pix"] "}"
    }

    if ((skip += delay(vid["fps"])) > 0) {
      skip--
      vid["skipped"]++
    } else {
      if (xres == 2) drawhi(vid)
      else draw2(vid)
    }

    if ( !(vid["frame"] % 13) )
      status(vid)
  }
}

END {
  status(vid)

  # reenable cursor
  cursor("on")

  # close running threads
  for (i=0; i<vid["threads"]; i++)
    close(thread[i])

  # reset colors and print newline
  printf("\033[0m\n")

  same["total"] = same["four"] + same["three"] + same["two"] + same["twotwo"] + same["rest"]
same["total"]=0
  if (same["total"]) {
    printf("four : %9d (%5.1f%%)\n", same["four"] , same["four"]  * 100 / same["total"])
    printf("three: %9d (%5.1f%%)\n", same["three"], same["three"] * 100 / same["total"])
    printf("two  : %9d (%5.1f%%)\n", same["two"]  , same["two"]   * 100 / same["total"])
    printf("two2 : %9d (%5.1f%%)\n", same["twotwo"], same["twotwo"] * 100 / same["total"])
    printf("rest : %9d (%5.1f%%)\n", same["rest"] , same["rest"]  * 100 / same["total"])

    found = 0
    for (i=0; i<=7; i++) {
      found += time[i]
      printf("time[%d] : %9.2f (%5.1f%%)\n", i, time[i], time[i] * 100 / time["total"])
    }

    printf("lost : %9.2f (%5.1f%%)\n", time["total"]-found, (time["total"] - found) * 100 / time["total"])
    printf("line : %9.2f (%5.1f%%)\n", time["line"], time["line"] * 100 / time["total"])
    printf("total: %9.2f (%5.1f%%)\n", time["total"], time["total"] * 100 / time["total"])
  }
}

