
function min(a, b) { return (a < b) ? a : b }
function max(a, b) { return (a > b) ? a : b }
function clip(a, b, c) { return min(max(a,b), c) }

function yuv2rgb(y, u, v,   c, d, e, r, g, b) {
  c = y - 16
  d = u - 128
  e = v - 128

  r = clip( (1.164383 * c)                  + (1.596027 * e) , 0, 255 )
  g = clip( (1.164383 * c) - (0.391762 * d) - (0.812968 * e), 0, 255 )
  b = clip( (1.164383 * c) + (2.017232 * d)                 , 0, 255 )

  return sprintf("%d;%d;%d", r, g, b)
}

function decode(vid, data,    byte, linepos, x, rgb)
{
  byte = 1
  linepos = vid["scanline"] * vid["width"]

  if (vid["pix_fmt"] == "rgb24") 
  {
    for (x=0; x<vid["width"]; x++)
    {
      vid[linepos+x] = sprintf("%d;%d;%d", ORD[data[byte]], ORD[data[byte+1]], ORD[data[byte+2]])
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

  if (vid["pix_fmt"] == "rgb8")
  {
    for (x=0; x<vid["width"]; x++)
    {
      rgb = ORD[data[byte]]
      vid[linepos+x] = sprintf("%d;%d;%d", and(rgb,0xE0) / 0xE0 * 0xFF, and(rgb,0x1C) / 0x1C * 0xFF, and(rgb, 0x03) / 0x03 * 0xFF)
      byte += vid["bytes_per_pix"]
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

}

