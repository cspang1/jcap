{{
    File:     vga_display.spin
    Author:   Connor Spangler
    Description:
        This file contains the PASM code to drive a VGA signal using video data
        from hub RAM
}}

OBJ
    system: "system"

VAR
    long    cog_            ' Variable containing ID of display cog
    long    var_addr_base_  ' Variable for pointer to base address of Main RAM variables
  
PUB start(varAddrBase) : status ' Function to start vga driver with pointer to Main RAM variables
    var_addr_base_ := varAddrBase   ' Assign local base variable address

    ' Start VGA driver
    ifnot cog_ := cognew(@vga, var_addr_base_) + 1  ' Initialize cog running "vga" routine with reference to start of variable registers
        return FALSE                                ' Graphics system failed to initialize

    return TRUE ' Graphics system successfully initialized

PUB stop                    ' Function to stop VGA driver
    if cog_                 ' If cog is running
      cogstop(cog_~ - 1)    ' Stop the cog
  
DAT
        org             0
vga           
        ' Initialize variables
        add             clptr,  par                     ' Initialize pointer to current scanline
        add             vbptrs, par                     ' Initialize pointer to video buffer
        rdlong          datptr, par                     ' Load data indicator location
        rdlong          clptr,  clptr                   ' Load current scanline memory location
        rdlong          vbptrs, vbptrs                  ' Load video buffer memory location
        mov             initvb, vbptrs                  ' Initialize initial video buffer memory location
        mov             cursl,  #system#VID_BUFFER_SIZE ' Initialize segment pointer

        ' Generate scancode               
:rdlng  mov             sc+0,   iR          ' Move rdlong instruction
:wvid   mov             sc+1,   iW          ' Move waitvid instruction
        add             :rdlng, d1          ' Increment next rdlong instruction move
        add             :wvid,  d1          ' Increment next waitvid instruction move
        add             iR,     d0s0        ' Increment next memory location
        add             iW,     d0          ' Increment next memory location
:vmmov  mov             vbptrs+1, vbptrs+0  ' Copy memory location to next
:vminc  add             vbptrs+1, #4        ' Increment Main RAM location
        add             :vmmov, d0s0        ' Increment next Main RAM move
        add             :vminc, d0          ' Increment next Main RAM location
        djnz            cursl,  #:rdlng     ' Repeat for all parts of scanline

        ' Setup and start video generator
        or              dira,   vgapin      ' Set video generator output pins
        andn            outa,   vgapin      ' Drive VGA pins low for blanking
        or              dira,   syncpin     ' Set sync output pins
        andn            outa,   syncpin     ' Drive sync pins high
        mov             frqa,   pllfreq     ' Set Counter A frequency
        mov             ctra,   CtrCfg      ' Set Counter A control register
        rdlong          cnt,    #0          ' Retrive system clock
        shr             cnt,    #10         ' Set-up ~1ms wait
        add             cnt,    cnt         ' Add 1ms wait
        waitcnt         cnt,    #0          ' Allow PLL to settle
        mov             vcfg,   SyncCfg     ' Configure and start video generator
        
        ' Display video
        mov             cursl,  #0      ' Initialize current scanline
        wrlong          cursl,  clptr   ' Set initial scanline in Main RAM
video   mov             vidx,   numFP   ' Initialize vertical sync pointer

        ' Display vertical sync area
:fporch mov             vscl,   blkScale    ' Set video scale for blank active video area
        waitvid         sColor, pixel3      ' Display blank active video line
        mov             vscl,   fphScale    ' Set video generator scale to half front porch
        waitvid         sColor, pixel0      ' Display first half of front porch
        or              outa,   syncpin     ' Take control of sync pins from video generator
        mov             vcfg,   SyncCfg     ' Set video configuration to control sync pins
        waitvid         sColor, pixel3      ' Display second half of front porch
        andn            outa,   syncpin     ' Hand sync pin control to video generator
        mov             vscl,   hsScale     ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2      ' Display horizontal sync
        mov             vscl,   bphScale    ' Set video generator scale to half back porch
        waitvid         sColor, pixel3      ' Display first half of back porch
        or              outa,   syncpin     ' Take sync pin control back from video generator
        waitvid         sColor, pixel0      ' Display second half of back porch
        mov             vcfg,   ColCfg      ' Set video configuration to control color pins
        djnz            vidx,   #:fporch    ' Display front porch lines
        mov             vcfg,   SyncCfg     ' Set video generator control to sync pins
        mov             vidx,   numVS       ' Initialize vertical sync pointer
