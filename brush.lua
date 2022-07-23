
function initBrush(inX, inY, inSize)
    Brush = {   size = inSize,
                pos = vec(inX, inY),
                prev = vec(inX, inY),
                dir = vec(0, 1),
                drawing = false,
                spacing = 4, -- Units = pixels,
                wrap = true,
                mode = "lazy" -- Options: normal, lazy
            }

    function Brush:moveTo(mPos)
        if self.prev ~= self.pos then
            self.prev = self.pos
            self.pos = mPos
            self.dir = normalize(self.pos - self.prev)
        end
        return
    end

    function Brush:moveToLazy(mPos)
        mouse_vec = mPos - self.pos
        mouse_dist = vLength(mouse_vec)
        if mouse_dist > BRUSH_LAZY_RADIUS then
            self.prev = self.pos
            self.pos = self.pos + normalize(mouse_vec) * (mouse_dist - BRUSH_LAZY_RADIUS)
            self.dir = normalize(mouse_vec)
        end
    end

    function Brush:drawOutline(mPos)
        lg.setCanvas(CANVAS_UI)

        lg.setColor(.7, .15, .15)
        lg.circle("line", self.pos.x, self.pos.y, self.size, 64)

        lg.setColor(.15, .15, .75)
        lg.circle("line", self.pos.x, self.pos.y, BRUSH_LAZY_RADIUS, 64)

        if self.mode == "lazy" then 
            lg.line(self.pos.x, self.pos.y, mPos.x, mPos.y)
        end

        lg.setCanvas()
    end

    function Brush:draw()
        lg.setCanvas(CANVAS_IMAGE)
        lg.setColor(self.dir.x*.5+.5, self.dir.y*.5+.5, 0)

        -- Draw tweens backwards since we don't know future brush direction
        movement = self.prev - self.pos 

        -- Add additional circles in between mouse positions if user draws furiously
        if vLength(movement) / self.spacing > 0 then
            for i = 0, math.floor(vLength(movement) / self.spacing) do
                tween_pos = toCanvasSpace(self.pos + normalize(movement) * i * self.spacing)
                lg.circle("fill", tween_pos.x, tween_pos.y, self.size, 64)

                if self.wrap then
                    tween_wrap = self.wrapped(tween_pos)
                    lg.circle("fill", tween_wrap.x, tween_wrap.y, self.size, 64)
                end
            end
        end

        pos_convert = toCanvasSpace(self.pos)
        lg.circle("fill", pos_convert.x, pos_convert.y, self.size, 64)

        if self.wrap then
            pos_wrap = self.wrapped(pos_convert)
            lg.circle("fill", pos_wrap.x, pos_wrap.y, self.size, 64)
        end

        lg.setCanvas()
    end

    -- Returns a wrapped around vector
    function Brush:wrapped(inVec)
        -- Wrapping around canvas so convert to canvas space
        --inVec = toCanvasSpace(self.pos)
        --inVec = self.pos
        local outX = -1000
        local outY = -1000

        if inVec.x > WIDTH - self.size then
            outX = inVec.x - WIDTH
        elseif inVec.x < self.size then
            outX = inVec.x + WIDTH
        end

        if inVec.y > HEIGHT - self.size then
            outY = inVec.y - HEIGHT
        elseif inVec.y < self.size then
            outY = inVec.y + HEIGHT
        end

        return vec(outX, outY)
    end

    return Brush
end