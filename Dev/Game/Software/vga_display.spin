{{
        File:     vga_display.spin
        Author:   Connor Spangler
        Date:     1/23/2018
        Version:  0.2
        Description: 
                  This file contains the PASM code to drive a VGA signal using video data
                  from hub RAM
}}

VAR
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase)          ' Function to start vga driver with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase ' Assign local base variable address

  ' Start VGA driver
  cognew(@vga, var_addr_base_)  ' Initialize cog running "vga" routine with reference to start of variable registers
  
DAT
        org             0
vga           
        ' Setup and start video generator
        or              dira,   vgapin          ' Set video generator output pins        
        mov             frqa,   pllfreq         ' Set Counter A frequency
        mov             ctra,   CtrCfg          ' Set Counter A control register
        mov             vcfg,   VidCfg          ' Set video generator config register
        rdlong          cnt,    #0              ' Retrive system clock
        shr             cnt,    #10             ' Set-up ~1ms wait
        add             cnt,    cnt             ' Add 1ms wait
        waitcnt         cnt,    #0              ' Allow PLL to settle
        mov             vcfg,   VidCfg          ' Start video generator

        ' Initialize variables
        mov             clptr,  par             ' Initialize pointer to current scanline
        mov             vbptr,  par             ' Initialize pointer to video buffer
        add             vbptr,  #4              ' Point video buffer pointer to video buffer                
        mov             cursl,  numLines        ' Initialize current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM
        mov             lptr,   #2              ' Initialize line pointer             
        
:video  ' Signal vertical sync pin
        or              outa,   vspin           ' Drive vertical sync signal pin high        

        ' Display vertical sync area
        mov             vptr,   numFP           ' Initialize vertical sync pointer        
:fporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        andn            outa,   vspin           ' Drive vertical sync signal pin low
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:fporch        ' Display front porch lines           
        mov             vptr,   numVS           ' Initialize vertical sync pointer        
:vsync  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        djnz            vptr,   #:vsync         ' Display vertical sync lines 
        mov             vptr,   numBP           ' Initialize vertical sync pointer        
:bporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:bporch        ' Display back porch lines 

:active ' Display active video
        mov             vscl,   BVidScl         {{ TEST DISPLAY ONE FULL SCANLINE }}
        waitvid         tColor, vpPixel         {{ TEST DISPLAY ONE FULL SCANLINE }}         

        ' Display horizontal sync area
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        
        djnz            lptr,   #:active        ' Display same line twice
        mov             lptr,   #2              ' Reset line pointer             

        sub             cursl,  #1              ' Decrement current scanline
        wrlong          cursl,  clptr           ' Set current scanline in Main RAM                
        tjnz            cursl,  #:active        ' Continue displaying remaining scanlines 

        mov             cursl,  numLines        ' Reset current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM

        jmp             #:video                 ' Return to start of display

' Test values
tColor        long      %11000011_00110011_00001111_11111111                    ' Test colors                                                                

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' VGA output pins
vspin         long      |< 24                                                                           ' VSync signal output pin
pllfreq       long      337893130                                                                       ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111                                      ' Video generator configuration
VVidScl       long      %000000000000_00000010_000000001000                                             ' Video generator visible video scale register
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register

' Video Generator inputs
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
hPixel        long      %%0_0_0_0_0_0_3_3_3_2_2_2_2_2_2_3                       ' HSync pixels
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
vpPixel       long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Vertical porch blank pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Video attributes
numFP         long      10      ' Number of vertical front porch lines                        
numVS         long      2       ' Number of vertical sync lines                        
numBP         long      33      ' Number of vertical back porch lines
numLines      long      240     ' Number of rendered lines

' Frame pointers
lptr          res       1       ' Current line being rendered
vptr          res       1       ' Current vertical sync line being rendered
mptr          res       1       ' Current pointer to hub RAM pixels being rendered

' Other pointers
clptr         res       1       ' Pointer to location of current scanline in Main RAM
vbptr         res       1       ' Pointer to location of video buffer in Main RAM
cursl         res       1       ' Container for current scanline
pixels        res       1       ' Container for currently rendering pixels

        fit
        