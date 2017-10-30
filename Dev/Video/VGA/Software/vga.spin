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
  long  vga_dat                 ' VGA data placeholder
  word  input_state             ' Register in Main RAM containing state of inputs
  long  tile_map_base           ' Register pointing to base of tile maps
  long  tile_palette_base       ' Register pointing to base of tile palettes
  long  color_palette_base      ' Register pointing to base of color palettes

PUB main
  tile_map_base := @tile_map                            ' Point tile_map_base to base of tile maps
  tile_palette_base := @tile_palette                    ' Point tile_map_base to base of tile maps
  color_palette_base := @palette_map                    ' Point tile_map_base to base of tile maps
  cognew(@vga, @tile_map_base)                          ' Initialize cog running "vga" routine with reference to start of variable registers
  cognew(@input, @input_state)                          ' Initialize cog running "input" routine with reference to start of variable registers
  
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
        mov             vcfg,   VidCfg      

        ' Initialize variables
        mov             tmbase, par             ' Load Main RAM tile_map_base address
        mov             tpbase, par             ' Load Main RAM tile_map_base address
        mov             cpbase, par             ' Load Main RAM tile_map_base address
        add             tpbase, #4              ' Point tile palette pointer to correct register
        add             cpbase, #8              ' Point color palette pointer to correct register

        ' Display visible area              
:frame  mov             colors, ColorK          ' Set default color to black
        mov             fptr,   numTF           ' Initialize frame pointer
        mov             tmptr,  tmbase          ' Initialize tile map pointer
:active mov             lptr,   numLT           ' Initialize line pointer
:tile
        
        rdword          cmap,   tmptr           ' Read start of tile map from Main RAM
        mov             ti,     cmap            ' Store current map into tile index
        and             ti,     #255            ' Isolate tile index of current map tile
        shr             cmap,   #8              ' Isolate color index of current map tile
        mov             ci,     cmap            ' Store color index of current map tile        
        shl             ti,     #5              ' Multiply tile index by 64 (each tile palette is 4*16=64 bytes: tile palette address = tile palette base * (tile palette index * 64))
        add             ti,     tpbase          ' Add ti*64 to the tile palette base address to reference specific tile
        rdlong          tile,   ti              ' Read tile from Main RAM
        shl             ci,     #2              ' Multiply color index by 4 (each color palette is 4 bytes: color palette address = color palette base * (color palette index * 4))
        add             ci,     cpbase          ' Add ci*4 to the color palette base address to reference specific color palette
        'rdlong          colors, ci              ' Read tile from Main RAM
                 
        
        mov             tptr,   numTL           ' Initialize tile pointer
        mov             vscl,   VidScl          ' Set video scale for active video
:line   waitvid         colors, tPixel          ' Update 16-pixel scanline                 
        djnz            tptr,   #:line          ' Display ten 16-pixel segments (one scanline, 40*16=640 pixels downsampled to 10)

        ' Display horizontal sync area
        mov             vscl,   HVidScl         ' Set video scale for HSync
        waitvid         sColor, hPixel          ' Horizontal sync
        djnz            lptr,   #:tile          ' Display sixteen scanlines (one row of tiles, 40*16*16=10240 pixels)
        djnz            fptr,   #:active        ' Display twelve tiles (entire frame, 480/16=30 tiles downsampled to 12)

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
vgapin        long      |< 16 | |< 17 | |< 18 | |< 19 | |< 20 | |< 21 | |< 22 | |< 23                   ' VGA output pins
pllfreq       long      337893130                                                                       ' Counter A frequency
CtrCfg        long      %0_00001_101_00000000_000000_000_000000                                         ' Counter A configuration                        
VidCfg        long      %0_01_1_0_0_000_00000000000_010_0_11111111                                      ' Video generator configuration
VidScl        long      %000000000000_00000100_000001000000                                             ' Video generator scale register                         
HVidScl       long      %000000000000_00010000_000010100000                                             ' Video generator horizontal sync scale register
BVidScl       long      %000000000000_00000000_001010000000                                             ' Video generator blank line scale register

' Video Generator inputs
ColorR        long      %11000011_11000011_11000011_11000011                    ' Test colors
ColorG        long      %00110011_00110011_00110011_00110011                    ' Test colors
ColorB        long      %00001111_00001111_00001111_00001111                    ' Test colors
ColorW        long      %11111111_11111111_11111111_11111111                    ' Test colors
ColorK        long      %00000011_00000011_00000011_00000011                    ' Test colors
sColor        long      %00000011_00000001_00000010_00000000                    ' Sync colors (porch_HSync_VSync_HVSync)
tPixel        long      %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0                       ' Test pixels
hPixel        long      %%0_0_0_0_0_0_3_3_3_2_2_2_2_2_2_3                       ' HSync pixels
vPixel        long      %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1                       ' VSync pixels
vpPixel       long      %%3_3_3_3_3_3_3_3_3_3_3_3_3_3_3_3                       ' Vertical porch blank pixels
hvPixel       long      %%0_0_0_0_0_0_1_1_1_0_0_0_0_0_0_1                       ' HVSync pixels

