#!/usr/bin/gawk -f

## sort functions used in PROCINFO["sorted_in"] for array printing
## sort based on key/index
function cmp_idx(i1, v1, i2, v2,   n1, n2) {
  n1 = i1 + 0
  n2 = i2 + 0
#  if (n1 == i1) return (n2 == i2) ? (n1 - n2) : -1
#  else if (n2 == i2) return 1
  return (i1 < i2) ? -1 : (i1 != i2)
}

## sort based on value
function cmp_val(i1, v1, i2, v2,   n1, n2) {
  n1 = v1 + 0
  n2 = v2 + 0
#  if (n1 == v1) return (n2 == v2) ? (n1 - n2) : -1
#  else if (n2 == v2) return 1
  return (v1 < v2) ? -1 : (v1 != v2)
}

function timex() {
  getline < "/proc/uptime"
  close("/proc/uptime")
  return($1)
}

function fps(f,   now, i) {
  now = timex()

  i = (1/f)-(now-glib["fps","last"])
  if (i > 0)
    system(sprintf("sleep %0.2f", i))

  glib["fps","last"] = timex()
}

BEGIN {
  PROCINFO["sorted_in"] = "cmp_val"

  color["black"] = 0
  color["red"] = 1
  color["green"] = 2
  color["yellow"] = 3
  color["blue"] = 4
  color["magenta"] = 5
  color["cyan"] = 6
  color["white"] = 7

  color["brightblack"] = 8
  color["brightred"] = 9
  color["brightgreen"] = 10
  color["brightyellow"] = 11
  color["brightblue"] = 12
  color["brightmagenta"] = 13
  color["brightcyan"] = 14
  color["brightwhite"] = 15

  "tput cols"  | getline terminal["width"]
  "tput lines" | getline terminal["height"]

  positive["on"] = 1
  positive["true"] = 1
  positive["yes"] = 1

  negative["off"] = 1
  negative["false"] = 1
  negative["no"] = 1

  glib["transparent"] = color["black"]

  glib["pi"] = atan2(0, -1)
  for (i=0; i<360; i++) glib["sin",i] = sin((glib["pi"]*i)/180) * 255
}

# initialize a graphic buffer
function init(dst, w,h, x,y, dx,dy) {
  dst["width"] = w
  dst["height"] = h

  dst["x"] = x
  dst["y"] = y

  dst["dx"] = dx
  dst["dy"] = dy
}

# turn cursor on or off
function cursor(state) {
  if (state in negative) printf("\033[?25l")
  else if (state in positive) printf("\033[?25h")
}

# clear the terminal
function clrscr() {
  printf("\033[2J")
}

# set default transparent value
function transparent(col) {
  config["transparent"] = col ? col : color["black"]
}

# reset graphic buffer to single color (default black)
function clear(dst, col,   i, size) {
  size = dst["width"] * dst["height"]
  col = col ? col : color["black"]

  for (i=0; i<size; i++)
    dst[i] = col
}

# horizontal flip graphic buffer
function hflip(src, dst,   w,h, x,y, sz,i) {
  w = src["width"]
  h = src["height"]
  sz = h*w

  # hflip src into data
  for (y=0; y<h; y++)
    for (x=0; x<w; x++)
      data[(y*w)+x] = src[(h-1-y)*w+x]

  # copy back data to dst
  for (i=0; i<sz; i++) src[i] = data[i]
  delete data
}

# vertical flip graphic buffer
function vflip(src, dst,   w,h, x,y, sz,i) {
  w = src["width"]
  h = src["height"]
  sz = h*w

  # vflip src into data
  for (y=0; y<h; y++)
    for (x=0; x<w; x++)
      data[(y*w)+x] = src[y*w+(w-1-x)]

  # copy back data to dst
  for (i=0; i<sz; i++) src[i] = data[i]
  delete data
}

