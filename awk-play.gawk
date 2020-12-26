#!/usr/bin/gawk -f

@include "glib.gawk"

## convert 16 bit rgb565 to 24 bit RGB
function rgb565to24bits(rgb,      r,g,b) {
  b = int(and(rgb, 0x1F) / 0x1F * 0xFF)
  g = int(and(rshift(rgb,5), 0x3F) / 0x3F * 0xFF)
  r = int(and(rshift(rgb,11), 0x1F) / 0x1F * 0xFF)

  return(sprintf("#%02X%02X%02X", r,g,b))
}

## horizontal sync, call on each (scan)line update
function hsync(vid) {
  vid["scanline"]++

  ## if current scanline is the height of the video
  if (vid["scanline"] == vid["height"]) {
    ## reset the scanline and increase the frame number
    vid["scanline"] = 0
    vid["frame"]++
    return 1
  }

  return 0
}

BEGIN {
  # initialize ORD byte-array
  for (i=0; i<256; i++) ORD[sprintf("%c",i)] = i;

  # get terminal width and height
  width = terminal["width"]
  height = (terminal["height"]-1)*2

  init(myscr, width, height)

  vid["width"] = vwidth ? vwidth : 192
  vid["height"] = vheight ? vheight : 108

printf("vwidth: %s (%s)\nvheight %s (%s)\n", vwidth, vid["width"], vheight, vid["height"])

  #vid["width"] = 192
  #vid["height"] = 108
  vid["framesize"] = vid["height"] * vid["width"]

  # set RS to twice the width of the video
  # each pixel contains 16 bits (rgb565), so each line width*2 bytes
  # this RS "hack" will make it possible to stream the data line by line
  RS = ".{" vid["width"] * 2"}"

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

  # left most pixel (2 bytes) seems to contain weird data(?!), so skip those
  byte = 2

  for (x=0; x<vid["width"]; x++) {
    # get 16 bit rgb565 from data (2 bytes)
    rgb = ORD[data[byte]] * 256 + ORD[data[byte+1]]
    byte += 2

    # convert to 24 bit RGB value
    vid[linepos+x] = rgb565to24bits(rgb)
  }

  ## if this is the last line (hsync) then draw the frame
  if (hsync(vid))
    draw(vid)

}

END {
  cursor("on")
}

