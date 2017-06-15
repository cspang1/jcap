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
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        
        
VAR
  long  vga_dat
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
              mov       hpos,   vis_h
              mov       vpos,   vis_v
              call      #genclr
:disp         waitvid   clrs,   pxls
              djnz      hpos,   #:disp
genclr        mov       clrs,   #0
              or        clrs,   clr0
              shl       clrs,   #8
              or        clrs,   clr1
              shl       clrs,   #8
              or        clrs,   clr2
              shl       clrs,   #8
              or        clrs,   clr3
              add       clr0,   #1
              add       clr1,   #1
              add       clr2,   #1
              add       clr3,   #1
genclr_ret    ret
:loop         jmp       #:loop                  ' Loop infinitely

vgapin        long      |< 0 | |< 1 | |< 2 | |< 3 | |< 4 | |< 5 | |< 6 | |< 7   ' Counter A output pin
pllfreq       long      337893130                                               ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                 ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_000_0_11111111              ' Video generator configuration
VidScl        long      %000000000000_00000001_000000010000                     ' Video generator scale register

vis_h         long      640
vis_v         long      480
fp_h          long      16
fp_v          long      10
bp_h          long      48
bp_v          long      33
sync_h        long      96
sync_v        long      2
pxls          long      $E4E4E4E4
clr0          long      %00000000
clr1          long      %00000000
clr2          long      %00000000
clr3          long      %00000000
clrs          long      0
hpos          long      0
vpos          long      0