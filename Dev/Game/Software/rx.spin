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
  RX_PIN = 0                                            ' Pin used for data reception
  VS_PIN = 24                                           ' Pin used for VSYNC

VAR
  long  cog_                    ' Variable containing ID of reception cog
  
PUB start(gfxBuffBase) : status                         ' Function to start reception driver with pointer to Main RAM variables
  stop                                                  ' Stop any existing reception cogs

  ' Start reception driver
  ifnot cog_ := cognew(@rx, gfxBuffBase) + 1            ' Initialize cog running "rx" routine with reference to start of variable registers
    return FALSE                                        ' Reception system failed to initialize

  return TRUE                                           ' Reception system successfully initialized

PUB stop                                                ' Function to stop reception driver
  if cog_                                               ' If cog is running
    cogstop(cog_~ - 1)                                  ' Stop the cog
  
DAT
        org             0
rx
        ' Initialize variables
        add             buffsz, par             ' Initialize pointer to variables
        rdlong          bufptr, par
        rdlong          buffsz, buffsz

        ' Initialize pins
        andn            dira,   RxPin           ' Set input pin
        andn            dira,   VsPin           ' Set input pin

        ' Receive graphics buffer
rxbuff  mov             curbuf, BuffSz          ' Initialize graphics buffer size
        mov             curlng, bufptr          ' Initialize graphics buffer location

        ' Receive long
        waitpeq         VsPin,  VsPin           ' Wait for VSYNC
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
        wrlong          rxval,  curlng          ' Store current long
        add             curlng, #4              ' Increment to next graphics buffer long
        djnz            curbuf, #:rxlong        ' Repeat for all longs in buffer

        ' Prepare for next buffer reception
        or              dira,   RxPin           ' Set RX pin as output for ACK
        or              outa,   RxPin           ' Send ACK
        andn            outa,   RxPin           ' Complete ACK
        andn            dira,   RxPin           ' Set RX pin as input
        jmp             #rxbuff                 ' Loop infinitely

bufptr        long      0                       ' Pointer to graphics resources buffer in main RAM w/ offset
buffsz        long      4                       ' Pointer to graphics resources buffer size in main RAM w/ offset
RxPin         long      |< RX_PIN               ' Set reception pin
VsPin         long      |< VS_PIN               ' Set VSYNC pin
RxCont        long      -1                      ' High transmission start pulse

curbuf        res       1       ' Container for current graphics resources buffer
curlng        res       1       ' Container for current long address
rxval         res       1       ' Container for current long

        fit