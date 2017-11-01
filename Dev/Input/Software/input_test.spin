{{
        File:     input.spin
        Author:   Connor Spangler
        Date:     05/24/2017
        Version:  5.0
        Description: 
                  This file contains the PASM code to create an interface between the
                  Propeller P8X32A and a dual 74HC165 daisy-chained setup. Its purpose
                  is to read in the searialized inputs of 16 physical arcade controls
                  and store them in Main RAM on the Hub.
}}

CON
  _CLKMODE = xtal1 + pll16x     ' Fast external clock mode w/ 16x PLL
  _XINFREQ = 5_000_000          ' 5Mhz crystal
OBJ
  Input : "input"
VAR
  word base_input_addr_         ' Register in Main RAM containing state of inputs
  byte bast_tilt_addr_          ' Register in Main RAM containing state of tilt sensor 
PUB main                          
  Input.start(@base_input_addr_)
  Input.tester