{{
        File:     gpu.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code defining a JCAP GPU
}}

CON
    ' Clock settings
    _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
    _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

    ' Pin settings
    VS_PIN = 0
    RX_PIN = 1
    KEY_PIN = 8
    DEBUG_PIN = 27

OBJ
    system        : "system"      ' Import system settings
    gfx_rx        : "rx"          ' Import graphics reception system
    vga_render    : "vga_render"  ' Import VGA render system
    vga_display   : "vga_display" ' Import VGA display system
    serial        : "serial"      ' Import COM serial system

VAR
    ' Video system pointers
    long  gfx_buffer_base_        ' Register pointing to graphics resources buffer
    long  gfx_buffer_size_        ' Size of the graphics buffer
    long  data_ready_base_        ' Register pointing to data status indicator
    long  cur_scanline_base_      ' Register pointing to current scanline being requested by the VGA Display system
    long  scanline_buff_base_     ' Register pointing to scanline buffer
    long  horizontal_position_    ' Register pointing to base of tile color palettes
    long  tcolor_palette_base_    ' Register pointing to base of tile color palettes
    long  scolor_palette_base_    ' Register pointing to base of sprite color palettes
    long  sprite_att_base_        ' Register pointing to base of sprite attribute table
    long  tile_map_base_          ' Register pointing to base of tile maps
    long  tile_palette_base_      ' Register pointing to base of tile palettes
    long  sprite_palette_base_    ' Register pointing to base of sprite palettes

PUB main | rx1, rx2, debug
    ' Set unused pin states
    ' dira[2..7]~~
    ' dira[9..15]~~
    ' dira[27]~~
    ' outa[2..7]~
    ' outa[9..15]~
    ' outa[27]~

    dira[KEY_PIN]~
    dira[DEBUG_PIN]~

    ' Initialize graphics system pointers
    gfx_buffer_base_ := @gfx_buff                                                   ' Point graphics buffer base to graphics buffer
    gfx_buffer_size_ := system#GFX_BUFFER_SIZE                                      ' Set the size of the graphics resources buffer
    cur_scanline_base_ := @cur_scanline                                             ' Point current scanline base to current scanline
    data_ready_base_ := @data_ready                                                 ' Point data ready base to data ready indicator
    scanline_buff_base_ := @scanline_buff                                           ' Point video buffer base to video buffer
    horizontal_position_ := gfx_buffer_base_                                        ' Point tile color palette base to base of tile color palettes
    tcolor_palette_base_ := horizontal_position_+system#NUM_PARALLAX_REGS*4         ' Point tile color palette base to base of tile color palettes
    scolor_palette_base_ := tcolor_palette_base_+system#NUM_TILE_COLOR_PALETTES*4*4 ' Point sprite color palette base to base of sprite color palettes
    sprite_att_base_ := scolor_palette_base_+system#NUM_SPRITE_COLOR_PALETTES*4*4   ' Point sprite attribute table base to base of sprite attribute table
    tile_map_base_ := sprite_att_base_+system#SAT_SIZE*4                            ' Point tile map base to base of tile maps
    tile_palette_base_ := @tile_palettes                                            ' Point tile palette base to base of tile palettes
    sprite_palette_base_ := @sprite_palettes                                        ' Point sprite palette base to base of sprite palettes

    ' Start subsystems
    rx1 := constant(NEGX|RX_PIN)
    rx2 := constant(system#GFX_BUFFER_SIZE << 16) | @gfx_buff

    if ina[DEBUG_PIN]
        serial.init(31, 30, 19200)
        debug := 0
        repeat while debug == 0
            debug := serial.rx
            if debug <> 89
                debug := 0
        if ina[KEY_PIN]
            serial.str(string("GPU"))
        else
            serial.str(string("CPU"))
        serial.finalize

    gfx_rx.start(@rx1, VS_PIN, RX_PIN)                       ' Start video data RX driver
    repeat while rx1

    vga_display.start(@data_ready_base_)                  ' Start display driver
    vga_render.start(@data_ready_base_)                   ' Start renderers

DAT

              ' Graphics engine resources
data_ready    long      0                       ' Graphics data ready indicator
cur_scanline  long      0                       ' Current scanline being rendered
scanline_buff long      0[system#VID_BUFFER_SIZE]      ' Video buffer
gfx_buff      long      0[system#GFX_BUFFER_SIZE]      ' Graphics resources buffer

tile_palettes   file    "tiles.dat"

sprite_palettes file    "sprites.dat"