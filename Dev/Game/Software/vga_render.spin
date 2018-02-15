{{
        File:     vga_render.spin
        Author:   Connor Spangler
        Date:     1/27/2018
        Version:  0.2
        Description: 
                  This file contains the PASM code to generate video data and store it to hub RAM
                  to be displayed by the vga_display routine
}}

CON
  ' Graphics system attributes
  numRenderCogs = 5             ' Number of cogs used for rendering

VAR
  ' Cog attributes
  long  cog_[numRenderCogs]     ' Array containing IDs of rendering cogs

  ' Graphics system attributes
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  cog_sem_                ' Cog semaphore
  long  start_line_             ' Variable for start of cog line rendering
  
PUB start(varAddrBase) : status | cIndex                                        ' Function to start renderer with pointer to Main RAM variables
  stop                                                                          ' Stop render cogs if running

  ' Instantiate variables
  var_addr_base_ := varAddrBase                                                 ' Assign local base variable address
  start_line_ := 0                                                              ' Initialize first scanline index
  
  ' Create cog semaphore
  if (cog_sem_ := locknew) == -1                                                ' Create new lock
    return FALSE                                                                ' No locks available
  
  repeat cIndex from 0 to numRenderCogs - 1
    ifnot cog_[cIndex] := cognew(@render, @var_addr_base_) + 1                  ' Initialize cog running "render" routine with reference to start of variables
      stop                                                                      ' Stop render cogs if running
      return FALSE                                                              ' Graphics system failed to initialize
  
  lockret(cog_sem_)                                                             ' Release lock
  
  return TRUE                                                                   ' Graphics system successfully initialized

PUB stop | cIndex                                       ' Function to stop VGA driver
  repeat cIndex from 0 to numRenderCogs - 1             ' Loop through cogs
    if cog_[cIndex]                                     ' If cog is running
      cogstop(cog_[cIndex]~ - 1)                        ' Stop the cog

DAT
        org             0
render
        ' Initialize variables
        rdlong          clptr,  par             ' Initialize pointer to current scanline
        add             semptr, par             ' Initialize pointer to semaphore
        add             ilptr,  par             ' Initialize pointer to initial scanline
        rdbyte          semptr, semptr          ' Get semaphore ID
        add             vbptr,  clptr           ' Point video buffer pointer to video buffer
        rdlong          vbptr,  vbptr           ' Load video buffer memory location
        add             tmptr,  clptr           ' Point tile map pointer to tile map
        rdlong          tmptr,  tmptr           ' Load tile map memory location
        add             tpptr,  clptr           ' Point tile palette pointer to tile palettes
        rdlong          tpptr,  tpptr           ' Load tile palette memory location
        add             tcpptr, clptr           ' Point color palette pointer to color palettes
        rdlong          tcpptr, tcpptr          ' Load color palette memory location
        add             saptr,  clptr           ' Point sprite attribute table pointer to sprite attribute table
        rdlong          saptr,  saptr           ' Load sprite attribute table memory location
        add             spptr,  clptr           ' Point sprite palette pointer to sprite palettes
        rdlong          spptr,  spptr           ' Load sprite palette memory location
        add             scpptr, clptr           ' Point sprite color palette pointer to sprite color palettes
        rdlong          scpptr, scpptr          ' Load sprite color palette memory location
        rdlong          clptr,  clptr           ' Load current scanline memory location
        mov             spxsz,  #8              ' Initialize sprite horizontal size
        mov             spysz,  #8              ' Initialize sprite vertical size

        ' Get initial scanline and set next cogs via semaphore
:lock   lockset         semptr wc               ' Attempt to lock semaphore
        if_c  jmp       #:lock                  ' Re-attempt to lock semaphore
        rdlong          initsl, ilptr           ' Load initial scanline
        add             initsl, #1              ' Increment initial scanline for next cog
        wrlong          initsl, ilptr           ' Write back next initial scanline
        lockclr         semptr                  ' Clear semaphore
        sub             initsl, #1              ' Re-decrement initial scanline
        mov             cursl,  initsl          ' Initialize current scanline

slgen   'Calculate tile map line memory location
        mov             tmindx, cursl           ' Initialize tile map index
        shr             tmindx, #3              ' tmindx = floor(cursl/8)
        mov             temp,   tmindx          ' Store tile map index into temp variable
        shl             temp,   #6              ' tmindx *= 64
        shl             tmindx, #4              ' tmindx *= 16
        add             tmindx, temp            ' tmindx = tmindx(64+16)
        add             tmindx, tmptr           ' tmindx += tmptr + tmindx*80

        ' Generate each tile
        mov             index , numTiles        ' Initialize number of tiles to parse
