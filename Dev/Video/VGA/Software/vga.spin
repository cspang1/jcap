 {{
        File:     vga.spin
        Author:   Connor Spangler
        Date:     06/09/2017
        Version:  1.0
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
vga           or        dira,   Pin_CA          ' Set Counter A output pin        
              mov       ctra,   CtrCfg          ' Set Counter A control register
              mov       frqa,   pll8mhz         ' Set Counter A frequency
:loop         jmp       #:loop                  ' Loop infinitely

Pin_CA        long      |< 0                                                    ' Counter A output pin
pll8mhz       long      256                                                     ' Counter A frequency
CtrCfg        long      %0_00100_111_00000000_000000_000_000000                 ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_000_0_11111111              ' Video generator configuration
'VidScl        long      %000000000000_10100000_101000000000                    ' Video generator scale register 