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
        mov             bufptr, par             ' Initialize pointer to variables
        add             cntptr, bufptr          ' Initialize pointer to control flag
        rdlong          bufptr, par             ' Initialize pointer to buffer
        add             ntcp,   bufptr          ' Calculate tile color palette amount address
        add             nscp,   bufptr          ' Calculate sprite color palette amount address
        rdlong          ntcp,   ntcp            ' Load sprite color palette amount
        add             ns,     bufptr          ' Calculate sprite amount address
        add             tms,    bufptr          ' Calculate tile map size address
        rdlong          nscp,   nscp            ' Load sprite color palette amount 
        rdlong          ns,     ns              ' Load sprite amount
        rdlong          tms,    tms             ' Load tile map size
        rdlong          bufptr, bufptr          ' Load buffer base address

        ' Calculate graphics buffer size in LONGs
        shl             tms,    #1              ' Calculate bytes in tile map
        add             ntcp,   nscp            ' Calculate total color palettes
        shl             ntcp,   #4              ' Calculate bytes in color palettes
        shl             ns,     #2              ' Calculate bytes in sprites
        add             tms,    ntcp            ' Aggregate
        add             tms,    ns              ' Buffer Size in BYTEs
        shr             tms,    #2              ' BufferSize in LONGs
        mov             buffsz, tms             ' Set buffer size

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
ntcp          long      4                       ' Container for number of tile color palettes w/ offset
nscp          long      8                       ' Container for number of sprite color palettes w/ offset
ns            long      12                      ' Container for number of sprites in SAT w/ offset
tms           long      16                      ' Container for size of tile map w/ offset

buffsz        res       1       ' Container for buffer size in LONGs
curbuf        res       1       ' Container for current iteration of graphics buffer
curlng        res       1       ' Container for current long address
txval         res       1       ' Container for current long
txindx        res       1       ' Container for index of current graphics buffer long bit being transferred
poll          res       1       ' Container for polled control flag
temp          res       1       ' Container for temporary variables

        fit