@include "src/ord.gawk"
@include "src/yuv.gawk"

function dec_gray(data, byte, offset,    gray) {  
  gray = ORD[data[byte]]
  return sprintf("%d;%d;%d", gray, gray, gray) 
}

function dec_rgb8(data, byte, offset,    rgb) {  
  rgb = ORD[data[byte]]
  return sprintf("%d;%d;%d", and(rgb,0xE0) / 0xE0 * 0xFF, and(rgb,0x1C) / 0x1C * 0xFF, and(rgb,0x03) / 0x03 * 0xFF) 
}

function dec_bgr8(data, byte, offset,    rgb) {  
  rgb = ORD[data[byte]]
  return sprintf("%d;%d;%d", and(rgb,0x07) / 0x07 * 0xFF, and(rgb,0x38) / 0x38 * 0xFF, and(rgb,0xC0) / 0xC0 * 0xFF) 
}

function dec_rgb565(data, byte, offset,    rgb) {  
  rgb = ORD[data[byte]] + ORD[data[byte+1]] * 256
  return sprintf("%d;%d;%d", and(rgb,0xF800) / 0xF800 * 0xFF, and(rgb,0x07E0) / 0x07E0 * 0xFF, and(rgb,0x1F) / 0x1F * 0xFF) 
}

function dec_bgr565(data, byte, offset,    rgb) {  
  rgb = ORD[data[byte]] + ORD[data[byte+1]] * 256
  return sprintf("%d;%d;%d", and(rgb,0x1F) / 0x1F * 0xFF, and(rgb,0x07E0) / 0x07E0 * 0xFF, and(rgb,0xF800) / 0xF800 * 0xFF) 
}

function dec_rgb24(data, byte, offset) { 
  return sprintf("%d;%d;%d", ORD[data[byte + offset["r"]]], ORD[data[byte + offset["g"]]], ORD[data[byte + offset["b"]]])
}

function dec_yuyv422(data, byte, offset,     y1, u, y2, v) {
  y1 = ORD[data[byte + offset["y1"] ]]
   u = ORD[data[byte + offset["u"]  ]]
  y2 = ORD[data[byte + offset["y2"] ]]
   v = ORD[data[byte + offset["v"]  ]]

  return yuv2rgb(y1, u, v) " " yuv2rgb(y2, u, v)
}

