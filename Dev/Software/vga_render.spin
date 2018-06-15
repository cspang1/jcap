{{
        File:     vga_render.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code to generate video data and store it to hub RAM
                  to be displayed by the vga_display routine
}}

CON
  ' Graphics system attributes
  numRenderCogs = 6             ' Number of cogs used for rendering
  numSprites = 64               ' Number of sprites in the sprite attribute table
  maxSprRen = 16                ' Maximum number of sprites rendered per scanline
  sprSzX = 8                    ' Horizontal size of sprites
  sprSzY = 8                    ' Vertical size of sprites

VAR
  ' Cog attributes
  long  cog_[numRenderCogs]     ' Array containing IDs of rendering cogs

  ' Graphics system attributes
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  cog_sem_                ' Cog semaphore
  long  start_line_             ' Variable for start of cog line rendering
  
PUB start(varAddrBase) | cIndex                                        ' Function to start renderer with pointer to Main RAM variables
  stop                                                                          ' Stop render cogs if running

  ' Instantiate variables
  var_addr_base_ := varAddrBase                                                 ' Assign local base variable address
  start_line_ := 0                                                              ' Initialize first scanline index
  
  ' Create cog semaphore
  cog_sem_ := locknew                                                           ' Create new lock
  
  repeat cIndex from 0 to numRenderCogs - 2
    ifnot cog_[cIndex] := cognew(@render, @var_addr_base_) + 1                  ' Initialize cog running "render" routine with reference to start of variables
      stop                                                                      ' Stop render cogs if running

  coginit(COGID, @render, @var_addr_base_)                                      ' Start final render cog in cog 0

PUB stop | cIndex                                       ' Function to stop VGA driver
  repeat cIndex from 0 to numRenderCogs - 1             ' Loop through cogs
    if cog_[cIndex]                                     ' If cog is running
      cogstop(cog_[cIndex]~ - 1)                        ' Stop the cog

DAT
        org             0
render
        ' Initialize variables
        rdlong          datptr, par             ' Initialize pointer to current scanline
        add             semptr, par             ' Initialize pointer to semaphore
        add             ilptr,  par             ' Initialize pointer to initial scanline
        rdbyte          semptr, semptr          ' Get semaphore ID
        add             cslptr, datptr          ' Calculate current scanline memory location
        rdlong          cslptr, cslptr          ' Load current scanline memory location
        add             slbptr, datptr          ' Calculate video buffer memory location
        rdlong          slbptr, slbptr          ' Load video buffer memory location
        add             tcpptr, datptr          ' Calculate graphics resource buffer memory location
        rdlong          tcpptr, tcpptr          ' Load graphics resource buffer memory location
        add             scpptr, datptr          ' Calculate sprite color palette memory location
        rdlong          scpptr, scpptr          ' Load sprite color palette memory locations
        add             satptr, datptr          ' Calculate sprite attribute table memory location
        rdlong          satptr, satptr          ' Load sprite attribute table memory location
        add             tmptr,  datptr          ' Calculate tile map location
        rdlong          tmptr,  tmptr           ' Load tile map location
        add             tpptr,  datptr          ' Calculate tile palette location
        rdlong          tpptr,  tpptr           ' Load tile palette location
        add             spptr,  datptr          ' Calculate sprite palette location
        rdlong          spptr,  spptr           ' Load sprite palette location
        rdlong          datptr, datptr          ' Load current scanline memory location

        ' Get initial scanline and set next cogs via semaphore
:lock   lockset         semptr wc               ' Attempt to lock semaphore
        if_c  jmp       #:lock                  ' Re-attempt to lock semaphore
        rdlong          initsl, ilptr           ' Load initial scanline
        add             initsl, #1              ' Increment initial scanline for next cog
        wrlong          initsl, ilptr           ' Write back next initial scanline
        lockclr         semptr                  ' Clear semaphore
        sub             initsl, #1              ' Re-decrement initial scanline
        mov             cursl,  initsl          ' Initialize current scanline
        cogid           temp wz, nr             ' Check if this is the final cog to be initialized
        if_z  lockret   semptr                  ' Return lock handle if so

slgen   'Calculate tile map line memory location
        mov             tmindx, cursl           ' Initialize tile map index
        shr             tmindx, #3              ' tmindx = floor(cursl/8)
        mov             temp,   tmindx          ' Store tile map index into temp variable
        shl             temp,   #6              ' tmindx *= 64
        shl             tmindx, #4              ' tmindx *= 16
        add             tmindx, temp            ' tmindx = tmindx(64+16)
        add             tmindx, tmptr           ' tmindx += tmptr + tmindx*80

        ' Generate each tile
        mov             index,  numTiles        ' Initialize number of tiles to parse
