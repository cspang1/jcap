{{
        File:     vga_rx.spin
        Author:   Connor Spangler
        Date:     5/1/2018
        Version:  0.2
        Description: 
                  This file contains the PASM code to receive graphics resources from 
                  another Propeller
}}

CON
  BUFFER_SIZE = ((40*30*2)+(32*16)*2+(64*4))/4          ' Size of transmission buffer in LONGs (tile map + color palettes + SAT)

VAR
  long  cog_                    ' Variable containing ID of reception cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase) : status                         ' Function to start reception driver with pointer to Main RAM variables
  stop                                                  ' Stop any existing reception cogs

  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address

  ' Start reception driver
  ifnot cog_ := cognew(@rx, @var_addr_base_) + 1        ' Initialize cog running "rx" routine with reference to start of variable registers
    return FALSE                                        ' Reception system failed to initialize

  return TRUE                                           ' Reception system successfully initialized

PUB stop                                                ' Function to stop reception driver
  if cog_                                             ' If cog is running
    cogstop(cog_~ - 1)                                ' Stop the cog
  
DAT
        org             0
rx
        ' Initialize variables
        rdlong          bufptr, par             ' Initialize pointer to variables

        ' Initialize pins
        andn            dira,   RxPin           ' Set input pin
        andn            outa,   RxPin           ' Initialize low
        or              dira,   tstpin

        ' Receive graphics buffer
rxbuff  mov             bufsiz, BuffSz          ' Initialize graphics buffer size
        mov             curlng, bufptr          ' Initialize graphics buffer location

        ' Receive long
:rxlong waitpeq         RxPin,  RxPin           ' Wait for ACK

        ' Receive bits
:rxbits test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit
        test            RxPin,  ina wc          ' Get bit
        rcl             rxval,  #1              ' Shift in bit

        ' Store long and prepare for the next
        wrlong          rxval, curlng           ' Store current long
        add             curlng, #4              ' Increment to next graphics buffer long
        djnz            bufsiz, #:rxlong        ' Repeat for all longs in buffer

        ' Prepare for next buffer reception
        or              dira,   RxPin           ' Set RX pin as output for ACK
        or              outa,   RxPin           ' Send ACK
        andn            outa,   RxPin           ' Complete ACK
        andn            dira,   RxPin           ' Set RX pin as input
        jmp             #rxbuff                 ' Loop infinitely

tstpin        long      |< 1
BuffSz        long      BUFFER_SIZE             ' Size of graphics buffer
bufptr        long      0                       ' Pointer to reception buffer in main RAM w/ offset
RxPin         long      |< 0                    ' Set reception pin
RxCont        long      -1                      ' High transmission start pulse

bufsiz        res       1       ' Container for size of graphics buffer
curlng        res       1       ' Container for current long address
rxval         res       1       ' Container for current long

        fit