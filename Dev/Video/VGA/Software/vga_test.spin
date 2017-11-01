 {{
        File:     vga_test.spin
        Author:   Connor Spangler
        Date:     10/31/2017
        Version:  1.0
        Description: 
                  This file contains the PASM code to instantiate the VGA and input system drivers
}}

CON
        _clkmode = xtal1 + pll16x                       ' Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

OBJ
  input : "input"
  vga : "vga"
VAR
  long  tile_map_base_          ' Register pointing to base of tile maps
  long  tile_palette_base_      ' Register pointing to base of tile palettes
  long  color_palette_base_     ' Register pointing to base of color palettes
  long  input_state_base_       ' Register in Main RAM containing state of inputs

PUB main
  tile_map_base_ := @tile_maps                          ' Point tile_map_base to base of tile maps
  tile_palette_base_ := @tile_palettes                  ' Point tile_map_base to base of tile maps
  color_palette_base_ := @color_palettes                ' Point tile_map_base to base of tile maps
  input_state_base_ := @input_states                    ' Point tile_map_base to base of tile maps
  vga.start(@tile_map_base_)                            ' Start VGA engine
  input.start(input_state_base_)                        ' Start input system                        
  
DAT
tile_maps
              '         |<------------------visible on screen-------------------------------->|<------ to right of screen ---------->|
              ' column     0      1      2      3      4      5      6      7      8      9   |  10     11     12     13     14     15
              ' just the maze
tile_map0     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 1
              word      $00_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 2
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 3
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 4
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 5
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 6
              word      $00_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 7
              word      $00_01,$00_00,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 8
              word      $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 9
              word      $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 10
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 11
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 12
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus dots
tile_map1     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 2
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 3
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 4
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 5
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 6
              word      $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 7
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 8
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 9
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 10
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 11
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 12
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus powerpills
tile_map2     word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 0
              word      $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 1
              word      $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 2
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 3
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 4
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 5
              word      $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 6
              word      $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 7
              word      $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 8
              word      $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 9
              word      $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00                 ' row 10
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 11
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 12
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 13
              word      $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01                 ' row 14

              ' maze plus powerpills (alt color)
tile_map3     word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 0
              word      $01_01,$01_04,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_04,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 1
              word      $01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 2
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 3
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_02,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 4
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_01,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 5
              word      $01_01,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 6
              word      $01_01,$01_02,$01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 7
              word      $01_01,$01_02,$01_01,$01_02,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 8
              word      $01_01,$01_02,$01_01,$01_01,$01_02,$01_01,$01_02,$01_01,$01_02,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 9
              word      $01_01,$01_04,$01_02,$01_02,$01_02,$01_02,$01_02,$01_02,$01_04,$01_01,$01_00,$01_00,$01_00,$01_00,$01_00,$01_00                 ' row 10
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 11
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 12
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 13
              word      $01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01,$01_01                 ' row 14

tile_palettes
              ' empty tile
tile_blank    long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' box tile
tile_box      long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' tile 1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1

              ' dot tile
tile_dot      long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 2
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long      %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long      %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long      %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup      long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 3
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long      %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long      %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long      %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long      %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long      %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long      %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long      %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long      %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long      %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup2     long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' tile 4
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_3_3_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_3_2_2_3_0_0_0_0_0_0
              long      %%0_0_0_0_0_3_2_2_2_2_3_0_0_0_0_0
              long      %%0_0_0_0_3_2_2_2_2_2_2_3_0_0_0_0
              long      %%0_0_0_3_2_2_2_2_2_2_2_2_3_0_0_0
              long      %%0_0_3_2_2_2_2_2_2_2_2_2_2_3_0_0
              long      %%0_0_3_2_2_2_2_2_2_2_2_2_2_3_0_0
              long      %%0_0_0_3_2_2_2_2_2_2_2_2_3_0_0_0
              long      %%0_0_0_0_3_2_2_2_2_2_2_3_0_0_0_0
              long      %%0_0_0_0_0_3_2_2_2_2_3_0_0_0_0_0
              long      %%0_0_0_0_0_0_3_2_2_3_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_3_3_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

color_palettes
              ' Test palettes
c_palette1    long      %11000011_00110011_00011111_00000011                    ' palette 0 - background and wall tiles, 0-black,
                                                                                ' 1-blue, 2-red, 3-white
c_palette2    long      %00000011_00110011_11111111_11000011                    ' palette 1 - background and wall tiles, 0-black,

input_states
              ' Input states
control_state long      0       ' Control (joystick/button) states
tilt_state    byte      0       ' Tilt shift state 
                                                       
