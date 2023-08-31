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
        rdlong          datptr, par     ' Initialize pointer to main RAM variables
        add             ilptr,  par     ' Initialize pointer to initial scanline
        add             semptr, par     ' Calculate and load semaphore ID
        rdbyte          semptr, semptr  ' |
        add             cslptr, datptr  ' Calculate and load current scanline memory location
        rdlong          cslptr, cslptr  ' |
        add             slbptr, datptr  ' Calculate and load video buffer memory location
        rdlong          slbptr, slbptr  ' |
        add             pxtptr, datptr  ' Calculate and load parallax table memory location
        rdlong          pxtptr, pxtptr  ' |
        add             tcpptr, datptr  ' Calculate and load tile color pallete memory location
        rdlong          tcpptr, tcpptr  ' |
        add             scpptr, datptr  ' Calculate and load sprite color palette memory location
        rdlong          scpptr, scpptr  ' |
        add             satptr, datptr  ' Calculate and load sprite attribute table memory location
        rdlong          satptr, satptr  ' |
        add             tmptr,  datptr  ' Calculate and load tile map location
        rdlong          tmptr,  tmptr   ' |
        add             tpptr,  datptr  ' Calculate and load (from phsb+2*frqb) tile palette location
        rdlong          frqb,   tpptr   ' |
        shr             frqb,   #1      ' |
        add             spptr,  datptr  ' Calculate and load sprite palette location
        rdlong          spptr,  spptr   ' |
        rdlong          datptr, datptr  ' Load data ready indicator location

        ' Calculate initial parallax parameters
        mov             plxoff, #system#PARALLAX_MIN-1          ' Calculate highest parallax table memory address we need to inspect
        shl             plxoff, #2                              ' |
        mov             temptr, pxtptr                          ' |
        add             temptr, plxoff                          ' |
        mov             maxptr, #system#NUM_PARALLAX_REGS       ' Calculate absolute highest parallax table memory address
        shl             maxptr, #2                              ' |
        add             maxptr, pxtptr                          ' |

        ' Get initial scanline and set next cogs via semaphore
:lock   lockset         semptr wc                       ' Wait for semaphore unlock and lock
        if_c  jmp       #:lock                          ' |
        rdlong          initsl, ilptr                   ' Load initial scanline and set for next cog
        adds            initsl, #1                      ' |
        mov             cursl,  initsl                  ' |
        wrlong          initsl, ilptr                   ' |
        lockclr         semptr                          ' Clear semaphore and return lock handle if no more cogs to initialize
        cogid           temp wz, nr                     ' |
        if_z  lockret   semptr                          ' |
        mov             nxtsl,  cursl                   ' Calculate the next scanline this cog will render after cursl
        add             nxtsl,  #system#NUM_REN_COGS    ' |

        ' Start Counter B for tile loading routine
        movi            ctrb,   #%0_11111_000   ' Start counter b in logic.always mode

frame   ' Initialize parallax positions
:initp  rdlong          temp,   temptr  ' Identify the first parallax table entry relevant to this cog
        and             temp,   #$FF    ' |
        cmp             initsl, temp wc ' |
        if_nc jmp       #:cont          ' |
        sub             temptr, #4      ' |
        jmp             #:initp         ' |
:cont   rdlong          nxtpte, temptr  ' Store the value of that parallax table entry
        mov             nxtptr, temptr  ' Calculate the next table entry address as well
        add             nxtptr, #4      ' |

slgen   ' Calculate tile map row memory address
nxtcal  call            #nxt                    ' Get current and next parallax values
        mov             possl,  cursl           ' Calculate net vertical position w/ wrapping compensation
        add             possl,  verpos          ' |
        cmpsub          possl,  numMemLines     ' |
        mov             tmindx, possl           ' Calculate first tile memory address of resulting row
        shr             tmindx, #3              ' |
        mov             temp,   tmindx          ' |
        shl             tmindx, #3              ' |
        sub             tmindx, temp            ' |
        shl             tmindx, #4              ' |
        add             tmindx, tmptr           ' | tmindx = tmptr + (possl/8)*112
        mov             initti, tmindx          ' |

        ' Calculate starting tile map memory address and load
        mov             index,  numTiles                        ' Initialize number of tiles to parse
        mov             temp,   horpos                          ' Calculate tile map column memory address due to horizontal parallax
        mov             thpos,  temp                            ' |
        shr             temp,   #3                              ' |
        mov             remtil, #system#MEM_TILE_MAP_WIDTH+1    ' |
        sub             remtil, temp                            ' |
        shl             temp,   #1                              ' |
        add             tmindx, temp                            ' |
        call            #tld                                    ' Load first tile

        ' Determine horizontal pixel location in tile
        and             thpos,  #%111   ' Calculate start pixel in tile and patch 
        add             patch,  thpos   ' |
        shl             thpos,  #2      ' Calculate tile offset and shift to first pixel
        shl             curpt,  thpos   ' |
patch   mov             temp,   ptable  ' Retrieve first pixel load subroutine address
        movs            patch,  #ptable ' Reset the patch instruction
