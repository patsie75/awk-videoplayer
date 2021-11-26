#/usr/bin/gawk -f

## global vars: now, prev

function delay(target,    skip, onesec, i) {
  skip = 0
  onesec = 0
  now = timex()

  # init sliding window
  if ( !(0 in window) )
    for (i=0; i<(target-1); i++)
      window[i] = 1/target

  # too slow, return number of frames to skip
  if ( (now-prev) > (1/target) )
    skip = int( (now-prev) / (1/target) )
  else {
    # calculate sliding FPS window
    for (i=1; i<target; i++)
      onesec += window[i]

    # do delay
    while ( onesec + (now-prev) < 1 ) {
      system("sleep 0.005")
      now = timex()
    }
  }

  # update sliding FPS window
  for (i=0; i<(target-1); i++)
    window[i] = window[i+1]
  window[target-1] = (now - prev)

  prev = now

  return skip
}

