{{
        File:     cpu.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code defining a JCAP CPU
}}

CON
    ' Clock settings
    _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
    _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

    ' Pin settings
    VS_PIN = 14
    TX_PIN = 15

OBJ
    system        : "system"      ' Import system settings
    gfx_tx        : "tx"          ' Import graphics transmission system
    input         : "input"       ' Import input system

VAR
    ' Game resource pointers
    long  input_state_base_       ' Register in Main RAM containing state of inputs
    long  gfx_resources_base_     ' Register in Main RAM containing base of graphics resources
    long  gfx_buffer_size_        ' Container for graphics resources buffer size

    ' TEST RESOURCE POINTERS
    long  satts[system#SAT_SIZE]

PUB main | time,trans,cont,temp,x,y,z,q,plx1,plx2,plx3,plx4,plx5,plx6,plx7,plx8
    ' Initialize variables
    input_state_base_ := @input_states                    ' Point input state base to base of input states
    gfx_resources_base_ := @tile_color_palettes           ' Set graphics resources base to start of tile color palettes
    gfx_buffer_size_ := system#GFX_BUFFER_SIZE                   ' Set graphics resources buffer size

    ' Start subsystems
    trans := constant(NEGX|15)                              ' link setup
    gfx_tx.start(@trans, VS_PIN, TX_PIN)                    ' Start graphics resource transfer system
    repeat while trans

    input.start(@input_state_base_)                       ' Start input system

    '     sprite         x position       y position    color v h size
    '|<------------->|<--------------->|<------------->|<--->|-|-|<->|
    ' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    '|----spr<<24----|------x<<15------|-----y<<7------|c<<4-|8|4|x-y|

    temp := 0
    plx1 := 0
    plx2 := 0
    plx3 := 0
    plx4 := 0
    plx5 := 0
    plx6 := 0
    plx7 := 0
    plx8 := 0
    x := 16 ' starting horizontal pos
    y := 128 'starting vertical pos
    z := 8 'sprites per line
    q := 8 'n lines
    repeat q
        repeat z
            satts[temp] := (2 << 24) | (x << 15) | (y << 7) | 2 | 1
            x += 16
            temp += 1
        y += 16
        x := 16
    repeat system#SAT_SIZE-z*q
        satts[temp] := (0 << 15) | (0 << 7)
        temp += 1

    longmove(@sprite_atts, @satts, system#SAT_SIZE)
    longfill(@plx_pos, $FF, system#NUM_PARALLAX_REGS)
    long[@plx_pos][0] := 0
    long[@plx_pos][1] := 60
    long[@plx_pos][2] := 180
    long[@plx_pos][3] := (0 << 20) | 209
    long[@plx_pos][4] := (5 << 20) | 210
    long[@plx_pos][5] := (10 << 20) | 211
    long[@plx_pos][6] := (15 << 20) | 212
    long[@plx_pos][7] := (20 << 20) | 213
    long[@plx_pos][8] := (25 << 20) | 214
    time := cnt
    
    ' Main game loop
    repeat
        waitcnt(Time += clkfreq/60) ' Strictly for sensible sprite speed
        trans := constant(system#GFX_BUFFER_SIZE << 16) | @plx_pos{0}            ' register send request
        x := (word[@control_state][0] >> 7) & %10100000
        y := (word[@control_state][0] >> 7) & %01010000
        if x == %10000000 or x == %00100000
            left_right(x)
        if y == %01000000 or y == %00010000
            up_down(y)
        plx1 := long[@plx_pos][1] >> 20
        plx2 := long[@plx_pos][2] >> 20
        plx3 := long[@plx_pos][3] >> 20
        plx4 := long[@plx_pos][4] >> 20
        plx5 := long[@plx_pos][5] >> 20
        plx6 := long[@plx_pos][6] >> 20
        plx7 := long[@plx_pos][7] >> 20
        plx8 := long[@plx_pos][8] >> 20
        if plx1 == 446
            long[@plx_pos][1] &= $FFFFF
        else
            long[@plx_pos][1] := (long[@plx_pos][1] & $FFFFF) | ((plx1 + 2) << 20)
        if plx2 == 447
            long[@plx_pos][2] &= $FFFFF
        else
            long[@plx_pos][2] := (long[@plx_pos][2] & $FFFFF) | ((plx2 + 3) << 20)
        if plx3 == 447
            long[@plx_pos][3] &= $FFFFF
        else
            long[@plx_pos][3] := (long[@plx_pos][3] & $FFFFF) | ((plx3 + 1) << 20)
        if plx4 == 447
            long[@plx_pos][4] &= $FFFFF
        else
            long[@plx_pos][4] := (long[@plx_pos][4] & $FFFFF) | ((plx4 + 1) << 20)
        if plx5 == 447
            long[@plx_pos][5] &= $FFFFF
        else
            long[@plx_pos][5] := (long[@plx_pos][5] & $FFFFF) | ((plx5 + 1) << 20)
        if plx6 == 447
            long[@plx_pos][6] &= $FFFFF
        else
            long[@plx_pos][6] := (long[@plx_pos][6] & $FFFFF) | ((plx6 + 1) << 20)
        if plx7 == 447
            long[@plx_pos][7] &= $FFFFF
        else
            long[@plx_pos][7] := (long[@plx_pos][7] & $FFFFF) | ((plx7 + 1) << 20)
        if plx8 == 447
            long[@plx_pos][8] &= $FFFFF
        else
            long[@plx_pos][8] := (long[@plx_pos][8] & $FFFFF) | ((plx8 + 1) << 20)

        cont := tilt_state
        if (tilt_state & 1) == 0
            longfill(@sprite_atts, 0, system#SAT_SIZE)

pri left_right(x_but) | x,dir,mir,temp,xsp
    x := long[@sprite_atts][0]
    temp := x & %00000000000000000111111111111011
    dir := 2 << 24
    x >>= 15
    x &= %111111111
    xsp := long[@plx_pos][0] >> 20
    if x_but == %10000000
        mir := 0
        x := (x + 1) & %111111111
        if xsp == 447
            long[@plx_pos][0] &= $FFFFF
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFFFF) | ((xsp + 1) << 20)
    if x_but == %00100000
        mir := 1 << 2
        x := (x - 1) & %111111111
        if xsp == 0
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFFFF) | (447 << 20)
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFFFF) | ((xsp - 1) << 20)
    if temp & 2 == 2
        if x == 336
            x := 1
        elseif x == 0
            x := 335
    else
        if x == 336
            x := 9
        elseif x == 8
            x := 335
    x <<= 15
    temp |= (x | mir | dir)
    longmove(@sprite_atts, @temp, 1)

pri up_down(y_but) | y,dir,mir,temp,ysp
    y := long[@sprite_atts][0]
    temp := y & %00000000111111111000000001110111
    dir := 2 << 24
    y >>= 7
    y &= %11111111
    ysp := (long[@plx_pos][0] & $FFF00) >> 8
    if y_but == %01000000
        mir := 1 << 3
        y := (y + 1) & %11111111
        if ysp == 271
            long[@plx_pos][0] &= $FFF000FF
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFF000FF) | ((ysp + 1) << 8)
    if y_but == %00010000
        mir := 0
        y := (y - 1) & %11111111
        if ysp == 0
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFF000FF) | (271 << 8)
        else
            long[@plx_pos][0] := (long[@plx_pos][0] & $FFF000FF) | ((ysp - 1) << 8)
    if temp & 1 == 1
        if y == 255
            y := 1
        elseif y == 0
            y := 254
    else
        if y == 255
            y := 9
        elseif y == 8
            y := 254
    y <<= 7
    temp |= (y | mir | dir)
    longmove(@sprite_atts, @temp, 1)