trset   mov             px7,    shlcall ' Reset the previously patched pixel subroutine
        movd            tiset,  temp    ' Set this frame's tile load routine call location
        movd            trset,  temp    ' Set the next frame's patched pixel subroutine reset dest
tiset   mov             0-0,    tldcall ' Set this frame's tile load

        ' Parse palette tile pixels
tile    mov             temp,   curpt   ' Load current palette tile into temp variable
        shr             temp,   #28     ' LSB align palette index
        add             temp,   cpindx  ' Calculate color palette offset
        rdbyte          curcp,  temp    ' Load color
        mov             pxbuf1, curcp   ' Initialize first half-tile pixel buffer
        ror             pxbuf1, #8      ' Allocate space for next color
px0     shl             curpt,  #4      ' Shift palette tile left 4 bits
        mov             temp,   curpt   ' Process second pixel
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        or              pxbuf1, curcp   ' |
        ror             pxbuf1, #8      ' |
px1     shl             curpt,  #4      ' |
        mov             temp,   curpt   ' Process third pixel
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        or              pxbuf1, curcp   ' |
        ror             pxbuf1, #8      ' |
px2     shl             curpt,  #4      ' |
        mov             temp,   curpt   ' Process fourth pixel
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        or              pxbuf1, curcp   ' |
        ror             pxbuf1, #8      ' |
px3     shl             curpt,  #4      ' |
        mov             temp,   curpt   ' Process fifth pixel
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        mov             pxbuf2, curcp   ' Initialize second half-tile pixel buffer        
        ror             pxbuf2, #8      ' Allocate space for next color
px4     shl             curpt,  #4      ' Process sixth pixel
        mov             temp,   curpt   ' |
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        or              pxbuf2, curcp   ' |
        ror             pxbuf2, #8      ' |
px5     shl             curpt,  #4      ' |
        mov             temp,   curpt   ' Process seventh pixel 
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        or              pxbuf2, curcp   ' |
        ror             pxbuf2, #8      ' |
px6     shl             curpt,  #4      ' |
        mov             temp,   curpt   ' Process eighth pixel
        shr             temp,   #28     ' |
        add             temp,   cpindx  ' |
        rdbyte          curcp,  temp    ' |
        or              pxbuf2, curcp   ' |
        ror             pxbuf2, #8      ' |
px7     shl             curpt,  #4      ' |

        ' Store tile pixels
shbuf1  mov             slbuff+4, pxbuf1    ' Store the two 4-pixel halves
        add             shbuf1, d1          ' |
shbuf2  mov             slbuff+5, pxbuf2    ' |
        add             shbuf2, d1          ' |
        djnz            index , #tile       ' Repeat for all tiles in scanline
        movd            shbuf1, #slbuff+4   ' Reset shbuf destination address
        movd            shbuf2, #slbuff+5   ' Reset shbuf destination address

        ' Render sprites
        mov             index,  #system#SAT_SIZE    ' Initialize size of sprite attribute table
        mov             tmindx, satptr              ' Initialize sprite attribute table index

sprites ' Load sprite vertical position and check visibility
        rdlong          curmt,  tmindx              ' Parse SAT entry component
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
        shr             temp,   #3      ' floor(offset/8)
        mov             findx,  temp    ' Store previous
        shl             findx,  #3      ' offset *= 8
        shl             temp,   #7      ' offset *= 128
        sub             temp,   findx   ' Final is *= 120
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
        mov             index,  numSegs     ' Wait until current scanline data is requested by display cog
        mov             curvb,  slbptr      ' |
        mov             ptr,    curvb       ' |
gettsl  rdlong          temp,   cslptr      ' |
        cmp             temp,   cursl wz    ' |
        if_nz jmp       #gettsl             ' |

        ' Write scanline buffer to video buffer in Main RAM
        movd            long0,  #ptr-5                          ' last long in cog buffer
        movd            long1,  #ptr-6                          ' second-to-last long in cog buffer
        add             ptr,    #system#VID_BUFFER_SIZE*4-1     ' last byte in hub buffer (8n + 7)
        movi            ptr,    #system#VID_BUFFER_SIZE-2       ' add magic marker
long0   wrlong          0-0,    ptr                             ' |
        sub             long0,  d1                              ' |
        sub             ptr,    i2s7 wc                         ' |
long1   wrlong          0-0,    ptr                             ' |
        sub             long1,  d1                              ' |
        if_nc djnz      ptr,    #long0                          ' sub #7/djnz (Thanks Phil!)

        ' Prepare for next scanline to render
        add             cursl,  #system#NUM_REN_COGS            ' Increment current scanline for next render
        cmp             cursl,  numLines wc                     ' Check if at bottom of screen {{ MOVE THIS DOWN BELOW mov/add??? }}
        mov             nxtsl,  cursl                           ' Calculate next scanline index
        add             nxtsl,  #system#NUM_REN_COGS            ' |
        if_c jmp        #slgen                                  ' If not continue to next scanline, otherwise...

        ' Prepare for next frame to render
        mov             temptr, pxtptr                          ' Re-calculate the first parallax table entry to check for the next frame
        add             temptr, plxoff                          ' | {{ WE SHOULD STORE THIS VALUE PERMANENTLY TO AVOID RE-CALCULATING EACH FRAME }}
        mov             cursl,  initsl                          ' Re-initialize current and next scanlines
        mov             nxtsl,  cursl                           ' |
        add             nxtsl,  #system#NUM_REN_COGS            ' |
