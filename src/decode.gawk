#!/usr/bin/gawk -f
@include "src/ord.gawk"
@include "src/yuv.gawk"

function decode(vid, data,    byte, linepos, x, rgb)
{
  byte = 1
  linepos = vid["scanline"] * vid["width"]

  if (vid["pix_fmt"] == "gray")
  {
    for (x=0; x<width; x++)
    {
      gray = ORD[data[byte]]
      vid[linepos+x] = sprintf("%d;%d;%d", gray, gray, gray)
      byte++
    }
  }

  if (vid["pix_fmt"] == "rgb8")
  {
    for (x=0; x<vid["width"]; x++)
    {
      rgb = ORD[data[byte]]
      vid[linepos+x] = sprintf("%d;%d;%d", and(rgb,0xE0) / 0xE0 * 0xFF, and(rgb,0x1C) / 0x1C * 0xFF, and(rgb, 0x03) / 0x03 * 0xFF)
      byte += vid["bytes_per_pix"]
    }
  }

  if (vid["pix_fmt"] == "rgb565")
  {
    for (x=0; x<vid["width"]; x++)
    {
      rgb = ORD[data[byte]] + ORD[data[byte+1]] * 256
      vid[linepos+x] = sprintf("%d;%d;%d", and(rgb,0xF800) / 0xF800 * 0xFF, and(rgb,0x07E0) / 0x07E0 * 0xFF, and(rgb, 0x1F) / 0x1F * 0xFF)
      byte += vid["bytes_per_pix"]
    }
  }

  if (vid["pix_fmt"] == "rgb24")
  {
    for (x=0; x<vid["width"]; x++)
    {
      vid[linepos+x] = sprintf("%d;%d;%d", ORD[data[byte]], ORD[data[byte+1]], ORD[data[byte+2]])
      byte += vid["bytes_per_pix"]
    }
  }

  if (vid["pix_fmt"] == "uyvy422")
  {
    for (x=0; x<width; x+=2)
    {
      u  = ORD[data[byte]]
      y1 = ORD[data[byte+1]]
      v  = ORD[data[byte+2]]
      y2 = ORD[data[byte+3]]

      vid[linepos+x]   = yuv2rgb(y1, u, v)
      vid[linepos+x+1] = yuv2rgb(y2, u, v)

      byte += 4
    }
  }

  if (vid["pix_fmt"] == "yuyv422")
  {
    for (x=0; x<width; x+=2)
    {
      y1 = ORD[data[byte]]
      u  = ORD[data[byte+1]]
      y2 = ORD[data[byte+2]]
      v  = ORD[data[byte+3]]

      vid[linepos+x]   = yuv2rgb(y1, u, v)
      vid[linepos+x+1] = yuv2rgb(y2, u, v)

      byte += 4
    }
  }

  if (vid["pix_fmt"] == "yvyu422")
  {
    for (x=0; x<width; x+=2)
    {
      y1 = ORD[data[byte]]
      v  = ORD[data[byte+1]]
      y2 = ORD[data[byte+2]]
      u  = ORD[data[byte+3]]

      vid[linepos+x]   = yuv2rgb(y1, u, v)
      vid[linepos+x+1] = yuv2rgb(y2, u, v)

      byte += 4
    }
  }

}

