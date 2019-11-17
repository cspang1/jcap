VAR
    long    parallax_array
    long    sprite_array

pub setup(plx_arr_loc, spr_arr_loc)
    parallax_array := plx_arr_loc
    sprite_array := spr_arr_loc

pub animate_sprite(sprindx,clock,freq,nframes,frameptr) | sprite,new_frame
    new_frame := byte[frameptr][(clock/freq)//nframes]
    set_sprite_tile (new_frame,sprindx)

pub mv_scr_reg(x,y,indx) | x_max,y_max,curr_x,curr_y,new_x,new_y
    x_max := 447
    y_max := 271
    curr_x := get_scr_reg_hor_pos (indx)
    curr_y := get_scr_reg_vert_pos (indx)
    if x
        new_x := curr_x + x
        if new_x < 0
            new_x := (x_max + 1) + new_x
        elseif new_x > x_max
            new_x := -1 + new_x - x_max
        set_scr_reg_hor_pos(new_x,indx)
    if y
        new_y := curr_y + y
        if new_y < 0
            new_y := (y_max + 1) + new_y
        elseif new_y > y_max
            new_y := -1 + new_y - y_max
        set_scr_reg_vert_pos(new_y,indx)

pub get_scr_reg_pos(indx)
    return (get_scr_reg_hor_pos(indx) << 16) | get_scr_reg_vert_pos(indx)

pub set_scr_reg_pos(x,y,indx)
    set_scr_reg_hor_pos(x,indx)
    set_scr_reg_vert_pos(y,indx)

pub get_scr_reg_hor_pos(indx)
    return (long[parallax_array][indx] & $FFF00000) >> 20

pub get_scr_reg_vert_pos(indx)
    return (long[parallax_array][indx] & $000FFF00) >> 8

pub set_scr_reg_hor_pos(x,indx) | scr_reg
    scr_reg := long[parallax_array][indx]
    long[parallax_array][indx] := (scr_reg & $FFFFF) | (x << 20)

pub set_scr_reg_vert_pos(y,indx) | scr_reg
    scr_reg := long[parallax_array][indx]
    long[parallax_array][indx] := (scr_reg & $FFF000FF) | (y << 8)

pub init_sprite(tile,x,y,color,vmir,hmir,wide,tall,indx)
    set_sprite_tile (tile,indx)
    set_sprite_pos (x,y,indx)
    set_sprite_color(color,indx)
    set_sprite_hor_mir (hmir,indx)
    set_sprite_vert_mir (vmir,indx)
    set_sprite_wide (wide,indx)
    set_sprite_tall (tall,indx)

pub mv_sprite(x,y,indx) | x_max,y_max,curr_x,curr_y,new_x,new_y,size_x,size_y
    x_max := 344
    y_max := 255
    curr_x := get_sprite_hor_pos (indx)
    curr_y := get_sprite_vert_pos (indx)
    size_x := get_sprite_wide (indx) ^ 1
    size_y := get_sprite_tall (indx) ^ 1

    if x
        new_x := curr_x + x
        if new_x < size_x * 8
            new_x := x_max + new_x - size_x * 8 + 1
        elseif new_x > x_max
            new_x := -x_max + new_x + size_x * 8 - 1
        set_sprite_hor_pos (new_x,indx)
    if y
        new_y := curr_y + y
        if new_y < size_y * 8
            new_y := y_max + new_y - size_y * 8 + 1
        elseif new_y > y_max
            new_y := -y_max + new_y + size_y * 8 - 1
        set_sprite_vert_pos (new_y,indx)

pub get_sprite_tile(indx)
    return (long[sprite_array][indx] & $FF000000) >> 24

pub set_sprite_tile(tile_indx,spr_indx) | sprite
    sprite := long[sprite_array][spr_indx]
    long[sprite_array][spr_indx] := (sprite & $FFFFFF) | (tile_indx << 24)

pub get_sprite_color(indx)
    return (long[sprite_array][indx] & $00000070) >> 4

pub set_sprite_color(color_indx,spr_indx) | sprite
    sprite := long[sprite_array][spr_indx]
    long[sprite_array][spr_indx] := (sprite & $FFFFFF8F) | (color_indx << 4)

pub get_sprite_pos(indx)
    return (get_sprite_hor_pos(indx) << 16) | get_sprite_vert_pos(indx)

pub set_sprite_pos(x,y,indx)
    set_sprite_hor_pos(x,indx)
    set_sprite_vert_pos(y,indx)

pub get_sprite_hor_pos(indx)
    return (long[sprite_array][indx] & $FF8000) >> 15

pub get_sprite_vert_pos(indx)
    return (long[sprite_array][indx] & $7F80) >> 7

pub set_sprite_hor_pos(x,indx) | sprite
    sprite := long[sprite_array][indx]
    long[sprite_array][indx] := (sprite & $FF007FFF) | (x << 15)

pub set_sprite_vert_pos(y,indx) | sprite
    sprite := long[sprite_array][indx]
    long[sprite_array][indx] := (sprite & $FFFF807F) | (y << 7) 

pub get_sprite_hor_mir(indx)
    if long[sprite_array][indx] & 4
        return 1
    return 0

pub get_sprite_vert_mir(indx)
    if long[sprite_array][indx] & 8
        return 1
    return 0

pub set_sprite_hor_mir(mir,indx)
    if mir
        long[sprite_array][indx] |= 4
    else
        long[sprite_array][indx] &= !4

pub set_sprite_vert_mir(mir,indx)
    if mir
        long[sprite_array][indx] |= 8
    else
        long[sprite_array][indx] &= !8

pub get_sprite_wide(indx)
    if long[sprite_array][indx] & 2
        return 1
    return 0

pub get_sprite_tall(indx)
    if long[sprite_array][indx] & 1
        return 1
    return 0

pub set_sprite_wide(wide,indx)
    if wide
        long[sprite_array][indx] |= 2
    else
        long[sprite_array][indx] &= !2

pub set_sprite_tall(tall,indx)
    if tall
        long[sprite_array][indx] |= 1
    else
        long[sprite_array][indx] &= !1