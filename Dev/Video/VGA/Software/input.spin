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
VAR
  long base_input_addr_      ' Register in Main RAM containing state of inputs 
PUB start (base_input_addr)                          
  base_input_addr_ := base_input_addr                   ' Set global base_input_addr var
  cognew(@input, base_input_addr_)                      ' Initialize cog running "input" routine with reference to start of variable registers
DAT        
        org             0
{{
The "input" routine interfaces with the arcade controls via the 74HC165s
}}
input   or              dira,   Pin_outs        ' Set output pins
        andn            dira,   Pin_Q7          ' Set input pin
        andn            outa,   Pin_CE_n        ' Drive clock enable pin low
        mov             iptr,   par             ' Load Main RAM input_state address into iptr
        rdlong          iptr,   iptr            ' Load actual control state address
        mov             tptr,   iptr            ' Load Main RAM control state address into tptr
        add             tptr,   #2              ' Increment tptr to point to tilt_state in Main RAM                  
{{
The "poll" subroutine reprents the entire process of latching and then pulsing the 74HC165s
}}
:poll   andn            outa,   Pin_CP          ' Drive clock pin low
        andn            outa,   Pin_PL_n        ' Drive parallel load pin low
        or              outa,   Pin_PL_n        ' Drive parallel load pin high           
        mov             pcnt,   #15             ' Load number of 74HC165 polls into register
{{
The "dsin" subroutine performs the individual clock pulses to retrieve the bits from the 74HC165s
}}
:dsin   or              outa,   Pin_CP          ' Drive clock pin high
        andn            outa,   Pin_CP          ' Drive clock pin low
        test            Pin_Q7, ina wc          ' Poll and carry state of Pin_Q7
        rcl             inputs, #1              ' Shift Pin_Q7 state in inputs register             
        djnz            pcnt,   #:dsin          ' Repeat to retrieve all 16 bits
        or              outa,   Pin_CP          ' Drive clock pin high
        andn            outa,   Pin_CP          ' Drive clock pin low
        test            Pin_Q7, ina wc          ' Poll and carry state of Pin_Q7
        wrword          inputs, iptr            ' Write inputs to Main RAM input_state register
        rcl             inputs, #1              ' Shift tilt state in inputs register
        and             inputs, #1              ' Isolate tilt state
        wrbyte          inputs, tptr            ' Write tilt state to Main RAM 
        jmp             #:poll                  ' Loop infinitely
Pin_CP        long      |< 0                    ' 74HC165 clock pin bitmask
Pin_CE_n      long      |< 1                    ' 74HC165 clock enable pin bitmask
Pin_PL_n      long      |< 2                    ' 74HC165 parallel load pin bitmask
Pin_outs      long      |< 0 | |< 1 | |< 2      ' Set output pin bitmask                      
Pin_Q7        long      |< 12                   ' 74HC165 serial output pin bitmask
iptr          res       1                       ' Pointer to input_state register in Main RAM
tptr          res       1                       ' Pointer to tilt_state register in Main RAM
pcnt          res       1                       ' 74HC165 clock pulse pcnt
inputs        res       1                       ' Control input shift register
        fit