:vsync  mov             vscl,   blkScale    ' Set video scale for blank active video area
        waitvid         sColor, pixel1      ' Display blank active VSync video line
        andn            outa,   syncpin     ' Hand sync pin control to video generator
        mov             vscl,   fphScale    ' Set video generator scale to half front porch
        waitvid         sColor, pixel1      ' Display first half of front porch
        waitvid         sColor, pixel1      ' Display second half of front porch
        mov             vscl,   hsScale     ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel0      ' Display horizontal sync
        mov             vscl,   bphScale    ' Set video generator scale to half back porch
        waitvid         sColor, pixel1      ' Display first half of back porch
        waitvid         sColor, pixel1      ' Display second half of back porch
        djnz            vidx,   #:vsync     ' Display vertical sync lines
        mov             vidx,   numBP       ' Initialize vertical sync pointer
:bporch mov             vscl,   blkScale    ' Set video scale for blank active video area
        waitvid         sColor, pixel3      ' Display blank active video line
        mov             vscl,   fphScale    ' Set video generator scale to half front porch
        waitvid         sColor, pixel3      ' Display first half of front porch
        waitvid         sColor, pixel3      ' Display second half of front porch
        mov             vscl,   hsScale     ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2      ' Display horizontal sync
        mov             vscl,   bphScale    ' Set video generator scale to half back porch
        waitvid         sColor, pixel3      ' Display first half of back porch
        cmp             vidx,   #1 wz       ' Check if last back porch line
        if_z  or        outa,   syncpin     ' Take control of sync pins from video generator
        if_z  waitvid   sColor, pixel0      ' Display second half of back porch
        if_z  mov       vcfg,   ColCfg      ' Set video configuration to control color pins
        if_nz waitvid   sColor, pixel3      ' Display second half of back porch
        cmp             vidx,   dataSig wz  ' Check if graphics data ready
        if_z  wrlong    pixel0, datptr      ' Indicate graphics resources data ready
        djnz            vidx,   #:bporch    ' Display back porch lines
        wrlong          pixel1, datptr      ' Disable data ready indicator

        ' Display active video
nextsl  add             cursl,  #1          ' Increment current scanline
active  mov             vscl,   visScale    ' Set video scale for visible video

        ' Display scanline first time
sc      long            0[80*2]             ' Buffer containing display scancode
        mov             vscl,   fphScale    ' Set video generator scale to half front porch
        waitvid         sColor, pixel0      ' Display first half of front porch
        or              outa,   syncpin     ' Take control of sync pins from video generator
        mov             vcfg,   SyncCfg     ' Set video configuration to control sync pins
        waitvid         sColor, pixel3      ' Display second half of front porch
        andn            outa,   syncpin     ' Hand sync pin control to video generator
        mov             vscl,   hsScale     ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2      ' Display horizontal sync
        mov             vscl,   bphScale    ' Set video generator scale to half back porch
        waitvid         sColor, pixel3      ' Display first half of back porch
        or              outa,   syncpin     ' Take sync pin control back from video generator
        waitvid         sColor, pixel0      ' Display second half of back porch
        mov             vcfg,   ColCfg      ' Set video configuration to control color pins

        ' Update target scanline in main RAM
        cmp             cursl,  numLines wz ' Check if at bottom of screen
        if_z  mov       cursl,  #0          ' Reset current scanline
        wrlong          cursl,  clptr       ' Set current scanline in Main RAM

        ' Display scanline second time
        mov             vscl,   visScale                ' Set video scale for visible video
        mov             temp,   initvb                  ' scanline hub address
        mov             vidx,   #system#VID_BUFFER_SIZE ' Initialize segment counter
        movd            :loop,  #vbptrs+0               ' Initialize initial render address
        movd            :patch, #vbptrs+0               ' Initialize initial patch address
