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
  serial        : "FullDuplexSerial"
  
VAR
  ' Video system pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system

PUB main | time
  serial.Start(31, 30, %0000, 57600)                    'requires 1 cog for operation
  waitcnt(cnt + (1 * clkfreq))                          'wait 1 second for the serial object to start

  ' Start video system
  vga_tx.start(@input)
  vga_rx.start(@output)
  time := cnt

  repeat
    waitcnt(time += (clkfreq/60))
    vga_tx.transmit
    serial.Str(LONG[@output][0])                                     'print a test string
    serial.Tx($0D)                                               'print a new line

DAT
input         long      $AAAA_AAAA[((40*30*2)+(32*16)*2+(64*4))/4]
output        long      0[((40*30*2)+(32*16)*2+(64*4))/4]
