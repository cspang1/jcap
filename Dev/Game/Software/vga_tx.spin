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
  TX_PIN = 0                                            ' Pin used for data transmission
  VS_PIN = 1                                            ' Pin used for VSYNC

VAR
  long  cog_                    ' Variable containing ID of transmission cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  cont_                   ' Variable containing control flag for transmission routine
  long  watch_dog_              ' Variable containing the cycle count for the watchdog timer
  
PUB start(varAddrBase) : status                         ' Function to start transmission driver with pointer to Main RAM variables
  stop                                                  ' Stop any existing transmission cogs


  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address
  cont_ := FALSE                                        ' Instantiate control flag
  watch_dog_ := clkfreq / 1_000 * 500                   ' Calculate time to wait

  ' Start transmission driver
  ifnot cog_ := cognew(@tx, @var_addr_base_) + 1        ' Initialize cog running "tx" routine with reference to start of variable registers
    return FALSE                                        ' Transmission system failed to initialize

  return TRUE                                           ' Transmission system successfully initialized

PUB stop                        ' Function to stop transmission driver
  if cog_                       ' If cog is running
    cogstop(cog_~ - 1)          ' Stop the cog

PUB transmit | waitstart
  waitstart := cnt                                      ' Set start time
  repeat while cont_                                    ' Wait for previous transfer to complete
    if (cnt - waitstart => watch_dog_)                  ' Check if time limit blown i.e. TX has hung somewhere
      start(var_addr_base_)                             ' Restart TX routine
      return                                            ' Exit function
  cont_ := TRUE                                         ' Signal transfer start

DAT
        org     0
tx
        ' Initialize variables
        add             cntptr, par             ' Initialize pointer to control flag
        rdlong          bufptr, par             ' Initialize pointer to buffer
        add             buffsz, bufptr          ' Calculate buffer size address
        rdlong          buffsz, buffsz          ' Load buffer size
        rdlong          bufptr, bufptr          ' Load buffer base address

        ' Setup Counter in NCO mode
        mov             ctra,   CtrCfg          ' Set Counter A control register mode
        mov             frqa,   #0              ' Zero Counter A frequency register
        or              dira,   TxPin           ' Set output pin
        andn            dira,   VsPin           ' Set input pin

        ' Transfer entire graphics buffer
txbuff  mov             curbuf, buffsz          ' Initialize graphics buffer size
        mov             curlng, bufptr          ' Initialize graphics buffer location

        ' Wait for control flag to go high
:wait   rdlong          poll,   cntptr wz       ' Poll control flag
        if_z  jmp       #:wait                  ' Loop while low
        waitpeq         VsPin,  VsPin           ' Wait for VSYNC

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
        djnz            curbuf, #:txlong        ' Repeat for all longs in buffer

        ' Wait for ACK and prepare for next transmission
        andn            dira,   TxPin           ' Set transmission pin to input for ACK
        waitpeq         TxPin,  TxPin           ' Wait for ACK
        wrlong          zero,   cntptr          ' Reset control flag
        or              dira,   TxPin           ' Reset transmission pin for output
        jmp             #txbuff                 ' Loop infinitely

TxStart       long      -1                      ' High transmission start pulse
CtrCfg        long      (%00100 << 26) | TX_PIN ' Counter A configuration
TxPin         long      |< TX_PIN               ' Pin used for data transmission
VsPin         long      |< VS_PIN               ' Pin used for data transmission
zero          long      0                       ' Zero for control flag
bufptr        long      0                       ' Pointer to transmission buffer in main RAM w/ offset
cntptr        long      4                       ' Pointer to transmission control flag in main RAM w/ offset
buffsz        long      4                       ' Pointer to buffer size in LONGs w/ offset

curbuf        res       1       ' Container for current iteration of graphics buffer
curlng        res       1       ' Container for current long address
txval         res       1       ' Container for current long
txindx        res       1       ' Container for index of current graphics buffer long bit being transferred
poll          res       1       ' Container for polled control flag
temp          res       1       ' Container for temporary variables

        fit