tile    rdword          curmt,  tmindx          ' Load current map tile from Main RAM
        mov             cpindx, curmt           ' Store map tile to into color palette index
        and             curmt,  #255            ' Isolate palette tile index of map tile
        shr             cpindx, #8              ' Isolate color palette index of map tile

        ' Calculate color palette location
        shl             cpindx, #4              ' cpindx *= 16
        add             cpindx, tcpptr          ' cpindx += tcpptr

        ' Calculate and load palette tile
        mov             tpindx, cursl           ' Initialize tile palette index
        and             tpindx, #7              ' tpindx %= 8
        shl             tpindx, #2              ' tpindx *= 4
        shl             curmt,  #5              ' tilePaletteIndex *= 32
        add             tpindx, curmt           ' tpindx += paletteTileIndex
        add             tpindx, tpptr           ' tpindx += tpptr
        rdlong          curpt,  tpindx          ' Load current palette tile from Main RAM

        ' Parse palette tile pixels
        mov             ftindx, #2              ' Initialize full tile index
ftile   mov             htindx, #4              ' Initialize half tile index
        mov             pxbuff, #0              ' Initialize half-tile pixel buffer
htile   mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits
        djnz            htindx, #htile          ' Repeat for half of tile

        ' Store tile pixels
shbuf   mov             slbuff+0, pxbuff        ' Allocate space for color
        add             shbuf,  d0              ' Increment scanline buffer OR position
        djnz            ftindx, #ftile          ' Repeat for second half of tile
        add             tmindx, #2              ' Increment pointer to tile in tile map
        djnz            index , #tile           ' Repeat for all tiles in scanline
        movd            shbuf,  #slbuff+0       ' Reset shbuf destination address

        ' Render sprites
        mov             index,  numSprts        ' Initialize size of sprite attribute table
        mov             tmindx, saptr           ' Initialize sprite attribute table index
sprites rdlong          curmt,  tmindx          ' Load sprite attributes from Main RAM

        ' Get sprite size
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        and             temp,   #1              ' Mask sprite vertical size attribute
        shl             spysz,  temp            ' Convert sprite vertical size
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #1              ' Move sprite horizontal size attribute to LSB
        and             temp,   #1              ' Mask sprite horizontal size attribute
        shl             spxsz,  temp            ' Convert sprite horizontal size

        ' Check if sprite is on scanline vertically
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #7              ' Shift vertical position to LSB
        and             temp,   #255            ' Mask out vertical position
        mov             spypos, temp            ' Store sprite vertical position
        add             temp,   spysz           ' Calculate sprite vertical position upper bound
        sub             temp,   #1              ' Modify for inclusivity
        cmp             temp,   cursl wc        ' Check sprite upper bound
        if_nc cmp       cursl,  spypos wc       ' Check sprite lower bound
        if_nc jmp       #:contx                 ' Check sprite horizontally within scanline
        cmpsub          temp,   #256 wc         ' Force wrap (carry if wrapped)
        if_c  cmpx      cursl,  temp wc         ' Re-check bounds
        if_nc jmp       #:skip                  ' Skip sprite

        ' Calculate vertical sprite pixel palette offset
        mov             spyoff, spysz           ' Copy sprite vertical size to sprite offset
        sub             temp,   cursl           ' Subtract current scanline from sprite lower bound
        sub             spyoff, temp            ' Subtract vertical sprite position from vertical sprite size
:contx  if_nc mov       spyoff, cursl           ' Store current scanline into sprite offset
        if_nc sub       spyoff, spypos          ' Subtract vertical sprite position from sprite offset
        shl             spyoff, #2              ' Calculate vertical sprite pixel palette offset

        ' Check if sprite is within scanline horizontally
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #15             ' Shift horizontal position to LSB
        and             temp,   #511            ' Mask out horizontal position
        mov             spxpos, temp            ' Store sprite horizontal position
        add             temp,   spxsz           ' Calculate sprite horizontal position upper bound
        sub             temp,   #1              ' Modify for inclusivity
        cmp             maxVis, spxpos wc       ' Check sprite upper bound
        if_nc jmp       #:cont                  ' Render sprite
        cmpsub          temp,   maxHor wc       ' Force wrap (carry if wrapped)
        if_nc jmp       #:skip                  ' Skip sprite

        ' Render current sprite
