VAR
    long    parallax_array
    long    sprite_array

pub setup(plx_arr_loc, spr_arr_loc)
    parallax_array := plx_arr_loc
    sprite_array := spr_arr_loc

pub mv_scr_reg(x,y,indx) | scr_reg,x_max,y_max,curr_x,curr_y,new_x,new_y
    x_max := 447
    y_max := 271
    scr_reg := long[parallax_array][indx]
    curr_x := scr_reg >> 20
    curr_y := (scr_reg >> 8) & $FFF
    if x
        new_x := curr_x + x
        if new_x < 0
            new_x := (x_max + 1) + new_x
        elseif new_x > x_max
            new_x := -1 + new_x - x_max
        scr_reg := (scr_reg & $FFFFF) | (new_x << 20)
    if y
        new_y := curr_y + y
        if new_y < 0
            new_y := (y_max + 1) + new_y
        elseif new_y > y_max
            new_y := -1 + new_y - y_max
        scr_reg := (scr_reg & $FFF000FF) | (new_y << 8)
    long[parallax_array][indx] := scr_reg

pub mv_sprite(x,y,indx) | sprite,x_max,y_max,curr_x,curr_y,new_x,new_y,size_x,size_y
    x_max := 337
    y_max := 255
    sprite := long[sprite_array][indx]
    curr_x := (sprite >> 15) & $1FF
    curr_y := (sprite >> 7) & $FF
    size_x := (sprite & 2) >> 1
    size_y := sprite & 1
    if x
        new_x := curr_x + x
        if new_x < (8 - size_x * 8)
            new_x := (x_max + 1) + new_x
        elseif new_x > x_max
            new_x := 7 + new_x - x_max - size_x * 8
        sprite := (sprite & $FF007FFF) | (new_x << 15)
    if y
        new_y := curr_y + y
        if new_y < (8 - size_y * 8)
            new_y := (y_max + 1) + new_y
        elseif new_y > y_max
            new_y := 7 + new_y - y_max - size_y * 8
        sprite := (sprite & $FFFF807F) | (new_y << 7)
    long[sprite_array][indx] := sprite

pub set_sprite_tile(tile_indx,spr_indx) | sprite
    sprite := long[sprite_array][spr_indx]
    long[sprite_array][spr_indx] := (sprite & $FFFFFF) | (tile_indx << 24)

pub set_sprite_color(color_index,indx) | sprite
    sprite := long[sprite_array][indx]
    long[sprite_array][indx] := (sprite & $FFFFFF8F) | (color_index << 4)

pub set_sprite_pos(x,y,indx)
    set_sprite_hor_pos(x,indx)
    set_sprite_vert_pos(y,indx)
    
pub set_sprite_hor_pos(x,indx) | sprite
    sprite := long[sprite_array][indx]
    long[sprite_array][indx] := (sprite & $FF007FFF) | (x << 15)

pub set_sprite_vert_pos(y,indx) | sprite
    sprite := long[sprite_array][indx]
    long[sprite_array][indx] := (sprite & $FFFF807F) | (y << 7) 

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
