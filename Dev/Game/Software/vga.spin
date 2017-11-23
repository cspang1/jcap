{{
        File:     vga.spin
        Author:   Connor Spangler
        Date:     10/26/2017
        Version:  3.0
        Description: 
                  This file contains the PASM code to drive a VGA signal via the Propeller
                  Cog Video Generator.
}}

VAR
  long  cog_[8]                 ' Array containing IDs of cogs generating video
  long  num_cogs_               ' Number of cogs used for video generation
  long  graphics_addr_base_     ' Base address if graphics resources
  long  sync_cnt_               ' System clock count used to synchronize video cogs
  
PUB start(graphics_addr_base, n_att, tlsl_ratio, lines_per_cog, t_mem_size_h, num_FP, num_VS, num_BP) : vidstatus               ' Function to start VGA driver with pointer to Main RAM variables
    stop                                                                        ' Stop driver if already running
    graphics_addr_base_ := graphics_addr_base                                   ' Set global base graphics address
    snatt.byte := n_att                                                         ' Set number of attributes to be loaded                        
    sync_cnt_ := $8000 + cnt                                                    ' Initialize sync count which cogs will sync with 
    movvs.byte := num_VS                                                        ' Set number of sync lines in cogs    

    ' Initialize cog #1
    movfp.byte := num_FP                                                        ' Set number of front porch lines in cog
    movbp.byte := num_BP                                                        ' Set number of back porch lines in cog
    setptr.byte := (lines_per_cog / tlsl_ratio) * t_mem_size_h                  ' Set initial tile palette pointer position
    setcsl.byte := lines_per_cog // tlsl_ratio                                  ' Set initial vertical upscale iteration
    ifnot cog_[0] := cognew(@vga, @graphics_addr_base_) + 1                     ' Initialize cog running "vga" routine with reference to start of variable registers
      stop                                                                      ' Stop all cogs if insufficient number available
      abort FALSE                                                               ' Abort returning FALSE
    waitcnt($2000 + cnt)                                                        ' Wait for cog to finish initializing

    ' Initialize cog #2
    movfp.byte := num_FP + lines_per_cog                                        ' Set number of front porch lines in cog
    movbp.byte := num_BP - lines_per_cog                                        ' Set number of back porch lines in cog
    setptr.byte := 0                                                            ' Set initial tile palette pointer position
    setcsl.byte := 0                                                            ' Set initial vertical upscale iterations
    ifnot cog_[1] := cognew(@vga, @graphics_addr_base_) + 1                     ' Initialize cog running "vga" routine with reference to start of variable registers
      stop                                                                      ' Stop all cogs if insufficient number available
      abort FALSE                                                               ' Abort returning FALSE
    waitcnt($2000 + cnt)                                                        ' Wait for cog to finish initializing       

    return TRUE                                                                 ' Return TRUE                                                
    
PUB stop | cIndex                                       ' Function to stop VGA driver 
  repeat cIndex from 0 to 1                             ' Loop through cogs                        
    if cog_[cIndex]                                     ' If cog is running
      cogstop(cog_[cIndex]~ - 1)                        ' Stop the cog
  
DAT
        org             0
        
        ' Initialize frame attributes
vga     mov             csl,    #0              ' Initialize upscale tracking register
        rdlong          attptr, par             ' Load base attribute address
snatt   mov             xptr,   #0-0            ' Initialize number of attributes
        movd            att,    #vTilesH        ' Modify instruction @att to load first attribute address
        add             attptr, #4              ' Increment to point to start of attributes 
att     rdlong          0-0,    attptr          ' Load current attribute into current register         
        add             attptr, #4              ' Increment to point to next attribute                  
        add             att,    incDest         ' Increment to point to next register 
        djnz            xptr,   #att            ' Iterate through all attributes                                                
        mov             slr,    tlslRatio       ' Set tile line per scanline ratio                           
        sub             slr,    #1              ' Decrement to be used as djnz loop limit
        
        ' Set correct Main RAM read instruction based on tile size
        test            tMaskH, tSizeV wc       ' Check the width of the tiles
        if_nc movi      movp,   #%000001001     ' Read 8-pixel-wide tile from Main RAM
        if_c  movi      movp,   #%000010001     ' Read 16-pixel-wide tile from Main RAM

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

        ' Start of VGA routine
screen  mov             rptr,   rPerCog         ' Initialize render pointer
setptr  mov             tpptr,  #0-0            ' Initialize tile palette pointer
setcsl  mov             csl,    #0-0            ' Initialize current scan line register
        rdlong          tmptr,  tmbase          ' Set tile map pointer to current start tile

        ' Display vertical sync
movvs   mov             vptr,   #0-0            ' Initialize vertical sync pointer
vsync   mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        djnz            vptr,   #vsync          ' Display vertical sync lines 

        ' Display vertical back porch        
movbp   mov             vptr,   #0-0            ' Initialize vertical back porch pointer
bporch  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #bporch         ' Display back porch lines

        ' Blank lines
blank   mov             vscl,   lSclVal         ' Set video scale for entire line
        waitvid         CtrCfg, #0              ' Output all low (lower byte of CtrCfg used as zeroed color)
    
        ' Populate scanline buffer
        mov             lrptr,  lPerCog         ' Set number of tiles per render
        movd            movp,   #pixBuff        ' Initialize pointer to start of pixel buffer
        movd            movc,   #colBuff        ' Initialize pointer to start of color buffer
