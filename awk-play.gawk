#!/usr/bin/gawk -f

@include "glib.gawk"

## convert 16 bit rgb565 to 24 bit RGB
function rgb565to24bits(rgb,      r,g,b) {
  b = int(and(rgb, 0x1F) / 0x1F * 0xFF)
  g = int(and(rshift(rgb,5), 0x3F) / 0x3F * 0xFF)
  r = int(and(rshift(rgb,11), 0x1F) / 0x1F * 0xFF)

  return(sprintf("#%02X%02X%02X", r,g,b))
}

## convert 24 bit rgb24 to 3x8 bit RGB
function rgb24to24bits(rgb,      r,g,b) {
  b = and(rgb, 0xFF)
  g = and(rshift(rgb,8), 0xFF)
  r = and(rshift(rgb,16), 0xFF)

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

    # increase framecount and update timer
    vid["framecnt"]++
    vid["now"] = timex()

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
  # initialize ORD byte-array
  for (i=0; i<256; i++) ORD[sprintf("%c",i)] = i;

  # get terminal width and height
  width = terminal["width"]
  height = (terminal["height"]-1)*2

  init(myscr, width, height)

  vid["width"] = vwidth ? vwidth : 192
  vid["height"] = vheight ? vheight : 108

  #vid["width"] = 192
  #vid["height"] = 108
  vid["framesize"] = vid["height"] * vid["width"]

  vid["pix_fmt"] = pix_fmt ? pix_fmt : "rgb565"

  if (vid["pix_fmt"] == "rgb565")
    vid["bpp"] = 16

  if (vid["pix_fmt"] == "rgb24")
    vid["bpp"] = 24

  vid["bytes_per_pix"] = int(vid["bpp"] / 8)

  vid["start"] = vid["then"] = vid["now"] = timex()

  # set RS to twice the width of the video
  # each pixel contains 16 bits (rgb565), so each line width*2 bytes
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

  # left most pixel ("depth" bytes) seems to contain weird data(?!), so skip those
  byte = vid["bytes_per_pix"]
  #byte = 0

  ## rgb565
  if (vid["pix_fmt"] == "rgb565") {
    for (x=0; x<vid["width"]; x++) {
      #vid[linepos+x] = rgb565to24bits( ORD[data[byte]] * 256 + ORD[data[byte+1]] )

      rgb = ORD[data[byte]] * 256 + ORD[data[byte+1]]
      vid[linepos+x] = sprintf("#%02X%02X%02X", int(and(rshift(rgb,11), 0x1F) / 0x1F * 0xFF), int(and(rshift(rgb,5), 0x3F) / 0x3F * 0xFF), int(and(rgb, 0x1F) / 0x1F * 0xFF) )
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

