
Brush = {
    pos = vec(0),
    prev_pos = vec(0),
    dir = vec(0, 1),
    prev_dir = vec(0, 1),
    active = false,
    erasing = false,
    drawTime = 0,
    alpha = li.newImageData("assets/alphas/1.png"),
    size = inSize,
    hardness = 0,
    spacing = 5, -- Units = pixels,
    wrap = true, -- Brush wraparound
    rotate = true,
    mode = "lazy" -- Options: normal, lazy
}


--- Create a new instance of Brush
---@param o table
---@param inPos table
---@param inSize number
function Brush:new(o, inPos, inSize)
    local o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Instance parameters
    o.pos = inPos
    o.size = inSize

    return o
end


--function Brush:updateProperties()



-- Regular movement. Looks kind of shitty so probably won't use it ever
function Brush:moveTo(mPos)
    if self.prev_pos ~= self.pos then
        self.prev_pos = self.pos
        self.prev_dir = self.dir
        self.pos = mPos
        self.dir = normalize(self.pos - self.prev_pos)
    end
    return
end


--- Move brush. "Lazy mouse"
---@param mPos table
function Brush:moveToLazy(mPos)
    mouse_vec = mPos - self.pos
    mouse_dist = vLength(mouse_vec)

    self.prev_pos = vCopy(self.pos)
    self.prev_dir = vCopy(self.dir)

    if mouse_dist > BRUSH_LAZY_RADIUS + self.spacing then

        -- Limit movement while drawing to steps defined in object to prevent gaps in stroke
        if self.active then
            self.pos = self.pos + normalize(mouse_vec) * math.min(mouse_dist - BRUSH_LAZY_RADIUS, self.spacing)
        else
            self.pos = self.pos + normalize(mouse_vec) * math.min(mouse_dist - BRUSH_LAZY_RADIUS)
        end
        self.dir = normalize(mouse_vec)
    end
end


--- Draw brush outline to UI
---@param mPos table
function Brush:drawOutline(mPos)
    lg.setCanvas(CANVAS_UI)
    lg.setLineWidth(1.5)
    lg.setLineStyle('smooth')

    -- Add a circle if wraparound is used
    if self.wrap then
        lg.setColor(.15, .75, .15)
        local brush_wrap0 = toWindowSpace(wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, self.size))
        local brush_wrap1 = toWindowSpace(wrapped(toCanvasSpace(brush_wrap0), SIZE_OUT.x, SIZE_OUT.y, self.size))
        lg.circle("line", brush_wrap0.x, brush_wrap0.y, self.size, 64)
        lg.circle("line", brush_wrap1.x, brush_wrap1.y, self.size, 64)
    end

    -- Actual brush circle
    lg.setColor(.7, .15, .15)
    lg.circle("line", self.pos.x, self.pos.y, self.size, 64)

    -- Lazy mouse radius and line to mouse
    lg.setColor(.15, .15, .75)
    if self.mode == "lazy" then 
        lg.circle("line", self.pos.x, self.pos.y, BRUSH_LAZY_RADIUS, 64)
        lg.line(self.pos.x, self.pos.y, mPos.x, mPos.y)
    end

    lg.setCanvas()
end


--- Main function for drawing
function Brush:draw()
    if vLength(self.dir) == 0 then
        return
    end

    local draw_size = self.size * (1 / CANVAS_SCALE)

    -- Set color from direction vector
    local col = toZeroOne(self.dir)

    -- Since drawing onto canvas, convert the position to canvas coordinates before drawing
    local pos_convert = toCanvasSpace(self.pos)
    self:drawToImgData(pos_convert, draw_size, col)

    if self.wrap then
        local pos_wrap0 = wrapped(pos_convert, SIZE_OUT.x, SIZE_OUT.y, draw_size)
        self:drawToImgData(pos_wrap0, draw_size, col)

        -- Wraparound for the wraparound to handle cases where brush is wrapping OOB
        local pos_wrap1 = wrapped(pos_wrap0, SIZE_OUT.x, SIZE_OUT.y, draw_size)
        self:drawToImgData(pos_wrap1, draw_size, col)
    end
end


--- Modify pixels in imageData
---@param inVector table
---@param draw_size number 
---@param col table
function Brush:drawToImgData(inVector, draw_size, col)

    -- Map pixel colors using image alpha
    local function pixelFunctionAlphaDraw(x, y, r, g, b, a)

        -- Convert from global xy to local alpha xy
        local alpha_x = ((x - PIXEL_INPUT_CORNER.x) / PIXEL_INPUT_DIMS.x) * PIXEL_INPUT_ALPHADIMS.x
        local alpha_y = ((y - PIXEL_INPUT_CORNER.y) / PIXEL_INPUT_DIMS.y) * PIXEL_INPUT_ALPHADIMS.y

        -- If alpha pixel OOB, return 0, otherwise return pixel value from image
        local brush_alpha = 0
        if (alpha_x > 0 and alpha_y > 0) and (alpha_x <= PIXEL_INPUT_ALPHADIMS.x and alpha_y <= PIXEL_INPUT_ALPHADIMS.x) then
            brush_alpha = self.alpha:getPixel(alpha_x, alpha_y)
        end

        -- Smoothstep according to brush hardness value
        brush_alpha = smoothStep(0, 1 - self.hardness, brush_alpha)

        local new_r = PIXEL_INPUT_COL.r
        local new_g = PIXEL_INPUT_COL.g
        local new_b = PIXEL_INPUT_COL.b

        r = lerp(r, new_r, brush_alpha)
        g = lerp(g, new_g, brush_alpha)
        b = lerp(b, new_b, brush_alpha)

        return r, g, b, a
    end

    -- Brush radius to diameter
    local brush_w = draw_size * 2
    local brush_h = draw_size * 2

    -- Brush_dim is basically lower right corner distance from draw area 0-edges
    -- Brush_loc is top left corner of brush area
    local brush_dim = SIZE_OUT - inVector + vec(draw_size)
    local brush_loc = inVector - vec(draw_size)

    -- Brush width/height either a square of size (draw_size * 2) or distance from 0-edge, whichever is lower
    brush_w = math.min(brush_w, brush_dim.x)
    brush_h = math.min(brush_h, brush_dim.y)

    -- Cap location minimum to .1 to avoid random errors
    brush_loc.x = math.max(brush_loc.x, .1)
    brush_loc.y = math.max(brush_loc.y, .1)

    -- Width/height of the brush alpha image
    local alpha_w, alpha_h = self.alpha:getDimensions()

    -- Cheese in brush and color vectors as globals
    -- Brush using image alpha
    PIXEL_INPUT_CORNER = inVector - vec(draw_size) -- Pass absolute brush corner location in relation to draw area
    PIXEL_INPUT_DIMS = vec(draw_size * 2) -- Pass in absolute brush size in pixels
    PIXEL_INPUT_ALPHADIMS = vec(alpha_w, alpha_h) -- Pass in size of alpha image

    -- Brush using computational alpha
    PIXEL_INPUT_VEC0 = inVector
    PIXEL_INPUT_SIZE = draw_size

    -- Draw color
    if self.erasing then
        PIXEL_INPUT_COL = {r = .5, g = .5, b = 0}
    else
        PIXEL_INPUT_COL = {r = col.x, g = col.y, b = 0}
    end

    if (brush_w > 0 and brush_h > 0) and (inVector.x > -draw_size and inVector.y > -draw_size) then
        IMGDATA_MAIN:mapPixel(pixelFunctionAlphaDraw, brush_loc.x, brush_loc.y, brush_w, brush_h)
    end
end