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
  word  input_state   ' Register in Main RAM containing state of inputs 
  
PUB main
  cognew(@vga, @input_state)    ' Initialize cog running "vga" routine with reference to start of variable registers
  cognew(@input, @input_state)  ' Initialize cog running "input" routine with reference to start of variable registers
  
DAT
        org       0
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
        mov             iptr,   par             ' Load Main RAM input_state address into iptr              

        ' Display visible area              
:frame  rdword          is,     iptr            ' Read input_state from Main RAM
        mov             colors, ColorK          ' Set default color to black        
        test            btn1,   is wc           ' Test button 1 pressed
        if_c  mov       colors, ColorR          ' If button 1 pressed set color to red
        test            btn2,   is wc           ' Test button 2 pressed
        if_c  mov       colors, ColorG          ' If button 2 pressed set color to green
        test            btn3,   is wc           ' Test button 3 pressed
        if_c  mov       colors, ColorB          ' If button 3 pressed set color to blue
        test            tilt,   is wc           ' Test tilt sensor
        if_c  mov       colors, ColorW          ' If tilt sensor triggered set color to white
        mov             fptr,   numTF           ' Initialize frame pointer
:active mov             lptr,   numLT           ' Initialize line pointer
:tile   mov             tptr,   numTL           ' Initialize tile pointer
        mov             vscl,   VidScl          ' Set video scale for active video
:line   waitvid         colors, tPixel          ' Update 16-pixel scanline                 
        djnz            tptr,   #:line          ' Display forty 16-pixel segments (one scanline, 40*16=640 pixels)

        ' Display horizontal sync area
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            lptr,   #:tile          ' Display sixteen scanlines (one row of tiles, 40*16*16=10240 pixels)
        djnz            fptr,   #:active        ' Display thirty tiles (entire frame, 480/16=30 tiles)

        ' Display vertical sync area
        mov             vptr,   numFP           ' Initialize vertical sync pointer        
:fporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:fporch        ' Display 10 front porch lines           
        mov             vptr,   numVS           ' Initialize vertical sync pointer        
:vsync  mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vPixel          ' Display blank active VSync video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hvPixel         ' Horizontal + vertical sync
        djnz            vptr,   #:vsync         ' Display 2 vertical sync lines 
        mov             vptr,   numBP           ' Initialize vertical sync pointer        
:bporch mov             vscl,   BVidScl         ' Set video scale for blank active video area
        waitvid         sColor, vpPixel         ' Display blank active video line
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            vptr,   #:bporch        ' Display 33 back porch lines 
        jmp             #:frame                 ' Display frames forever      

' Config values
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' Counter A output pin
pllfreq       long      337893130                                                                       ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111                                      ' Video generator configuration
VidScl        long      %000000000000_00000001_000000010000                                             ' Video generator scale register
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register

' Input locations
btn1          long      |< 7    ' Button 1 location in input states
btn2          long      |< 6    ' Button 2 location in input states
btn3          long      |< 5    ' Button 3 location in input states
tilt          long      |< 4    ' Tilt location in input states

' Video Generator inputs
ColorR        long      %11000011_11000011_11000011_11000011                    ' Test colors
ColorG        long      %00110011_00110011_00110011_00110011                    ' Test colors
ColorB        long      %00001111_00001111_00001111_00001111                    ' Test colors
ColorW        long      %11111111_11111111_11111111_11111111                    ' Test colors
ColorK        long      %00000011_00000011_00000011_00000011                    ' Test colors
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
tPixel        long      %11_10_01_00_11_10_01_00_11_10_01_00_11_10_01_00        ' Test pixels
hPixel        long      %00_00_00_00_00_00_11_11_11_10_10_10_10_10_10_11        ' HSync pixels
vPixel        long      %01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01        ' VSync pixels
vpPixel       long      %11_11_11_11_11_11_11_11_11_11_11_11_11_11_11_11        ' Vertical porch blank pixels
hvPixel       long      %00_00_00_00_00_00_01_01_01_00_00_00_00_00_00_01        ' HVSync pixels

' Frame attributes
numTL         long      40      ' Number of tiles per scanline (640 pixels/16 pixels per tile = 40 tiles) 
numLT         long      16      ' Number of scanlines per tile (16 pixels tall)
numTF         long      30      ' Number of vertical tiles per frame (480 pixels/16 pixels per tile = 30 tiles)                        
numFP         long      10      ' Number of vertical front porch lines                        
numVS         long      2       ' Number of vertical sync lines                        
numBP         long      33      ' Number of vertical back porch lines                        

' Frame pointers
tptr          res       1       ' Current tile being rendered
lptr          res       1       ' Current line being rendered
fptr          res       1       ' Current frame position being rendered
vptr          res       1       ' Current vertical sync line being rendered
iptr          res       1       ' Pointer to input states in Main RAM
is            res       1       ' Register containing input states
colors        res       1       ' Register containing current colors
        fit
DAT        
        org             0
{{
The "input" routine interfaces with the arcade controls via the 74HC165s
}}
input   or              dira,   Pin_outs        ' Set output pins
        andn            dira,   Pin_Q7          ' Set input pin
        andn            outa,   Pin_CE_n        ' Drive clock enable pin low
        mov             Inptr,  par             ' Load Main RAM input_state address into Inptr
        mov             Tltptr, par             ' Load Main RAM input_state address into Inptrr
        add             Tltptr, #2              ' Increment Tltptr to point to tilt_state in Main RAM          
{{
The "poll" subroutine reprents the entire process of latching and then pulsing the 74HC165s
}}
:poll   andn            outa,   Pin_CP          ' Drive clock pin low
        andn            outa,   Pin_PL_n        ' Drive parallel load pin low
        or              outa,   Pin_PL_n        ' Drive parallel load pin high           
        mov             Count,  #15             ' Load number of 74HC165 polls into register
{{
The "dsin" subroutine performs the individual clock pulses to retrieve the bits from the 74HC165s
}}
:dsin   or              outa,   Pin_CP          ' Drive clock pin high
        andn            outa,   Pin_CP          ' Drive clock pin low
        test            Pin_Q7, ina wc          ' Poll and carry state of Pin_Q7
        rcl             Inputs, #1              ' Shift Pin_Q7 state in Inputs register             
        djnz            Count,  #:dsin          ' Repeat to retrieve all 16 bits
        or              outa,   Pin_CP          ' Drive clock pin high
        andn            outa,   Pin_CP          ' Drive clock pin low
        test            Pin_Q7, ina wc          ' Poll and carry state of Pin_Q7
        wrword          Inputs, Inptr           ' Write Inputs to Main RAM input_state register
        rcl             Inputs, #1              ' Shift tilt state in Inputs register
        and             Inputs, #1              ' Isolate tilt state
        wrbyte          Inputs, Tltptr          ' Write tilt state to Main RAM 
        jmp             #:poll                  ' Loop infinitely
Pin_CP        long      |< 0                    ' 74HC165 clock pin bitmask
Pin_CE_n      long      |< 1                    ' 74HC165 clock enable pin bitmask
Pin_PL_n      long      |< 2                    ' 74HC165 parallel load pin bitmask
Pin_outs      long      |< 0 | |< 1 | |< 2      ' Set output pin bitmask                      
Pin_Q7        long      |< 12                   ' 74HC165 serial output pin bitmask
Inptr         res       1                       ' Pointer to input_state register in Main RAM
Tltptr        res       1                       ' Pointer to tilt_state register in Main RAM
Count         res       1                       ' 74HC165 clock pulse count
Inputs        res       1                       ' Control input shift register
        fit