DAT
input_states
              ' Input states
control_state   word    0   ' Control states
tilt_state      word    0   ' Tilt shift state

plx_pos         long    0[system#NUM_PARALLAX_REGS]   ' Parallax array (x[31:20]|y[19:8]|i[7:0] where 'i' is scanline index)

tile_color_palettes
            ' Tile color palettes
t_palette0  byte    %00000011,%11000011,%00001111,%11111111                    ' Tile color palette 0
            byte    %11110011,%00111111,%11001111,%11000011
            byte    %11010011,%00110111,%01001111,%01111011
            byte    %11010111,%01110111,%01011111,%00000011
t_palette1  byte    %00000011,%11110011,%11001111,%11000011                    ' Tile color palette 1
            byte    %00000011,%00110011,%11111111,%11000011
            byte    %00000011,%00110011,%11111111,%11000011
            byte    %00000011,%00110011,%11111111,%11000011

sprite_color_palettes
            ' Sprite color palettes
s_palette0  byte    %00000011,%00110011,%11000011,%11111111                    ' Tile color palette 0
            byte    %11110011,%00111111,%11001111,%11000011
            byte    %11010011,%00110111,%01001111,%01111011
            byte    %11010111,%01110111,%01011111,%00000011
s_palette1  byte    %00000011,%00110011,%11111111,%11000011                    ' Tile color palette 1
            byte    %00000011,%00110011,%11111111,%11000011
            byte    %00000011,%00110011,%11111111,%11000011
            byte    %00000011,%00110011,%11111111,%11000011

            ' Sprite attribute table
sprite_atts long    0[system#SAT_SIZE]

tile_maps
            ' Main tile map
tile_map0   word    $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02, $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 0
            word    $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03, $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 1
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 2
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 3
            word    $00_01,$00_02,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 4
            word    $00_04,$00_03,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 5
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 6
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 7
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 8
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 9
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 10
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 11
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 12
            word    $00_04,$00_03,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 13
            word    $00_01,$00_02,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 14
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 15
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 16
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 17
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 18
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 19
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 20
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 21
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 22
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 23
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 24
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 25
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 26
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 27
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 28
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 29
            word    $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 30
            word    $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00, $01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 31
            word    $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02, $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 32
            word    $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03, $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 33
