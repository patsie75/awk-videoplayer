#!/usr/bin/gawk -f
## usage: codec.gawk -v thread=[0-9] -v pix_fmt="rgb8|rgb565|rgb24" -v width=vid["width"]

BEGIN {
  # initialize ORD byte-array
  for (i=0; i<256; i++)
    ORD[sprintf("%c",i)] = i;

  # define bits per pixel for pixel formats
  bpp["rgb8"]          = 8
  bpp["rgb565"]        = 16
  bpp["rgb24"]         = 24

  # set video details
  vid["width"]         = width   ? width   : 192
#  vid["height"]        = height  ? height  : 108
  vid["pix_fmt"]       = pix_fmt ? pix_fmt : "rgb24"

  vid["bpp"]           = bpp[vid["pix_fmt"]]
  vid["bytes_per_pix"] = int(vid["bpp"] / 8)

  # set RS to "bytes_per_pixel" times the width of the video
  # each pixel contains "bpp" bits of data, so each line "width" x "bytes_per_pixel"
  # this RS "hack" will make it possible to stream the data line by line
  RS = ".{" vid["width"] * vid["bytes_per_pix"] "}"
}

{
  # with our RS "hack", RT contains our line data
  split(RT, data, "")

  # start at first byte of the line
  byte = 1
  line = ""

  ## rgb8
  if (vid["pix_fmt"] == "rgb8") {
    for (x=0; x<vid["width"]; x++) {
      rgb = ORD[data[byte]]
      line = line " " sprintf("#%02X%02X%02X", int(and(rgb,0xE0) / 0xE0 * 0xFF), int(and(rgb,0x1C) / 0x1C * 0xFF), int(and(rgb, 0x03) / 0x03 * 0xFF) )
      byte += vid["bytes_per_pix"]
    }
  }

  ## rgb565
  if (vid["pix_fmt"] == "rgb565") {
    for (x=0; x<vid["width"]; x++) {
      rgb = ORD[data[byte]] + ORD[data[byte+1]] * 256
      line = line " " sprintf("#%02X%02X%02X", int(and(rgb,0xF800) / 0xF800 * 0xFF), int(and(rgb,0x07E0) / 0x07E0 * 0xFF), int(and(rgb, 0x1F) / 0x1F * 0xFF) )
      byte += vid["bytes_per_pix"]
    }
  }

  ## rgb24
  if (vid["pix_fmt"] == "rgb24") {
    for (x=0; x<vid["width"]; x++) {
      line = line " " sprintf("#%02X%02X%02X", ORD[data[byte]], ORD[data[byte+1]], ORD[data[byte+2]])
      byte += vid["bytes_per_pix"]
    }
  }

  # output processed data back for main thread
  printf("%s\n", substr(line,2))
  fflush()
}

