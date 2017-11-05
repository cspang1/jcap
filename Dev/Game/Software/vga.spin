{{
        File:     vga.spin
        Author:   Connor Spangler
        Date:     10/26/2017
        Version:  1.2
        Description: 
                  This file contains the PASM code to drive a VGA signal via the Propeller
                  Cog Video Generator.
}}

CON
  ' Constants defining screen dimensions
  sResH = 640                                           ' Horizontal screen resolution
  sResV = 480                                           ' Vertical screen resolution

VAR
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
  
PUB start(graphAddr, numHorTiles, numVertTiles, horTileSize, vertTileSize, horTileMapSize, vertTileMapSize)                     ' Function to start vga driver with pointer to Main RAM variables
  ' Calculate video/tile attributes                    
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
  v_scl_val_ := (c_per_pixel_ << 12) + c_per_frame_     ' Calculate vscl register value for visible pixels}}
  graphics_addr_base_ := graphAddr                      ' Point tile_map_base to base of tile maps

  ' Start VGA driver
  cognew(@vga, @graphics_addr_base_)                    ' Initialize cog running "vga" routine with reference to start of variable registers
  
DAT
        org             0
vga           
        ' Setup and start video generator
        or              dira,   vgapin          ' Set video generator output pins        
        mov             frqa,   pllfreq         ' Set Counter A frequency
        mov             ctra,   CtrCfg          ' Set Counter A control register
        mov             vcfg,   VidCfg          ' Set video generator config register
        rdlong          cnt,    #0              ' Retrive system clock
        shr             cnt,    #10             ' Set-up ~1ms wait
        add             cnt,    cnt             ' Add 1ms wait
        waitcnt         cnt,    #0              ' Allow PLL to settle
        mov             vcfg,   VidCfg          ' Start video generator

        ' Initialize frame attributes
        mov             csl,    #0              ' Initialize upscale tracking register
        mov             attptr, par             ' Set attribute pointer        
        add             attptr, #4              ' Iterate through attributes and set external to internal equivalents        
        rdlong          vTilesH,attptr
        mov             numTL,  vTilesH
        add             attptr, #4
        rdlong          vTilesV,attptr
        mov             numTF,  vTilesV
        add             attptr, #4
        rdlong          tSizeH,attptr
        add             attptr, #4
        rdlong          tSizeV,attptr
        add             attptr, #4
        rdlong          tMapSizeH,attptr
        add             attptr, #4
        rdlong          tMapSizeV,attptr
        add             attptr, #4
        rdlong          tMemSizeH,attptr
        add             attptr, #4
        rdlong          tSize,attptr
        add             attptr, #4
        rdlong          tOffset,attptr
        add             attptr, #4
        rdlong          vLineSize,attptr
        add             attptr, #4
        rdlong          tMapLineSize,attptr
        add             attptr, #4
        rdlong          tlslRatio,attptr
        mov             slr,    tlslRatio
        sub             slr,    #1
        add             attptr, #4
        rdlong          lPerTile,attptr
        mov             numLT,  lPerTile
        add             attptr, #4
        rdlong          cPerFrame,attptr
        add             attptr, #4
        rdlong          cPerPixel,attptr
        add             attptr, #4
        rdlong          vSclVal,attptr

        ' Initialize graphics resource pointers
        rdlong          tmbase, par             ' Load Main RAM tile map base address
        mov             tpbase, tmbase          ' Load Main RAM tile map base address
        mov             cpbase, tmbase          ' Load Main RAM tile map base address
        add             tpbase, #4              ' Point tile palette pointer to correct Main RAM register
        add             cpbase, #8              ' Point color palette pointer to correct Main RAM register
        rdlong          tpbase, tpbase          ' Load tile palette base pointer
        rdlong          cpbase, cpbase          ' Load color palette base pointer
        
        ' Display screen              
:frame  mov             fptr,   numTF           ' Initialize frame pointer
        rdlong          tmptr,  tmbase          ' Set tile map pointer to current start tile 

        ' Display active video
:active mov             lptr,   numLT           ' Initialize line pointer
        mov             tpptr,  #0              ' Initialize tile palette pointer
        mov             csl,    #0              ' Initialize current scan line register
        
        ' Display scanline
:tile   mov             tptr,   numTL           ' Initialize tile pointer       
        mov             vscl,   vSclVal         ' Set video scale for active video
