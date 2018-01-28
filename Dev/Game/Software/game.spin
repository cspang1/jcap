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
  _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

OBJ
  vga_render    : "vga_render"  ' Import VGA display system
  vga_display   : "vga_display" ' Import VGA display system
  
VAR
  ' Video resource pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system
  long  video_buffer_base_      ' Registers in Main RAM containing the scanline buffer

PUB main
  cur_scanline_base_ := @cur_scanline                   ' Point current scanline to current scanline
  video_buffer_base_ := @video_buffer                   ' Point video buffer to base of video buffer                        

  vga_render.start(@cur_scanline_base_)                 ' Start renderer
  vga_display.start(@cur_scanline_base_)                ' Start display driver
      
DAT
cur_scanline  long      0                                                       ' Current scanline being rendered
video_buffer  long      %11000011_11000011_11000011_11000011[20]                ' Buffer of 320 pixels (one scanline, 80 longs of 4 8-bit pixels)
              long      %00110011_00110011_00110011_00110011[20]
              long      %00001111_00001111_00001111_00001111[20]
              long      %11111111_11111111_11111111_11111111[20]