# draw graphic buffer to terminal
function draw(scr, xpos, ypos, cls,   screen, line, x,y, w,h, fg,bg, fgprev,bgprev, y_mul_w, y1_mul_w) {
  w = scr["width"]
  h = scr["height"]

  fgprev = bgprev = 0

  # position of zero means center
  if (xpos == 0) xpos = int((terminal["width"] - w) / 2)+1
  if (ypos == 0) ypos = int((terminal["height"] - h/2) / 2)+1

  # negative position means right aligned
  if (xpos < 0) xpos = (terminal["width"] - w + (xpos+1))
  if (ypos < 0) ypos = (terminal["height"] - h/2 + (ypos+1))

  screen = cls ? "\033[2J" : ""
  for (y=0; y<h; y+=2) {
    y_mul_w = y*w
    y1_mul_w = (y+1)*w

    # set cursor position
    line = sprintf("\033[%0d;%0dH", ypos+(y/2), xpos)

    for (x=0; x<w; x++) {
      if (substr(scr[y_mul_w+x],1,1) == "#") {
        #fg = "38;2;" int("0x"substr(scr[y_mul_w+x],2,2)) ";" int("0x"substr(scr[y_mul_w+x],4,2)) ";" int("0x"substr(scr[y_mul_w+x],6,2))
        #fg = "38;2;" strtonum("0x"substr(scr[y_mul_w+x],2,2)) ";" strtonum("0x"substr(scr[y_mul_w+x],4,2)) ";" strtonum("0x"substr(scr[y_mul_w+x],6,2))
        val = strtonum("0x"substr(scr[y_mul_w+x],2))
        fg = "38;2;" rshift(and(val,0xFF0000),16) ";" rshift(and(val,0x00FF00),8) ";" and(val,0xFF)
      } else
        fg = (scr[y_mul_w+x] > 7) ? scr[y_mul_w+x] + 82 : scr[y_mul_w+x] + 30

      # for odd-height pictures, add black (bg) pixel at bottom
      if (substr(scr[y1_mul_w+x],1,1) == "#") {
        #bg = (y%2) ? 40 : "48;2;" int("0x"substr(scr[y1_mul_w+x],2,2)) ";" int("0x"substr(scr[y1_mul_w+x],4,2)) ";" int("0x"substr(scr[y1_mul_w+x],6,2))
        #bg = (y%2) ? 40 : "48;2;" strtonum("0x"substr(scr[y1_mul_w+x],2,2)) ";" strtonum("0x"substr(scr[y1_mul_w+x],4,2)) ";" strtonum("0x"substr(scr[y1_mul_w+x],6,2))
        #bg = "48;2;" strtonum("0x"substr(scr[y1_mul_w+x],2,2)) ";" strtonum("0x"substr(scr[y1_mul_w+x],4,2)) ";" strtonum("0x"substr(scr[y1_mul_w+x],6,2))
        val = strtonum("0x"substr(scr[y1_mul_w+x],2))
        bg = "48;2;" rshift(and(val,0xFF0000),16) ";" rshift(and(val,0x00FF00),8) ";" and(val,0xFF)
      } else
        bg = (y%2) ? 40 : (scr[y1_mul_w+x] > 7) ? scr[y1_mul_w+x] + 92 : scr[y1_mul_w+x] + 40

      # set forground/background colors and draw pixel(s)
      if ((fg != fgprev) || (bg != bgprev)) {
        line = line "\033[" fg ";" bg "m▀"
        fgprev = fg
        bgprev = bg
      } else line = line "▀"
    }

    screen = screen line
  }
  # draw screen to terminal and reset color
  printf("%s\033[0m", screen)
}

# copy graphic buffer to another graphic buffer (with transparency, and edge clipping)
# usage: dst, src, [dstx, dsty, [srcx, srcy, [srcw, srch, [transparent] ] ] ]
function copy(dst, src, dstx, dsty, srcx, srcy, srcw, srch, transp,   dx,dy, dw,dh, sx,sy, sw,sh, x,y, w,h, t, pix, sw_mul_y, ydy_mul_dw, xdx) {
  dw = dst["width"]
  dh = dst["height"]
  sw = src["width"]
  sh = src["height"]

  if (("animation","x") in src) {
    dx = int(src["x"])
    dy = int(src["y"])
    sx = int(src["animation","x"])
    sy = int(src["animation","y"])
    w = src["animation","width"]
    h = src["animation","height"]
  } else {
    dx = int(src["x"])
    dy = int(src["y"])
    sx = 0
    sy = 0
    w = src["width"]
    h = src["height"]
  }
  if (length(dstx)) dx = dstx
  if (length(dsty)) dy = dsty
  if (length(srcx)) sx = srcx
  if (length(srcy)) sy = srcy
  if (length(srcw)) w = ((srcw > 0) && (srcw < src["width"])) ? srcw : w
  if (length(srch)) h = ((srch > 0) && (srch < src["height"])) ? srch : h

  if (sprintf("%s", transp)) t = transp
  else if ("transparent" in src) t = src["transparent"]
  else if ("transparent" in glib) t = glib["transparent"]

  for (y=sy; y<(sy+h); y++) {
    # clip image off top/bottom
    if ((dy + y) >= dh) break
    if ((dy + y) < 0) continue
    sw_mul_y = sw * y
    ydy_mul_dw = (y - sy + dy) * dw
    for (x=sx; x<(sx+w); x++) {
      xdx = x - sx + dx

      # clip image on left/right
      if (xdx >= dw) break
      if (xdx < 0) continue

      # draw non-transparent pixel or else background
      pix = src[sw_mul_y + x]
      dst[ydy_mul_dw + xdx] = ((pix == t) || (pix == "None")) ? dst[ydy_mul_dw + xdx] : pix
    }
  }
}

