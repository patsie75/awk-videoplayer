#/usr/bin/gawk -f

@load "time"

## global vars: now, prev

function delay(target,    skip, onesec, oneframe, i) {
  skip = 0
  onesec = 0
  oneframe = 1/target
  #now = timex()
  now = gettimeofday()

  # init sliding window
  if ( !(0 in window) )
    for (i=0; i<(target-1); i++)
      window[i] = oneframe

  # too slow, return number of frames to skip
  if ( (now-prev) > (oneframe) )
    skip = int( (now-prev) / (oneframe) )
  else {
    # calculate sliding FPS window
    for (i=1; i<target; i++)
      onesec += window[i]

    # do delay
    #while ( onesec + (now-prev) < 1 ) {
    while ( ((onesec + (now-prev)) < 1) && ((now-prev) < (oneframe*2)) ) {
      #system("sleep 0.005")
      sleep(0.0005)
      #now = timex()
      now = gettimeofday()
    }
  }

  # update sliding FPS window
  for (i=0; i<(target-1); i++)
    window[i] = window[i+1]
  window[target-1] = (now - prev)

  prev = now

  return skip
}

