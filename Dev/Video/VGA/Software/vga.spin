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
  vTilesH = 10                                          ' Number of visible tiles horizontally                                          
  vTilesV = 10                                          ' Number of visible tiles vertically

  ' Constants defining memory tile map
  tMapSizeH = 16                                        ' Horizontal tile map size in words
  tMapSizeV = 10                                        ' Vertical tile map size in words

  ' Constants defining memory tile palette
  tSizeH = 16                                           ' Width of tiles in pixels 
  tSizeV = 16                                           ' Height of tiles in pixels                       
  
  ' Constants defining calculated attributes
  tMemSizeH = tSizeH/4                                  ' Width of tiles in bytes
  tSize = tMemSizeH * tSizeV                            ' Total size of tile in bytes                       
  tOffset = (>| tSize) - 1                              ' Tile offset modifier
  vLineSize = vTilesH * 2                               ' Total visible line size in words                         
  tMapLineSize = tMapSizeH * 2                          ' Total tile map line size in words                         
  tMapSize = tMapSizeH * tMapSizeV * 2                  ' Total tile map size in words
  tlslRatio = (sResV / tSizeV) / vTilesV                ' Ratio of tile lines to scan lines
  lPerTile = tlslRatio * tSizeV                         ' Scan lines per tile
  cPerFrame = sResH / vTilesH                           ' Pixel clocks per pixel
  cPerPixel = cPerFrame / tSizeH                        ' Pixel clocks per frame
  vSclVal = (cPerPixel << 12) + cPerFrame               ' vscl register value for visible pixels
  sMaxH = (tMapSizeH - vTilesH) * 2                     ' Maximum horizontal scroll in words

VAR
  long  graphics_addr_base_                             ' Register pointing to base address of graphics

PUB start(graphics_addr_base)                           ' Function to start vga driver with pointer to Main RAM variables
  graphics_addr_base_ := graphics_addr_base             ' Point tile_map_base to base of tile maps
  cognew(@vga, graphics_addr_base_)                     ' Initialize cog running "vga" routine with reference to start of variable registers
  
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

        ' Initialize variables
        mov             csl,    #0              ' Initialize upscale tracking register
        mov             tmbase, par             ' Load Main RAM tile_map_base address
        mov             tpbase, par             ' Load Main RAM tile_map_base address
        mov             cpbase, par             ' Load Main RAM tile_map_base address
        mov             isptr,  par             ' Load Main RAM tile_map_base address
        add             tpbase, #4              ' Point tile palette pointer to correct Main RAM register
        add             cpbase, #8              ' Point color palette pointer to correct Main RAM register
        add             isptr,  #12             ' Point input state pointer to input states in Main RAM
        rdlong          tmbase, tmbase          ' Load tile map base pointer 
        rdlong          tpbase, tpbase          ' Load tile palette base pointer
        rdlong          cpbase, cpbase          ' Load color palette base pointer
        rdlong          isptr,  isptr           ' Load inputs base pointer
        
        ' Calculate and set tile map locations
        mov             map0,   tmbase          ' Load base tile map
        mov             map1,   tmbase          ' Load base tile map
        add             map1,   #tMapSize       ' Point to next tile map
        mov             map2,   map1            ' Store tile map location
        add             map2,   #tMapSize       ' Point to next tile map
        mov             map3,   map2            ' Store tile map location
        add             map3,   #tMapSize       ' Point to next tile map
        mov             map4,   map3            ' Store tile map location
        add             map4,   #tMapSize       ' Point to next tile map
        mov             tmbase, map0            ' Load tile map to be used
        
        ' Calculate max scroll boundry
        mov             curt,   tmbase          ' Instantiate tile pointer for scrolling
        mov             mScroll,tmbase          ' Set max scroll to base of specified tile map
        add             mScroll,#sMaxH          ' Add maximum scroll amount to max scroll
                        
        ' Display screen              
:frame  mov             fptr,   numTF           ' Initialize frame pointer
        mov             tmptr,  curt            ' Set tile map pointer to current start tile 

        ' Scroll tile map
:left   rdword          is,     isptr           ' Read input states from Main RAM
        test            btn1,   is wc           ' Test button 1 pressed
        if_c  mov       pstateL,#1              ' Set pressed state 1 to 1 if so
        if_c  jmp       #:active                ' And continue to displaying video
        cmp             pstateL,#1 wz           ' Otherwise test if button 1 was previously pressed
        if_nz jmp       #:right                 ' If not continue to testing button two
        mov             pstateL,#0              ' Otherwise reset pressed 1 state
        cmp             tmbase, tmptr wc        ' Test if video at far left of tile map
        if_c  sub       curt,   #2              ' If not scroll left
        jmp             #:active                ' Continue to displaying video