' Frame attributes
numTL         long      10      ' Number of tiles per scanline (640 pixels/16 pixels per tile = 40 tiles downsampled to 10 via vscl)
numLT         long      40      ' Number of scanlines per tile (16 pixels tall, upsampled to 40 for 12 vertical tiles)
numTF         long      12      ' Number of vertical tiles per frame (480 pixels/16 pixels per tile = 30 tiles downsampled to 12 via vscl)                    
numFP         long      10      ' Number of vertical front porch lines                        
numVS         long      2       ' Number of vertical sync lines                        
numBP         long      33      ' Number of vertical back porch lines

' Frame pointers
tptr          res       1       ' Current tile being rendered
lptr          res       1       ' Current line being rendered
fptr          res       1       ' Current frame position being rendered
vptr          res       1       ' Current vertical sync line being rendered

' Tile and color map pointers
tmptr         res       1       ' Pointer to current tile map in Main RAM
tpptr         res       1       ' Pointer to current tile palette in Main RAM
cpptr         res       1       ' Pointer to current color palette in Main RAM
tmbase        res       1       ' Pointer to tile maps base in Main RAM
tpbase        res       1       ' Pointer to tile palettes base in Main RAM
cpbase        res       1       ' Pointer to color palettes base in Main RAM
cmap          res       1       ' Current map 
tcmap         res       1       ' Current map temp variable 
ti            res       1       ' Tile index
ci            res       1       ' Color index
tile          res       1       ' Current tile section       
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
DAT
        org             0
tile_map
              ' just the maze
tile_map0     word $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01 ' row 0
              word $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 1
              word $00_01,$00_00,$01_01,$01_01,$01_01,$00_00,$01_01,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 2
              word $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 3
              word $00_01,$00_00,$01_01,$00_00,$00_00,$00_00,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 4
              word $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$01_01,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 5
              word $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 6
              word $00_01,$00_00,$01_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 7
              word $00_01,$00_00,$01_01,$00_00,$00_00,$01_01,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 8
              word $00_01,$00_00,$01_01,$01_01,$00_00,$01_01,$00_00,$01_01,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 9
              word $00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 10
              word $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01 ' row 11

              ' maze plus dots
tile_map1     word $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01 ' row 0
              word $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 1
              word $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 2
              word $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 3
              word $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 4
              word $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 5
              word $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 6
              word $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 7
              word $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 8
              word $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 9
              word $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 10
              word $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01 ' row 11

              ' maze plus powerpills
tile_map2     word $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01 ' row 0
              word $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 1
              word $00_01,$00_02,$01_01,$01_01,$01_01,$00_02,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 2
              word $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 3
              word $00_01,$00_02,$01_01,$00_02,$00_02,$00_02,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 4
              word $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$01_01,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 5
              word $00_01,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 6
              word $00_01,$00_02,$01_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 7
              word $00_01,$00_02,$01_01,$00_02,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 8
              word $00_01,$00_02,$01_01,$01_01,$00_02,$01_01,$00_02,$01_01,$00_02,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 9
              word $00_01,$00_03,$00_02,$00_02,$00_02,$00_02,$00_02,$00_02,$00_03,$00_01,$00_00,$00_00,$00_00,$00_00,$00_00,$00_00 ' row 10
              word $00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01,$00_01 ' row 11

tile_palette
              ' empty tile
tile_blank    long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0 ' tile 0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' box tile
tile_box      long %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1 ' tile 1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1
              long %%1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1

              ' dot tile
tile_dot      long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0 ' tile 2
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long %%0_0_0_0_0_1_1_1_1_1_1_0_0_0_0_0
              long %%0_0_0_0_0_0_1_1_1_1_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_1_1_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' power-up tile
tile_pup      long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0 ' tile 3
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long %%0_0_2_1_1_1_1_1_1_1_1_1_1_2_0_0
              long %%0_0_0_2_1_1_1_1_1_1_1_1_2_0_0_0
              long %%0_0_0_2_1_1_1_1_1_1_1_2_0_0_0_0
              long %%0_0_0_0_2_1_1_1_1_1_1_2_0_0_0_0
              long %%0_0_0_0_0_2_1_1_1_1_2_0_0_0_0_0
              long %%0_0_0_0_0_0_2_1_1_2_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_2_2_0_0_0_0_0_0_0
              long %%0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0

              ' Test palettes
palette_map   long %11000011_00110011_00001111_00000011 ' palette 0 - background and wall tiles, 0-black,
                                ' 1-blue, 2-red, 3-white
              long %01010111_10101011_11001111_11111111 ' palette 1 - background and wall tiles, 0-black,
                                ' 1-green, 2-red, 3-white                                          

        fit         