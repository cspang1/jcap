 {{
        File:     vga.spin
        Author:   Connor Spangler
        Date:     10/26/2017
        Version:  1.2
        Description: 
                  This file contains the PASM code to drive a VGA signal via the Propeller
                  Cog Video Generator.
}}

CON
        _clkmode = xtal1 + pll16x                       ' Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        
VAR
  long  vga_dat       ' VGA data placeholder
  
PUB main
  cognew(@vga, @vga_dat)  ' Initialize cog running "vga" routine with reference to start of variable registers
  
DAT
vga           
              ' Setup and start video generator
              or        dira,   vgapin          ' Set video generator output pins        
              mov       frqa,   pllfreq         ' Set Counter A frequency
              mov       ctra,   CtrCfg          ' Set Counter A control register
              mov       vcfg,   VidCfg          ' Set video generator config register
              rdlong    cnt,    #0              ' Retrive system clock
              shr       cnt,    #10             ' Set-up ~1ms wait
              add       cnt,    cnt             ' Add 1ms wait
              waitcnt   cnt,    #0              ' Allow PLL to settle
              mov       vcfg,   VidCfg          ' Start video generator              

              ' Display video frame              
:frame        mov       fptr,   numTF           ' Initialize frame pointer
:active       mov       lptr,   numLT           ' Initialize line pointer
:tile         mov       tptr,   numTL           ' Initialize tile pointer
              mov       vscl,   VidScl          ' Set video scale for active video
:line         waitvid   tColor, tPixel          ' Update 16-pixel scanline                 
              djnz      tptr,   #:line          ' Display forty 16-pixel segments (one scanline, 40*16=640 pixels)

              'Display horizontal sync area
              mov       vscl,   HVidScl         ' Set video scale for HSync
              waitvid   sColor, hPixel          ' Horizontal sync
              djnz      lptr,   #:tile          ' Display sixteen scanlines (one row of tiles, 40*16*16=10240 pixels)
              djnz      fptr,   #:active        ' Display thirty tiles (entire frame, 480/16=30 tiles)

              'Display vertical sync area
              mov       vptr,   numFP           ' Initialize vertical sync pointer        
:frontporch   mov       vscl,   BVidScl         ' Set video scale for blank active video area
              waitvid   sColor, vpPixel         ' Display blank active video line
              mov       vscl,   HVidScl         ' Set video scale for HSync
              waitvid   sColor, hPixel          ' Horizontal sync
              djnz      vptr,   #:frontporch    ' Display 10 front porch lines           
              mov       vptr,   numVS           ' Initialize vertical sync pointer        
:vsync        mov       vscl,   BVidScl         ' Set video scale for blank active video area
              waitvid   sColor, vPixel          ' Display blank active VSync video line
              mov       vscl,   HVidScl         ' Set video scale for HSync
              waitvid   sColor, hvPixel         ' Horizontal + vertical sync
              djnz      vptr,   #:vsync         ' Display 2 vertical sync lines 
              mov       vptr,   numBP           ' Initialize vertical sync pointer        
:backporch    mov       vscl,   BVidScl         ' Set video scale for blank active video area
              waitvid   sColor, vpPixel         ' Display blank active video line
              mov       vscl,   HVidScl         ' Set video scale for HSync
              waitvid   sColor, hPixel          ' Horizontal sync
              djnz      vptr,   #:backporch     ' Display 33 back porch lines 
              jmp       #:frame                 ' Display frames forever      

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' Counter A output pin
pllfreq       long      337893130                                               ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                 ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111              ' Video generator configuration
VidScl        long      %000000000000_00000001_000000010000                     ' Video generator scale register
HVidScl       long      %000000000000_00010000_000010100000                     ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                     ' Video generator blank line scale register

' Video Generator inputs
tColor        long      %00000011_00000111_00010111_00011111                    ' Test colors
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
tPixel        long      %01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01        ' Test pixels
hPixel        long      %00_00_00_00_00_00_11_11_11_10_10_10_10_10_10_11        ' HSync pixels
vPixel        long      %01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01        ' VSync pixels
vpPixel       long      %11_11_11_11_11_11_11_11_11_11_11_11_11_11_11_11        ' Vertical porch blank pixels
hvPixel       long      %00_00_00_00_00_00_01_01_01_00_00_00_00_00_00_01        ' HVSync pixels

' Frame attributes
numTL         long      40                                                      ' Number of tiles per scanline (640 pixels/16 pixels per tile = 40 tiles) 
numLT         long      16                                                      ' Number of scanlines per tile (16 pixels tall)
numTF         long      30                                                      ' Number of vertical tiles per frame (480 pixels/16 pixels per tile = 30 tiles)                        
numFP         long      10                                                      ' Number of vertical front porch lines                        
numVS         long      2                                                       ' Number of vertical sync lines                        
numBP         long      33                                                      ' Number of vertical back porch lines                        

' Frame pointers
tptr          long      0                                                       ' Current tile being rendered (SHOULD BE RES?)
lptr          long      0                                                       ' Current line being rendered (SHOULD BE RES?)
fptr          long      0                                                       ' Current frame position being rendered (SHOULD BE RES?)
vptr          long      0                                                       ' Current vertical sync line being rendered (SHOULD BE RES?)