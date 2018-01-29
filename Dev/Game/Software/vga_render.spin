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
  byte  cog_sem_                ' Cog semaphore
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
        mov             semptr, par             ' Initialize pointer to semaphore
        mov             ilptr,  par             ' Initialize pointer to initial scanline
        add             semptr, #1              ' Point semaphore pointer
        add             ilptr,  #4              ' Point initial scanline pointer

        ' 
:lock   lockset         semptr wc               ' Attempt to lock semaphore
        if_c  jmp       #:lock                  ' Re-attempt to lock semaphore
        rdlong          initsl, ilptr           ' Load initial scanline
        add             initsl, #1              ' Increment initial scanline for next cog
        wrlong          initsl, ilptr           ' Write back next initial scanline
        lockclr         semptr                  ' Clear semaphore
        
        sub             initsl, #1              ' Re-decrement initial scanline
        neg             initsl, initsl          ' Invert initial scanline
        adds            initsl, numLines        ' Subtract initial scanline from number of scanlines
        mov             cursl,  initsl          ' Initialize current scanline
        mov             vbptr,  clptr           ' Initialize pointer to video buffer
        add             vbptr,  #4              ' Point video buffer pointer to video buffer
        rdlong          clptr,  clptr           ' Load current scanline memory location
        rdlong          vbptr,  vbptr           ' Load video buffer memory location
        
        {{ TEST CODE }}
        
        ' Set default colors
        cmp             initsl, #240 wz
        if_z  mov       tColor, tColor0
        cmp             initsl, #239 wz
        if_z  mov       tColor, tColor1
        cmp             initsl, #238 wz
        if_z  mov       tColor, tColor2
        cmp             initsl, #237 wz
        if_z  mov       tColor, tColor3
        cmp             initsl, #236 wz
        if_z  mov       tColor, tColor4

        ' Load default colors into scanline buffer
        mov             curseg, numSegs         ' Initialize current scanline segment
wrt     mov             slbuff+0, tColor
        add             wrt,  d0                ' Increment scanline buffer memory location
        djnz            curseg, #wrt            ' Repeat for all scanline segments

        {{ TEST CODE }}

        ' Wait for target scanline        
slgen   mov             curvb,  vbptr           ' Initialize Main RAM video buffer memory location
        mov             curseg, numSegs         ' Initialize current scanline segment
gettsl  rdlong          tgtsl,  clptr           ' Read target scanline number from Main RAM
        cmp             tgtsl,  cursl wz        ' Check if current scanline is being requested for display
        if_nz jmp       #gettsl                 ' If not, re-read target scanline

        ' Write scanline buffer to video buffer in Main RAM
write   wrlong          slbuff+0, curvb         ' If so, write scanline buffer to Main RAM video buffer
        add             write,  d0              ' Increment scanline buffer memory location
        add             curvb,  #4              ' Increment video buffer memory location
        djnz            curseg, #write          ' Repeat for all scanline segments
        movd            write,  #slbuff         ' Reset initial scanline buffer position
        subs            cursl,  #5              ' Decrement current scanline for next render
        cmps            cursl,  #1 wc           ' Check if at bottom of screen
        if_c  mov       cursl,  initsl          ' Reinitialize current scanline if so
        jmp             #slgen                  ' Generate next scanline

' Test values
tColor        long      0
tColor0       long      %11000011_11000011_11000011_11000011
tColor1       long      %00110011_00110011_00110011_00110011
tColor2       long      %00001111_00001111_00001111_00001111
tColor3       long      %11111111_11111111_11111111_11111111
tColor4       long      %11000011_00000011_00000011_00000011
tLine         long      120

        
' Video attributes
numLines      long      240     ' Number of rendered scanlines
numSegs       long      80      ' Number of scanline segments

' Other values
d0            long      1 << 9  ' Value to increment destination register

' Scanline buffer
slbuff        res       80      ' Buffer containing scanline

' Other pointers
semptr        res       1       ' Pointer to location of semaphore in Main RAM
ilptr         res       1       ' Pointer to location of initial scanline in Main RAM
clptr         res       1       ' Pointer to location of current scanline in Main RAM
vbptr         res       1       ' Pointer to location of video buffer in Main RAM
initsl        res       1       ' Container for initial scanline
cursl         res       1       ' Container for current cog scanline
tgtsl         res       1       ' Container for target scanline
curvb         res       1       ' Current video buffer Main RAM location being written
curseg        res       1       ' Current segment being written to Main RAM

        fit