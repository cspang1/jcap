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
        add             tpptr,  clptr           ' Point tile palette pointer to video buffer
        rdlong          tpptr,  tpptr           ' Load tile palette memory location
        add             cpptr,  clptr           ' Point color palette pointer to video buffer
        rdlong          cpptr,  cpptr           ' Load color palette memory location
        rdlong          clptr,  clptr           ' Load current scanline memory location

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
        mov             curseg, numTiles        ' Initialize number of tiles to parse
tile    rdword          curmt,  tmindx          ' Load current map tile from Main RAM
        mov             cpindx, curmt           ' Store map tile to into color palette index
        and             curmt,  #255            ' Isolate palette tile index of map tile
        shr             cpindx, #8              ' Isolate color palette index of map tile

        ' Calculate color palette location
        shl             cpindx, #4              ' cpindx *= 16
        add             cpindx, cpptr           ' cpindx += cpptr

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
        mov             htbuff, #0              ' Initialize half-tile pixel buffer
htile   mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              htbuff, curcp           ' Store color
        ror             htbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits
        djnz            htindx, #htile          ' Repeat for half of tile

        ' Store pixels
shbuf   mov             slbuff+0, htbuff        ' Allocate space for color
        add             shbuf,  d0              ' Increment scanline buffer OR position
        djnz            ftindx, #ftile          ' Repeat for second half of tile
        add             tmindx, #2              ' Increment pointer to tile in tile map
        djnz            curseg, #tile           ' Repeat for all tiles in scanline
        movd            shbuf,  #slbuff+0       ' Reset shbuf destination address

        ' Wait for target scanline
        mov             curseg, numSegs         ' Initialize current scanline segment
        mov             curvb,  vbptr           ' Initialize Main RAM video buffer memory location
gettsl  rdlong          tgtsl,  clptr           ' Read target scanline index from Main RAM
        cmp             tgtsl,  cursl wz        ' Check if current scanline is being requested for display
        if_nz jmp       #gettsl                 ' If not, re-read target scanline

        ' Write scanline buffer to video buffer in Main RAM
write   wrlong          slbuff+0, curvb         ' If so, write scanline buffer to Main RAM video buffer
        add             write,  d0              ' Increment scanline buffer memory location
        add             curvb,  #4              ' Increment video buffer memory location
        djnz            curseg, #write          ' Repeat for all scanline segments
        movd            write,  #slbuff         ' Reset initial scanline buffer position
        add             cursl,  #5              ' Increment current scanline for next render
        cmp             cursl,  numLines wc     ' Check if at bottom of screen
        if_nc mov       cursl,  initsl          ' Reinitialize current scanline if so
        jmp             #slgen                  ' Generate next scanline

' Test values
d1            long      1 << 10 ' Value to increment destination register by 2
tColor        long      0
        
' Video attributes
numLines      long      240     ' Number of rendered scanlines
numSegs       long      80      ' Number of scanline segments
numTiles      long      40      ' Number of tiles per scanline

' Main RAM pointers
semptr        long      4       ' Pointer to location of semaphore in Main RAM w/ offset
ilptr         long      8       ' Pointer to location of initial scanline in Main RAM w/ offset
clptr         long      0       ' Pointer to location of current scanline in Main RAM w/ offset
vbptr         long      4       ' Pointer to location of video buffer in Main RAM w/ offset
tmptr         long      8       ' Pointer to location of tile map in Main RAM w/ offset
tpptr         long      12      ' Pointer to location of tile palettes in Main RAM w/ offset
cpptr         long      16      ' Pointer to location of color palettes in Main RAM w/ offset

' Other values
d0            long      1 << 9  ' Value to increment destination register

' Scanline buffer
slbuff        long      0[80]   ' Buffer containing scanline

' Graphics pointers
tmindx        res       1       ' Tile map index
tpindx        res       1       ' Tile palette index
cpindx        res       1       ' Color palette index
curmt         res       1       ' Current map tile
curpt         res       1       ' Current palette tile
curcp         res       1       ' Current color palette

' Other pointers
initsl        res       1       ' Container for initial scanline
cursl         res       1       ' Container for current cog scanline
tgtsl         res       1       ' Container for target scanline
curvb         res       1       ' Container for current video buffer Main RAM location being written
curseg        res       1       ' Container for current segment being written to Main RAM
htbuff        res       1       ' Container for half-tile buffer
htindx        res       1       ' Container for half-tile index
ftindx        res       1       ' Container for full-tile index
temp          res       1       ' Container for temporary variables

        fit
