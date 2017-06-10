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
  long  symbol
   
OBJ
  nickname      : "object_name"
  
PUB public_method_name


PRI private_method_name


DAT
name    byte  "string_data",0        
        