:cont   mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #24             ' Align sprite pixel palette attribute to LSB
        and             temp,   #255            ' Mask out sprite pixel palette attribute
        shl             temp,   #5              ' Calculate sprite pixel palette Main RAM location offset
        add             temp,   spptr           ' Calculate sprite pixel palette Main RAM base location
        add             temp,   spyoff          ' Calculate final sprite pixel palette Main RAM location
        rdlong          pxbuff, temp            ' Load sprite pixel palette line from Main RAM

        {{ TEST }}
        mov             slbuff, tColor
        {{ TEST }}

:skip   mov             spxsz,  #8              ' Re-initialize sprite horizontal size
        mov             spysz,  #8              ' Re-initialize sprite vertical size
        add             tmindx, #4              ' Increment pointer to next sprite in SAT
        djnz            index,  #sprites        ' Repeat for all sprites in SAT

        ' Wait for target scanline
        mov             index , numSegs         ' Initialize current scanline segment
        mov             curvb,  vbptr           ' Initialize Main RAM video buffer memory location
gettsl  rdlong          tgtsl,  clptr           ' Read target scanline index from Main RAM
        cmp             tgtsl,  cursl wz        ' Check if current scanline is being requested for display
        if_nz jmp       #gettsl                 ' If not, re-read target scanline

        ' Write scanline buffer to video buffer in Main RAM
write   wrlong          slbuff+0, curvb         ' If so, write scanline buffer to Main RAM video buffer
        add             write,  d0              ' Increment scanline buffer memory location
        add             curvb,  #4              ' Increment video buffer memory location
        djnz            index , #write          ' Repeat for all scanline segments
        movd            write,  #slbuff         ' Reset initial scanline buffer position
        add             cursl,  #5              ' Increment current scanline for next render
        cmp             cursl,  numLines wc     ' Check if at bottom of screen
        if_nc mov       cursl,  initsl          ' Reinitialize current scanline if so
        jmp             #slgen                  ' Generate next scanline

' Test values
tColor        long      %00000011_11000011_00001111_11111111
        
' Video attributes
maxHor        long      512     ' Maximum horizontal position
maxVis        long      319     ' Maximum visible horizontal position
numLines      long      240     ' Number of rendered scanlines
numSegs       long      80      ' Number of scanline segments
numTiles      long      40      ' Number of tiles per scanline
numSprts      long      8       ' Number of sprites in sprite attribute table

' Main RAM pointers
semptr        long      4       ' Pointer to location of semaphore in Main RAM w/ offset
ilptr         long      8       ' Pointer to location of initial scanline in Main RAM w/ offset
clptr         long      0       ' Pointer to location of current scanline in Main RAM w/ offset
vbptr         long      4       ' Pointer to location of video buffer in Main RAM w/ offset
tmptr         long      8       ' Pointer to location of tile map in Main RAM w/ offset
tpptr         long      12      ' Pointer to location of tile palettes in Main RAM w/ offset
tcpptr        long      16      ' Pointer to location of tile color palettes in Main RAM w/ offset
saptr         long      20      ' Pointer to location of sprite attribute table in Main RAM w/ offset
spptr         long      24      ' Pointer to location of sprite palettes in Main RAM w/ offset
scpptr        long      28      ' Pointer to location of sprite color palettes in Main RAM w/ offset

' Other values
d0            long      1 << 9  ' Value to increment destination register

' Scanline buffer
slbuff        long      0[80]   ' Buffer containing scanline

' Tile pointers
tmindx        res       1       ' Tile map index
tpindx        res       1       ' Tile palette index
cpindx        res       1       ' Color palette index
curmt         res       1       ' Current map tile
curpt         res       1       ' Current palette tile
curcp         res       1       ' Current color palette

' Sprite pointers
spindx        res       1       ' Sprite pixel palette index
spxpos        res       1       ' Sprite horizontal position
spypos        res       1       ' Sprite vertical position
spcol         res       1       ' Sprite color palette index
spxsz         res       1       ' Sprite horizontal size
spysz         res       1       ' Sprite vertical size
spyoff        res       1       ' Sprite pixel palette offset

' Other pointers
initsl        res       1       ' Container for initial scanline
cursl         res       1       ' Container for current cog scanline
tgtsl         res       1       ' Container for target scanline
curvb         res       1       ' Container for current video buffer Main RAM location being written
index         res       1       ' Container for temporary index
pxbuff        res       1       ' Container for temporary pixel buffer
htindx        res       1       ' Container for half-tile index
ftindx        res       1       ' Container for full-tile index
temp          res       1       ' Container for temporary variables

        fit