CON
  _CLKMODE = xtal1 + pll16x
  _XINFREQ = 5_000_000

PUB main
  cognew(@input, 0) ' Start a Cog with our assembly routine, no stack
                    ' is required since PASM requires we explicitly
                    ' assign and use memory locations within the Cog/Hub
DAT
        org     0
input   mov     dira,   Pin_CP | Pin_CE_n | Pin_PL_n | Pin_DS       ' Set our Pins to an output
        rdlong  Delay,  #0        ' Prime the Delay variable with memory location 0
                                  ' this is where the Propeller stores the CLKFREQ variable
                                  ' which is the number of clock ticks per second
        mov     Time,   cnt       ' Prime our timer with the current value of the system counter
        add     Time,   Delay     ' Add a minimum delay ( more on this below )
:loop   waitcnt Time,   Delay     ' Start waiting
        xor     outa,   Pin       ' Toggle our output pin with "xor"
        jmp     #:loop            ' Jump back to the beginning of our loop

' Pin definitions - 1 = Output/0 = Input
Pin_CP      long    |< 0
Pin_CE_n    long    |< 1
Pin_PL_n    long    |< 2
Pin_DS      long    |< 3
Delay       res     1
Time        res     1
        fit
		
' 1. Pull Pin_PL_n and Pin_CP low
' 2. Wait 
' 3. Pull Pin_PL_n high
' 4. Pull Pin_CE_n low
' 5. Wait
' 6. Shift Pin_DS into buffer
'    Repeat 15 times:
' 7. Pull Pin_CP high
' 8. Wait
' 9. Pull Pin_CP low
' 10. Shift Pin_DS into buffer
' 11. Jump to #7
' 12. Write buffer to Hub RAM/Write buffer to LED pins
' 13. Jump to #1