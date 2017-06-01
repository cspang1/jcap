CON
  _CLKMODE = xtal1 + pll16x
  _XINFREQ = 5_000_000

VAR
  long input_state  
PUB main
  cognew(@input, @input_state) ' Start a Cog with our assembly routine, no stack
                    ' is required since PASM requires we explicitly
                    ' assign and use memory locations within the Cog/Hub
DAT
        org             0
input   or              dira,   Pin_CP          ' Set Pin_CP direction output
        or              dira,   Pin_CE_n        ' Set Pin_CE_n direction output
        or              dira,   Pin_PL_n        ' Set Pin_PL_n direction output
        andn            dira,   Pin_Q7
        or              dira,   Pin_test

        mov             Del_us, #80         
        mov             Delay,  Del_us
                                                
:poll   call            #wait                   ' Wait for parallel-loaded bits to propogate        
        mov             Inputs, #0              ' Reset Inputs register
        andn            outa,   Pin_CP          ' Drive clock pin low
        andn            outa,   Pin_PL_n        ' Drive parallel load pin low
        or              outa,   Pin_CE_n        ' Drive clock enable pin high
        
        call            #wait                   ' Wait for parallel-loaded bits to propogate
        
        or              outa,   Pin_PL_n        ' Drive parallel load pin high
        andn            outa,   Pin_CE_n        ' Drive clock enable pin low   
        
        call #wait                              ' Wait for clock enable to propogate
        
        call #sreg
         
        mov             Count,  #15
:dsin   call            #wait
        or              outa,   Pin_CP          ' Drive clock pin high
        call            #wait                   ' Wait for clock signal to propogate
        andn            outa,   Pin_CP          ' Drive clock pin low
        
        call #sreg

        djnz            count,  #:dsin
        
        wrword          Inputs, par
        
        jmp             #:poll                  ' Jump back to the beginning of our loop

sreg          mov       Pin_in, ina             ' Read pin states
              shl       Inputs, #1              ' Shift Inputs left one bit
              and       Pin_in, Pin_Q7 wc       ' Mask Pin_DS and check parity        
        if_c  add       Inputs, #1              ' If parity was odd, shift 1 into LSB
        if_c  or        outa,   Pin_test
        if_nc andn      outa,   Pin_test       
sreg_ret      ret

wait          mov       Time,   cnt             ' Prime our timer with the current value of the system counter
              add       Time,   Delay           ' Add a minimum delay ( more on this below )
              waitcnt   Time,   Delay           ' Wait for parallel-loaded bits to propogate
wait_ret      ret

Pin_CP        long      |< 0    ' 74HC165 clock pin bitmask
Pin_CE_n      long      |< 1    ' 74HC165 clock enable pin bitmask
Pin_PL_n      long      |< 2    ' 74HC165 parallel load pin bitmask
Pin_Q7        long      |< 3    ' 74HC165 serial output pin bitmask
Pin_test      long      |< 14
Pin_in        res       1       ' I/O pin state bitmask         
Inputs        res       1       ' Control input shift register
Del_us        res       1       ' 1 microsecond delay ticks register
Delay         res       1       ' Delay register
Time          res       1       ' Time register
Count         res       1       ' 74HC165 clock pulse count register
        fit