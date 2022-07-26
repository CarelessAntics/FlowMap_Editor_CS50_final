-- TODO: Convert brushes from drawing circles to canvas to drawing into imagedata
-- See: Imagedata:mapPixel()
function initBrush(inX, inY, inSize)
    Brush = {   size = inSize,
                pos = vec(inX, inY),
                prev_pos = vec(inX, inY),
                dir = vec(0, 1),
                prev_dir = dir,
                drawing = false,
                spacing = 5, -- Units = pixels,
                wrap = true, -- Brush wraparound
                mode = "lazy" -- Options: normal, lazy
            }

    -- Regular movement. Looks kind of shitty so probably won't use it
    function Brush:moveTo(mPos)
        if self.prev_pos ~= self.pos then
            self.prev_pos = self.pos
            self.prev_dir = self.dir
            self.pos = mPos
            self.dir = normalize(self.pos - self.prev_pos)
        end
        return
    end

    -- Lazy mouse movement
    function Brush:moveToLazy(mPos)
        mouse_vec = mPos - self.pos
        mouse_dist = vLength(mouse_vec)
        if mouse_dist > BRUSH_LAZY_RADIUS then
            self.prev_pos = vCopy(self.pos)
            self.prev_dir = vCopy(self.dir)
            self.pos = self.pos + normalize(mouse_vec) * (mouse_dist - BRUSH_LAZY_RADIUS)
            self.dir = normalize(mouse_vec)
        end
    end

    -- Draw brush outline
    function Brush:drawOutline(mPos)
        lg.setCanvas(CANVAS_UI)

        -- Add a circle if wraparound is used
        if self.wrap then
            lg.setColor(.15, .75, .15)
            local brush_wrap0 = toWindowSpace(wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, self.size))
            local brush_wrap1 = toWindowSpace(wrapped(toCanvasSpace(brush_wrap0), SIZE_OUT.x, SIZE_OUT.y, self.size))
            lg.circle("line", brush_wrap0.x, brush_wrap0.y, self.size, 64)
            lg.circle("line", brush_wrap1.x, brush_wrap1.y, self.size, 64)
        end

        lg.setColor(.7, .15, .15)
        lg.circle("line", self.pos.x, self.pos.y, self.size, 64)

        -- Lazy mouse radius and line to mouse
        if self.mode == "lazy" then 
            lg.setColor(.15, .15, .75)
            lg.circle("line", self.pos.x, self.pos.y, BRUSH_LAZY_RADIUS, 64)
            lg.line(self.pos.x, self.pos.y, mPos.x, mPos.y)
        end

        lg.setCanvas()
    end

    -- Use Brush to Draw
    function Brush:draw()
        if vLength(self.dir) == 0 then
            return
        end

        lg.setCanvas(CANVAS_IMAGE)

        -- Draw tweens backwards since we don't know future brush direction
        movement = self.prev_pos - self.pos 

        -- Add additional circles in between mouse positions if user draws furiously
        local steps = math.floor(vLength(movement) / self.spacing)
        local draw_size = self.size * (1 / CANVAS_SCALE)

        if steps > 0 then
            -- Iterate "backwards" from previous position to current position so the gradient is drawn correctly
            for i = steps, 0, -1 do
                local tween_pos = toCanvasSpace(self.pos + normalize(movement) * i * self.spacing)
                local tween_dir = normalize(lerp(self.dir, self.prev_dir, i / steps))
                local lerp_col = toZeroOne(tween_dir)

                lg.setColor(lerp_col.x, lerp_col.y, 0)
                lg.circle("fill", tween_pos.x, tween_pos.y, draw_size, 32)

                -- Wraparound support
                if self.wrap then
                    -- Wraparound for the wraparound to handle cases where brush is wrapping OOB
                    tween_wrap0 = wrapped(tween_pos, SIZE_OUT.x, SIZE_OUT.y, draw_size)
                    tween_wrap1 = wrapped(tween_wrap0, SIZE_OUT.x, SIZE_OUT.y, draw_size)
                    lg.circle("fill", tween_wrap0.x, tween_wrap0.y, draw_size, 32)
                    lg.circle("fill", tween_wrap1.x, tween_wrap1.y, draw_size, 32)

                end
            end
        end

        -- Start drawing actual brush stroke
        local col = toZeroOne(self.dir)
        lg.setColor(col.x, col.y, 0)

        -- Since drawing onto canvas, convert the position to canvas coordinates before drawing
        local pos_convert = toCanvasSpace(self.pos)
        lg.circle("fill", pos_convert.x, pos_convert.y, draw_size, 32)

        if self.wrap then
            -- Wraparound for the wraparound to handle cases where brush is wrapping OOB
            local pos_wrap0 = wrapped(pos_convert, SIZE_OUT.x, SIZE_OUT.y, draw_size)
            local pos_wrap1 = wrapped(pos_wrap0, SIZE_OUT.x, SIZE_OUT.y, draw_size)
            lg.circle("fill", pos_wrap0.x, pos_wrap0.y, draw_size, 32)
            lg.circle("fill", pos_wrap1.x, pos_wrap1.y, draw_size, 32)
        end

        lg.setCanvas()
    end

    return Brush
end