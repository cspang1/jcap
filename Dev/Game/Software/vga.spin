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
  numCogs = 2                   ' Number of cogs used for video generation  
  
VAR
  long cog_[numCogs]            ' Array containing IDs of cogs generating video
  long graphics_addr_base_      ' Base address if graphics resources
  long sync_cnt_                ' System clock count used to synchronize video cogs
  
PUB start(graphics_addr_base, num_FP, num_VS, num_BP) : vidstatus | nCogs, cIndex                       ' Function to start VGA driver with pointer to Main RAM variables
    stop                                                                        ' Stop driver if already running
    graphics_addr_base_ := graphics_addr_base                                   ' Set global base graphics address
    sync_cnt_ := 240000 + cnt                                                   ' Initialize sync count which cogs will sync with 
    numVS := num_VS                                                             ' Set number of sync lines in cogs                        
    repeat cIndex from 0 to numCogs-1                                           ' Loop through cogs
      numFP := num_FP + cIndex                                                  ' Set number of front porch lines in cog
      numBP := num_BP - cIndex                                                  ' Set number of back porch lines in cog
      ifnot cog_[cIndex] := cognew(@vga, @graphics_addr_base_) + 1              ' Initialize cog running "vga" routine with reference to start of variable registers
        stop                                                                    ' Stop all cogs if insufficient number available
        abort FALSE                                                             ' Abort returning FALSE
      waitcnt(8192 + cnt)                                                       ' Wait for cogs to finish initializing 
    return TRUE                                                                 ' Return TRUE                                                
    
PUB stop | nCogs, cIndex                                ' Function to stop VGA driver 
  repeat cIndex from 0 to numCogs-1                     ' Loop through cogs                        
    if cog_[cIndex]                                     ' If cog is running
      cogstop(cog_[cIndex]~ - 1)                        ' Stop the cog
  
DAT
        org             0
vga
        ' Initialize frame attributes
        mov             csl,    #0              ' Initialize upscale tracking register
        rdlong          attptr, par             ' Load base attribute address
        add             attptr, #4              ' Increment to point to number of attributes
        rdlong          natt,   attptr          ' Initialize number of attributes
        movd            :att,   #vTilesH        ' Modify instruction @:att to load first attribute address
        add             attptr, #4              ' Increment to point to start of attributes 
:att    rdlong          0-0,    attptr          ' Load current attribute into current register         
        add             attptr, #4              ' Increment to point to next attribute                  
        add             :att,   incDest         ' Increment to point to next register 
        djnz            natt,   #:att           ' Iterate through all attributes                                                
        mov             numTL,  vTilesH         ' Set tiles per line
        mov             numTF,  vTilesV         ' Set tiles per frame     
        mov             numLT,  lPerTile        ' Set lines per tile
        mov             slr,    tlslRatio       ' Set tile line per scanline ratio                           
        sub             slr,    #1              ' Decrement to be used as do while loop limit                                                

        ' Initialize graphics resource pointers
        rdlong          tmbase, par             ' Load base variable address
        rdlong          tmbase, tmbase          ' Load Main RAM tile map base address
        mov             tpbase, tmbase          ' Load Main RAM tile map base address
        mov             cpbase, tmbase          ' Load Main RAM tile map base address
        add             tpbase, #4              ' Point tile palette pointer to correct Main RAM register
        add             cpbase, #8              ' Point color palette pointer to correct Main RAM register
        rdlong          tpbase, tpbase          ' Load tile palette base pointer
        rdlong          cpbase, cpbase          ' Load color palette base pointer

        ' Synchronize cogs
        mov             attptr, par             ' Load the base variable address
        add             attptr, #4              ' Increment to point to the sync count
        rdlong          sCnt,   attptr          ' Load the sync count          
        waitcnt         sCnt,   delay           ' Wait for sync count and add 3 ms delay
        mov             frqa,   pllfreq         ' Set Counter A video frequency
        mov             vscl,   #1              ' Reload video generator on every pixel
        mov             ctra,   CtrCfg          ' Start Counter A
        mov             vcfg,   VidCfg          ' Start video generator
        or              dira,   vgapin          ' Set video generator output pins        
        waitcnt         sCnt,   delay           ' Wait 3 ms for PLL to settle
        mov             vscl,   vSclVal         ' Set video scale

        ' Display vertical sync
screen  mov             lptr,   #240
        mov             vptr,   numVS           ' Initialize vertical sync pointer
vsync   mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        djnz            vptr,   #vsync          ' Display vertical sync lines 

        ' Display vertical back porch        
        mov             vptr,   numBP           ' Initialize vertical sync pointer
bporch  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #bporch         ' Display back porch lines

        ' Blank this cog's line
linex2  mov             vscl,   lSclVal         ' Set video scale for entire line
        waitvid         zero,   #0              ' Output all low

        ' Display this cog's visible line
        mov             vscl,   tVidScl         ' Set video scale for active video
        waitvid         tColor, tPixel          ' Display test pixels

        ' Display horizontal sync area
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync        

        ' Display all lines
        djnz            lptr,   #linex2         ' Display 240 sets of 2 lines

        ' Display vertical front porch
        mov             vptr,   numFP           ' Initialize vertical sync pointer
fporch  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #fporch         ' Display front porch lines           

        ' Return to start of screen
        jmp             #screen     

' TESTING
tColor        long      %11111111_00110011_00011111_00000011                    ' Test colors
tPixel        long      %%0_0_0_0_1_1_1_1_2_2_2_2_3_3_3_3                       ' Test pixels
tVidScl       long      %000000000000_00101000_001010000000                     ' Test vscl

' Config values
vgapin        long      |< 24 | |< 25 | |< 26 | |< 27 | |< 28 | |< 29 | |< 30 | |< 31                   ' VGA output pins
pllfreq       long      337893130                                                                       ' Counter A PLL frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_011_0_11111111                                      ' Video generator configuration
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register
tMaskH        long      16                                                                              ' Mask to detect horizontal pixel width of tiles
incDest       long      %1000000000                                                                     ' Value to increment dest field during attribute loading
delay         long      240000                                                                          ' Delay value for 3 ms delay
zero          long      0                                                                               ' Zero register

' Video Generator inputs
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
hPixel        long      %%0_0_0_0_0_0_3_3_3_2_2_2_2_2_2_3                       ' HSync pixels
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
vpPixel       long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Vertical porch blank pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Video attributes
numFP         long      0       ' Number of vertical front porch lines                        
numVS         long      0       ' Number of vertical sync lines                        
numBP         long      0       ' Number of vertical back porch lines

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
natt          res       1       ' Number of attributes
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
lSclVal       res       1       ' vscl register value for entire line

' Other variables
sCnt          res       1       ' Value used to synchronize cogs
        fit
       
{{
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
        nop                                     ' Flush pipeline between vscl and waitvid
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
        nop                                     ' Flush pipeline between vscl and waitvid
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        nop                                     ' Flush pipeline between vscl and waitvid
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:fporch        ' Display front porch lines           
        mov             vptr,   numVS           ' Initialize vertical sync pointer        
:vsync  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        nop                                     ' Flush pipeline between vscl and waitvid
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        nop                                     ' Flush pipeline between vscl and waitvid
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        djnz            vptr,   #:vsync         ' Display vertical sync lines 
        mov             vptr,   numBP           ' Initialize vertical sync pointer        
:bporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        nop                                     ' Flush pipeline between vscl and waitvid
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        nop                                     ' Flush pipeline between vscl and waitvid
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:bporch        ' Display back porch lines 
        jmp             #:frame                 ' Return to start of video frame
}}      
        