tile    rdword          curmt,  tmindx          ' Load current map tile from Main RAM
        mov             cpindx, curmt           ' Store map tile into color palette index
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
        {{ HALF 1 PIXEL 1 }}
        mov             pxbuff, #0              ' Initialize half-tile pixel buffer
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        {{ HALF 1 PIXEL 2 }}
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        {{ HALF 1 PIXEL 3 }}
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        {{ HALF 1 PIXEL 4 }}
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        ' Store first half tile pixels
shbuf1  mov             slbuff+0, pxbuff        ' Allocate space for color
        add             shbuf1,   d1            ' Increment scanline buffer OR position

        {{ HALF 2 PIXEL 1 }}
        mov             pxbuff, #0              ' Initialize half-tile pixel buffer
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        {{ HALF 2 PIXEL 2 }}
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        {{ HALF 3 PIXEL 3 }}
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color
        shl             curpt,  #4              ' Shift palette tile left 4 bits

        {{ HALF 4 PIXEL 4 }}
        mov             temp,   curpt           ' Load current palette tile into temp variable
        shr             temp,   #28             ' LSB align palette index
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        or              pxbuff, curcp           ' Store color
        ror             pxbuff, #8              ' Allocate space for next color

        ' Store second half tile pixels
shbuf2  mov             slbuff+1, pxbuff        ' Allocate space for color
        add             shbuf2, d1              ' Increment scanline buffer OR position

        add             tmindx, #2              ' Increment pointer to tile in tile map
        djnz            index , #tile           ' Repeat for all tiles in scanline
        movd            shbuf1, #slbuff+0       ' Reset shbuf destination address
        movd            shbuf2, #slbuff+1       ' Reset shbuf destination address

        ' Render sprites
        mov             index,  numSprts        ' Initialize size of sprite attribute table
        mov             tmindx, satptr          ' Initialize sprite attribute table index
        mov             nrensp, #0              ' Initialize number of rendered sprites on this scanline
sprites rdlong          curmt,  tmindx          ' Load sprite attributes from Main RAM

        ' Check if sprite is on scanline vertically
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #7              ' Shift vertical position to LSB
        and             temp,   #255            ' Mask out vertical position
        mov             spypos, temp            ' Store sprite vertical position
        add             temp,   #SprSzY         ' Calculate sprite vertical position upper bound
        sub             temp,   #1              ' Modify for inclusivity
        cmp             temp,   cursl wc        ' Check sprite upper bound
        if_nc cmp       cursl,  spypos wc       ' Check sprite lower bound
        if_nc jmp       #:contx                 ' Check sprite horizontally within scanline
        cmpsub          temp,   #256 wc         ' Force wrap (carry if wrapped)
        if_c  cmpx      cursl,  temp wc         ' Re-check bounds
        if_nc jmp       #:skip                  ' Skip sprite

        ' Calculate vertical sprite pixel palette offset
        mov             spyoff, #SprSzY         ' Copy sprite vertical size to sprite vertical offset
        sub             temp,   cursl           ' Subtract current scanline from sprite lower bound
        sub             spyoff, temp            ' Subtract vertical sprite position from vertical sprite size
        sub             spyoff, #1              ' Decrement offset for inclusivity
:contx  if_nc mov       spyoff, cursl           ' Store current scanline into sprite offset
        if_nc sub       spyoff, spypos          ' Subtract vertical sprite position from sprite offset

        ' Check if sprite is within scanline horizontally
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #15             ' Shift horizontal position to LSB
        and             temp,   #511            ' Mask out horizontal position
        mov             spxpos, temp            ' Store sprite horizontal position
        cmp             maxVis, spxpos wc       ' Check sprite upper bound
        if_nc jmp       #:cont                  ' Render sprite
        add             temp,   #sprSzX         ' Calculate sprite horizontal position upper bound
        sub             temp,   #1              ' Modify for inclusivity
        cmpsub          temp,   maxHor wc       ' Force wrap (carry if wrapped)
        if_nc jmp       #:skip                  ' Skip sprite

        ' Calculate horizontal scanline buffer offset
        mov             spxoff, #sprSzX         ' Copy sprite horizontal size to sprite horizontal offset
        sub             spxoff, temp            ' Subtract horizontal sprite position from horizontal sprite size
        sub             spxoff, #1              ' Decrement offset for inclusivity
        mov             spxpos, #0              ' Move sprite horizontal position to origin
