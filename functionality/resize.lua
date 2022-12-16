function resizeImageBilinear(btn_newsize_x, btn_newsize_y)
    -- old_img: imagedata
    -- new_size: vector

    local new_size = vec(0)
    new_size.x = btn_newsize_x:getValueNumber()
    new_size.y = btn_newsize_y:getValueNumber()

    local old_img = IMGDATA_MAIN

    local new_img = li.newImageData(new_size.x, new_size.y, "rgba16")

    local old_w, old_h = old_img:getDimensions()
    local new_w, new_h = new_img:getDimensions()

    local step_x = new_w / old_w--old_w / new_w
    local step_y = new_h / old_h--old_h / new_h

    -- step_x = step_x >= 1 and step_x or 1/step_x
    -- step_y = step_y >= 1 and step_y or 1/step_y

    function resizeBilinear(x, y, r, g, b, a)
        local old_x = math.floor(x * step_x)
        local old_y = math.floor(y * step_y)

        local t_x = math.fmod(x * step_x, 1)
        local t_y = math.fmod(y * step_y, 1)

        local P0 = vec(old_x, old_y)
        local P1 = new_w > old_x + 1 and vec(old_x + 1, old_y) or vec(old_x, old_y)
        local P2 = new_h > old_y + 1 and vec(old_x, old_y + 1) or vec(old_x, old_y)
        --local P3 = vec(old_x, old_y)

        local R0, G0, B0, _ = old_img:getPixel(P0.x, P0.y)
        local R1, G1, B1, _ = old_img:getPixel(P1.x, P1.y)
        local R2, G2, B2, _ = old_img:getPixel(P2.x, P2.y)
        --local R3, G3, B3, _ = old_img:getPixel(P3.x, P3.y)


        local new_r = lerp(R0, R1, t_x)
        local new_g = lerp(G0, G1, t_x)
        local new_b = lerp(B0, B1, t_x)

        return new_r, new_g, new_b, a

    end
    
    new_img:mapPixel(resizeBilinear, 0, 0, new_w, new_h)

    IMGDATA_MAIN = new_img
    initImage()
end