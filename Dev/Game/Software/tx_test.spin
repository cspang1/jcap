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
  vga_tx        : "vga_tx"      ' Import graphics transmission system

PUB main | time, indx
  vga_tx.start(@input)
  time := cnt

  repeat
    waitcnt(time += (clkfreq/60))
    vga_tx.transmit

DAT

input         long      $ABCD_DCBA[((40*30*2)+(32*16)*2+(64*4))/4]