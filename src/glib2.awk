#!/usr/bin/mawk -f

@load "time"

function maxa(arr,   i, val, idx) { for (i in arr) if (arr[i] > val) { idx = i; val = arr[i] }; return idx }

function drawhi(src, xpos,ypos,     w,h, x,y, pix, d, avgp, maxavgp, i, fg,bg, group,group0,group1, maxval,maxindx, line, screen) {
  w = src["width"]
  h = src["height"]

  # position of zero means center
  if (xpos == 0) xpos = int((terminal["width"] - w/2) / 2)+1
  if (ypos == 0) ypos = int((terminal["height"] - h/2) / 2)+2

  # negative position means right aligned
  if (xpos < 0) xpos = (terminal["width"] - w/2 + (xpos+1))
  if (ypos < 0) ypos = (terminal["height"] - h/2 + (ypos+1))

ss = gettimeofday()
  for (y=0; y<h; y+=2) {
sss = gettimeofday()
    line = sprintf("\033[%0d;%0dH", ypos+(y/2), xpos)

    for (x=0; x<w; x+=2) {
s = gettimeofday()
      pix[1] = src[x+0,y+0]
      pix[2] = src[x+1,y+0]
      pix[3] = src[x+0,y+1]
      pix[4] = src[x+1,y+1]

      # draw left half of screen lo-res
if (mode == "mixed") {
      if (x < (w/2)) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[3], hires["1100"])
        continue
      }
}
      
time[0] += (t=gettimeofday()) - s; s=t

      # four same colors
      if ((pix[1] == pix[2]) && (pix[2] == pix[3]) && (pix[3] == pix[4])) {
        line = line sprintf("\033[48;2;%sm%s", pix[1], hires["0000"])
#        line = line sprintf("\033[0m%s", hires["1111"])
        same["four"]++
        continue
      }

      # three+one same colors
      if ((pix[1] == pix[2]) && (pix[2] == pix[3])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[4], hires["1110"])
#        line = line sprintf("\033[0;32m%s", hires["1110"])
        same["three"]++
        continue
      }
      if ((pix[1] == pix[2]) && (pix[2] == pix[4])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[3], hires["1101"])
#        line = line sprintf("\033[0;32m%s", hires["1101"])
        same["three"]++
        continue
      }
      if ((pix[1] == pix[3]) && (pix[3] == pix[4])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[2], hires["1011"])
#        line = line sprintf("\033[0;32m%s", hires["1011"])
        same["three"]++
        continue
      }
      if ((pix[2] == pix[3]) && (pix[3] == pix[4])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[2], pix[1], hires["0111"])
#        line = line sprintf("\033[0;32m%s", hires["0111"])
        same["three"]++
        continue
      }

      # two same colors
      if ((pix[1] == pix[2]) && (pix[3] == pix[4])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[3], hires["1100"])
#        line = line sprintf("\033[0;31m%s", hires["1100"])
        same["two"]++
        continue
      }
      if (pix[1] == pix[2]) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], rgbmix2(pix[3], pix[4]), hires["1100"])
#        line = line sprintf("\033[0;31m%s", hires["1100"])
        same["twotwo"]++
        continue
      }
      if (pix[3] == pix[4]) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[3], rgbmix2(pix[1], pix[2]), hires["0011"])
#        line = line sprintf("\033[0;31m%s", hires["0011"])
        same["twotwo"]++
        continue
      }

      if ((pix[1] == pix[3]) && (pix[2] == pix[4])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[2], hires["1010"])
#        line = line sprintf("\033[0;33m%s", hires["1010"])
        same["two"]++
        continue
      }
      if (pix[1] == pix[3]) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], rgbmix2(pix[2], pix[4]), hires["1010"])
#        line = line sprintf("\033[0;31m%s", hires["1010"])
        same["twotwo"]++
        continue
      }
      if (pix[2] == pix[4]) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[2], rgbmix2(pix[1], pix[3]), hires["0101"])
#        line = line sprintf("\033[0;31m%s", hires["0101"])
        same["twotwo"]++
        continue
      }

      if ((pix[1] == pix[4]) && (pix[2] == pix[3])) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[2], hires["1001"])
#        line = line sprintf("\033[0;33m%s", hires["1001"])
        same["two"]++
        continue
      }
      if (pix[1] == pix[4]) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], rgbmix2(pix[2], pix[3]), hires["1001"])
#        line = line sprintf("\033[0;31m%s", hires["1001"])
        same["twotwo"]++
        continue
      }
      if (pix[2] == pix[3]) {
        line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[2], rgbmix2(pix[1], pix[4]), hires["0110"])
#        line = line sprintf("\033[0;31m%s", hires["0110"])
        same["twotwo"]++
        continue
      }

time[1] += (t=gettimeofday()) - s; s=t