:line
        ' Retrieve tile and colors
        rdword          cmap,   tmptr           ' Read start of tile map from Main RAM
        mov             ti,     cmap            ' Store current map into tile index
        and             ti,     #255            ' Isolate tile index of current map tile
        shr             cmap,   #8              ' Isolate color index of current map tile
        mov             ci,     cmap            ' Store color index of current map tile        
        shl             ti,     tOffset         ' Multiply tile index by size of tile map
        add             ti,     tpbase          ' Increment tile index to correct line
        add             ti,     tpptr           ' Add tile palette pointer to tile index to specify row of tile to be displayed
        test            tMaskH, tSizeV wc       ' Check the width of the tiles
        if_nc rdword    tile,   ti              ' Read 8-pixel-wide tile from Main RAM
        if_c  rdlong    tile,   ti              ' Read 16-pixel-wide tile from Main RAM
        shl             ci,     #2              ' Multiply color index by size of color palette
        add             ci,     cpbase          ' Increment color index to correct palette
        rdlong          colors, ci              ' Read tile from Main RAM
        waitvid         colors, tile            ' Update scanline
        add             tmptr,  #2              ' Increment tile map pointer to next tile in row                         
        djnz            tptr,   #:line          ' Display one whole line of scanlines

        ' Display horizontal sync area
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        sub             tmptr,  vLineSize       ' Return tile map pointer to beginning of row
        cmp             csl,    slr wz          ' Test if next line of tile palette is to be drawn   
        if_z  add       tpptr,  tMemSizeH       ' Increment tile palette pointer if so        
        if_z  mov       csl,    #0              ' Reset scan line register if so
        if_nz add       csl,    #1              ' Increment scan line register otherwise
        djnz            lptr,   #:tile          ' Display forty-eight scanlines
        add             tmptr,  tMapLineSize    ' Increment tile map pointer to next row of tiles
        djnz            fptr,   #:active        ' Display fifteen tiles

        ' Display vertical sync area
        mov             vptr,   numFP           ' Initialize vertical sync pointer        
:fporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:fporch        ' Display front porch lines           
        mov             vptr,   numVS           ' Initialize vertical sync pointer        
:vsync  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        djnz            vptr,   #:vsync         ' Display vertical sync lines 
        mov             vptr,   numBP           ' Initialize vertical sync pointer        
:bporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:bporch        ' Display back porch lines 
        jmp             #:frame                 ' Return to start of video frame      

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' VGA output pins
pllfreq       long      337893130                                                                       ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111                                      ' Video generator configuration
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register
tMaskH        long      16                                                                              ' Mask to detect horizontal pixel width of tiles

' Video Generator inputs
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
tPixel        long      %%0_0_0_0_1_1_1_1_2_2_2_2_3_3_3_3                       ' Test pixels
hPixel        long      %%0_0_0_0_0_0_3_3_3_2_2_2_2_2_2_3                       ' HSync pixels
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
vpPixel       long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Vertical porch blank pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Video attributes
numFP         long      10      ' Number of vertical front porch lines                        
numVS         long      2       ' Number of vertical sync lines                        
numBP         long      33      ' Number of vertical back porch lines

' Frame pointers
tptr          res       1       ' Current tile being rendered
lptr          res       1       ' Current line being rendered
fptr          res       1       ' Current frame position being rendered
vptr          res       1       ' Current vertical sync line being rendered
csl           res       1       ' Upscale tracking register

' Tile and color map pointers
tmptr         res       1       ' Pointer to current tile map in Main RAM
tpptr         res       1       ' Pointer to current tile palette in Main RAM
cpptr         res       1       ' Pointer to current color palette in Main RAM
tmbase        res       1       ' Pointer to tile maps base in Main RAM
tpbase        res       1       ' Pointer to tile palettes base in Main RAM
cpbase        res       1       ' Pointer to color palettes base in Main RAM
cmap          res       1       ' Current map 
ti            res       1       ' Tile index
ci            res       1       ' Color index
tile          res       1       ' Current tile section        
colors        res       1       ' Register containing current colors

' Frame attributes
numTL         res       1       ' Number of visible tiles per scanline
numLT         res       1       ' Number of scanlines per tile
numTF         res       1       ' Number of vertical tiles per frame
slr           res       1       ' Ratio of scanlines to tile lines
attptr        res       1       ' Pointer to attributes in Main RAM
vTilesH       res       1       ' Visible horizontal tiles
vTilesV       res       1       ' Visible vertical tiles
tSizeH        res       1       ' Horizontal tile size 
tSizeV        res       1       ' Vertical tile size
tMapSizeH     res       1       ' Horizontal tile map size
tMapSizeV     res       1       ' Vertical tile map size
tMemSizeH     res       1       ' Width of tile map in bytes
tSize         res       1       ' Total size of tile in bytes                       
tOffset       res       1       ' Tile offset modifier
vLineSize     res       1       ' Total visible line size in words                         
tMapLineSize  res       1       ' Total tile map line size in words                         
tlslRatio     res       1       ' Ratio of tile lines to scan lines
lPerTile      res       1       ' Scan lines per tile
cPerFrame     res       1       ' Pixel clocks per pixel
cPerPixel     res       1       ' Pixel clocks per frame
vSclVal       res       1       ' vscl register value for visible pixels
        fit
        