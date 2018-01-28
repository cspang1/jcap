{{
        File:     vga_render.spin
        Author:   Connor Spangler
        Date:     1/27/2018
        Version:  0.1
        Description: 
                  This file contains the PASM code to generate video data and store it to hub RAM
                  to be displayed by the vga_display routine
}}

CON

VAR
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase)          ' Function to start renderer with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase ' Assign local base variable address

  ' Start VGA driver
  cognew(@render, var_addr_base_)  ' Initialize cog running "vga" routine with reference to start of variable registers
  
DAT
        org             0
render           
        ' Initialize variables
        mov             clptr,  par             ' Initialize pointer to current scanline
        mov             vbptr,  par             ' Initialize pointer to video buffer
        add             vbptr,  #4              ' Point video buffer pointer to video buffer
        rdlong          clptr,  clptr           ' Load current scanline memory location
        rdlong          vbptr,  vbptr           ' Load video buffer memory location
loop    mov             curseg, numSegs
        mov             curvb,  vbptr
write   wrlong          tColor, curvb
        add             curvb,  #4
        djnz            curseg, #write
        jmp             #loop                   ' Loop infinitely

' Test values
tColor        long      %11000011_11000011_00000011_00000011
tLine         long      120
        
' Video attributes
numLines      long      240     ' Number of rendered scanlines
numSegs       long      80      ' Number of scanline segment

' Other pointers
clptr         res       1       ' Pointer to location of current scanline in Main RAM
vbptr         res       1       ' Pointer to location of video buffer in Main RAM
cursl         res       1       ' Container for current scanline
curvb         res       1       ' Current video buffer Main RAM location being written
curseg        res       1       ' Current segment being written to Main RAM

        fit