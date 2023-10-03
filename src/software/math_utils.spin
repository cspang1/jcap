pub sin(degree, range) : s | c,z,angle
  angle := (degree*91)~>2  ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*range)~>16     ' return sin = -range..+range