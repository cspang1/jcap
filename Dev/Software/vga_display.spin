{{
        File:     vga_display.spin
        Author:   Connor Spangler
        Description: 
                  This file contains the PASM code to drive a VGA signal using video data
                  from hub RAM
}}

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
        add             clptr,  par
        add             vbptrs, par             ' Initialize pointer to video buffer
        rdlong          datptr, datptr          ' Load data indicator location
        rdlong          clptr,  clptr           ' Load current scanline memory location
        rdlong          vbptrs, vbptrs          ' Load video buffer memory location
        mov             cursl,  #0              ' Initialize current scanline
        wrlong          cursl,  clptr           ' Set initial scanline in Main RAM
        mov             lidx,   #2              ' Initialize line pointer
        mov             scnptr, numSegs         ' Initialize segment pointer

        ' Generate scancode               
:rdlng  mov             scancode+0, iR          ' Move rdlong instruction
:wvid   mov             scancode+1, iW          ' Move waitvid instruction
        add             :rdlng, d1              ' Increment next rdlong instruction move
        add             :wvid,  d1              ' Increment next waitvid instruction move
        add             iR,     #1              ' Increment next memory location
:vmmov  mov             vbptrs+1, vbptrs+0      ' Copy memory location to next
:vminc  add             vbptrs+1, #4            ' Increment Main RAM location
        add             :vmmov, d0s0            ' Increment next Main RAM move
        add             :vminc, d0              ' Increment next Main RAM location
        djnz            scnptr, #:rdlng         ' Repeat for all parts of scanline

        ' Setup and start video generator
        or              dira,   vgapin          ' Set video generator output pins
        andn            outa,   vgapin          ' Drive VGA pins low for blanking
        or              dira,   vspin           ' Set VSync signal output pin
        or              dira,   sigpin          ' Set data ready signal output pin
        or              dira,   syncpin         ' Set sync output pins
        andn            outa,   syncpin         ' Drive sync pins high
        mov             frqa,   pllfreq         ' Set Counter A frequency
        mov             ctra,   CtrCfg          ' Set Counter A control register
        rdlong          cnt,    #0              ' Retrive system clock
        shr             cnt,    #10             ' Set-up ~1ms wait
        add             cnt,    cnt             ' Add 1ms wait
        waitcnt         cnt,    #0              ' Allow PLL to settle
        mov             vcfg,   SyncCfg         ' Configure and start video generator
        
        ' Display video
video   or              outa,   vspin           ' Drive vertical sync signal pin high
        mov             vidx,   numFP           ' Initialize vertical sync pointer

        ' Display vertical sync area
:fporch mov             vscl,   blkScale        ' Set video scale for blank active video area
        andn            outa,   vspin           ' Drive vertical sync signal pin low
        waitvid         sColor, pixel3          ' Display blank active video line
        mov             vscl,   fphScale        ' Set video generator scale to half front porch
        waitvid         sColor, pixel0          ' Display first half of front porch
        or              outa,   syncpin         ' Take control of sync pins from video generator
        mov             vcfg,   SyncCfg         ' Set video configuration to control sync pins
        waitvid         sColor, pixel3          ' Display second half of front porch
        andn            outa,   syncpin         ' Hand sync pin control to video generator
        mov             vscl,   hsScale         ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2          ' Display horizontal sync
        mov             vscl,   bphScale        ' Set video generator scale to half back porch
        waitvid         sColor, pixel3          ' Display first half of back porch
        or              outa,   syncpin         ' Take sync pin control back from video generator
        waitvid         sColor, pixel0          ' Display second half of back porch
        mov             vcfg,   ColCfg          ' Set video configuration to control color pins
        djnz            vidx,   #:fporch        ' Display front porch lines
        mov             vcfg,   SyncCfg         ' Set video generator control to sync pins
        mov             vidx,   numVS           ' Initialize vertical sync pointer
:vsync  mov             vscl,   blkScale        ' Set video scale for blank active video area
        waitvid         sColor, pixel1          ' Display blank active VSync video line
        andn            outa,   syncpin         ' Hand sync pin control to video generator
        mov             vscl,   fphScale        ' Set video generator scale to half front porch
        waitvid         sColor, pixel1          ' Display first half of front porch
        waitvid         sColor, pixel1          ' Display second half of front porch
        mov             vscl,   hsScale         ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel0          ' Display horizontal sync
        mov             vscl,   bphScale        ' Set video generator scale to half back porch
        waitvid         sColor, pixel1          ' Display first half of back porch
        waitvid         sColor, pixel1          ' Display second half of back porch
        djnz            vidx,   #:vsync         ' Display vertical sync lines
        mov             vidx,   numBP           ' Initialize vertical sync pointer
