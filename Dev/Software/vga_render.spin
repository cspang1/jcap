{{
        File:     vga_render.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code to generate video data and store it to hub RAM
                  to be displayed by the vga_display routine
}}

OBJ
    system: "system"    ' Import system settings

VAR
    ' Cog attributes
    long    cog_[system#NUM_REN_COGS] ' Array containing IDs of rendering cogs

    ' Graphics system attributes
    long    var_addr_base_  ' Variable for pointer to base address of Main RAM variables
    long    cog_sem_        ' Cog semaphore
    long    start_line_     ' Variable for start of cog line rendering
  
PUB start(varAddrBase) | cIndex ' Function to start renderer with pointer to Main RAM variables
    stop    ' Stop render cogs if running

    ' Instantiate variables
    var_addr_base_ := varAddrBase   ' Assign local base variable address
    start_line_ := -1               ' Initialize first scanline index

    ' Create cog semaphore
    cog_sem_ := locknew ' Create new lock

    repeat cIndex from 0 to system#NUM_REN_COGS - 2                 ' Iterate over cogs
        ifnot cog_[cIndex] := cognew(@render, @var_addr_base_) + 1  ' Initialize cog running "render" routine with reference to start of variables
            stop                                                    ' Stop render cogs if running

    coginit(COGID, @render, @var_addr_base_)    ' Start final render cog in cog 0

PUB stop | cIndex                                   ' Function to stop VGA driver
    repeat cIndex from 0 to system#NUM_REN_COGS - 1 ' Loop through cogs
        if cog_[cIndex]                             ' If cog is running
            cogstop(cog_[cIndex]~ - 1)              ' Stop the cog

DAT
        org             0
render
        ' Initialize variables
        rdlong          datptr, par     ' Initialize pointer to current scanline
        add             semptr, par     ' Initialize pointer to semaphore
        add             ilptr,  par     ' Initialize pointer to initial scanline
        rdbyte          semptr, semptr  ' Get semaphore ID
        add             cslptr, datptr  ' Calculate current scanline memory location
        rdlong          cslptr, cslptr  ' Load current scanline memory location
        add             slbptr, datptr  ' Calculate video buffer memory location
        rdlong          slbptr, slbptr  ' Load video buffer memory location
        add             hspptr, datptr  ' Calculate horizontal screen position memory location
        rdlong          hspptr, hspptr  ' Load horizontal screen position memory location
        add             tcpptr, datptr  ' Calculate graphics resource buffer memory location
        rdlong          tcpptr, tcpptr  ' Load graphics resource buffer memory location
        add             scpptr, datptr  ' Calculate sprite color palette memory location
        rdlong          scpptr, scpptr  ' Load sprite color palette memory locations
        add             satptr, datptr  ' Calculate sprite attribute table memory location
        rdlong          satptr, satptr  ' Load sprite attribute table memory location
        add             tmptr,  datptr  ' Calculate tile map location
        rdlong          tmptr,  tmptr   ' Load tile map location
        add             tpptr,  datptr  ' Calculate tile palette location
        rdlong          frqb,   tpptr   ' Load tile palette location
        shr             frqb,   #1      ' load from phsb+2*frqb
        add             spptr,  datptr  ' Calculate sprite palette location
        rdlong          spptr,  spptr   ' Load sprite palette location
        rdlong          datptr, datptr  ' Load current scanline memory location

        ' Calculate last initial parallax table entry offset
        mov             plxoff, #system#PARALLAX_MIN-1
        shl             plxoff, #2
        mov             temptr, hspptr  ' Store into temporary pointer
        add             temptr, plxoff

        ' Get initial scanline and set next cogs via semaphore
:lock   lockset         semptr wc       ' Attempt to lock semaphore
        if_c  jmp       #:lock          ' Re-attempt to lock semaphore
        rdlong          initsl, ilptr   ' Load initial scanline
        adds            initsl, #1      ' Increment initial scanline for next cog
        mov             cursl,  initsl  ' Initialize current scanline
        wrlong          initsl, ilptr   ' Write back next initial scanline
        lockclr         semptr          ' Clear semaphore
        cogid           temp wz, nr     ' Check if this is the final cog to be initialized
        if_z  lockret   semptr          ' Return lock handle if so

        ' Start Counter B for tile loading routine
        movi            ctrb,   #%0_11111_000   ' Start counter b in logic.always mode

frame   ' Initialize parallax positions
        mov             index,  #system#PARALLAX_MIN    ' Load minimum parallax check iterations
:initp  rdlong          temp,   temptr      ' Retrieve horizontal screen position
        and             temp,   #$FF
        cmp             initsl, temp wc
        if_nc jmp       #slgen
        sub             temptr, #4
        djnz            index,  #:initp

slgen   ' Calculate tile map line memory location
        rdlong          horpos, temptr      ' Retrieve horizontal screen position
        mov             verpos, horpos      ' Load position into vertical position
        shr             verpos, #8          ' Shift vertical position to LSB
        and             verpos, vpmask      ' Mask out vertical position
        mov             possl,  cursl       ' Store current scanline into position scanline
        add             possl,  verpos      ' Calculate net vertical position
        cmpsub          possl,  numMemLines ' Compensate for wrapping
        mov             tmindx, possl       ' Initialize tile map index
        shr             tmindx, #3          ' tmindx = floor(cursl/8)
        mov             temp,   tmindx      ' Store tile map index into temp variable
        shl             tmindx, #3          ' x8
        sub             tmindx, temp        ' x7
        shl             tmindx, #4          ' x112
        add             tmindx, tmptr       ' tmindx = tmptr + (cursl/8)*112
        mov             initti, tmindx      ' Store initial row tile location

        ' Calculate initial tile offset and load
        mov             index,  numTiles                        ' Initialize number of tiles to parse
        shr             horpos, #20                             ' Align horizontal position w/ LSB
        mov             temp,   horpos                          ' Store horizontal screen position in temp variable
        shr             temp,   #3                              ' temp = floor(horpos/8)
        mov             remtil, #system#MEM_TILE_MAP_WIDTH+1    ' Load pre-incremented width of tile map in memory
        sub             remtil, temp                            ' Subtract offset from map memory width
        shl             temp,   #1                              ' temp *= 2
        add             tmindx, temp                            ' Calculate final offset
        call            #tld                                    ' Load initial tile

        ' Determine horizontal pixel location in tile
        and             horpos, #%111   ' limit
        add             patch,  horpos  ' base+index
        shl             horpos, #2      ' *= 4
        shl             curpt,  horpos  ' Shift to first pixel
patch   mov             temp,   ptable  ' load relevant offset
        movs            patch,  #ptable ' restore
trset   mov             px7,    shlcall ' make sure we don't corrupt location 0 (might be important some day)
        movd            tiset,  temp    ' Set next frame's reset
        movd            trset,  temp    ' Set this frame's tile load routine call location
tiset   mov             0-0,    tldcall ' Set this frame's tile load 

        ' Parse palette tile pixels
tile    mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        mov             pxbuf1, curcp   ' Initialize first half-tile pixel buffer
        ror             pxbuf1, #8      ' Allocate space for next color
px0     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        or              pxbuf1, curcp   ' Store color
        ror             pxbuf1, #8      ' Allocate space for next color
px1     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        or              pxbuf1, curcp   ' Store color
        ror             pxbuf1, #8      ' Allocate space for next color
px2     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        or              pxbuf1, curcp   ' Store color
        ror             pxbuf1, #8      ' Allocate space for next color
px3     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        mov             pxbuf2, curcp   ' Initialize second half-tile pixel buffer        
        ror             pxbuf2, #8      ' Allocate space for next color
px4     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        or              pxbuf2, curcp   ' Store color
        ror             pxbuf2, #8      ' Allocate space for next color
px5     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        or              pxbuf2, curcp   ' Store color
        ror             pxbuf2, #8      ' Allocate space for next color
px6     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        or              pxbuf2, curcp   ' Store color
        ror             pxbuf2, #8      ' Allocate space for next color
px7     shl             curpt,  #4      ' Shift palette tile left 4 bits

        ' Store tile pixels
shbuf1  mov             slbuff+4, pxbuf1    ' Allocate space for color
        add             shbuf1, d1          ' Increment scanline buffer OR position
shbuf2  mov             slbuff+5, pxbuf2    ' Allocate space for color
        add             shbuf2, d1          ' Increment scanline buffer OR position
        djnz            index , #tile       ' Repeat for all tiles in scanline
        movd            shbuf1, #slbuff+4   ' Reset shbuf destination address
        movd            shbuf2, #slbuff+5   ' Reset shbuf destination address

        ' Render sprites
        mov             index,  #system#SAT_SIZE    ' Initialize size of sprite attribute table
        mov             tmindx, satptr              ' Initialize sprite attribute table index

sprites ' Load sprite vertical position and check visibility
        rdlong          curmt,  tmindx              ' Load sprite attributes from Main RAM
        mov             spypos, curmt               ' Copy sprite attributes to temp variable
        shr             spypos, #7                  ' Shift vertical position to LSB
        and             spypos, #255 wz             ' Mask out vertical position, checking invisibility
        cmp             maxVVis, spypos wc          ' Check sprite upper bound
        if_be jmp       #:skip                      ' Skip sprite if invisible or out of bounds
        test            curmt,  #1 wc               ' Check sprite tall
        if_c mov        spysiz, #system#SPR_SZ_L-1  ' If so set vertical size as large
        if_nc mov       spysiz, #system#SPR_SZ_S-1  ' Else set as small
        mov             temp,   cursl               ' Temporarily store current scanline
        add             temp,   #16                 ' Compensate for off-screen top area
        sub             temp,   spypos              ' Find difference from position
        cmp             temp,   spysiz wc, wz       ' Check if visible
        if_a jmp        #:skip                      ' Skip if not

        ' Check if sprite is within scanline horizontally
        mov             spxpos, curmt       ' Copy sprite attributes to temp variable
        shr             spxpos, #15         ' Shift horizontal position to LSB
        and             spxpos, #511 wz     ' Mask out horizontal position, checking invisivility
        cmp             maxHVis, spxpos wc  ' Check sprite upper bound
        if_be jmp       #:skip              ' Skip sprite if invisible or out of bounds
        test            curmt,  #2 wc       ' Check if sprite is wide
        if_c mov        widesp, #2          ' If so increment wide sprite index
        if_c mov        wmmod,  #8          ' And set sprite position modifier
        if_nc mov       widesp, #1          ' Otherwise only render one sprite palette line

        ' Finalize vertical offset calculations
        test            curmt,  #8 wc   ' Check sprite mirrored vertically
        if_c mov        spyoff, spysiz  ' If so grab vertical sprite size
        if_c sub        spyoff, temp    ' If so find difference from offset
        if_nc mov       spyoff, temp    ' Else grab offset
        mov             temp,   spyoff  ' Store offset temporarily
        and             temp,   neg8    ' Perform floor(offset/8)*8
        add             spyoff, temp    ' Combine
        shl             spyoff, #2      ' *= 4 to get final vertical sprite palette line offset

        ' Retrieve sprite pixel palette line
        mov             temp,   curmt           ' Copy sprite attributes to temp variable
        shr             temp,   #24             ' Align sprite pixel palette attribute to LSB
        shl             temp,   #5              ' Calculate sprite pixel palette Main RAM location offset
        add             temp,   spptr           ' Calculate sprite pixel palette Main RAM base location
        add             temp,   spyoff          ' Calculate final sprite pixel palette Main RAM location
        rdlong          curpt,  temp            ' Load sprite pixel palette line from Main RAM
        add             temp,   #32             ' Increment to retrieve next palette line
        and             curmt,  #6 wz, wc, nr   ' Check sprite wide and mirrored horizontally
        rdlong          nxtpt,  temp            ' Read next palette line
        if_a add        spxpos, #8              ' If so pre-increment sprite position
        if_a mov        wmmod,  neg8            ' Set wide/mir mod amount
        test            curmt,  #4 wc           ' Check sprite mirrored horizontally
        sub             spxpos, #1              ' Pre-decrement horizontal sprite position

        ' Retrieve sprite color palette
        and             curmt,  #112    ' Mask out color palette index * 16
        add             curmt,  scpptr  ' cpindx * 16 += scpptr

        ' Parse sprite pixel palette line
:wide   mov             findx,  #8                  ' Store sprite horizontal size into index
:sprite mov             temp,   curpt               ' Load current sprite pixel palette line into temp variable
        and             temp,   #15                 ' Mask out current pixel
        tjz             temp,   #:trans             ' Skip if pixel is transparent
        add             temp,   curmt               ' Calculate color palette offset
        rdbyte          curcp,  temp                ' Load color
        mov             temp,   spxpos              ' Store sprite horizontal position into temp variable
        if_c add        temp,   #system#SPR_SZ_S+1  ' If mirrored horizontally add sprite size to position
        sumc            temp,   findx               ' Calculate final offset
        mov             slboff, temp                ' Store scanline buffer offset
        shr             slboff, #2                  ' slboff /= 4
        add             slboff, #slbuff             ' slboff += @slbuff
        movs            :slbget, slboff             ' Move target scanline buffer segment source
        movd            :slbput, slboff             ' Move target scanline buffer segment destination
        shl             temp,   #3                  ' temp *= 8
        shl             curcp,  temp                ' Shift pixel color to calculated pixel location
:slbget mov             tmpslb, 0-0                 ' Store target scanline buffer segment into temp variable
        mov             slboff, pxmask              ' Temporarily store scanline buffer segment mask
        rol             slboff, temp                ' Rotate mask to calculated pixel location
        and             tmpslb, slboff              ' Mask away calculated pixel location
        or              tmpslb, curcp               ' Insert pixel
:slbput mov             0-0,    tmpslb              ' Re-store target scanline buffer segment
:trans  shr             curpt,  #4                  ' Shift palette line right 4 bits to next pixel
        djnz            findx,  #:sprite            ' Repeat for all pixels on sprite palette line
        mov             curpt,  nxtpt               ' Move next palette tile into current
        adds            spxpos, wmmod               ' Compensate for mirrored wideness
        djnz            widesp, #:wide              ' Render rest of wide sprite if applicable
:skip   add             tmindx, #4                  ' Increment pointer to next sprite in SAT
        djnz            index,  #sprites            ' Repeat for all sprites in SAT

        ' Wait for target scanline
        mov             index,  numSegs     ' Initialize current scanline segment
        mov             curvb,  slbptr      ' Initialize Main RAM video buffer memory location
        mov             ptr,    curvb       ' Initialize transfer counter
gettsl  rdlong          temp,   cslptr      ' Read target scanline index from Main RAM
        cmp             temp,   cursl wz    ' Check if current scanline is being requested for display
        if_nz jmp       #gettsl             ' If not, re-read target scanline

        ' Write scanline buffer to video buffer in Main RAM
        movd            long0,  #ptr-5                      ' last long in cog buffer
        movd            long1,  #ptr-6                      ' second-to-last long in cog buffer
        add             ptr,    #system#VID_BUFFER_SIZE*4-1 ' last byte in hub buffer (8n + 7)
        movi            ptr,    #system#VID_BUFFER_SIZE-2   ' add magic marker
long0   wrlong          0-0,    ptr                         ' |
        sub             long0,  d1                          ' |
        sub             ptr,    i2s7 wc                     ' |
long1   wrlong          0-0,    ptr                         ' |
        sub             long1,  d1                          ' |
        if_nc djnz      ptr,    #long0                      ' sub #7/djnz (Thanks Phil!)
        add             cursl,  #system#NUM_REN_COGS        ' Increment current scanline for next render
        cmp             cursl,  numLines wc                 ' Check if at bottom of screen
        if_c jmp        #slgen                              ' If not continue to next scanline, otherwise...
        mov             temptr, hspptr
        add             temptr, plxoff
        mov             cursl,  initsl                      ' Reinitialize current scanline
waitdat rdlong          temp,   datptr wz                   ' Check if graphics resources ready
        if_nz  jmp      #waitdat                            ' Wait for graphics resources to be ready
        jmp             #frame                              ' Generate next frame

        ' Tile loading routine
tld     djnz            remtil, #:next  ' Check if need to wrap to beginning
        if_z mov        tmindx, initti  ' If so wrap to beginning
:next   rdword          curmt,  tmindx  ' Load current map tile from Main RAM
        mov             cpindx, curmt   ' Store map tile into color palette index
        and             curmt,  #255    ' Isolate palette tile index of map tile
        shr             cpindx, #8      ' Isolate color palette index of map tile
        shl             cpindx, #4      ' cpindx *= 16
        add             cpindx, tcpptr  ' cpindx += tcpptr
        mov             phsb,   possl   ' Initialize tile palette index
        and             phsb,   #7      ' tpindx %= 8
        shl             phsb,   #2      ' tpindx *= 4
        shl             curmt,  #5      ' tilePaletteIndex *= 32
        add             phsb,   curmt   ' tpindx += paletteTileIndex
        rdlong          curpt,  phsb    ' Load current palette tile from Main RAM
        add             tmindx, #2      ' Increment pointer to tile in tile map
tld_ret ret

        ' Instructions for dynamic tile shifting
tldcall call            #tld        ' Tile load instr call
shlcall shl             curpt,  #4  ' Shift left instr call

' Video attributes
maxHor      long    system#MAX_MEM_HOR_POS      ' Maximum horizontal position
maxHVis     long    system#MAX_VIS_HOR_POS-1    ' Maximum visible horizontal position
maxVVis     long    system#MAX_VIS_VER_POS-1    ' Maximum visible vertical position
numLines    long    system#MAX_VIS_VER_POS-16   ' Number of rendered scanlines
numMemLines long    system#MAX_MEM_VER_POS      ' Number of scanlines in memory
numSegs     long    system#VID_BUFFER_SIZE      ' Number of scanline segments
numTiles    long    system#VIS_TILE_MAP_WIDTH   ' Number of tiles per scanline

' Main RAM pointers
semptr      long    4   ' Pointer to location of semaphore in Main RAM w/ offset
ilptr       long    8   ' Pointer to location of initial scanline in Main RAM w/ offset
datptr      long    0   ' Pointer to location of data indicator in Main RAM w/ offset
cslptr      long    4   ' Pointer to location of current scanline in Main RAM w/ offset
slbptr      long    8   ' Pointer to location of scanline buffer in Main RAM w/ offset
hspptr      long    12  ' Pointer to location of horizontal screen position in Main RAM w/ offset
tcpptr      long    16  ' Pointer to location of tile color palettes in Main RAM w/ offset
scpptr      long    20  ' Pointer to location of sprite color palettes in Main RAM w/ offset
satptr      long    24  ' Pointer to location of sprite attribute table in Main RAM w/ offset
tmptr       long    28  ' Pointer to location of tile map in Main RAM w/ offset
tpptr       long    32  ' Pointer to location of tile palettes in Main RAM w/ offset
spptr       long    36  ' Pointer to location of sprite palettes in Main RAM w/ offset

' Other values
d0          long    1 << 9                  ' Value to increment destination register
d1          long    1 << 10                 ' Value to increment destination register
i2s7        long    2 << 23 | 7             ' Value to summon Cthullu
pxmask      long    $FFFFFF00               ' Mask for pixels in scanline buffer
vpmask      long    $FFF                    ' Mask for vertical game world position
ptable      long    px7, px6, px5, px4      ' Patch table for modifying tile load logic
            long    px3, px2, px1, px0
neg8        long    -8                      ' Value to modify sprite position given wide+mirrored

' Scanline buffer
slbuff      res     system#VID_BUFFER_SIZE+8    ' Buffer containing scanline
ptr         res     1                           ' Data pointer assisting scanline buffer cog->hub tx

' Tile pointers
tmindx      res     1   ' Tile map index
tpindx      res     1   ' Tile palette index
cpindx      res     1   ' Color palette index
curmt       res     1   ' Current map tile
curpt       res     1   ' Current palette tile
nxtpt       res     1   ' Next palette tile
curcp       res     1   ' Current color palette

' Sprite pointers
spxpos      res     1   ' Sprite horizontal position
spypos      res     1   ' Sprite vertical position
spysiz      res     1   ' Sprite vertical size
spyoff      res     1   ' Sprite vertical pixel palette offset

' Other pointers
horpos      res     1   ' Container for current horizontal screen position
verpos      res     1   ' Container for current vertical screen position
initti      res     1   ' Container for current row's initial tile
remtil      res     1   ' Container for remaining number of tiles to render before wrapping
initsl      res     1   ' Container for initial scanline
cursl       res     1   ' Container for current cog scanline
possl       res     1   ' Container for current psotion scanline
curvb       res     1   ' Container for current video buffer Main RAM location being written
index       res     1   ' Container for temporary index
pxbuf1      res     1   ' Container for temporary pixel buffer
pxbuf2      res     1   ' Container for temporary pixel buffer
findx       res     1   ' Container for full-tile index
slboff      res     1   ' Container for scanline buffer offset
tmpslb      res     1   ' Container for temporary scanline buffer segment
widesp      res     1   ' Container for wide sprite index
wmmod       res     1   ' Container for wide/mirrored sprite mod
plxoff      res     1   ' Container for initial parallax offset
temptr      res     1   ' Container for temporary pointer to parallax table
temp        res     1   ' Container for temporary variables

        fit