:right  test            btn2,   is wc           ' Test button 2 pressed
        if_c  mov       pstateR,#1              ' Set pressed state 2 to 1 if so
        if_c  jmp       #:active                ' And continue to displaying video
        cmp             pstateR,#1 wz           ' Otherwise test if button 2 was previously pressed
        if_nz jmp       #:active                ' If not continue to displaying video
        mov             pstateR,#0              ' Otherwise reset pressed 2 state
        cmp             tmptr, mScroll wc       ' Test if video at far right of tile map
        if_c  add       curt,   #2              ' If not scroll left

        ' Display active video
:active mov             lptr,   numLT           ' Initialize line pointer
        mov             tpptr,  #0              ' Initialize tile palette pointer
        mov             csl,    #0              ' Initialize current scan line register
        
        ' Display scanline
:tile   mov             tptr,   numTL           ' Initialize tile pointer       
        mov             vscl,   AVidScl         ' Set video scale for active video
:line
        ' Retrieve tile and colors
        rdword          cmap,   tmptr           ' Read start of tile map from Main RAM
        mov             ti,     cmap            ' Store current map into tile index
        and             ti,     #255            ' Isolate tile index of current map tile
        shr             cmap,   #8              ' Isolate color index of current map tile
        mov             ci,     cmap            ' Store color index of current map tile        
        shl             ti,     #tOffset        ' Multiply tile index by size of tile map
        add             ti,     tpbase          ' Increment tile index to correct line
        add             ti,     tpptr           ' Add tile palette pointer to tile index to specify row of tile to be displayed
        test            tMaskH, #tSizeV wc      ' Check the width of the tiles
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
        sub             tmptr,  #vLineSize      ' Return tile map pointer to beginning of row
        cmp             csl,    slr wz          ' Test if next line of tile palette is to be drawn   
        if_z  add       tpptr,  #tMemSizeH      ' Increment tile palette pointer if so        
        if_z  mov       csl,    #0              ' Reset scan line register if so
        if_nz add       csl,    #1              ' Increment scan line register otherwise
        djnz            lptr,   #:tile          ' Display forty-eight scanlines
        add             tmptr,  #tMapLineSize   ' Increment tile map pointer to next row of tiles
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
AVidScl       long      vSclVal                                                                         ' Video generator active video scale register                         

' Video Generator inputs
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
tPixel        long      %%0_0_0_0_1_1_1_1_2_2_2_2_3_3_3_3                       ' Test pixels
hPixel        long      %%0_0_0_0_0_0_3_3_3_2_2_2_2_2_2_3                       ' HSync pixels
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
vpPixel       long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Vertical porch blank pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Input attributes
btn1          long      |< 7    ' Button 1 location in input states
btn2          long      |< 6    ' Button 2 location in input states
btn3          long      |< 5    ' Button 3 location in input states
btn4          long      |< 4    ' Button 3 location in input states
pstateL       long      0
pstateR       long      0

' Frame attributes
numTL         long      vTilesH                 ' Number of visible tiles per scanline
numLT         long      lPerTile                ' Number of scanlines per tile
numTF         long      vTilesV                 ' Number of visible vertical tiles per frame
tMaskH        byte      16                      ' Mask to detect horizontal pixel width of tiles
slr           long      tlslRatio - 1           ' Ratio of screen scan lines to tile rows

' Video attributes
numFP         long      10                      ' Number of vertical front porch lines                        
numVS         long      2                       ' Number of vertical sync lines                        
numBP         long      33                      ' Number of vertical back porch lines

' Frame pointers
tptr          res       1       ' Current tile being rendered
lptr          res       1       ' Current line being rendered
fptr          res       1       ' Current frame position being rendered
vptr          res       1       ' Current vertical sync line being rendered
csl           res       1       ' Upscale tracking register
curt          res       1       ' Current tile in map
mScroll       res       1       ' Max scroll position pointer

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
isptr         res       1       ' Register containing pointer to input states                
is            res       1       ' Register containing input states
map0          res       1       ' Register containing address of map 0
map1          res       1       ' Register containing address of map 1
map2          res       1       ' Register containing address of map 2
map3          res       1       ' Register containing address of map 3
map4          res       1       ' Register containing address of map 4
        fit         
