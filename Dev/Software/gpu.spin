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
    VS_PIN = 26
    RX_PIN = 0

OBJ
    system        : "system"      ' Import system settings
    gfx_rx        : "rx"          ' Import graphics reception system
    vga_render    : "vga_render"  ' Import VGA render system
    vga_display   : "vga_display" ' Import VGA display system

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

PUB main | rx1, rx2
    ' Initialize graphics system pointers
    gfx_buffer_base_ := @gfx_buff                                                 ' Point graphics buffer base to graphics buffer
    gfx_buffer_size_ := system#GFX_BUFFER_SIZE                                           ' Set the size of the graphics resources buffer
    cur_scanline_base_ := @cur_scanline                                           ' Point current scanline base to current scanline
    data_ready_base_ := @data_ready                                               ' Point data ready base to data ready indicator
    scanline_buff_base_ := @scanline_buff                                         ' Point video buffer base to video buffer
    horizontal_position_ := gfx_buffer_base_                                      ' Point tile color palette base to base of tile color palettes
    tcolor_palette_base_ := horizontal_position_ + 4                                      ' Point tile color palette base to base of tile color palettes
    scolor_palette_base_ := tcolor_palette_base_+system#NUM_TILE_COLOR_PALETTES*4*4      ' Point sprite color palette base to base of sprite color palettes
    sprite_att_base_ := scolor_palette_base_+system#NUM_SPRITE_COLOR_PALETTES*4*4        ' Point sprite attribute table base to base of sprite attribute table
    tile_map_base_ := sprite_att_base_+system#NUM_SPRITES*4                              ' Point tile map base to base of tile maps
    tile_palette_base_ := @tile_palettes                                          ' Point tile palette base to base of tile palettes
    sprite_palette_base_ := @sprite_palettes                                      ' Point sprite palette base to base of sprite palettes

    ' Start subsystems
    rx1 := constant(NEGX|0)
    rx2 := constant(system#GFX_BUFFER_SIZE << 16) | @gfx_buff
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

tile_palettes
              ' Empty tile
tile_blank    long      $0_0_0_0_0_0_0_0        ' Tile 0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0
              long      $0_0_0_0_0_0_0_0

              ' Upper left corner of box
tile_box_tl   long      $1_1_1_1_1_1_1_1        ' Tile 1
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2

              ' Upper right corner of box
tile_box_tr   long      $1_1_1_1_1_1_1_1        ' Tile 2
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1

              ' Bottom right corner of box
tile_box_br   long      $2_2_2_2_2_2_2_1        ' Tile 3
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $2_2_2_2_2_2_2_1
              long      $1_1_1_1_1_1_1_1

              ' Bottom left corner of box
tile_box_bl   long      $1_2_2_2_2_2_2_2        ' Tile 4
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_2_2_2_2_2_2_2
              long      $1_1_1_1_1_1_1_1

sprite_palettes
              ' Ship sprite
sprite_ship   long      $0_0_0_0_1_0_0_0        ' Sprite 0
              long      $0_0_0_1_1_1_0_0
              long      $0_0_0_0_1_0_0_0
              long      $0_0_0_0_1_0_0_0
              long      $0_0_0_1_1_1_0_0
              long      $0_0_1_2_2_2_1_0
              long      $0_4_1_3_3_3_1_6
              long      $0_4_1_0_3_0_1_6

              ' Rock sprite
sprite_rock   long      $0_0_0_0_0_0_0_0        ' Sprite 1
              long      $4_4_0_0_0_0_0_0
              long      $1_1_1_0_0_0_0_0
              long      $0_3_2_1_0_0_1_0
              long      $3_3_2_1_1_1_1_1
              long      $0_3_2_1_0_0_1_0
              long      $1_1_1_0_0_0_0_0
              long      $6_6_0_0_0_0_0_0

              ' Blank sprite
sprite_blank  long      $5_5_5_5_5_5_5_5        ' Sprite 2
              long      $F_F_F_F_F_F_F_F
              long      $4_4_4_4_4_4_4_4
              long      $F_F_F_F_F_F_F_F
              long      $6_6_6_6_6_6_6_6
              long      $F_F_F_F_F_F_F_F
              long      $8_8_8_8_8_8_8_8
              long      $F_F_F_F_F_F_F_F