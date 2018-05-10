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
  vga_rx        : "vga_rx"      ' Import graphics reception system
  
VAR
  ' Video system pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system

PUB main | cont,temp,temps,x,y
  ' Start video system
  vga_tx.start(@testing)                          ' Start graphics transmission

DAT
testing       long      %10101010_10101010_10101010_10101010[((40*30*2)+(32*16)*2+(64*4))/4]
