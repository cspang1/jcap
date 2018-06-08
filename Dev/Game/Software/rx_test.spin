{{
        File:     txrx.spin
        Author:   Connor Spangler
        Date:     5/9/2018
        Version:  1.0
        Description: 
                  This file contains the PASM code defining a test transmission routine
}}

CON
  ' Clock settings
  _clkmode = xtal1 + pll16x     ' Standard clock mode w/ 16x PLL
  _xinfreq = 6_500_000          ' 6.5 MHz clock for x16 = 104 MHz

  ' Game settings
  NUM_TILE_PALETTES = 256                               ' Number of tile palettes
  NUM_SPRITE_PALETTES = 256                             ' Number of sprite palettes
  NUM_TILE_COLOR_PALETTES = 32                          ' Number of tile color palettes
  NUM_SPRITE_COLOR_PALETTES = 32                        ' Number of sprite color palettes
  NUM_SPRITES = 64                                      ' Number of sprites in sprite attribute table
  TILE_MAP_WIDTH = 40                                   ' Number of horizontal tiles in tile map
  TILE_MAP_HEIGHT = 30                                  ' Number of vertical tiles in tile map

  ' Display system attributes
  GFX_BUFFER_SIZE = ((TILE_MAP_WIDTH*TILE_MAP_HEIGHT)*2+(NUM_TILE_COLOR_PALETTES+NUM_SPRITE_COLOR_PALETTES)*16+NUM_SPRITES*4)/4 ' Number of LONGs in graphics resources buffer
  VID_BUFFER_SIZE = 80                                                                                                          ' Number of scanline segments in video buffer

OBJ
  vga_rx        : "vga_rx"      ' Import graphics reception system
  vga_render    : "vga_render"  ' Import VGA render system
  vga_display   : "vga_display" ' Import VGA display system

VAR
  ' Video system pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system
  long  scanline_buff_base_     ' Register in Main RAM containing the scanline buffer
  long  gfx_buffer_base_        ' Register in Main RAM containing the graphics buffer
  long  gfx_buffer_size_        ' Size of the graphics buffer

PUB main
' Initialize pointers 
  cur_scanline_base_ := @cur_scanline                   ' Point current scanline base to current scanline
  scanline_buff_base_ := @scanline_buff                 ' Point video buffer base to video buffer
  gfx_buffer_base_ := @gfx_buff                         ' Point graphics buffer base to graphics buffer
  gfx_buffer_size_ := GFX_BUFFER_SIZE                   ' Set the size of the graphics resources buffer

  ' Start subsystems
  vga_rx.start(@gfx_buffer_base_)                       ' Start video data RX driver
  vga_display.start(@cur_scanline_base_)                ' Start display driver
  vga_render.start(@cur_scanline_base_)                 ' Start renderers

DAT

cur_scanline  long      0                       ' Current scanline being rendered
scanline_buff long      0[VID_BUFFER_SIZE]      ' Video buffer
gfx_buff      long      0[GFX_BUFFER_SIZE]      ' Graphics resources buffer

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

tp_fill       long      0[2008]

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

sp_fill       long      0[2024]
