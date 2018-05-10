{{
        File:     txrx.spin
        Author:   Connor Spangler
        Date:     5/9/2018
        Version:  1.0
        Description: 
                  This file contains the PASM code defining a test transmission routine
}}

CON
  ' Clock settings
  _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
  _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

OBJ
  vga_rx        : "vga_rx"      ' Import graphics reception system
  serial        : "FullDuplexSerial"

PUB main | time, indx
  serial.Start(31, 30, %0000, 57600)
  waitcnt(cnt + (1 * clkfreq))

  vga_rx.start(@output)
  indx := 0
  time := cnt

  repeat
    waitcnt(time += (clkfreq/60))
    serial.Hex(long[@output][indx], 8)
    serial.Tx($0D)
    indx++
    if indx == ((40*30*2)+(32*16)*2+(64*4))/4
      indx := 0

DAT

output        long      0[((40*30*2)+(32*16)*2+(64*4))/4]