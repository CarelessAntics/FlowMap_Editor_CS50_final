
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

    function Brush:moveTo(mPos)
        if self.prev_pos ~= self.pos then
            self.prev_pos = self.pos
            self.prev_dir = self.dir
            self.pos = mPos
            self.dir = normalize(self.pos - self.prev_pos)
        end
        return
    end

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

    function Brush:drawOutline(mPos)
        lg.setCanvas(CANVAS_UI)

        if self.wrap then
            lg.setColor(.15, .75, .15)
            local wrap_vec = toWindowSpace(wrapped(toCanvasSpace(self.pos), WIDTH, HEIGHT, self.size))
            lg.circle("line", wrap_vec.x, wrap_vec.y, self.size, 64)
        end

        lg.setColor(.7, .15, .15)
        lg.circle("line", self.pos.x, self.pos.y, self.size, 64)

        if self.mode == "lazy" then 
            lg.setColor(.15, .15, .75)
            lg.circle("line", self.pos.x, self.pos.y, BRUSH_LAZY_RADIUS, 64)
            lg.line(self.pos.x, self.pos.y, mPos.x, mPos.y)
        end

        lg.setCanvas()
    end

    function Brush:draw()
        if vLength(self.dir) == 0 then
            return
        end

        lg.setCanvas(CANVAS_IMAGE)

        -- Draw tweens backwards since we don't know future brush direction
        movement = self.prev_pos - self.pos 

        -- Add additional circles in between mouse positions if user draws furiously
        local steps = math.floor(vLength(movement) / self.spacing)
        if steps > 0 then
            for i = steps, 0, -1 do
                local tween_pos = toCanvasSpace(self.pos + normalize(movement) * i * self.spacing)
                local tween_dir = normalize(lerp(self.dir, self.prev_dir, i / steps))
                local lerp_col = toZeroOne(tween_dir)
                lg.setColor(lerp_col.x, lerp_col.y, 0)
                lg.circle("fill", tween_pos.x, tween_pos.y, self.size, 32)

                if self.wrap then
                    tween_wrap = wrapped(tween_pos, WIDTH, HEIGHT, self.size)
                    lg.circle("fill", tween_wrap.x, tween_wrap.y, self.size, 32)
                end
            end
        end

        local col = toZeroOne(self.dir)
        lg.setColor(col.x, col.y, 0)

        -- Since drawing onto canvas, convert the position to canvas coordinates before drawing
        local pos_convert = toCanvasSpace(self.pos)
        lg.circle("fill", pos_convert.x, pos_convert.y, self.size, 32)

        if self.wrap then
            local pos_wrap = wrapped(pos_convert, WIDTH, HEIGHT, self.size)
            lg.circle("fill", pos_wrap.x, pos_wrap.y, self.size, 32)
        end

        lg.setCanvas()
    end

    return Brush
end