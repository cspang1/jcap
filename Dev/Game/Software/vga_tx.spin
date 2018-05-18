{{
        File:     vga_tx.spin
        Author:   Connor Spangler
        Date:     5/1/2018
        Version:  1.0
        Description: 
                  This file contains the PASM code to transmit graphics resources from one
                  Propeller to another
}}

CON
  BUFFER_SIZE = ((40*30*2)+(32*16)*2+(64*4))/4          ' Size of transmission buffer in LONGs (tile map + color palettes + SAT)
  TX_PIN = 0                                            ' Pin used for data transmission

VAR
  long  cog_                    ' Variable containing ID of transmission cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  cont_                   ' Variable containing control flag for transmission routine
  
PUB start(varAddrBase) : status                         ' Function to start transmission driver with pointer to Main RAM variables
  stop                                                  ' Stop any existing transmission cogs

  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address
  cont_ := 0                                            ' Instantiate control flag

  dira |= |< 2
   ' Start transmission driver
  ifnot cog_ := cognew(@tx, @var_addr_base_) + 1        ' Initialize cog running "tx" routine with reference to start of variable registers
    return FALSE                                        ' Transmission system failed to initialize

  return TRUE                                           ' Transmission system successfully initialized

PUB stop                        ' Function to stop transmission driver
  if cog_                       ' If cog is running
    cogstop(cog_~ - 1)          ' Stop the cog

PUB transmit
  outa |= |< 2
  repeat while cont_
  cont_ := $FFFF_FFFF
  outa  &= !(|<2)

DAT
        org     0
tx
        ' Initialize variables
        mov             bufptr, par
        add             cntptr, bufptr          ' Initialize pointer to control flag
        rdlong          bufptr, par             ' Initialize pointer to variables

        ' Setup Counter in NCO mode
        mov             ctra,   CtrCfg          ' Set Counter A control register mode
        mov             frqa,   #0              ' Zero Counter A frequency register
        or              dira,   TxPin           ' Set output pin

        andn            outa,   tstpin
        or              dira,   tstpin

        ' Transfer entire graphics buffer
txbuff  mov             bufsiz, BuffSz          ' Initialize graphics buffer size
        mov             curlng, bufptr          ' Initialize graphics buffer location

        ' Wait for control flag to go high
        or              outa,   tstpin
:wait   rdlong          poll,   cntptr wz       ' Poll control flag
        if_z  jmp       #:wait                  ' Loop while low
        andn            outa,   tstpin

        ' Transfer current long of graphics buffer
:txlong rdlong          txval,  curlng          ' Load current long
        add             curlng, #4              ' Increment to next graphics buffer long
        mov             txindx, #31             ' Load number of bits in long

        ' Setup long transmission start
        nop                                     ' Compensation NOP
        nop                                     ' Compensation NOP
        nop                                     ' Compensation NOP
        mov             phsa,   TxStart         ' Send one bit high
        mov             phsa,   txval           ' Stage long for transfer

        ' Transmit bits
:txbits shl             phsa,   #1              ' Shift next bit to transmit
        djnz            txindx, #:txbits        ' Repeat for all bits

        ' Setup long transmission end
        mov             phsa,   #0              ' Pull data line low
        djnz            bufsiz, #:txlong        ' Repeat for all longs in buffer

        ' Wait for ACK and prepare for next transmission
        andn            dira,   TxPin           ' Set transmission pin to input for ACK
        or              outa,   tstpin
        waitpeq         TxPin,  TxPin           ' Wait for ACK
        andn            outa,   tstpin
        wrlong          zero,   cntptr          ' Reset control flag
        or              dira,   TxPin           ' Reset transmission pin for output
        jmp             #txbuff                 ' Loop infinitely

tstpin        long      |< 1
BuffSz        long      BUFFER_SIZE             ' Size of graphics buffer
TxStart       long      -1                      ' High transmission start pulse
CtrCfg        long      (%00100 << 26) | TX_PIN ' Counter A configuration
TxPin         long      |< TX_PIN               ' Pin used for data transmission
zero          long      0                       ' Zero for control flag
bufptr        long      0                       ' Pointer to transmission buffer in main RAM w/ offset
cntptr        long      4                       ' Pointer to transmission control flag in main RAM w/ offset

bufsiz        res       1       ' Container for size of graphics buffer
curlng        res       1       ' Container for current long address
txval         res       1       ' Container for current long
txindx        res       1       ' Container for index of current graphics buffer long bit being transferred
poll          res       1       ' Container for polled control flag

        fit