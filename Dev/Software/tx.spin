''
'' single wire serial link - transmitter
''
''        Author: Marko Lukat
''   Modified by: Connor Spangler
'' Last modified: 2018/06/26
''       Version: 0.7
''
'' long[par][0]: cog startup: [!Z]:chn0 =  24:8 -> zero (ready)
''               transaction: size:addr = 16:16 -> zero (transaction accepted)
''
'' 20110514: increased net transfer rate
'' 20180621: refactored for JAMMA
''

CON
    shl_phsb_imm1 = $2CFFFA01                     ' shl phsb, #1

VAR
    long  cog_                    ' Variable containing ID of transmission cog

PUB start(varAddrBase) : status
    stop

    ' Start transmission driver
    ifnot cog_ := cognew(@tx, varAddrBase) + 1            ' Initialize cog running "vga" routine with reference to start of variable registers
        return FALSE                                        ' Graphics system failed to initialize

    return TRUE                                           ' Graphics system successfully initialized

PUB stop                                                ' Function to stop VGA driver
    if cog_                                             ' If cog is running
      cogstop(cog_~ - 1)                                ' Stop the cog

DAT             org     0                       ' proplink transmitter

tx              jmpret  $, #:setup              ' once

                rdlong  tx_addr, par wz         '  +0 = size:addr = 16:16
        if_z    jmp     #$-1

                mov     tx_lcnt, tx_addr
                wrlong  par, par                '  +0 = accept transaction
                shr     tx_lcnt, #16 wz         '       extract long count
        if_z    jmp     %%0

' The transmission loop is sync'd to the hub window. Minimal cycle count is
' 8(rdlong) + 140(transfer) + 8(loop) = 156(160). In the receiver we need at
' least 20 cycles between stop and start bit plus an additional 15 cycles in
' case we miss the hub window (35). The transmitter covers 16 cycles already
' (rdlong+loop) which leaves us with an artificial delay of 19(20) cycles.

                waitpeq VsPin, VsPin
:primary        rdlong  buff, tx_addr             '  +0 = 176 cycles

' prerequisites: ctra NCO clkfreq/4, low centres around phase D
'                ctrb NCO inactive, output preset to high (mutes ctra)

' transfer starts, 2 start bits, 32 data bits, 1 stop bit

                mov     phsb, #0                ' start bit 0
                neg     phsb, #1                ' start bit 1
                xor     phsb, buff              ' bit 31
                long    shl_phsb_imm1[31]       ' bit 30..0
                neg     phsb, #1                ' stop bit

' transfer ends

                mov     cnt, cnt                ' |
                add     cnt, #9{14}+ 6          ' |
                waitcnt cnt, #0                 ' delay 20 cycles
                
                add     tx_addr, #4             ' advance address
                djnz    tx_lcnt, #:primary      ' next long

                jmp     %%0                     ' handle next transaction


:setup          rdbyte  ctra, par               ' read transmitter pin ([!Z]:chn0 = 24:8)

                neg     phsb, #1                ' preset high
                movs    ctrb, ctra              ' copy pin assignment
                movi    ctrb, #%0_00100_000     ' NCO single-ended

                andn    dira, VsPin
                shl     tx_mask, ctra           ' pin number -> pin mask
                mov     dira, tx_mask           ' set output
                
                movi    ctra, #%0_00100_000     ' NCO single-ended
                movi    phsa, #%1100_0000_0     ' preset (low centres around phase D)
                movi    frqa, #%0100_0000_0     ' clkfreq/4

                wrlong  par, par                ' setup done
                jmp     %%0                     ' ret
                
' initialised data and/or presets

tx_mask         long    1                       ' pin mask (outgoing data)
VsPin           long    |< 14

' uninitialised data and/or temporaries

buff            res     1                       ' payload

tx_addr         res     1
tx_lcnt         res     1

                fit