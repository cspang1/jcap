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
  VID_BUFF_SIZE = 80
  GFX_BUFF_SIZE = ((32*16)*2+(64*4)+(40*30*2))/4

OBJ
  vga_rx        : "vga_rx"      ' Import graphics reception system
  vga_render    : "vga_render"  ' Import VGA render system
  vga_display   : "vga_display" ' Import VGA display system

VAR
  ' Video system pointers
  long  cur_scanline_base_      ' Register in Main RAM containing current scanline being requested by the VGA Display system
  long  scanline_buff_base_     ' Register in Main RAM containing the scanline buffer
  long  gfx_buffer_base_        ' Register in Main RAM containing the graphics buffer

PUB main
' Initialize pointers 
  cur_scanline_base_ := @cur_scanline                   ' Point current scanline base to current scanline
  scanline_buff_base_ := @scanline_buff                 ' Point video buffer base to video buffer
  gfx_buffer_base_ := @gfx_buff                         ' Point graphics buffer base to graphics buffer

  vga_render.start(@cur_scanline_base_)                 ' Start renderers
  vga_display.start(@cur_scanline_base_)                ' Start display driver
  vga_rx.start(gfx_buffer_base_)                        ' Start video data RX driver

DAT

cur_scanline  long      0                       ' Current scanline being rendered
scanline_buff long      0[VID_BUFF_SIZE]        ' Video buffer

{{
              Graphics Buffer Layout:
              $0000 - $01FF     (128 LONGs/512 BYTEs)   Tile Color Palettes     }
              $0200 - $03FF     (128 LONGs/512 BYTEs)   Sprite Color Palettes   }___ Transfered
              $0400 - $04FF     (64 LONGs/256 BYTEs)    Sprite Attribute Table  }    from CPU
              $0500 - $0E5F     (600 LONGs/2400 BYTEs)  Tile Map                }
              -------------
              $0E60 - $2E59     (2048 LONGs/8192 BYTEs) Tile Palettes           }___ Stored statically
              $2E60 - $4E59     (2048 LONGs/8192 BYTEs) Sprite Palettes         }    within GPU
}}

gfx_buff      long      0[GFX_BUFF_SIZE]

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
              ' Blank sprite
sprite_test   long      $5_5_5_5_5_5_5_5        ' Sprite 2
              long      $F_F_F_F_F_F_F_F
              long      $4_4_4_4_4_4_4_4
              long      $F_F_F_F_F_F_F_F
              long      $6_6_6_6_6_6_6_6
              long      $F_F_F_F_F_F_F_F
              long      $8_8_8_8_8_8_8_8
              long      $F_F_F_F_F_F_F_F

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