:bporch mov             vscl,   blkScale        ' Set video scale for blank active video area
        waitvid         sColor, pixel3          ' Display blank active video line
        mov             vscl,   fphScale        ' Set video generator scale to half front porch
        waitvid         sColor, pixel3          ' Display first half of front porch
        waitvid         sColor, pixel3          ' Display second half of front porch
        mov             vscl,   hsScale         ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2          ' Display horizontal sync
        mov             vscl,   bphScale        ' Set video generator scale to half back porch
        waitvid         sColor, pixel3          ' Display first half of back porch
        cmp             vidx,   #1 wz           ' Check if last back porch line
        if_z  or        outa,   syncpin         ' Take control of sync pins from video generator
        if_z  waitvid   sColor, pixel0          ' Display second half of back porch
        if_z  mov       vcfg,   ColCfg          ' Set video configuration to control color pins
        if_nz waitvid   sColor, pixel3          ' Display second half of back porch
        cmp             vidx,   dataSig wz      ' Check if graphics data ready
        if_z  or        outa,   sigpin          ' Signal data ready
        djnz            vidx,   #:bporch        ' Display back porch lines
        andn            outa,   sigpin          ' Disable data ready signal

        ' Display active video
nextsl  add             cursl,  #1              ' Increment current scanline
active  mov             vscl,   visScale        ' Set video scale for visible video
        jmp             #scancode               ' Display line
scanret djnz            lidx,   #active         ' Display same line twice
        cmp             cursl,  numLines wz     ' Check if at bottom of screen
        if_z  mov       cursl,  #0              ' Reset current scanline
        wrlong          cursl,  clptr           ' Set current scanline in Main RAM
        mov             lidx,   #2              ' Reset line pointer
        if_nz jmp       #nextsl                 ' Continue displaying remaining scanlines
        jmp             #video                  ' Return to start of display

' Scancode resources
scancode      long      0[80*2]                 ' Buffer containing display scancode
        mov             vscl,   fphScale        ' Set video generator scale to half front porch
        waitvid         sColor, pixel0          ' Display first half of front porch
        or              outa,   syncpin         ' Take control of sync pins from video generator
        mov             vcfg,   SyncCfg         ' Set video configuration to control sync pins
        waitvid         sColor, pixel3          ' Display second half of front porch
        andn            outa,   syncpin         ' Hand sync pin control to video generator
        mov             vscl,   hsScale         ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2          ' Display horizontal sync
        mov             vscl,   bphScale        ' Set video generator scale to half back porch
        waitvid         sColor, pixel3          ' Display first half of back porch
        or              outa,   syncpin         ' Take sync pin control back from video generator
        waitvid         sColor, pixel0          ' Display second half of back porch
        mov             vcfg,   ColCfg          ' Set video configuration to control color pins
        jmp             #scanret                ' Return to rest of display
iR      rdlong          pixels, vbptrs+0        ' Load next pixels
iW      waitvid         pixels, #%%3210         ' Display pixels

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' VGA output pins
syncpin       long      |< 24 | |< 25                                                                   ' Sync pins
sigpin        long      |< 26                                                                           ' Data ready signal pin
vspin         long      |< 27                                                                           ' VSync signal output pin
pllfreq       long      259917792                                                                       ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration
ColCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111                                      ' Video generator color pins configuration
SyncCfg       long      %0_01_1_0_0_000_00000000000_011_0_11111111                                      ' Video generator sync pins configuration

' Video generator resources
visScale      long      %000000000000_00000010_000000001000                     ' Video generator visible video scale register
blkScale      long      %000000000000_00000000_001010000000                     ' Video generator blank line scale register
fphScale      long      %000000000000_00000000_000000001000                     ' Video generator scale for half of front porch
hsScale       long      %000000000000_00000000_000001100000                     ' Video generator scale for horizontal sync
bphScale      long      %000000000000_00000000_000000011000                     ' Video generator scale for horizontal sync
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
pixel0        long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' Porch color blank pixels
pixel1        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
pixel2        long      %%2_2_2_2_2_2_2_2_2_2_2_2_2_2_2_2                       ' HSync sync blank pixels
pixel3        long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Porch sync blank pixels

' Video frame attributes
numFP         long      10      ' Number of vertical front porch lines                        
numVS         long      2       ' Number of vertical sync lines                        
numBP         long      33      ' Number of vertical back porch lines
numLines      long      240     ' Number of rendered lines
numSegs       long      80      ' Number of scanline segments

' Other values
d0s0          long      1 << 9 + 1              ' Value to increment source and destination registers         
d0            long      1 << 9                  ' Value to increment destination register
d1            long      1 << 10                 ' Value to incrememnt destination register by 2
dataSig       long      15                      ' Back porch scanline to signal render cogs

' Main RAM pointers
datptr        long      0                       ' Pointer to location of data indicator
clptr         long      4                       ' Pointer to location of current scanline in Main RAM
vbptrs        long      8[80]                   ' Buffer containing Main RAM video buffer memory locations

' Frame indexes
lidx          res       1       ' Current line being rendered
vidx          res       1       ' Current vertical sync line being rendered

' Other values
scnptr        res       1       ' Pointer to current scancode section being generated
cursl         res       1       ' Container for current scanline
pixels        res       1       ' Container for currently rendering pixels

        fit