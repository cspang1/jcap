{{
        File:     cpu.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code defining a JCAP CPU
}}

CON
    ' clock settings
    _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
    _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

    ' Pin settings
    KEY_PIN = 8
    VS_PIN = 14
    TX_PIN = 15
    DEBUG_PIN = 27

    ' Test settings
    NUM_SEA_LINES = 56
    #0, UP, DOWN, LEFT, RIGHT

OBJ
    system        : "system"      ' Import system settings
    gfx_tx        : "tx"          ' Import graphics transmission system
    input         : "input"       ' Import input system
    gfx_utils     : "gfx_utils"   ' Import graphics utilities
    math_utils    : "math_utils"  ' Import math utilities
    serial        : "serial"      ' Import COM serial system

VAR
    ' Game resource pointers
    long    gfx_resources_base_     ' Register in Main RAM containing base of graphics resources

    ' Game clocks
    long    clock_

    ' TEST RESOURCE POINTERS
    long    plxvars[NUM_SEA_LINES]
    word    foxposx
    byte    foxposy
    byte    jumping
    byte    crouching
    byte    facing
    byte    jmpcnt
    byte    stillcnt
    byte    walkcnt

PUB main | time,trans,temp,x,y,z,q,elapsed,inputs
    ' Set unused pin states
    ' dira[3..7]~~
    ' dira[9..13]~~
    ' dira[16..26]~~
    ' outa[3..7]~
    ' outa[9..13]~
    ' outa[16..26]~

    dira[KEY_PIN]~
    dira[DEBUG_PIN]~

    ' Initialize variables
    gfx_resources_base_ := @gfx_base           ' Set graphics resources base to start of tile color palettes
    gfx_utils.setup (@plx_pos, @sprite_atts)
    clock_ := 0

    if ina[DEBUG_PIN]
        serial.init(31, 30, 19200)
        inputs := 0
        repeat while inputs == 0
            inputs := serial.rx
            if inputs <> 89
                inputs := 0
        if ina[KEY_PIN]
            serial.str(string("GPU"))
        else
            serial.str(string("CPU"))
        serial.finalize

    ' Start subsystems
    input.start                             ' Start input system
    trans := constant(NEGX|TX_PIN)          ' link setup
    gfx_tx.start(@trans, VS_PIN, TX_PIN)    ' Start graphics resource transfer system
    repeat while trans

    ' Initialize sprites
    ' Fox
    foxposx := 16
    foxposy := 123
    stillcnt := 0
    walkcnt := 0
    jumping := false
    crouching := false
    facing := RIGHT
    gfx_utils.init_sprite ($4,foxposx,foxposy,$2,false,false,true,true,0)
    gfx_utils.init_sprite ($6,foxposx+16,foxposy,$2,false,false,true,true,1)
    gfx_utils.init_sprite ($8,foxposx,foxposy+16,$2,false,false,true,true,2)
    gfx_utils.init_sprite ($A,foxposx+16,foxposy+16,$2,false,false,true,true,3)

    ' Birds
    gfx_utils.init_sprite ($0,40,85,$0,false,true,false,false,4)
    gfx_utils.init_sprite ($0,56,56,$0,false,false,false,false,5)
    gfx_utils.init_sprite ($0,190,22,$0,false,true,false,false,6)
    gfx_utils.init_sprite ($0,260,70,$0,false,false,false,false,7)

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
        if jumping and jmpcnt < 25
            animate_fox_jump
            jmpcnt++
            stillcnt := 0
            walkcnt := 0
        else
            jumping := false
            jmpcnt := 0
        clock_++

pri move(inputs)
    if inputs & $1000 ' Right
        ifnot crouching
            if (gfx_utils.get_scr_reg_hor_pos(57) < 128) and (gfx_utils.get_sprite_hor_pos(0) == 172)
                gfx_utils.mv_scr_reg(1,0,57)
            move_fox(RIGHT)
            walkcnt++
            stillcnt := 0
    if inputs & $4000 ' Left
        ifnot crouching
            if(gfx_utils.get_scr_reg_hor_pos(57) > 0)  and (gfx_utils.get_sprite_hor_pos(0) == 172)
                gfx_utils.mv_scr_reg(-1,0,57)
            move_fox(LEFT)
            walkcnt++
            stillcnt := 0
    if inputs & $2000 ' Up
        ifnot jumping or crouching
            jumping := true
    if inputs & $8000 ' Down
        ifnot jumping
            gfx_utils.set_sprite_tile ($3,0)
            gfx_utils.set_sprite_tile ($28,1)
            gfx_utils.set_sprite_tile ($2A,2)
            gfx_utils.set_sprite_tile ($2C,3)
            crouching := true
            stillcnt := 0
            walkcnt := 0
    else
        crouching := false
    ifnot (inputs & $F000)
        walkcnt := 0
        ifnot jumping
            animate_fox_still
            stillcnt++

