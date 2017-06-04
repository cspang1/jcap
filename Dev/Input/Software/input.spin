{{
        File:     input.spin
        Author:   Connor Spangler
        Date:     05/24/2017
        Version:  3.0
        Description: 
                  This file contains the PASM code to create an interface between the
                  Propeller P8X32A and a dual 74HC165 daisy-chained setup. Its purpose
                  is to read in the searialized inputs of 16 physical arcade controls
                  and store them in Main RAM on the Hub.
}}

CON
  _CLKMODE = xtal1 + pll16x     ' Fast external clock mode w/ 16x PLL
  _XINFREQ = 5_000_000          ' 5Mhz crystal

VAR
  word input_state              ' Register in Main RAM containing state of inputs                                      
PUB main
  cognew(@input, @input_state)  ' Initialize cog running input routine with reference to input_state register                           
DAT
        org             0
{{
The "input" routine is the main routine for interfacing with the 74HC165s
}}
input   or              dira,   Pin_outs        ' Set output pins
        andn            dira,   Pin_Q7          ' Set input pin

        andn            outa,   Pin_CE_n        ' Drive clock enable pin low   
                                                
{{
The "poll" subroutine reprents the entire processing of latching and then pulsing the 74HC165s
}}
:poll   andn            outa,   Pin_CP          ' Drive clock pin low
        andn            outa,   Pin_PL_n        ' Drive parallel load pin low
        or              outa,   Pin_PL_n        ' Drive parallel load pin high
         
        mov             Count,  #15             ' Load number of 74HC165 polls into register
{{
The "dsin" subroutine performs the individual clock pulses to retrieve the bits from the 74HC165s
 }}
:dsin   or              outa,   Pin_CP          ' Drive clock pin high
        andn            outa,   Pin_CP          ' Drive clock pin low
        
        test            Pin_Q7, ina wc          ' Poll and carry state of Pin_Q7
        rcr             Inputs, #1              ' Shift Pin_Q7 state in Inputs register             
        
        djnz            Count,  #:dsin          ' Repeat to retrieve all 16 bits
        
        wrword          Inputs, par             ' Write Inputs to Main RAM input_state register
        
        jmp             #:poll                  ' Loop infinitely

Pin_CP        long      |< 0                            ' 74HC165 clock pin bitmask
Pin_CE_n      long      |< 1                            ' 74HC165 clock enable pin bitmask
Pin_PL_n      long      |< 2                            ' 74HC165 parallel load pin bitmask
Pin_outs      long      |< 0 | |< 1 | |< 2              ' Set output pin bitmask                      
Pin_Q7        long      |< 12                           ' 74HC165 serial output pin bitmask
Count         res       1                               ' 74HC165 clock pulse count
Pin_in        res       1                               ' I/O pin state bitmask         
Inputs        res       1                               ' Control input shift register
        fit