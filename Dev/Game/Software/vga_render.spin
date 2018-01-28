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
  ' Graphics system attributes
  long  cog_[numRenderCogs]     ' Array containing IDs of rendering cogs
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  start_line_             ' Variable for start of cog line rendering
  
PUB start(varAddrBase) : status | cIndex                                        ' Function to start renderer with pointer to Main RAM variables
  stop                                                                          ' Stop render cogs if running

  ' Instantiate variables
  var_addr_base_ := varAddrBase                                                 ' Assign local base variable address

  repeat cIndex from 0 to numRenderCogs - 1
    start_line_ := cIndex                                                       ' Set start line for next cog
    ifnot cog_[cIndex] := cognew(@render, @var_addr_base_) + 1                  ' Initialize cog running "render" routine with reference to start of variables
      return FALSE                                                              ' Graphics system failed to initialize
    waitcnt($2000 + cnt)                                                        ' Wait for cogs to finish initializing

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
        mov             ilptr,  par             ' Initialize pointer to initial scanline
        add             ilptr,  #4              ' Point initial scanline pointer
        rdlong          initsl, ilptr           ' Load initial scanline
        neg             initsl, initsl          ' Invert initial scanline
        adds            initsl, numLines        ' Subtract initial scanline from number of scanlines
        mov             cursl,  initsl          ' Initialize current scanline
        mov             vbptr,  clptr           ' Initialize pointer to video buffer
        add             vbptr,  #4              ' Point video buffer pointer to video buffer
        rdlong          clptr,  clptr           ' Load current scanline memory location
        rdlong          vbptr,  vbptr           ' Load video buffer memory location

        ' TEST CODE
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
        ' TEST CODE
        
loop    mov             curvb,  vbptr
        mov             curseg, numSegs
lp      rdlong          tgtsl,  clptr
        cmp             tgtsl,  cursl wz
        if_nz jmp       #lp
write   wrlong          tColor, curvb
        add             curvb,  #4
        djnz            curseg, #write
        subs            cursl,  #5
        cmps            cursl,  #1 wc
        if_c  mov       cursl,  initsl
        jmp             #loop                   ' Loop infinitely

' Test values
tColor        long      0
tColor0       long      %11000011_11000011_11000011_11000011
tColor1       long      %00110011_00110011_00110011_00110011
tColor2       long      %00001111_00001111_00001111_00001111
tColor3       long      %11111111_11111111_11111111_11111111
tColor4       long      %00000011_00000011_00000011_00000011
tLine         long      120

        
' Video attributes
numLines      long      240     ' Number of rendered scanlines
numSegs       long      80      ' Number of scanline segments

' Scanline buffer
slbuff        res       80      ' Buffer containing scanline

' Other pointers
ilptr         res       1       ' Pointer to location of initial scanline in Main RAM
clptr         res       1       ' Pointer to location of current scanline in Main RAM
vbptr         res       1       ' Pointer to location of video buffer in Main RAM
initsl        res       1       ' Container for initial scanline
cursl         res       1       ' Container for current cog scanline
tgtsl         res       1       ' Container for target scanline
curvb         res       1       ' Current video buffer Main RAM location being written
curseg        res       1       ' Current segment being written to Main RAM

        fit