:loop   waitvid         vbptrs+0, #%%3210               ' Output 4 pixels
        add             $-1,    d0                      ' Increment render address
:patch  mov             vbptrs+0, temp                  ' Restore patch address
        add             $-1,    d0                      ' Increment patch address
        add             temp,   #4                      ' Increment main memory address
        djnz            vidx,   #:loop                  ' Repeat for all scanline segments
        mov             vscl,   fphScale                ' Set video generator scale to half front porch
        waitvid         sColor, pixel0                  ' Display first half of front porch
        or              outa,   syncpin                 ' Take control of sync pins from video generator
        mov             vcfg,   SyncCfg                 ' Set video configuration to control sync pins
        waitvid         sColor, pixel3                  ' Display second half of front porch
        andn            outa,   syncpin                 ' Hand sync pin control to video generator
        mov             vscl,   hsScale                 ' Set video generator scale to horizontal sync
        waitvid         sColor, pixel2                  ' Display horizontal sync
        mov             vscl,   bphScale                ' Set video generator scale to half back porch
        waitvid         sColor, pixel3                  ' Display first half of back porch
        or              outa,   syncpin                 ' Take sync pin control back from video generator
        waitvid         sColor, pixel0                  ' Display second half of back porch
        mov             vcfg,   ColCfg                  ' Set video configuration to control color pins

        ' Continue rendering frame
        if_nz jmp       #nextsl ' Continue displaying remaining scanlines
        jmp             #video  ' Return to start of display

' Scancode resources
iR      rdlong          vbptrs+0, vbptrs+0  ' Load next pixels
iW      waitvid         vbptrs+0, #%%3210   ' Display pixels

' Config values
vgapin      long      |<16 | |<17 | |<18 | |<19 | |<20 | |<21 | |<22 | |<23 ' VGA output pins
syncpin     long      |<24 | |<25                                           ' Sync pins
pllfreq     long      259917792                                             ' Counter A frequency
CtrCfg      long      %00000110100000000000000000000000                     ' Counter A configuration
ColCfg      long      %00110000000000000000010011111111                     ' Video generator color pins configuration
SyncCfg     long      %00110000000000000000011011111111                     ' Video generator sync pins configuration

' Video generator resources
visScale    long      %00000000000000000010000000001000 ' Video generator visible video scale register
blkScale    long      %00000000000000000000001010000000 ' Video generator blank line scale register
fphScale    long      %00000000000000000000000000001000 ' Video generator scale for half of front porch
hsScale     long      %00000000000000000000000001100000 ' Video generator scale for horizontal sync
bphScale    long      %00000000000000000000000000011000 ' Video generator scale for horizontal sync
sColor      long      %00000011000000100000000100000000 ' Sync colors (porch_HSync_VSync_HVSync)
pixel0      long      %%0000000000000000                ' Porch color blank pixels
pixel1      long      %%1111111111111111                ' VSync pixels blank pixels
pixel2      long      %%2222222222222222                ' HSync sync blank pixels
pixel3      long      %%3333333333333333                ' Porch sync blank pixels

' Video frame attributes
numFP       long      10    ' Number of vertical front porch lines
numVS       long      2     ' Number of vertical sync lines
numBP       long      33    ' Number of vertical back porch lines
numLines    long      240   ' Number of rendered lines

' Other values
d0s0        long      1<<9+1    ' Value to increment source and destination registers
d0          long      1<<9      ' Value to increment destination register
d1          long      1<<10     ' Value to incrememnt destination register by 2
dataSig     long      15        ' Back porch scanline to signal render cogs

' Main RAM pointers
datptr      long      0                             ' Pointer to location of data indicator
clptr       long      4                             ' Pointer to location of current scanline in Main RAM
vbptrs      long      8[system#VID_BUFFER_SIZE+1]   ' Buffer containing Main RAM video buffer memory locations
initvb      long      0                             ' Buffer containing initial Main RAM video buffer memory location

' Other values
vidx        res       1 ' Current vertical sync line being rendered
cursl       res       1 ' Container for current scanline
temp        res       1 ' Container for currently rendering pixels

        fit
