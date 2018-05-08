{{
        File:     vga_tx.spin
        Author:   Connor Spangler
        Date:     5/1/2018
        Version:  0.1
        Description: 
                  This file contains the PASM code to transmit graphics resources from one
                  Propeller to another
}}

VAR
  long  cog_                    ' Variable containing ID of transmission cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  long  cont_                   ' Variable containing control flag for transmission routine
  
PUB start(varAddrBase) : status                         ' Function to start transmission driver with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address

  ' Start transmission driver
  ifnot cog_ := cognew(@tx, var_addr_base_) + 1         ' Initialize cog running "tx" routine with reference to start of variable registers
    return FALSE                                        ' Transmission system failed to initialize

  return TRUE                                           ' Transmission system successfully initialized

PUB stop                                                ' Function to stop transmission driver
    if cog_                                             ' If cog is running
      cogstop(cog_~ - 1)                                ' Stop the cog
  
DAT
        org             0
        ' Start of the graphics data transmission routine
tx      jmp             #tx     ' Loop infinitely

        fit