pri move_fox(dir) | xpos0,xpos1,xpos2,xpos3,ypos0,ypos1,ypos2,ypos3,newdir
    xpos0 := gfx_utils.get_sprite_hor_pos(0)
    xpos1 := gfx_utils.get_sprite_hor_pos(1)
    xpos2 := gfx_utils.get_sprite_hor_pos(2)
    xpos3 := gfx_utils.get_sprite_hor_pos(3)
    ypos0 := gfx_utils.get_sprite_vert_pos(0)
    ypos1 := gfx_utils.get_sprite_vert_pos(1)
    ypos2 := gfx_utils.get_sprite_vert_pos(2)
    ypos3 := gfx_utils.get_sprite_vert_pos(3)

    if dir == RIGHT
        foxposx++
        newdir := RIGHT
        if facing <> newdir
            gfx_utils.mv_sprite(-16,0,0)
            gfx_utils.mv_sprite(16,0,1)
            gfx_utils.mv_sprite(-16,0,2)
            gfx_utils.mv_sprite(16,0,3)
        if (gfx_utils.get_sprite_hor_pos(0) < 172) or (gfx_utils.get_scr_reg_hor_pos(57) == 128)
            gfx_utils.mv_sprite(1,0,0)
            gfx_utils.mv_sprite(1,0,1)
            gfx_utils.mv_sprite(1,0,2)
            gfx_utils.mv_sprite(1,0,3)
        gfx_utils.set_sprite_hor_mir(false,0)
        gfx_utils.set_sprite_hor_mir(false,1)
        gfx_utils.set_sprite_hor_mir(false,2)
        gfx_utils.set_sprite_hor_mir(false,3)
    elseif dir == LEFT
        foxposx--
        newdir := LEFT
        if facing <> newdir
            gfx_utils.mv_sprite(16,0,0)
            gfx_utils.mv_sprite(-16,0,1)
            gfx_utils.mv_sprite(16,0,2)
            gfx_utils.mv_sprite(-16,0,3)
        if (gfx_utils.get_sprite_hor_pos(0) > 172) or (gfx_utils.get_scr_reg_hor_pos(57) == 0)
            gfx_utils.mv_sprite(-1,0,0)
            gfx_utils.mv_sprite(-1,0,1)
            gfx_utils.mv_sprite(-1,0,2)
            gfx_utils.mv_sprite(-1,0,3)
        gfx_utils.set_sprite_hor_mir(true,0)
        gfx_utils.set_sprite_hor_mir(true,1)
        gfx_utils.set_sprite_hor_mir(true,2)
        gfx_utils.set_sprite_hor_mir(true,3)

    facing := newdir
    ifnot jumping
        animate_fox_walk

pri animate_fox_still
    gfx_utils.set_sprite_tile($4,0)
    gfx_utils.set_sprite_tile($6,1)
    gfx_utils.animate_sprite (stillcnt,60,2,@fox_stillbl,2)
    gfx_utils.animate_sprite (stillcnt,60,2,@fox_stillbr,3)

pri animate_fox_walk
    gfx_utils.set_sprite_tile($4,0)
    gfx_utils.set_sprite_tile($6,1)
    gfx_utils.animate_sprite (walkcnt,15,4,@fox_walkbl,2)
    gfx_utils.animate_sprite (walkcnt,15,4,@fox_walkbr,3)

pri animate_fox_jump
    gfx_utils.animate_sprite (jmpcnt,5,5,@fox_jumptl,0)
    gfx_utils.animate_sprite (jmpcnt,5,5,@fox_jumptr,1)
    gfx_utils.animate_sprite (jmpcnt,5,5,@fox_jumpbl,2)
    gfx_utils.animate_sprite (jmpcnt,5,5,@fox_jumpbr,3)   

pri animate_birds
    gfx_utils.animate_sprite (clock_,15,8,@anim_bird,4)
    gfx_utils.animate_sprite (clock_,15,8,@anim_bird,5)
    gfx_utils.animate_sprite (clock_,15,8,@anim_bird,6)
    gfx_utils.animate_sprite (clock_,15,8,@anim_bird,7)
    ifnot clock_//2
      gfx_utils.mv_sprite(1,0,4)
      gfx_utils.mv_sprite(-1,0,5)
      gfx_utils.mv_sprite(1,0,6)
      gfx_utils.mv_sprite(-1,0,7)

DAT
anim_bird       byte    $0,$1,$10,$1,$0,$11,$2,$11
fox_stillbl     byte    $8,$C
fox_stillbr     byte    $A,$E
fox_walkbl      byte    $20,$8,$24,$8
fox_walkbr      byte    $22,$A,$26,$A
fox_jumptl      byte    $3,$40,$44,$48,$3
fox_jumptr      byte    $28,$42,$46,$4A,$28
fox_jumpbl      byte    $2A,$60,$64,$68,$2A
fox_jumpbr      byte    $2C,$62,$66,$6A,$2C

plx_pos       long    0[system#NUM_PARALLAX_REGS]
gfx_base
ti_col_pal  file    "tile_color_palettes.dat"
spr_col_pal file    "sprite_color_palettes.dat"
sprite_atts long    0[system#SAT_SIZE]
tile_maps   file    "tile_maps.dat"
