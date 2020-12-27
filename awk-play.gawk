#!/usr/bin/gawk -f

@include "glib.gawk"

## horizontal sync, call on each (scan)line update
function hsync(vid) {
  vid["scanline"]++

  ## if current scanline is the height of the video
  if (vid["scanline"] == vid["height"]) {
    ## reset the scanline and increase the frame number
    vid["scanline"] = 0
    vid["frame"]++

    # increase framecount and update timer
    vid["framecnt"]++
    vid["now"] = timex()

    # update fps every 0.5 seconds
    if ( (vid["now"] - vid["then"]) > 0.5 ) {
      vid["curfps"] = vid["framecnt"] / (vid["now"] - vid["then"])
      vid["avgfps"] = vid["frame"] / (vid["now"] - vid["start"])

      vid["framecnt"] = 0
      vid["then"] = vid["now"]
    }
    return 1
  }

  return 0
}

BEGIN {
  pixfmt["rgb565"] = 16
  pixfmt["rgb8"]   = 8
  pixfmt["rgb24"]  = 24

  # initialize ORD byte-array
  for (i=0; i<256; i++)
    ORD[sprintf("%c",i)] = i;

  # get terminal width and height
  width = terminal["width"]
  height = (terminal["height"]-1)*2

  init(myscr, width, height)

  vid["width"]     = vwidth ? vwidth : 192
  vid["height"]    = vheight ? vheight : 108
  vid["framesize"] = vid["height"] * vid["width"]
  vid["pix_fmt"]   = pix_fmt ? pix_fmt : "rgb24"

  if (vid["pix_fmt"] in pixfmt)
    vid["bpp"] = pixfmt[vid["pix_fmt"]]
  else {
    printf("Unknown pixel format: \"%s\"\n", vid["pix_fmt"])
    exit 1
  }

  vid["bytes_per_pix"] = int(vid["bpp"] / 8)

  vid["start"] = vid["then"] = vid["now"] = timex()

  # set RS to "bytes_per_pixel" times the width of the video
  # each pixel contains "bpp" bits of data, so each line "width" x "bytes_per_pixel"
  # this RS "hack" will make it possible to stream the data line by line
  RS = ".{" vid["width"] * vid["bytes_per_pix"] "}"

  # turn cursor off
  cursor("off")

}

## skip lines for every odd frame
(vid["frame"] % 2) {
  ## still handle scanlines/hsync
  hsync(vid)

  ## but do nothing with this frame/line
  next
}


{
  # with our RS "hack", RT contains our line data
  len = split(RT, data, "")
  linepos = vid["scanline"] * vid["width"]

  # left most pixel ("bytes_per_pixel" bytes) seems to contain weird data(?!), so skip those
  #byte = 0
  byte = vid["bytes_per_pix"]

  ## rgb8
  if (vid["pix_fmt"] == "rgb8") {
    for (x=0; x<vid["width"]; x++) {
      rgb = ORD[data[byte]]
      vid[linepos+x] = sprintf("#%02X%02X%02X", int(and(rshift(rgb,5), 0x07) / 0x07 * 0xFF), int(and(rshift(rgb,2), 0x07) / 0x07 * 0xFF), int(and(rgb, 0x03) / 0x03 * 0xFF) )
      byte += vid["bytes_per_pix"]
    }
  }

  ## rgb565
  if (vid["pix_fmt"] == "rgb565") {
    for (x=0; x<vid["width"]; x++) {
      rgb = ORD[data[byte]] * 256 + ORD[data[byte+1]]
      vid[linepos+x] = sprintf("#%02X%02X%02X", int(and(rshift(rgb,11), 0x1F) / 0x1F * 0xFF), int(and(rshift(rgb,5), 0x3F) / 0x3F * 0xFF), int(and(rgb, 0x1F) / 0x1F * 0xFF) )
      #vid[linepos+x] = sprintf("#%02X%02X%02X", int(and(rgb,0xF800) / 0xF800 * 0xFF), int(and(rgb,0x07E0) / 0x07E0 * 0xFF), int(and(rgb, 0x1F) / 0x1F * 0xFF) )
      byte += vid["bytes_per_pix"]
    }
  }

  ## rgb24
  if (vid["pix_fmt"] == "rgb24") {
    for (x=0; x<vid["width"]; x++) {
      ## RGB24 is actuall GRB ?!
      #vid[linepos+x] = sprintf("#%02X%02X%02X", ORD[data[byte+2]], ORD[data[byte+1]], ORD[data[byte]])
      vid[linepos+x] = sprintf("#%02X%02X%02X", ORD[data[byte+1]], ORD[data[byte+2]], ORD[data[byte]])
      byte += vid["bytes_per_pix"]
    }
  }

  ## if this is the last line (hsync) then draw the frame
  if (hsync(vid)) {
    draw(vid)
    printf("\033[Hsize (%dx%d) %s, frame: %8s  fps: %5.2f cur/%5.2f avg", vid["width"], vid["height"], vid["pix_fmt"], vid["frame"], vid["curfps"], vid["avgfps"])
  }

}


END {
  # reenable cursor
  cursor("on")

  # reset colors and print newline
  printf("\033[0m\n")
}