function chksize(width, height) {
  if ((terminal["width"] < width) || (terminal["height"] < int((height+1)/2)) ) {
    printf("Your terminal doesn't have enough resolution (%dx%d < %dx%d).\nPlease choose a smaller font or resize your terminal\n", terminal["width"], terminal["height"], width, (height+1)/2)
    exit(1)
  }
}

function centerx(src, dst) {
  if (("animation","width") in src) return( int((dst["width"] - src["animation","width"]) / 2) )
  else return( int((dst["width"] - src["width"]) / 2) )
}

function centery(src, dst) {
  if (("animation","height") in src) return( int((dst["height"] - src["animation","height"]) / 2) )
  else return( int((dst["height"] - src["height"]) / 2) )
}

function move(src) {
  src["x"] += src["dx"]
  src["y"] += src["dy"]
}


## spr.last		(timestamp.msec)
## spr.interval		(sec.msec)
## spr.type		("row", "col")
## spr.loop		("loop", "bounce")
## spr.width		(sprite width)
## spr.height		(sprite height)
## spr.x		(x-pos of current sprite in map)
## spr.y		(y pos of current sprite in map)
## spr.dx		(next row frame delta)
## spr.dy		(next col frame delta)
function animate(src,   now) {
  if (("animation","x") in src) {
    now = timex()

    if ( (now - src["animation","last"]) >= src["animation","interval"] ) {
      src["animation","last"] = now

      if (src["animation","type"] == "row") {
          src["animation","x"] += (src["animation","dx"] * src["animation","width"])

          if (src["animation","x"] > (src["width"] - src["animation","width"])) {
            if (src["animation","loop"] == "loop") src["animation","x"] = 0
            if (src["animation","loop"] == "bounce") { src["animation","dx"] *= -1; src["animation","x"] += (src["animation","dx"] * src["animation","width"]) }
          }

          if (src["animation","x"] < 0) {
            if (src["animation","loop"] == "loop") src["animation","x"] = src["width"] - src["animation","width"]
            if (src["animation","loop"] == "bounce") { src["animation","dx"] *= -1; src["animation","x"] = 0 }
          }

          #printf("type: %s, loop: %s, x: %04d, y: %04d\n", src["animation","type"], src["animation","loop"], src["animation","x"], src["animation","y"])
      }

      if (src["animation","type"] == "col") {
          src["animation","y"] += (src["animation","dy"] * src["animation","height"])

          if (src["animation","y"] > (src["height"] - src["animation","height"])) {
            if (src["animation","loop"] == "loop") src["animation","y"] = 0
            if (src["animation","loop"] == "bounce") { src["animation","dy"] *= -1; src["animation","y"] += (src["animation","dy"] * src["animation","height"]) }
          }

          if (src["animation","y"] < 0) {
            if (src["animation","loop"] == "loop") src["animation","y"] = src["height"] - src["animation","height"]
            if (src["animation","loop"] == "bounce") { src["animation","dy"] *= -1; src["animation","y"] = 0 }
          }

          printf("type: %s, loop: %s, x: %04d, y: %04d\n", src["animation","type"], src["animation","loop"], src["animation","x"], src["animation","y"])
      }

      #  case "rowcol":
      #  case "colrow":
      #    break
      #}
    }
  }
}

# font.chars = character list of src-font
function write(dst, src, dstx,dsty, msg,   i, c, l, fw,fh) {
  l = length(msg)
  fw = int(src["width"] /  length(src["font","charset"]))
  fh = src["height"]

  for (i=0; i<l; i++) {
    chr = substr(msg, i+1, 1)
    idx = index(src["font","charset"], chr)-1
    if (idx >= 0)
      copy(dst, src, dstx+(i*fw),dsty, (idx*fw),0, fw,fh)
  }
}


