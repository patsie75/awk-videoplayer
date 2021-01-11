function min(a, b)     { return (a < b) ? a : b }
function max(a, b)     { return (a > b) ? a : b }
function clip(a, b, c) { return min(max(a,b), c) }

function yuv2rgb(y, u, v,    c, d, e, r, g, b) {
  c = (y - 16) * 1.164383
  d = u - 128
  e = v - 128

  r = clip( c                  + (1.596027 * e), 0, 255 )
  g = clip( c - (0.391762 * d) - (0.812968 * e), 0, 255 )
  b = clip( c + (2.017232 * d)                 , 0, 255 )

  return sprintf("%d;%d;%d", r, g, b)
}
