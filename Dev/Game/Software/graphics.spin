{{
        File:     graphics.spin
        Author:   Connor Spangler
        Date:     10/26/2017
        Version:  1.2
        Description: 
                  This file contains the object code to enable configuration and launching
                  of VGA, RGBS, and NTSC graphics drivers
}}

CON
  ' Constants defining screen dimensions
  sResH = 640   ' Horizontal screen resolution
  sResV = 480   ' Vertical screen resolution

  ' Enumeration of video modes
  #0
  VGA_mode      ' VGA video mode                                                                      
  RGBS_mode     ' RGBS video mode
  NTSC_mode     ' NTSC video mode

OBJ
  vga : "vga"
  'rgbs : "rgbs"
  'ntsc : "ntsc"
  
VAR
  ' Video dirver attributes
  long  graphics_addr_base_                             ' Variable for pointer to base address of graphics
  long  v_tiles_h_                                      ' Variable for visible horizontal tiles 
  long  v_tiles_v_                                      ' Variable for visible vertical tiles
  long  t_size_h_                                       ' Variable for horizontal tile size 
  long  t_size_v_                                       ' Variable for vertical tile size
  long  t_map_size_h_                                   ' Variable for horizontal tile map size
  long  t_map_size_v_                                   ' Variable for vertical tile map size
  long  t_mem_size_h_                                   ' Variable for width of tile map in bytes
  long  t_size_                                         ' Variable for total size of tile in bytes                       
  long  t_offset_                                       ' Variable for tile offset modifier
  long  v_line_size_                                    ' Variable for total visible line size in words                         
  long  t_map_line_size_                                ' Variable for total tile map line size in words                         
  long  tlsl_ratio_                                     ' Variable for ratio of tile lines to scan lines
  long  l_per_tile_                                     ' Variable for scan lines per tile
  long  c_per_frame_                                    ' Variable for pixel clocks per pixel
  long  c_per_pixel_                                    ' Variable for pixel clocks per frame
  long  v_scl_val_                                      ' Variable for vscl register value for visible pixels

  ' Graphics system attributes
  byte  video_mode_                                     ' Variable for current video mode
  
PUB config(vidMode, graphAddr, numHorTiles, numVertTiles, horTileSize, vertTileSize, horTileMapSize, vertTileMapSize) : vidstatus                        ' Function to start vga driver with pointer to Main RAM variables
  ' Calculate video/tile attributes                    
  graphics_addr_base_ := graphAddr                      ' Point tile_map_base to base of tile maps
  v_tiles_h_ := numHorTiles                             ' Set visible horizontal tiles
  v_tiles_v_ := numVertTiles                            ' Set visible vertical tiles
  t_size_h_ := horTileSize                              ' Set horizontal tile size 
  t_size_v_ := vertTileSize                             ' Set vertical tile size
  t_map_size_h_ := horTileMapSize                       ' Set horizontal tile map size
  t_map_size_v_ := vertTileMapSize                      ' Set vertical tile map size
  t_mem_size_h_ := t_size_h_ / 4                        ' Calculate width of tile map in bytes
  t_size_ := t_mem_size_h_ * t_size_v_                  ' Calculate total size of tile in bytes                       
  t_offset_ := (>| t_size_) - 1                         ' Calculate tile offset modifier
  v_line_size_ := v_tiles_h_ * 2                        ' Calculate total visible line size in words                         
  t_map_line_size_ := t_map_size_h_ * 2                 ' Calculate total tile map line size in words                         
  tlsl_ratio_ := (sResV / t_size_v_) / v_tiles_v_       ' Calculate ratio of tile lines to scan lines
  l_per_tile_ := tlsl_ratio_ * t_size_v_                ' Calculate scan lines per tile
  c_per_frame_ := sResH / v_tiles_h_                    ' Calculate pixel clocks per pixel
  c_per_pixel_ := c_per_frame_ / t_size_h_              ' Calculate pixel clocks per frame
  v_scl_val_ := (c_per_pixel_ << 12) + c_per_frame_     ' Calculate vscl register value for visible pixels

  ' Set video mode
  video_mode_ := vidMode

PUB start
  ' Start specified video driver
  case video_mode_
    VGA_mode : return vga.start(@graphics_addr_base_)   ' Initialize cog running VGA driver with reference to start of variable registers
    RGBS_mode : return FALSE                            ' Initialize cog running RGBS driver with reference to start of variable registers
    NTSC_mode : return FALSE                            ' Initialize cog running NTSC driver with reference to start of variable registers
    other : abort FALSE                                 ' Invalid driver specified; abort
      
PUB stop
  ' Stop specified video driver
  case video_mode_
    VGA_mode : vga.stop         ' Stop VGA driver
    RGBS_mode : return          ' Stop RGBS driver
    NTSC_mode : return          ' Stop NTSC driver
    other : abort               ' Invalid driver specified; abort
  