''
'' single wire serial link - receiver
''
''        Author: Marko Lukat
''   Modified by: Connor Spangler
'' Last modified: 2018/06/26
''       Version: 0.7
''
'' long[par][0]: cog startup: [!Z]:chn0 =  24:8 -> zero (ready)
''               transaction: size:addr = 16:16 -> zero (transaction done)
''
'' 20110514: increased net transfer rate
'' 20180626: refactored for JAMMA
''

CON
    shr_frqa_imm1 = $28FFF401                     ' shr frqa, #1

VAR
    long  cog_                    ' Variable containing ID of transmission cog

PUB start(varAddrBase, vsPin, rxPin) : status
    ' Wait for CPU to start
    dira[rxPin] := 0
    dira[vsPin] := 1
    outa[vsPin] := 0
    waitpeq(|< rxPin, |< rxPin, 0)
    outa[vsPin] := 1
    outa[vsPin] := 0
    dira[vsPin] := 0

    stop

    ' Start transmission driver
    ifnot cog_ := cognew(@rx, varAddrBase) + 1            ' Initialize cog running "vga" routine with reference to start of variable registers
        return FALSE                                        ' Graphics system failed to initialize

    return TRUE                                           ' Graphics system successfully initialized

PUB stop                                                ' Function to stop VGA driver
    if cog_                                             ' If cog is running
      cogstop(cog_~ - 1)                                ' Stop the cog

DAT             org     0                       ' proplink receiver

rx              jmpret  $, #:setup              ' once

                wrlong  par, par                ' setup/transaction done
:cont           rdlong  rx_addr, gfx_addr
                mov     rx_lcnt, rx_addr
                shr     rx_lcnt, #16
                sub     rx_addr, #4             ' preset (increment before)     (%%)

' prerequisites: ctra POSEDGE detector
'                frqa NEGX

:primary        neg     phsa, frqa              ' counter start bit effect

' transfer starts, 2 start bits, 32 data bits, 1 stop bit

                waitpne rx_mask, rx_mask        ' wait for start bit
                waitpne rx_addr, #3 wr          ' bit 31, advance address (+4)  (%%)
                long    shr_frqa_imm1[31]       ' bit 30..0
                ror     frqa, #1                ' NEGX

' transfer ends

                mov     phsa, phsa              ' shadow[phsa] := counter[phsa]
                wrlong  phsa, rx_addr           ' store data

                djnz    rx_lcnt, #:primary      ' next long

                jmp     #:cont                  ' handle next transaction


:setup          mov     gfx_addr, par
                rdbyte  ctra, par               ' read receiver pin ([!Z]:chn0 = 24:8)
                add     gfx_addr, #4

                movi    ctra, #%0_01010_000     ' POSEDGE detector
                movi    frqa, #%10000000_0      ' NEGX

                shl     rx_mask, ctra           ' pin number -> pin mask

                jmp     %%0                     ' ret

' initialised data and/or presets

rx_mask         long    1                       ' pin mask (incoming data)
vs_mask         long    |< 0                    ' VSync signal output pin

' uninitialised data and/or gfx_addroraries

gfx_addr        res     1
rx_addr         res     1
rx_lcnt         res     1

                fit