:cont   if_nc mov       spxoff, #0              ' Start rendering the sprite at its origin
        shl             spxoff, #2              ' Calculate horizontal sprite pixel palette offset

        ' Retrieve sprite color palette
        mov             cpindx, curmt           ' Copy sprite attributes to color palette index
        and             cpindx, #112            ' Mask out color palette index * 16
        add             cpindx, scpptr          ' cpindx * 16 += scpptr

        ' Retrieve sprite mirroring attributes
        mov             spxmir, curmt           ' Copy sprite attributes to temp variable
        shr             spxmir, #2              ' Align sprite horizontal mirroring attribute to LSB
        and             spxmir, #1              ' Mask out sprite horizontal mirroring attribute
        mov             spymir, curmt           ' Copy sprite attributes to temp variable
        shr             spymir, #3              ' Align sprite vertical mirroring attribute to LSB
        and             spymir, #1              ' Mask out sprite vertical mirroring attribute

        ' Retrieve sprite pixel palette line
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #24             ' Align sprite pixel palette attribute to LSB
        and             temp,   #255            ' Mask out sprite pixel palette attribute
        shl             temp,   #5              ' Calculate sprite pixel palette Main RAM location offset
        add             temp,   spptr           ' Calculate sprite pixel palette Main RAM base location
        cmp             spymir, #1 wz           ' Check if sprite is mirrored vertically
        if_z  subs      spyoff, #SprSzY         ' If so calculate inverted offset...
        if_z  add       spyoff, #1              ' Modify for inclusivity...
        if_z  abs       spyoff, spyoff          ' And calculate final absolute offset
        shl             spyoff, #2              ' Calculate vertical sprite pixel palette offset
        add             temp,   spyoff          ' Calculate final sprite pixel palette Main RAM location
        rdlong          curpt,  temp            ' Load sprite pixel palette line from Main RAM
        cmp             spxmir, #1 wz           ' Check for horizontal mirroring
        if_nz shl       curpt,  spxoff          ' Shift sprite pixel palette line left to compensate for wrapping
        if_z  shr       curpt,  spxoff          ' Shift sprite pixel palette line right to compensate for mirrored wrapping

        ' Parse sprite pixel palette line
        mov             findx,  #sprSzX         ' Store sprite horizontal size into index
:sprite mov             temp,   curpt           ' Load current sprite pixel palette line into temp variable
        and             temp,   #15 wz          ' Mask out current pixel
        if_z  jmp       #:trans                 ' Skip if pixel is transparent
        add             temp,   cpindx          ' Calculate color palette offset
        rdbyte          curcp,  temp            ' Load color
        mov             temp,   spxpos          ' Store sprite horizontal position into temp variable
        cmp             spxmir, #1 wz           ' Check for horizontal mirroring
        if_z  mov       tmpmir, #sprSzX         ' If so store sprite horizontal size into temp variable
        if_z  sub       tmpmir, findx           ' And invert current index
        if_z  add       temp,   tmpmir          ' And add inverted pixel index
        if_nz add       temp,   findx           ' Or add current pixel index
        if_nz sub       temp,   #1              ' And decrement for inclusivity
        mov             slboff, temp            ' Store scanline buffer offset
        shr             slboff, #2              ' slboff /= 4
        cmp             slboff, #80 wc          ' Check if pixel out of bounds
        if_nc jmp       #:trans                 ' Skip if out of bounds
        add             slboff, #slbuff         ' slboff += @slbuff
        movs            :slbget, slboff         ' Move target scanline buffer segment source
        movd            :slbput, slboff         ' Move target scanline buffer segment destination
        and             temp,   #3              ' temp %= 4
        shl             temp,   #3              ' temp *= 8
        shl             curcp,  temp            ' Shift pixel color to calculated pixel location
:slbget mov             tmpslb, 0-0             ' Store target scanline buffer segment into temp variable
        mov             slboff, pxmask          ' Temporarily store scanline buffer segment mask
        rol             slboff, temp            ' Rotate mask to calculated pixel location
        and             tmpslb, slboff          ' Mask away calculated pixel location
        or              tmpslb, curcp           ' Insert pixel