waitdat rdlong          temp,   datptr wz                       ' Wait for graphics resources to be ready to render next frame
        if_nz  jmp      #waitdat                                ' |
        jmp             #frame                                  ' |

        ' We can move the entire nxt routine back inline
nxt     mov             horpos, nxtpte          ' Capture horizontal and vertical parallax values for this scanline 
        mov             verpos, horpos          ' |
        shr             horpos, #20             ' |
        shr             verpos, #8              ' | We can move nxt up to :try back to the main loop
        and             verpos, vpmask          ' | We can also move the whole :try routine back to the main loop
:try    rdlong          nxtpsl, nxtptr          ' Find the first entry that doesn't affect the next scanline
        and             nxtpsl, #$FF            ' |
        cmp             nxtptr, maxptr wz       ' |
        cmp             nxtpsl, nxtsl wc        ' |
        if_z_or_nc jmp  #:cont                  ' |
        add             nxtptr, #4              ' |
        jmp             #:try                   ' |
:cont   sub             nxtptr, #4              ' Decrement to get the last entry that does affect the next scanline
        rdlong          nxtpsl, nxtptr          ' I think we can change the dest here to nxtpte and remove the next instruction
        mov             nxtpte, nxtpsl          ' I also think we may be able to simplify this nxt/try loop...
nxt_ret ret

        ' Tile loading routine
tld     djnz            remtil, #:next  ' Wrap to beginning of tile map row if at end
        mov             tmindx, initti  ' |
:next   rdword          curmt,  tmindx  ' Load current map tile and parse color and tile palette indexes
        mov             cpindx, curmt   ' |
        and             curmt,  #255    ' |
        shr             cpindx, #8      ' |
        shl             cpindx, #4      ' Calculate main RAM color palette memory address
        add             cpindx, tcpptr  ' |
        mov             phsb,   possl   ' Use CTRB to fast-load tile
        and             phsb,   #7      ' |
        shl             phsb,   #2      ' |
        shl             curmt,  #5      ' |
        add             phsb,   curmt   ' |
        rdlong          curpt,  phsb    ' Load current palette tile from main RAM
        add             tmindx, #2      ' Increment pointer to tile in tile map
tld_ret ret

        ' Instructions for dynamic tile shifting
nxtcall call            #nxt            {{ THIS CAN BE REMOVED }}
nopcall nop                             {{ THIS CAN BE REMOVED }}
tldcall call            #tld            ' Tile load instr call
shlcall shl             curpt,  #4      ' Shift left instr call

' Video attributes
maxHor      long    system#MAX_MEM_HOR_POS      ' Maximum horizontal position {{ CAN BE REMOVED }}
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
pxtptr      long    12  ' Pointer to location of horizontal screen position in Main RAM w/ offset
tcpptr      long    16  ' Pointer to location of tile color palettes in Main RAM w/ offset
scpptr      long    20  ' Pointer to location of sprite color palettes in Main RAM w/ offset
satptr      long    24  ' Pointer to location of sprite attribute table in Main RAM w/ offset
tmptr       long    28  ' Pointer to location of tile map in Main RAM w/ offset
tpptr       long    32  ' Pointer to location of tile palettes in Main RAM w/ offset
spptr       long    36  ' Pointer to location of sprite palettes in Main RAM w/ offset

' Other values
d0          long    1 << 9              ' Value to increment destination register {{ CAN BE REMOVED }}
d1          long    1 << 10             ' Value to increment destination register
i2s7        long    2 << 23 | 7         ' Value to summon Cthullu
pxmask      long    $FFFFFF00           ' Mask for pixels in scanline buffer
vpmask      long    $FFF                ' Mask for vertical game world position
ptable      long    px7, px6, px5, px4  ' Patch table for modifying tile load logic
            long    px3, px2, px1, px0  ' |
neg8        long    -8                  ' Value to modify sprite position given wide+mirrored

' Scanline buffer
slbuff      res     system#VID_BUFFER_SIZE+8    ' Buffer containing scanline w/ off-screen padding
ptr         res     1                           ' Data pointer assisting scanline buffer cog->hub tx

' Tile pointers
tmindx      res     1   ' Tile map index
tpindx      res     1   ' Tile palette index {{ CAN BE REMOVED }}
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
nxtsl       res     1   ' Container for next cog scanline
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
maxptr      res     1   ' Container for max parallax array pointer
nxtptr      res     1   ' Container for next parallax array pointer
nxtpte      res     1   ' Container for next parallax table entry
nextvp      res     1   ' Container for next vertical parallax position {{ CAN BE REMOVED }}
nxtpsl      res     1   ' Container for next parallax change scanline
thpos       res     1   ' Container for temporary horizontal position
temp        res     1   ' Container for temporary variables

        fit