linex4  mov             tptr,   vTilesH         ' Initialize tile pointer
line    rdbyte          ti,     tmptr           ' Read tile index of current map tile
        add             tmptr,  #1              ' Increment tile map pointer to color index
        shl             ti,     tOffset         ' Multiply tile index by size of tile map
        rdbyte          ci,     tmptr           ' Store color index of current map tile
        add             ti,     tpbase          ' Increment tile index to correct line
        add             ti,     tpptr           ' Add tile palette pointer to tile index to specify row of tile to be displayed
movp    rdlong          0-0,    ti              ' Read tile from Main RAM
        shl             ci,     #2              ' Multiply color index by size of color palette
        add             ci,     cpbase          ' Increment color index to correct palette
movc    rdlong          0-0,    ci              ' Read tile from Main RAM
        add             movp,   incDest         ' Increment tile buffer pointer
        add             movc,   incDest         ' Increment color buffer pointer
        add             tmptr,  #1              ' Increment tile map pointer to next tile in row
        djnz            tptr,   #line           ' Generate one scanline of data
        sub             tmptr,  vLineSize       ' Return tile map pointer to beginning of row
        call            #com                    ' Call compensation routine        
        djnz            lrptr,  #linex4         ' Generate four scanlines of data

        ' Display scanline buffer
        mov             lptr,   lPerCog         ' Initialize render iteration pointer
        movd            wvid,   #colBuff        ' Initialize color buffer position
        movs            wvid,   #pixBuff        ' Initialize pixel buffer position
visible mov             dptr,   vTilesH         ' Initialize display pointer
        mov             vscl,   vSclVal         ' Set video scale for active video
wvid    waitvid         0-0,    0-0             ' Display test pixels
        add             wvid,   incDestSrc      ' Increment buffer positions
        djnz            dptr,   #wvid           ' Display full scanline
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            lptr,   #visible        ' Display all lines in iteration

        ' Compensate for blank lines
        mov             lrptr,  lPerCog         ' Set number of tiles per render
bcom    call            #com                    ' Call compensation routine
        djnz            lrptr,  #bcom           ' Perform compensation for all blanking lines
        
        djnz            rptr,   #blank          ' Display all render iterations

        ' Display vertical front porch
movfp   mov             vptr,   #0-0            ' Initialize vertical sync pointer
fporch  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #fporch         ' Display front porch lines           

        ' Return to start of screen
        jmp             #screen                 ' Display another screen

        ' Compensation routine
com     cmp             csl,    slr wz          ' Test if next line of tile palette is to be drawn   
        if_z  add       tpptr,  tMemSizeH       ' Increment tile palette pointer if so        
        if_z  mov       csl,    #0              ' Reset scan line register if so
        if_nz add       csl,    #1              ' Increment scan line register otherwise
        cmp             tpptr,  tSize wz        ' Test if at bottom of tile palette
        if_z  mov       tpptr,  #0              ' Reset tile palette pointer if so
        if_z  add       tmptr,  tMapLineSize    ' Increment tile map pointer to next row of tiles if so                
com_ret ret                                     ' Return to caller

' Config values
vgapin        long      |< 24 | |< 25 | |< 26 | |< 27 | |< 28 | |< 29 | |< 30 | |< 31                   ' VGA output pins
pllfreq       long      337893130                                                                       ' Counter A PLL frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_011_0_11111111                                      ' Video generator configuration
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register
tMaskH        long      16                                                                              ' Mask to detect horizontal pixel width of tiles
incDest       long      1 << 9                                                                          ' Value to increment dest field during attribute loading
incDestSrc    long      1 << 9 + 1                                                                      ' Value to increment dest and src field during display
delay         long      240000                                                                          ' Delay value for 3 ms delay

' Video Generator inputs
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
hPixel        long      %%0_0_0_0_0_0_3_3_3_2_2_2_2_2_2_3                       ' HSync pixels
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
vpPixel       long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Vertical porch blank pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Frame pointers
xptr          res       1       ' Multi-purpose pointer
tptr          res       1       ' Current tile being rendered
lptr          res       1       ' Current line being rendered
vptr          res       1       ' Current vertical sync line being rendered
rptr          res       1       ' Current set of lines being rendered
dptr          res       1       ' Current long of buffer being displayed
lrptr         res       1       ' Current render line
csl           res       1       ' Upscale tracking register

' Tile and color map pointers
tmptr         res       1       ' Pointer to current tile map in Main RAM
tpptr         res       1       ' Pointer to current tile palette in Main RAM
tmbase        res       1       ' Pointer to tile maps base in Main RAM
tpbase        res       1       ' Pointer to tile palettes base in Main RAM
cpbase        res       1       ' Pointer to color palettes base in Main RAM
ti            res       1       ' Tile index
ci            res       1       ' Color index

' Frame attributes
slr           res       1       ' Ratio of scanlines to tile lines
attptr        res       1       ' Pointer to attributes in Main RAM
vTilesH       res       1       ' Visible horizontal tiles
tSizeV        res       1       ' Vertical tile size
tMemSizeH     res       1       ' Width of tile map in bytes
tSize         res       1       ' Total size of tile in bytes                       
tOffset       res       1       ' Tile offset modifier
vLineSize     res       1       ' Total visible line size in words                         
tMapLineSize  res       1       ' Total tile map line size in words                         
tlslRatio     res       1       ' Ratio of tile lines to scan lines
lPerCog       res       1       ' Number of lines per iteration per cog
rPerCog       res       1       ' Number of render iterations per cog
vSclVal       res       1       ' vscl register value for visible pixels
lSclVal       res       1       ' vscl register value for entire line

' Other variables
sCnt          res       1       ' Value used to synchronize cogs

' Line buffers                 
pixBuff       res       40      ' Reserve 10 longs * 4 lines for pixel buffer
colBuff       res       40      ' Reserve 10 longs * 4 lines for color buffer 

        fit
        