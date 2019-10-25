CON
    ' Game settings
    NUM_TILE_COLOR_PALETTES = 2                     ' Number of tile color palettes
    NUM_SPRITE_COLOR_PALETTES = 2                   ' Number of sprite color palettes
    SAT_SIZE = 64                                   ' Number of sprites in sprite attribute table
    VIS_TILE_MAP_WIDTH = 40                         ' Number of visible horizontal tiles in tile map
    VIS_TILE_MAP_HEIGHT = 30                        ' Number of visible vertical tiles in tile map
    MEM_TILE_MAP_WIDTH = 56                         ' Number of visible horizontal tiles in tile map
    MEM_TILE_MAP_HEIGHT = 34                        ' Number of visible vertical tiles in tile map
    NUM_TILE_PALETTES = 5                           ' Number of tile palettes
    NUM_SPRITE_PALETTES = 6                         ' Number of sprite palettes
    SPR_SZ_S = 8                                    ' Number of pixels wide/tall for small sprites
    SPR_SZ_L = 16                                   ' Number of pixels wide/tall for large sprites
    VID_BUFFER_SIZE = 80                            ' Number of scanline segments in video buffer
    MAX_VIS_HOR_POS = VIS_TILE_MAP_WIDTH * 8 + 16   ' Max visible horizontal position, accounting for 16 px wrap buffer left side of screen
    MAX_MEM_HOR_POS = MEM_TILE_MAP_WIDTH * 8        ' Max screen horizontal position in memory
    MAX_VIS_VER_POS = VIS_TILE_MAP_HEIGHT * 8       ' Max visible vertical position
    MAX_MEM_VER_POS = MEM_TILE_MAP_HEIGHT * 8       ' Max screen horizontal position in memory
    MAX_SPR_HOR_POS = 512                           ' Max horizontal sprite position in memory
    MAX_SPR_VER_POS = 256                           ' Max vertical sprite position in memory
    NUM_REN_COGS = 6                                ' Number of render cogs instantiated for rendering
    GFX_BUFFER_SIZE = 1+((MEM_TILE_MAP_WIDTH*MEM_TILE_MAP_HEIGHT)*2+(NUM_TILE_COLOR_PALETTES+NUM_SPRITE_COLOR_PALETTES)*16+SAT_SIZE*4)/4    ' Number of LONGs in graphics resources buffer

PUB null