## horizontal sync, call for each (scan)line update
function hsync(vid)
{
  vid["scanline"]++

  ## if current scanline is the height of the video
  if (vid["scanline"] == vid["height"])
  {
    # reset the scanline and increase the frame number
    vid["scanline"] = 0
    vid["frame"]++

    # increase framecount and update timer
    vid["framecnt"]++
    vid["now"] = timex()
    vid["time"] = sprintf("%02dh%02dm%04.1fs", (vid["now"]-vid["start"])/3600, ((vid["now"]-vid["start"])/60)%60, (vid["now"]-vid["start"])%60 )

    # update fps every 0.5 seconds
    if ( (vid["now"] - vid["then"]) >= 0.5 )
    {
      vid["curfps"] = vid["framecnt"] / (vid["now"] - vid["then"])
      vid["avgfps"] = vid["frame"] / (vid["now"] - vid["start"])
      vid["framecnt"] = 0
      vid["then"] = vid["now"]
    }
    return 1
  }
  return 0
}
