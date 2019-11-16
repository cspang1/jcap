{{
        File:     cpu.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code defining a JCAP CPU
}}

CON
    ' clock_ settings
    _clkmode = xtal1 + pll16x     ' Standard clock_ mode w/ 16x PLL
    _xinfreq = 6_500_000          ' 6.5 MHz clock_ for x16 = 104 MHz

    ' Pin settings
    VS_PIN = 14
    TX_PIN = 15

    ' Test settings
    NUM_SEA_LINES = 56

OBJ
    system        : "system"      ' Import system settings
    gfx_tx        : "tx"          ' Import graphics transmission system
    input         : "input"       ' Import input system
    gfx_utils     : "gfx_utils"   ' Import graphics utilities
    math_utils    : "math_utils"  ' Import math utilities

VAR
    ' Game resource pointers
    long    gfx_resources_base_     ' Register in Main RAM containing base of graphics resources

    ' Game clock_
    long    clock_

    ' TEST RESOURCE POINTERS
    long    plxvars[NUM_SEA_LINES]

PUB main | time,trans,temp,x,y,z,q
    ' Set unused pin states
    dira[3..7]~~
    dira[8..13]~~
    dira[16..27]~~
    outa[3..7]~
    outa[8..13]~
    outa[16..27]~

    ' Initialize variables
    gfx_resources_base_ := @gfx_base           ' Set graphics resources base to start of tile color palettes
    gfx_utils.setup (@plx_pos, @sprite_atts)
    clock_ := 0

    ' Start subsystems
    trans := constant(NEGX|TX_PIN)                              ' link setup
    gfx_tx.start(@trans, VS_PIN, TX_PIN)                    ' Start graphics resource transfer system
    repeat while trans
    input.start                       ' Start input system

    '     sprite         x position       y position    color v h size
    '|<------------->|<--------------->|<------------->|<--->|-|-|<->|
    ' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    '|----spr<<24----|------x<<15------|-----y<<7------|c<<4-|8|4|x-y|

    {temp := 0
    x := 0  ' starting horizontal pos
    y := 128 'starting vertical pos
    z := 1 'sprites per line
    q := 1 'n lines
    repeat q
        repeat z
            gfx_utils.init_sprite (0,x+=16,y,0,false,false,true,true,temp++)
        y += 16
        x := 0
    repeat system#SAT_SIZE-z*q
        gfx_utils.init_sprite (0,0,0,0,false,false,true,true,temp++)}

    ' Initialize sprites
    gfx_utils.init_sprite (0,16,16,0,false,false,true,true,0)
    gfx_utils.init_sprite (4,40,85,0,false,true,false,false,1)
    gfx_utils.init_sprite (4,56,56,0,false,false,false,false,2)
    gfx_utils.init_sprite (4,190,22,0,false,true,false,false,3)
    gfx_utils.init_sprite (4,260,70,0,false,false,false,false,4)

    ' Setup parallaxing
    longfill(@plx_pos, 0, system#NUM_PARALLAX_REGS)
    gfx_utils.set_scr_reg_pos (50,0,0)
    x := 79
    repeat temp from 1 to NUM_SEA_LINES
        if (temp-1)//2 == 0
            plxvars[temp-1] := temp-1+148
        else
            plxvars[temp-1] := temp-1
        long[@plx_pos][temp] := x
        x += 1 
    long[@plx_pos][NUM_SEA_LINES+1] := x

    time := cnt

    ' Main game loop
    repeat
        waitcnt(time += clkfreq/60) ' Strictly for sensible sprite speed
        trans := constant(system#GFX_BUFFER_SIZE << 16) | @plx_pos{0}            ' register send request
        ifnot time//4
          long[@ti_col_pal][6] <-= 8
        repeat temp from 1 to NUM_SEA_LINES
            plxvars[temp-1] := plxvars[temp-1] + 2
            x := math_utils.sin(-plxvars[temp-1],(temp-1)//4) + 50 - (temp-1)
            if x < 0
                x += 447
            gfx_utils.set_scr_reg_hor_pos(x,temp)
        move(input.get_control_state)
        if input.get_tilt_state & 1
            longfill(@sprite_atts, 0, system#SAT_SIZE)
        animate_birds
        clock_++

pri animate_birds
    gfx_utils.animate_sprite (1,clock_,15,8,@anim_bird)
    gfx_utils.animate_sprite (2,clock_,15,8,@anim_bird)
    gfx_utils.animate_sprite (3,clock_,15,8,@anim_bird)
    gfx_utils.animate_sprite (4,clock_,15,8,@anim_bird)
    ifnot clock_//2
      gfx_utils.mv_sprite(1,0,1)
      gfx_utils.mv_sprite(-1,0,2)
      gfx_utils.mv_sprite(1,0,3)
      gfx_utils.mv_sprite(-1,0,4)

pri move(inputs)
    if inputs & $1000
        gfx_utils.mv_sprite(1,0,0)
        gfx_utils.set_sprite_hor_mir(false,0)
        gfx_utils.mv_scr_reg(1,0,57)
    if inputs & $4000
        gfx_utils.mv_sprite(-1,0,0)
        gfx_utils.set_sprite_hor_mir(true,0)
        gfx_utils.mv_scr_reg(-1,0,57)
    if inputs & $2000
        gfx_utils.mv_sprite(0,1,0)
        gfx_utils.set_sprite_vert_mir(true,0)
        gfx_utils.mv_scr_reg(0,1,57)
    if inputs & $8000
        gfx_utils.mv_sprite(0,-1,0)
        gfx_utils.set_sprite_vert_mir(false,0)
        gfx_utils.mv_scr_reg(0,-1,57)

DAT
anim_bird     byte    4,5,6,5,4,7,8,7

plx_pos       long    0[system#NUM_PARALLAX_REGS]   ' Parallax array (x[31:20]|y[19:8]|i[7:0] where 'i' is scanline index)

gfx_base
ti_col_pal  file    "tile_color_palettes.dat"

spr_col_pal file    "sprite_color_palettes.dat"

            ' Sprite attribute table
sprite_atts long    0[system#SAT_SIZE]

tile_maps   file    "tile_maps.dat"