{{
        File:     vga_display.spin
        Author:   Connor Spangler
        Date:     1/23/2018
        Version:  1.1
        Description: 
                  This file contains the PASM code to drive a VGA signal using video data
                  from hub RAM
}}

CON
  segs = 80     ' Set number of scanline segments (320 pixels/4 pixels per waitvid)

VAR
  long  cog_                    ' Variable containing ID of display cog
  long  var_addr_base_          ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase) : status                         ' Function to start vga driver with pointer to Main RAM variables
  ' Instantiate variables
  var_addr_base_ := varAddrBase                         ' Assign local base variable address

  ' Start VGA driver
  ifnot cog_ := cognew(@vga, var_addr_base_) + 1        ' Initialize cog running "vga" routine with reference to start of variable registers
    return FALSE                                        ' Graphics system failed to initialize

  return TRUE                                           ' Graphics system successfully initialized

PUB stop                                                ' Function to stop VGA driver
    if cog_                                             ' If cog is running
      cogstop(cog_~ - 1)                                ' Stop the cog
  
DAT
        org             0
vga           
        ' Initialize variables
        mov             clptr,  par             ' Initialize pointer to current scanline
        mov             vbptrs, par             ' Initialize pointer to video buffer
        add             vbptrs, #4              ' Point video buffer pointer to video buffer
        rdlong          clptr,  clptr           ' Load current scanline memory location
        rdlong          vbptrs, vbptrs          ' Load video buffer memory location
        mov             cursl,  numLines        ' Initialize current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM
        mov             lptr,   #2              ' Initialize line pointer
        mov             scnptr, #segs           ' Initialize segment pointer

        ' Generate scancode               
:rdlng  mov             scancode+0, i0          ' Move rdlong instruction
:wvid   mov             scancode+1, i1          ' Move waitvid instruction
        add             :rdlng, d1              ' Increment next rdlong instruction move
        add             :wvid,  d1              ' Increment next waitvid instruction move
        add             i0,     #1              ' Increment next memory location        
:vmmov  mov             vbptrs+1, vbptrs+0      ' Copy memory location to next
:vminc  add             vbptrs+1, #4            ' Increment Main RAM location
        add             :vmmov, d0s0            ' Increment next Main RAM move
        add             :vminc, d0              ' Increment next Main RAM location
        djnz            scnptr, #:rdlng         ' Repeat for all parts of scanline
        mov             scancode+segs*2+0, i2   ' Move hsync vscl change instruction
        mov             scancode+segs*2+1, i3   ' Move hsync waitvid instruction
        mov             scancode+segs*2+2, i4   ' Move jmp instruction

        ' Setup and start video generator
        or              dira,   vgapin          ' Set video generator output pins
        or              dira,   vspin           ' Set VSync signal output pinv        
        mov             frqa,   pllfreq         ' Set Counter A frequency
        mov             ctra,   CtrCfg          ' Set Counter A control register
        mov             vcfg,   VidCfg          ' Set video generator config register
        rdlong          cnt,    #0              ' Retrive system clock
        shr             cnt,    #10             ' Set-up ~1ms wait
        add             cnt,    cnt             ' Add 1ms wait
        waitcnt         cnt,    #0              ' Allow PLL to settle
        mov             vcfg,   VidCfg          ' Start video generator             
        
        ' Display vertical sync area
video   or              outa,   vspin           ' Drive vertical sync signal pin high
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

        ' Display active video
active  mov             vscl,   VVidScl         ' Set video scale for visible video
        jmp             #scancode               ' Display line
scanret djnz            lptr,   #active         ' Display same line twice
        mov             lptr,   #2              ' Reset line pointer             
        sub             cursl,  #1              ' Decrement current scanline
        wrlong          cursl,  clptr           ' Set current scanline in Main RAM                
        tjnz            cursl,  #active         ' Continue displaying remaining scanlines 
        mov             cursl,  numLines        ' Reset current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM
        jmp             #video                  ' Return to start of display

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' VGA output pins
vspin         long      |< 24                                                                           ' VSync signal output pin
pllfreq       long      259917792                                                                       ' Counter A frequency
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

' Instructions used to generate scancode
i0            rdlong    pixels, vbptrs+0        ' Load next pixels
i1            waitvid   pixels, #%%3210         ' Display pixels
i2            mov       vscl,   HVidScl         ' Set video scale for HSync
i3            waitvid   sColor, hPixel          ' Horizontal sync
i4            jmp       #scanret                ' Return to rest of display

' Other values
d0s0          long      1 << 9 + 1              ' Value to increment source and destination registers         
d0            long      1 << 9                  ' Value to increment destination register
d1            long      1 << 10                 ' Value to incrememnt destination register by 2

' Scancode buffer
scancode      long      0[80*2+3]               ' Buffer containing display scancode
vbptrs        long      0[80]                   ' Buffer containing Main RAM video buffer memory locations

' Frame pointers
lptr          res       1       ' Current line being rendered
vptr          res       1       ' Current vertical sync line being rendered

' Other pointers
scnptr        res       1       ' Pointer to current scancode section being generated
clptr         res       1       ' Pointer to location of current scanline in Main RAM
cursl         res       1       ' Container for current scanline
pixels        res       1       ' Container for currently rendering pixels

        fit