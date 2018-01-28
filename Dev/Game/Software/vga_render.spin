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
        rdlong          clptr,  clptr           ' Load current scanline memory location
loop    jmp             #loop                   ' Loop infinitely
        
' Video attributes
numLines      long      240     ' Number of rendered lines

' Other pointers
clptr         res       1       ' Pointer to location of current scanline in Main RAM
cursl         res       1       ' Container for current scanline

        fit