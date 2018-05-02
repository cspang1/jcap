{{
        File:     vga_rx.spin
        Author:   Connor Spangler
        Date:     5/1/2018
        Version:  0.1
        Description: 
                  This file contains the PASM code to receive graphics resources from 
                  another Propeller
}}

VAR
  long  cog_                    ' Variable containing ID of reception cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase) : status                         ' Function to start reception driver with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address

  ' Start reception driver
  ifnot cog_ := cognew(@rx, var_addr_base_) + 1         ' Initialize cog running "rx" routine with reference to start of variable registers
    return FALSE                                        ' Reception system failed to initialize

  return TRUE                                           ' Reception system successfully initialized

PUB stop                                                ' Function to stop reception driver
    if cog_                                             ' If cog is running
      cogstop(cog_~ - 1)                                ' Stop the cog
  
DAT
        org             0
        ' Start of the graphics data transmission routine
rx      jmp             #rx     ' Loop infinitely

        fit