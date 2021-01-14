@include "src/ord.gawk"
@include "src/yuv.gawk"

function dec_gray(data, byte,   gray) {  
  gray = ORD[data[byte]]
  return sprintf("%d;%d;%d", gray, gray, gray) 
}

function dec_rgb8(data, byte,   rgb) {  
  rgb = ORD[data[byte]]
  return sprintf("%d;%d;%d", and(rgb,0xE0) / 0xE0 * 0xFF, and(rgb,0x1C) / 0x1C * 0xFF, and(rgb,0x03) / 0x03 * 0xFF) 
}

function dec_bgr8(data, byte,   rgb) {  
  rgb = ORD[data[byte]]
  return sprintf("%d;%d;%d", and(rgb,0x03) / 0x03 * 0xFF, and(rgb,0x1C) / 0x1C * 0xFF, and(rgb,0xE0) / 0xE0 * 0xFF) 
}

function dec_rgb565(data, byte,   rgb) {  
  rgb = ORD[data[byte]] + ORD[data[byte+1]] * 256
  return sprintf("%d;%d;%d", and(rgb,0xF800) / 0xF800 * 0xFF, and(rgb,0x07E0) / 0x07E0 * 0xFF, and(rgb,0x1F) / 0x1F * 0xFF) 
}

function dec_bgr565(data, byte,   rgb) {  
  rgb = ORD[data[byte]] + ORD[data[byte+1]] * 256
  return sprintf("%d;%d;%d", and(rgb,0x1F) / 0x1F * 0xFF, and(rgb,0x07E0) / 0x07E0 * 0xFF, and(rgb,0xF800) / 0xF800 * 0xFF) 
}

function dec_rgb24(data, byte) { 
  return sprintf("%d;%d;%d", ORD[data[byte]], ORD[data[byte+1]], ORD[data[byte+2]])
}

function dec_bgr24(data, byte) { 
  return sprintf("%d;%d;%d", ORD[data[byte+2]], ORD[data[byte+1]], ORD[data[byte]])
}

function dec_argb(data, byte) { 
  return sprintf("%d;%d;%d", ORD[data[byte+1]], ORD[data[byte+2]], ORD[data[byte+3]])
}

function dec_abgr(data, byte) { 
  return sprintf("%d;%d;%d", ORD[data[byte+3]], ORD[data[byte+2]], ORD[data[byte+1]])
}

function dec_uyvy422(data, byte,    y1, u, y2, v) {
  u  = ORD[data[byte    ]]
  y1 = ORD[data[byte + 1]]
  v  = ORD[data[byte + 2]]
  y2 = ORD[data[byte + 3]]

  return yuv2rgb(y1, u, v) " " yuv2rgb(y2, u, v)
}

function dec_yuyv422(data, byte,    y1, u, y2, v) {
  y1 = ORD[data[byte    ]]
  u  = ORD[data[byte + 1]]
  y2 = ORD[data[byte + 2]]
  v  = ORD[data[byte + 3]]

  return yuv2rgb(y1, u, v) " " yuv2rgb(y2, u, v)
}

function dec_yvyu422(data, byte,    y1, u, y2, v) {
  y1 = ORD[data[byte    ]]
  v  = ORD[data[byte + 1]]
  y2 = ORD[data[byte + 2]]
  u  = ORD[data[byte + 3]]

  return yuv2rgb(y1, u, v) " " yuv2rgb(y2, u, v)
}