# load graphic from file
function load(dst, fname,   w, h, len, data, x, y) {
  # fetch data and determine width and height
  while ((getline < fname) > 0) {
    # skip comments and empty lines
    if ( ($1 ~ /^(#|;)/) || ($1 == "") ) continue
    len = length($0)
    w = (len > w) ? len : w
    data[h++] = $0
  }
  close(fname)

  dst["width"] = w
  dst["height"] = h

  for (y=0; y<h; y++) {
    for (x=0; x<w; x++) {
      # make sure data is in correct range/format
      #dst[(y*w)+x] = int("0x"substr(data[y], x+1, 1)) % 16
      dst[(y*w)+x] = strtonum("0x"substr(data[y], x+1, 1)) % 16
    }
  }

  delete data
}

# save graphic buffer to file
function save(src, fname,   w, h, x, y, col, line) {
  w = src["width"]
  h = src["height"]

  printf("# Created by awk-glib\n") >fname
  for (y=0; y<h; y++) {
    line = ""
    for (x=0; x<w; x++) {
      col = src[(y*w)+x]
      # convert black to space/" "
      if (col != color["black"]) line = line sprintf("%0X", col)
      else line = line " "
    }
    printf("%s\n", line) >>fname
  }
}

# load graphic from XPM2 file
function loadxpm2(dst, fname,   w,h, nrcolors,charsppx, col,color,data, i,pix) {
  # read header "! XPM2"
  if ( ((getline < fname) < 1) || ($0 != "! XPM2") ) { close(fname); return(0); }
#printf("loadxpm2(): XPM2 header found\n")

  # read picture meta info "<width> <height> <nrcolors> <chars-per-pixel>"
  if ( ((getline < fname) < 1) || (NF != 4) ) { close(fname); return(0); }
  w = int($1)
  h = int($2)
  nrcolors = int($3)
  charsppx = int($4)
#printf("loadxpm2(): w=%d h=%d cols=%d cpp=%d\n", w, h, nrcolors, charsppx)

  # read colormap "<chars> c #<RR><GG><BB>"
  for (i=0; i<nrcolors; i++) {
    if ((getline < fname) < 1) { close(fname); return(0); }
    chr = substr($0, 1, charsppx)
    col = substr($0, charsppx+4)
    color[chr] = col
    #printf("loadxpm2(): %2d: %s c %s\n", i, chr, col)
  }
#printf("loadxpm2(): Read %s/%s colors\n", i, nrcolors)

  # read pixel data
  data = ""
  while ( (length(data) / charsppx) < (w*h)) {
    if ((getline < fname) < 1) {
      printf("loadxpm2(): EOF -- data: %s\n", data)
      printf("loadxpm2(): %d out of %d pixels read\n", (length(data) / charsppx), (w*h))
      close(fname)
      return(0)
    }
    data = data $0
  }
#printf("loadxpm2(): Read %d pixels\n", (w*h))
#printf("loadxpm2(): data: %s\n", data)

  # done reading
  close(fname)

  # convert data to graphic
  for (i=0; i<(h*w); i++) {
    pix = substr(data, (i*charsppx)+1, charsppx)
    if (!(pix in color)) {
      printf("Could not find color %s in color[]\n", pix)
      printf("data = \"%s\"\n", data)
      return(0)
    } else dst[i] = color[pix]
  }
  dst["width"] = w
  dst["height"] = h

  delete color
  return(1)
}

function dumpimg(src,   x,y) {
  printf("w=%d, h=%d, x=%d, y=%d, dx=%d, dy=%d\n", src["width"], src["height"], src["x"], src["y"], src["dx"], src["dy"])
  for (y=0; y<src["height"]; y++) {
    for (x=0; x<src["width"]; x++) {
      printf("%s,", src[y*src["width"]+x])
    }
    printf("\n")
  }
}

# save graphic buffer to XPM2 file
function savexpm2(src, fname,   w,h,sz, x,y, i,j,m,n, c,col, map, nrcolors, charsppx, charmap, line) {
  w = src["width"]
  h = src["height"]
  sz = w*h

  # color map characters
  charmap = "0123456789ABCEDFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

  # count nr of colors
  for (i=0; i<sz; i++)
    if ( !(src[i] in col) )
      col[src[i]] = nrcolors++
  #printf("savexpm2(): Found %d unique colors\n", nrcolors)

  # calculate the number of characters we need per pixel
  charsppx = 1
  while ( (length(charmap)^charsppx) < nrcolors) charsppx++
  #printf("savexpm2(): using %d characters per pixel\n", charsppx)

  i = 0
  for (c in col) {
    m = ""
    n = col[c]
    for (j=0; j<charsppx; j++) {
      m = substr(charmap, (n % length(charmap))+1, 1) m
      n /= length(charmap)
    }
    map[c] = m
  }

  # write header, meta and color data
  printf("! XPM2\n%d %d %d %d\n", w, h, nrcolors, charsppx) > fname

  for (m in map) 
    printf("%s c %s\n", map[m], m) >>fname

  # write pixel data
  for (y=0; y<h; y++) {
    line=""
    for (x=0; x<w; x++)
      line = line map[src[y*w+x]]
    printf("%s\n", line) >>fname
  }

  # close file
  close(fname)

  return(1)
}

