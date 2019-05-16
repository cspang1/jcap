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

    ' Game settings
    NUM_TILE_COLOR_PALETTES = 2                           ' Number of tile color palettes
    NUM_SPRITE_COLOR_PALETTES = 2                         ' Number of sprite color palettes
    NUM_SPRITES = 64                                      ' Number of sprites in sprite attribute table
    TILE_MAP_WIDTH = 40                                   ' Number of horizontal tiles in tile map
    TILE_MAP_HEIGHT = 30                                  ' Number of vertical tiles in tile map
    NUM_TILE_PALETTES = 5                                 ' Number of tile palettes
    NUM_SPRITE_PALETTES = 3                               ' Number of sprite palettes

    ' GPU attributes
    GFX_BUFFER_SIZE = ((TILE_MAP_WIDTH*TILE_MAP_HEIGHT)*2+(NUM_TILE_COLOR_PALETTES+NUM_SPRITE_COLOR_PALETTES)*16+NUM_SPRITES*4)/4 ' Number of LONGs in graphics resources buffer

OBJ
    gfx_tx        : "tx"          ' Import graphics transmission system
    input         : "input"       ' Import input system

VAR
    ' Game resource pointers
    long  input_state_base_       ' Register in Main RAM containing state of inputs
    long  gfx_resources_base_     ' Register in Main RAM containing base of graphics resources
    long  gfx_buffer_size_        ' Container for graphics resources buffer size

    ' TEST RESOURCE POINTERS
    long  satts[num_sprites]

PUB main | time,trans,cont,temp,temps,x,y
    ' Initialize variables
    input_state_base_ := @input_states                    ' Point input state base to base of input states
    gfx_resources_base_ := @tile_color_palettes           ' Set graphics resources base to start of tile color palettes
    gfx_buffer_size_ := GFX_BUFFER_SIZE                   ' Set graphics resources buffer size

    ' Start subsystems
    trans := constant(NEGX|15)                              ' link setup
    gfx_tx.start(@trans)                    ' Start graphics resource transfer system
    repeat while trans

    input.start(@input_state_base_)                       ' Start input system

    '                                  sprite         x position       y position    color v h size
    '                             |<------------->|<--------------->|<------------->|<--->|-|-|<->|
    '                              0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    satts[0] :=                   %0_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[1] :=                   %0_0_0_0_0_0_1_0_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[2] :=                   %0_0_0_0_0_0_1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[3] :=                   %0_0_0_0_0_0_1_0_0_0_0_0_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[4] :=                   %0_0_0_0_0_0_1_0_0_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[5] :=                   %0_0_0_0_0_0_1_0_0_0_0_1_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[6] :=                   %0_0_0_0_0_0_1_0_0_0_0_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[7] :=                   %0_0_0_0_0_0_1_0_0_0_0_1_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[8] :=                   %0_0_0_0_0_0_1_0_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[9] :=                   %0_0_0_0_0_0_1_0_0_0_1_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[10] :=                  %0_0_0_0_0_0_1_0_0_0_1_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[11] :=                  %0_0_0_0_0_0_1_0_0_0_1_0_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[12] :=                  %0_0_0_0_0_0_1_0_0_0_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[13] :=                  %0_0_0_0_0_0_1_0_0_0_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[14] :=                  %0_0_0_0_0_0_1_0_0_0_1_1_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
    satts[15] :=                  %0_0_0_0_0_0_1_0_0_0_1_1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

    longmove(@sprite_atts, @satts, num_sprites)

    x := 0
    y := 0
    temp := @sprite_atts + (4*17)
    repeat num_sprites-17
        x += 6
        y += 6
        x &= %111111111
        y &= %11111111
        temps := (x << 15) | (y << 7)
        longmove(temp,@temps,1)
        temp += 4

    time := cnt
    
    ' Main game loop
    repeat
        waitcnt(Time += clkfreq/60) ' Strictly for sensible sprite speed
        trans := constant(GFX_BUFFER_SIZE << 16) | @tile_color_palettes{0}            ' register send request
        left_right((control_state >> 7) & %10100000)
        up_down((control_state >> 7) & %01010000)
        cont := tilt_state
        if (tilt_state & 1) == 0
            longfill(@sprite_atts, 0, num_sprites)

pri left_right(x_but) | x,dir,mir,temp
    if x_but == %10000000 OR x_but == %00100000
        longmove(@x, @sprite_atts, 1)
        temp := x & %00000000000000000111111111111011
        dir := 1 << 24
        x >>= 15
        x &= %111111111
        if x_but == %10000000
            mir := 0
            x := (x + 1) & %111111111
        if x_but == %00100000
            mir := 1 << 2
            x := (x - 1) & %111111111
        if x == 320
            x := 505
        elseif x == 504
            x := 319
        x <<= 15
        temp |= (x | mir | dir)
        longmove(@sprite_atts, @temp, 1)

pri up_down(y_but) | y,dir,mir,temp
    if y_but == %01000000 OR y_but == %00010000
        longmove(@y, @sprite_atts, 1)
        temp := y & %00000000111111111000000001110111
        dir := 0 << 24
        y >>= 7
        y &= %11111111
        if y_but == %01000000
            mir := 1 << 3
            y := (y + 1) & %11111111
        if y_but == %00010000
            mir := 0
            y := (y - 1) & %11111111
        if y == 240
            y := 249
        elseif y == 248
            y := 239
        y <<= 7
        temp |= (y | mir | dir)
        longmove(@sprite_atts, @temp, 1)

DAT
input_states
              ' Input states
control_state word      0       ' Control states
tilt_state    word      0       ' Tilt shift state

tile_color_palettes
              ' Tile color palettes
t_palette0    byte      %00000011,%11000011,%00001111,%11111111                    ' Tile color palette 0
              byte      %11110011,%00111111,%11001111,%11000011
              byte      %11010011,%00110111,%01001111,%01111011
              byte      %11010111,%01110111,%01011111,%00000011
t_palette1    byte      %00000011,%11110011,%11001111,%11000011                    ' Tile color palette 1
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011

sprite_color_palettes
              ' Sprite color palettes
s_palette0    byte      %00000011,%00110011,%11000011,%11111111                    ' Tile color palette 0
              byte      %11110011,%00111111,%11001111,%11000011
              byte      %11010011,%00110111,%01001111,%01111011
              byte      %11010111,%01110111,%01011111,%00000011
s_palette1    byte      %00000011,%00110011,%11111111,%11000011                    ' Tile color palette 1
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011
              byte      %00000011,%00110011,%11111111,%11000011

              ' Sprite attribute table
sprite_atts   long      0[NUM_SPRITES]

tile_maps
              ' Main tile map
tile_map0     word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 0
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 1
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 2
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 3
              word      $00_01,$00_02,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$00_01,$00_02                 ' row 4
              word      $00_04,$00_03,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$00_04,$00_03                 ' row 5
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 6
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 7
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 8
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 9
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 10
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$00_04,$00_03                 ' row 11
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$00_01,$00_02                 ' row 12
              word      $00_04,$00_03,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 13
              word      $00_01,$00_02,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 14
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 15
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 16
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 17
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 18
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 19
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 20
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 21
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 22
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 23
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 24
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 25
              word      $00_01,$00_02,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_04,$01_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_01,$00_02                 ' row 26
              word      $00_04,$00_03,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00,$00_04,$00_03                 ' row 27
              word      $00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02,$00_01,$00_02                 ' row 28
              word      $00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03,$00_04,$00_03                 ' row 29