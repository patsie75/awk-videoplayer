#!/usr/bin/gawk -f

function timex() {
  getline < "/proc/uptime"
  close("/proc/uptime")
  return($1)
}

BEGIN {
  "tput cols"  | getline terminal["width"]
  "tput lines" | getline terminal["height"]

  positive["on"] = 1
  positive["true"] = 1
  positive["yes"] = 1

  negative["off"] = 1
  negative["false"] = 1
  negative["no"] = 1

  #pix = "▀"
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
  printf("\033[?25%c", (state in negative) ? "l" : "h")
}

# clear the terminal
function clrscr() {
  printf("\033[2J")
}

# reset graphic buffer to single color (default black)
function clear(dst, col,   i, size) {
  size = dst["width"] * dst["height"]
  col = col ? col : color["black"]

  for (i=0; i<size; i++)
    dst[i] = col
}

# draw graphic buffer to terminal
function draw(scr, xpos, ypos, cls,   screen, line, x,y, w,h, fg,bg, fgprev,bgprev, y0_mul_w, y1_mul_w) {
  w = scr["width"]
  h = scr["height"]

  fgprev = bgprev = -1

  # position of zero means center
  if (xpos == 0) xpos = int((terminal["width"] - w) / 2)+1
  if (ypos == 0) ypos = int((terminal["height"] - h/2) / 2)+1

  # negative position means right aligned
  if (xpos < 0) xpos = (terminal["width"] - w + (xpos+1))
  if (ypos < 0) ypos = (terminal["height"] - h/2 + (ypos+1))

  screen = cls ? "\033[2J" : ""
  for (y=0; y<h; y+=2) {
    y0_mul_w = y*w
    y1_mul_w = y0_mul_w + w

    # set cursor position
    line = sprintf("\033[%0d;%0dH", ypos+(y/2), xpos)

    for (x=0; x<w; x++) {
      fg = scr[y0_mul_w+x]
      bg = scr[y1_mul_w+x]

      if (fg != fgprev) {
        if (bg != bgprev) line = line "\033[38;2;" fg ";48;2;" bg "m▀"
        else line = line "\033[38;2;" fg "m▀"
      } else {
        if (bg != bgprev) line = line "\033[48;2;" bg "m▀"
        else line = line "▀"
      }

      fgprev = fg
      bgprev = bg
    }
    screen = screen line
  }

  # draw screen to terminal and reset color
  printf("%s\033[0m", screen)
}

