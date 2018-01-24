{{
        File:     game.spin
        Author:   Connor Spangler
        Date:     11/3/2017
        Version:  2.0
        Description: 
                  This file contains the PASM code defining a test arcade game
}}

CON
  ' Clock settings
  _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
  _xinfreq = 5_000_000          ' 5 MHz clock for x16 = 80 MHz

OBJ
  vga_display   : "vga_display" ' Import VGA display system
  
VAR
  ' Video resource pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system
  long  video_buffer_base_      ' Registers in Main RAM containing the scanline buffer

PUB main
  cur_scanline_base_ := @cur_scanline                   ' Point current scanline to current scanline
  video_buffer_base_ := @video_buffer                   ' Point video buffer to base of video buffer                        
                           
  vga_display.start(@cur_scanline_base_)                ' Start graphics engine
      
DAT
cur_scanline  long      0       ' Current scanline being rendered
video_buffer  long      0[80]   ' Buffer of 320 pixels (one scanline, 80 longs of 4 8-bit pixels)
