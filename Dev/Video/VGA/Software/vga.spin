 {{
        File:     vga.spin
        Author:   Connor Spangler
        Date:     06/09/2017
        Version:  1.1
        Description: 
                  This file contains the PASM code to drive a VGA signal via the Propeller
                  Cog Video Generator.
}}

CON
        _clkmode = xtal1 + pll16x                       ' Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        
VAR
  long  vga_dat       ' VGA data placeholder
  
PUB main
  cognew(@vga, @vga_dat)  ' Initialize cog running "vga" routine with reference to start of variable registers
  
DAT
vga           or        dira,   vgapin          ' Set video generator output pins        
              mov       frqa,   pllfreq         ' Set Counter A frequency
              mov       ctra,   CtrCfg          ' Set Counter A control register
              mov       vscl,   VidScl          ' Set video generator scale register
              mov       vcfg,   VidCfg          ' Set video generator config register
              rdlong    cnt,    #0              ' Retrive system clock
              shr       cnt,    #10             ' Set-up ~1ms wait
              add       cnt,    cnt             ' Add 1ms wait
              waitcnt   cnt,    #0              ' Allow PLL to settle
              mov       vcfg,   VidCfg          ' Start video generator
              mov       tptr,   #40             ' Initialize tile pointer
:active       waitvid   colors, pixels          ' Update 16-pixel scanline                 
              djnz      tptr,   #:active        ' Display forty 16-pixel segments (40*16=640 pixels)
              jmp       #:active                ' Loop infinitely

vgapin        long      |< 0 | |< 1 | |< 2 | |< 3 | |< 4 | |< 5 | |< 6 | |< 7   ' Counter A output pin
pllfreq       long      337893130                                               ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                 ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_000_0_11111111              ' Video generator configuration
VidScl        long      %000000000000_00000001_000000010000                     ' Video generator scale register

colors        long      %00000011_00000111_00010111_00011111                    ' Navy Blue test color
pixels        long      %11_11_11_11_11_11_11_11_11_11_11_11_11_11_11_11        ' Test pixels

tptr          long      0                                                       ' Current tile being rendered

'R-R-G-G-B-B-H-V