{{
        File:     vga_tx.spin
        Author:   Connor Spangler
        Date:     5/1/2018
        Version:  0.2
        Description: 
                  This file contains the PASM code to transmit graphics resources from one
                  Propeller to another
}}

CON
  BUFFER_SIZE = ((40*30*2)+(32*16)*2+(64*4))/4          ' Size of transmission buffer in LONGs (tile map + color palettes + SAT)

VAR
  long  cog_                    ' Variable containing ID of transmission cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  cont_                   ' Variable containing control flag for transmission routine
  
PUB start(varAddrBase) : status                         ' Function to start transmission driver with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address
  cont_ := FALSE                                        ' Instantiate control flag

  ' Start transmission driver
  ifnot cog_ := cognew(@tx, @var_addr_base_) + 1        ' Initialize cog running "tx" routine with reference to start of variable registers
    return FALSE                                        ' Transmission system failed to initialize

  return TRUE                                           ' Transmission system successfully initialized

PUB stop                        ' Function to stop transmission driver
  if cog_                       ' If cog is running
    cogstop(cog_~ - 1)          ' Stop the cog

PUB transmit
  repeat while cont_            ' Wait for previous transmission to complete
  cont_ := TRUE                 ' Set control flag to start transmission

DAT
        org     0
tx
        ' Initialize variables
        mov             bufptr, par
        add             cntptr, bufptr          ' Initialize pointer to control flag
        rdlong          bufptr, par             ' Initialize pointer to variables
        'rdlong          bufptr, bufptr          ' Initialize pointer to graphics buffer

        ' Setup Counter in NCO mode
        mov             ctra,   CtrCfg          ' Set Counter A control register
        mov             frqa,   #0              ' Zero Counter A frequency register
        mov             dira,   TxPin           ' Set output pin

        ' Transfer entire graphics buffer
txbuff  mov             bufsiz, BuffSz          ' Instantiate graphics buffer size
        mov             curlng, bufptr          ' Instantiate graphics buffer location

        ' Wait for control flag to go high
:wait   rdlong          poll,   cntptr wz       ' Poll control flag
        if_z  jmp       #:wait                  ' Loop while low

        ' Transfer current long of graphics buffer
:txlong rdlong          txlong, curlng          ' Load current long
        add             curlng, #4              ' Increment to next graphics buffer long
        mov             txindx, #31             ' Load number of bits in long

        ' Setup long transmission start
        mov             phsa,   TxStart         ' Send one bit high
        mov             phsa,   txlong          ' Stage long for transfer

        ' Transmit bits
:txbits shl             phsa,   #1              ' Shift next bit to transmit
        djnz            txindx, #:txbits        ' Repeat for all bits

        ' Setup long transmission end
        mov             phsa,   #0              ' Pull data line low
        djnz            bufsiz, #:txlong        ' Repeat for all longs in buffer

        ' Wait for ACK and prepare for next transmission
        'andn            dira,   TxPin           ' Set transmission pin to input for ACK
        'waitpeq         TxPin,  TxPin           ' Wait for ACK
        'or              dira,   TxPin           ' Reset transmission pin for output
        wrlong          zero,   cntptr          ' Reset control flag
        jmp             #txbuff                 ' Loop infinitely

BuffSz        long      BUFFER_SIZE                                             ' Size of graphics buffer
TxStart       long      -1                                                      ' High transmission start pulse
CtrCfg        long      %0_00100_000_00000000_000000_000_000000                 ' Counter A configuration
TxPin         long      |< 0                                                    ' Set transmission pin
zero          long      0                                                       ' Zero for control flag

bufptr        long      0       ' Pointer to transmission buffer in main RAM w/ offset
cntptr        long      4       ' Pointer to transmission control flag in main RAM w/ offset

curlng        res       1       ' Container for current long address
bufsiz        res       1       ' Container for size of graphics buffer
txlong        res       1       ' Container for the currently transferring graphics buffer long
txindx        res       1       ' Container for index of current graphics buffer long bit being transferred
poll          res       1       ' Container for polled control flag

        fit