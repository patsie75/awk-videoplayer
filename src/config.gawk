function load_cfg(cfg, file,    label, n, keyval)
{
  n = 0

  while ((getline < file) > 0) {
    ## have a [label] tag to init-style switch labels
    if (match($0, /^\[([^]]*)\]$/, l))
      label = l[1]

    ## skip comments and split key=value pairs
    if ( ($0 !~ /^ *(#|;)/) && (match($0, /([^=]+)=(.+)/, keyval) > 0) ) {
      ## strip leading/trailing spaces and doublequotes
      gsub(/^ *"?|"? *$/, "", keyval[1])
      gsub(/^ *"?|"? *$/, "", keyval[2])

#      if (tolower(keyval[1]) == "offset") {
#        n = split(keyval[2], arr, ",")
#        for (i=0; i<n; i++)
#          cfg[label]["offset"][arr[i+1]] = i
#        continue
#      } 

      cfg[label][tolower(keyval[1])] = keyval[2]
      n++
    }

  }

  close(file)
  return(n)
}
