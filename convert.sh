#!/bin/bash

if [ $# -ge 2 ]; then
  #ffmpeg -t "${3:-10}" -i "$1" -vf scale=384:216 -vcodec rawvideo -f rawvideo -pix_fmt rgb565 "$2"
  ffmpeg -t "${3:-10}" -i "$1" -vf scale=192:108 -vcodec rawvideo -f rawvideo -pix_fmt rgb565 "$2"
  #ffmpeg -t "${3:-10}" -i "$1" -vf scale=192:108 -vcodec rawvideo -f rawvideo -pix_fmt rgb24 "$2"
else
  echo "Usage: $0 <infile> <outfile> [time]" >&2
  exit 1
fi