same["rest"]++
#     line = line sprintf("\033[0;34m%s", hires["1111"])
#     line = line sprintf("\033[38;2;%s;48;2;%sm%s", pix[1], pix[3], hires["1100"])
#     line = line sprintf("\033[38;2;%s;48;2;%sm%s", rgbmix2(pix[1], pix[3]), rgbmix2(pix[2], pix[4]), hires["1010"])
#     line = line sprintf("\033[38;2;%s;48;2;%sm%s", rgbmix2(pix[1], pix[2]), rgbmix2(pix[3], pix[4]), hires["1100"])
#     continue

      # convert RGB to brightness value
      for (i=1; i<=4; i++)
        l[i] = rgb2lum(pix[i])

time[2] += (t=gettimeofday()) - s; s=t

      # calculate brightness distance between pixels
      d[1,2] = d[2,1] = (l[2] - l[1])^2
      d[1,3] = d[3,1] = (l[3] - l[1])^2
      d[1,4] = d[4,1] = (l[4] - l[1])^2
      d[2,3] = d[3,2] = (l[3] - l[2])^2
      d[2,4] = d[4,2] = (l[4] - l[2])^2
      d[3,4] = d[4,3] = (l[4] - l[3])^2

      # average brightness distance to other pixels
      avgp[1] = (d[1,2] + d[1,3] + d[1,4]) / 3
      avgp[2] = (d[2,1] + d[2,3] + d[2,4]) / 3
      avgp[3] = (d[3,1] + d[3,2] + d[3,4]) / 3
      avgp[4] = (d[4,1] + d[4,2] + d[4,3]) / 3

      delete group0
      delete group1

time[3] += (t=gettimeofday()) - s; s=t

      ## pixel farthest from average is group0
      group0[1] = maxa(avgp) 
      group[group0[1]] = 0

      ## pixel farthest from group0 is group1
      maxval = -1
      maxidx = -1
      for (i=1; i<=4; i++) {
        if (i != group0[1]) {
          if (d[group0[1],i] > maxval) {
            maxval = d[group0[1],i]
            maxidx = i
          }
          group[maxidx] = 1
          group1[1] = maxidx
        }
      }

time[4] += (t=gettimeofday()) - s; s=t

      ## remaining pixels group closest to either group0 or 1
      for (i=1; i<=4; i++) {
        if ((i != group0[1]) && (i != group1[1])) {
          if (d[group0[1],i] > d[group1[1],i]) {
            group[i] = 1
            group1[length(group1)+1] = i
          } else {
            group[i] = 0
            group0[length(group0)+1] = i
          }
        }
      }

time[5] += (t=gettimeofday()) - s; s=t

      ## mix fg/bg colors from all pixels in group
      l0 = length(group0)

      if (l0 == 1) {
        fg = rgbmix3(pix[group1[1]], pix[group1[2]], pix[group1[3]])
        bg = pix[group0[1]]
      }
      if (l0 == 2) {
        fg = rgbmix2(pix[group1[1]], pix[group1[2]])
        bg = rgbmix2(pix[group0[1]], pix[group0[2]])
      }

time[6] += (t=gettimeofday()) - s; s=t

      line = line sprintf("\033[38;2;%s;48;2;%sm%s", fg, bg, hires[group[1] group[2] group[3] group[4]])
      #line = line sprintf("%s", hires[group[1] group[2] group[3] group[4]])

time[7] += (t=gettimeofday()) - s; s=t
    }
    screen = screen line "\033[0m"
time["line"] += gettimeofday() - sss
  }

  printf("%s", screen)

time["total"] += gettimeofday() - ss
}

# mix 2 colors
function rgbmix2(p1, p2,     rgb) {
  split(p1";"p2, rgb, ";")
  return sprintf("%d;%d;%d", (rgb[1]+rgb[4])/2, (rgb[2]+rgb[5])/2, (rgb[3]+rgb[6])/2)
}

# mix 3 colors
function rgbmix3(p1, p2, p3,     rgb) {
  split(p1";"p2";"p3, rgb, ";")
  return sprintf("%d;%d;%d", (rgb[1]+rgb[4]+rgb[7])/3, (rgb[2]+rgb[5]+rgb[8])/3, (rgb[3]+rgb[6]+rgb[9])/3)
}

# convert RGB pixel into brightless value
function rgb2lum(p,    rgb) {
  split(p, rgb, ";")
  return rgb[1] * 0.299 + rgb[2] * 0.587 + rgb[3] * 0.114
}

BEGIN {
  # high resolution pixels
  hires["0000"] = " "
  hires["0001"] = "▗"
  hires["0010"] = "▖"
  hires["0011"] = "▄"
  hires["0100"] = "▝"
  hires["0101"] = "▐"
  hires["0110"] = "▞"
  hires["0111"] = "▟"
  hires["1000"] = "▘"
  hires["1001"] = "▚"
  hires["1010"] = "▌"
  hires["1011"] = "▙"
  hires["1100"] = "▀"
  hires["1101"] = "▜"
  hires["1110"] = "▛"
  hires["1111"] = "█"
}
