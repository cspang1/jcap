This document describes the full JCAP system initialization and execution procedure. The entrypoint for each P8X32A is either CPU.spin or GPU.spin. The system.spin file is shared between them to maintain initial condition consistency.

CPU:
- The key and debug pins are set as inputs
    - KEY_PIN is pulled high for the GPU and low for the CPU.
    - DEBUG_PIN is pulled high to enable serial COM printing of GPU/CPU identification strings
- The input system is initialized to poll the dual 74HC165 inputs
- The transmission system is initialized with the transmission pin location
    - The transmission pin is set high, and the vertical sync pin is polled until it is set high by the GPU
    - The transmission cog is started
- The CPU waits for the transmission cog setup process to complete
- Sprites, parallax array, etc. are all initialized before the main game loop
- The time variable is initialized with the current CPU system count to seed the game clock
- The main game loop initiates
    - waitcnt is used to lock the game loop to 60 Hz
    - The transmission cog is signalled to start by loading the transmission register with the graphics buffer size and location
    - Game logic is executed

* The sprite table is of the format (sprite[31:24]|x[23:15]|y[14:7]|color[6:4]|v[3]|h[2]|size[1:0]):
         sprite         x position       y position    color v h size
    |<------------->|<--------------->|<------------->|<--->|-|-|<->|
     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

* The parallax table is of the format (x[31:20]|y[19:8]|i[7:0]):
        horizontal shift         vertical shift       scanline index
    |<--------------------->|<--------------------->|<------------->|
     0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

* The CPU graphics buffer is in the format of:
    plx_pos[NUM_PARALLAX_REGS] - 1 long each  
    ti_col_pal[NUM_TILE_PALETTES] - 16 bytes each
    spr_col_pal[NUM_SPRITE_COLOR_PALETTES] - 16 bytes each
    sprite_atts[SAT_SIZE] - 1 long each
    tile_maps[MEM_TILE_MAP_WIDTH*MEM_TILE_MAP_HEIGHT] - 1 word per tile in map

GPU:
- The key and debug pins are set as inputs
- The graphics system pointers are initialized
- The receiver registers are loaded with the receive pin number, graphics buffer size, and buffer address
- The receive system is initialized with the transmission pin location
    - The vertical sync pin is set low, the receive pin is polled until it goes high, and then the vertical sync pin is toggled to signal the CPU 
    - The receive cog is started
- The GPU waits for the reception cog setup process to complete
- The GPU starts the display cog, pointing it to the start of the graphics buffer
- The GPU starts the render cogs, pointing it to the start of the graphics buffer

* The GPU graphics buffer is in the format of:
    data_ready - 1 long
    cur_scanline - 1 long
    scanline_buff[VID_BUFFER_SIZE] - 1 long per 4-pixel scanline segment

VGA_DISPLAY:
- The display cog initializes pointers to main RAM memory locations, and loads the current scanline, video buffer, and data ready pointers themselves
- The display cog programmatically generates "scancode" subroutine as a sequence of VID_BUFFER_SIZE rdlong and watvid instructions along with front/back porch and HSYNC for a single video scanline
- The cog video generator, counter, and output pins are configured and started for VGA output
- The current scanline is set to 0 and set to such in main RAM
- The front porch, VSYNC, and back porch are displayed
- On the 15th to last back porch line, signal the render cogs to start generating video data; this provides time for the video data from the CPU to have been transferred and for the render cogs to generate the very first scanlines
- On the last back porch line, reconfigure the video control register for pixel display
- After the back porch is complete, disable the data ready indicator
- To start active video display, the current scanline is incremented to 1, and the vscl control register is configured for active video
- The generated "scancode" is run to retrieve and display each scanline segment from the main RAM graphics buffer, followed by the horizontal porches and sync
- If the display cog has reached the bottom of the screen, the current scanline is reset to 0
- The current scanline is stored back to main RAM
- The previous scanline is displayed a second time to accomplish upscaling
- Return to displaying the next visible scanline if not at bottom of screen, otherwise return to start of display routine and start the next vertical porch/sync section

* The native JCAP data resolution is 320x240 pixels (40x30 8-by-8 pixel tiles), but it is upscaled to 640x480 via vscl horizontally and duplicating scanlines vertically
* The display cog uses a waitvid trick to get around the 4 color palette limitation. It uses the scanline graphics data as the "color palette", and a quaternary %%3210 sequence as a the "video data" to use the pixel color data in the graphics buffer as essentially a dynamic color palette.
* The display cog also modifies the vscl control register to output the sync signals as a single waitvid stretched over the required time periods, as opposed to keeping the waitvid timing constant and using multiple invocations to accomplish the same goal.

VGA_RENDER:
- NUM_REN_COGS render cogs are loaded on the GPU, each seeded with a pointer to the GPU graphics data buffer
- A semaphore is used to protect a shared variable that is used to seed each render cog with its respective  initial scanline
- Each render cog starts by calculating address pointers to the various required render variables and loading them:
    - The initial scanline semaphore
    - Initial scanline
    - Current scanline
    - Video buffer
    - Parallax table
    - Tile color palettes
    - Sprite color palettes
    - Sprite attribute table
    - Tile map
    - Tile palettes
    - Sprite palettes
    - Data ready indicator
- The highest initial parallax table address we need to check is calculated
- The initial scanline a given cog will always use is set via semaphore
- The next scanline to be rendered after the initial one is calculated
- Counter B is initialized in logic.always mode to facilitate fast tile loading
- The parallax table is iterated over in reverse order to find the first entry with a scanline index less than or equal to a given render cog's initial scanline
- The horizontal & vertical parallax positions of that entry are masked out
- 

What's happening here is that a given scanline rendered by a render cog is beholden to the parallax effect of the closest scanline index in the parallax table less than it. E.g., if we're rendering scanline #35, and the closest parallax table entry index without going over 35 is say 25, then we will use the parallax effect dictated by that entry for all lines from 25 through whatever the next parallax table entry scanline index dictates, which would include out current scanline 35.

So, we need to identify what that last relevant parallax table entry is before rendering each scanline. We accomplish this in several steps:
    At render cog startup:
        1. We calculate the highest initial parallax table memory address we'll need to inspect (can't be further in the table than either the number of table entries or the number of render cogs, whichever is lower)
            - plxoff = memory offset of highest we need to inspect
            - temptr = actual mempry address of the offset parallax table entry
            - maxptr = last parallax table entry memory address
    At the start of a full screen (frame):
        2. We iterate over the parallax table in reverse from that initial address until we find an entry whose index <= the current cog's initial scanline (this is the first parallax table entry that will affect this render cog's scanlines)
            - temptr = memory address of the last parallax table entry that affects this cog
            - nxtpte = actual value of that temptr parallax table entry
            - nxtptr = next parallax table memory address after temptr
    At the start of each scanline:
        3. We advance forward through the parallax table to find the entry which will affect the next render cog scanline
            - horpos = horizontal parallax for this scanline
            - verpos = vertical parallax for this scanline
            - nxtpte = the parallax data for the next scanline