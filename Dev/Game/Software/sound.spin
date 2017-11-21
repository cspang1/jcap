{{
        File:     sound.spin
        Author:   Connor Spangler
        Date:     06/06/2017
        Version:  1.0
        Description: 
                  This file contains the PASM code which defines the PWM-based sound driver used to produce audio from
                  the Propeller.                  
}}

CON
  _CLKMODE = xtal1 + pll16x     ' Fast external clock mode w/ 16x PLL
  _XINFREQ = 5_000_000          ' 5Mhz crystal
VAR
PUB main
DAT        
        org             0
        fit