:slbput mov             0-0,    tmpslb          ' Re-store target scanline buffer segment
:trans  shr             curpt,  #4              ' Shift palette line right 4 bits to next pixel
        djnz            findx,  #:sprite        ' Repeat for all pixels on sprite palette line
        add             nrensp, #1              ' Increment rendered sprite counter
        cmp             nrensp, #maxSprRen wz   ' Check if max rendered sprites reached
        if_z  jmp       #maxsp                  ' If max sprites reached skip rest of sprites
:skip   add             tmindx, #4              ' Increment pointer to next sprite in SAT
        djnz            index,  #sprites        ' Repeat for all sprites in SAT

        ' Wait for target scanline
maxsp   mov             index,  numSegs         ' Initialize current scanline segment
        mov             curvb,  slbptr          ' Initialize Main RAM video buffer memory location
gettsl  rdlong          tgtsl,  cslptr          ' Read target scanline index from Main RAM
        cmp             tgtsl,  cursl wz        ' Check if current scanline is being requested for display
        if_nz jmp       #gettsl                 ' If not, re-read target scanline

        ' Write scanline buffer to video buffer in Main RAM
write   wrlong          slbuff+0, curvb         ' If so, write scanline buffer to Main RAM video buffer
        add             write,  d0              ' Increment scanline buffer memory location
        add             curvb,  #4              ' Increment video buffer memory location
        djnz            index,  #write          ' Repeat for all scanline segments
        movd            write,  #slbuff         ' Reset initial scanline buffer position
        add             cursl,  #numRenderCogs  ' Increment current scanline for next render
        cmp             cursl,  numLines wc     ' Check if at bottom of screen
        if_nc mov       cursl,  initsl          ' Reinitialize current scanline if so
waitdat if_nc rdlong    temp,   datptr wz       ' Check if graphics resources ready
        if_a  jmp       #waitdat                ' Wait for graphics resources to be ready
        jmp             #slgen                  ' Generate next scanline

TEMPR          LONG      $FFFF_FFFF
        
' Video attributes
maxHor        long      512                     ' Maximum horizontal position
maxVis        long      319                     ' Maximum visible horizontal position
numLines      long      240                     ' Number of rendered scanlines
numSegs       long      80                      ' Number of scanline segments
numTiles      long      40                      ' Number of tiles per scanline
numSprts      long      numSprites              ' Number of sprites in sprite attribute table

' Main RAM pointers
semptr        long      4       ' Pointer to location of semaphore in Main RAM w/ offset
ilptr         long      8       ' Pointer to location of initial scanline in Main RAM w/ offset
datptr        long      0       ' Pointer to location of data indicator in Main RAM w/ offset
cslptr        long      4       ' Pointer to location of current scanline in Main RAM w/ offset
slbptr        long      8       ' Pointer to location of scanline buffer in Main RAM w/ offset
tcpptr        long      12      ' Pointer to location of tile color palettes in Main RAM w/ offset
scpptr        long      16      ' Pointer to location of sprite color palettes in Main RAM w/ offset
satptr        long      20      ' Pointer to location of sprite attribute table in Main RAM w/ offset
tmptr         long      24      ' Pointer to location of tile map in Main RAM w/ offset
tpptr         long      28      ' Pointer to location of tile palettes in Main RAM w/ offset
spptr         long      32      ' Pointer to location of sprite palettes in Main RAM w/ offset

' Other values
d0            long      1 << 9                  ' Value to increment destination register
d1            long      1 << 10                 ' Value to increment destination register
pxmask        long      $FFFFFF00               ' Mask for pixels in scanline buffer

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
spxoff        res       1       ' Sprite horizontal pixel palette offset
spyoff        res       1       ' Sprite vertical pixel palette offset
spxmir        res       1       ' Sprite horizontal mirroring
spymir        res       1       ' Sprite horizontal mirroring

' Other pointers
initsl        res       1       ' Container for initial scanline
cursl         res       1       ' Container for current cog scanline
tgtsl         res       1       ' Container for target scanline
curvb         res       1       ' Container for current video buffer Main RAM location being written
index         res       1       ' Container for temporary index
pxbuff        res       1       ' Container for temporary pixel buffer
hindx         res       1       ' Container for half-tile index
findx         res       1       ' Container for full-tile index
slboff        res       1       ' Container for scanline buffer offset
tmpslb        res       1       ' Container for temporary scanline buffer segment
nrensp        res       1       ' Container for number of rendered sprites on current scanline
tmpmir        res       1       ' Container for temporary sprite mirror value
temp          res       1       ' Container for temporary variables

        fit