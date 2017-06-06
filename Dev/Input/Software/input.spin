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
  word input_state              ' Register in Main RAM containing state of inputs 
  byte tilt_state               ' Register in Main RAM containing state of tilt sensor  
PUB main
  cognew(@input, @input_state)  ' Initialize cog running "input" routine with reference to start of variable registers
  tester                        ' Test the "input" routine                        
PUB tester
  cognew(@testing, @input_state)' Initialize cog running "testing" routine with reference to start of variable registers
DAT        

        org             0
        
{{
The "input" routine interfaces with the arcade controls via the 74HC165s
}}
input   or              dira,   Pin_outs        ' Set output pins
        andn            dira,   Pin_Q7          ' Set input pin

        andn            outa,   Pin_CE_n        ' Drive clock enable pin low

        mov             Inptr,  par             ' Load Main RAM input_state address into Inptr
        mov             Tltptr, par             ' Load Main RAM input_state address into Inptrr
        add             Tltptr, #2              ' Increment Tltptr to point to tilt_state in Main RAM
                
{{
The "poll" subroutine reprents the entire process of latching and then pulsing the 74HC165s
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
        rcl             Inputs, #1              ' Shift Pin_Q7 state in Inputs register             
        
        djnz            Count,  #:dsin          ' Repeat to retrieve all 16 bits
        
        or              outa,   Pin_CP          ' Drive clock pin high
        andn            outa,   Pin_CP          ' Drive clock pin low
                
        test            Pin_Q7, ina wc          ' Poll and carry state of Pin_Q7

        wrword          Inputs, Inptr           ' Write Inputs to Main RAM input_state register
                
        rcl             Inputs, #1              ' Shift tilt state in Inputs register
        and             Inputs, #1              ' Isolate tilt state
                
        wrbyte          Inputs, Tltptr          ' Write tilt state to Main RAM 
           
        jmp             #:poll                  ' Loop infinitely

Pin_CP        long      |< 0                            ' 74HC165 clock pin bitmask
Pin_CE_n      long      |< 1                            ' 74HC165 clock enable pin bitmask
Pin_PL_n      long      |< 2                            ' 74HC165 parallel load pin bitmask
Pin_outs      long      |< 0 | |< 1 | |< 2              ' Set output pin bitmask                      
Pin_Q7        long      |< 12                           ' 74HC165 serial output pin bitmask
   
Inptr         res       1                               ' Pointer to input_state register in Main RAM
Tltptr        res       1                               ' Pointer to tilt_state register in Main RAM
Count         res       1                               ' 74HC165 clock pulse count
Inputs        res       1                               ' Control input shift register

        fit
DAT

        org             0
        
{{
The "testing" routine tests the behavior of the "input" routine via the DE0-Nano LEDs
}}
testing or              dira,   Pin_LED         ' Set LED output pins
        andn            dira,   pin_SW          ' Set controls/tilt sensor switch input

{{
The "loop" subroutine infinitely loops to display either input_state or tilt_state to the LEDs
}}        
:loop   mov             iptr,   par             ' Load Main RAM input_state address into iptr
        mov             tptr,   par             ' Load Main RAM input_state address into tptr 
        add             tptr,   #2              ' Increment tptr to point to tilt_state in Main RAM
        rdword          is,     iptr            ' Read input_state from Main RAM                                                        
        shl             is,     #16             ' Shift input_state to LED positions
        test            Pin_SW, ina wc          ' Test input switch
        rdbyte          ts,     tptr            ' Read tilt_state from Main RAM
        shl             ts,     #16             ' Shift tilt_state to LED positions
        if_nc mov       tmpled, is              ' Set input_state to be displayed
        if_c  mov       tmpled, ts              ' Set tilt_state to be displayed
        mov             ledout, Pin_LED         ' Combine chosen display state with current outputs        
        xor             ledout, xormask
        and             ledout, outa
        or              ledout, tmpled
        mov             outa,   ledout          ' Display chosen state on LEDs                                           
        jmp             #:loop                  ' Loop infinitely

pin_SW        long      |< 15                                                                           ' Arcade control/tilt sensor display switch pin bitmask
Pin_LED       long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' DE0-Nano LED pin bitmask
xormask       long      $FFFFFFFF                                                                       ' XOR bitmask to control outputs
iptr          res       1                                                                               ' Pointer to input_state register in Main RAM
tptr          res       1                                                                               ' Pointer to tilt_state register in Main RAM
is            res       1                                                                               ' Register holding input_state
ts            res       1                                                                               ' Register holding tilt_state
ledout        res       1                                                                               ' Register holding final output state
tmpled        res       1                                                                               ' Register holding intermediate output state

        fit
