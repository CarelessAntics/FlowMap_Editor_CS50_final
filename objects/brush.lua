
Brush = {
    pos = vec(0), -- Current brush position
    prev_pos = vec(0), -- Brush position on previous tick
    dir = vec(0, 1), -- Brush moving direction
    prev_dir = vec(0, 1), -- Direction on previous tick
    active = false, -- Is brush currently drawing
    erasing = false, -- Is brush erasing
    drawTime = 0,
    alpha_original = li.newImageData("assets/alphas/1.png"), --Unmodified brush alpha
    alpha = nil, -- Brush alpha with transformations
    alpha_angle = 0, -- Current angle of brush alpha
    size = nil, -- Brush alpha
    lazy_size = nil, -- Lazy mouse radius
    hardness = 0, -- Alpha hardness, or ratio of solid black/white to grayscale
    spacing = 5, -- Units = pixels
    wrap = true, -- Brush wraparound
    alpha_transp = 1,
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
    o.size = 50
    o.lazy_size = 100
    o.alpha_transp = 1
    o.alpha = li.newImageData("assets/alphas/1.png")

    return o
end

-- Get values from properties
function Brush:updateBrushFromProperties(UI_ref)
    local properties_id = 'brush_drawing_properties'
    --print(UI_ref.properties)
    local properties = UI_ref.properties[properties_id].contents

    local range_size = {min = 5, max = 500}
    local range_hardness = {min = 0., max = .999}
    local range_lazy = {min = 5, max = 600}
    
    self.size = clamp(range_size.min, range_size.max, properties['p_brush_rad']:getValueNumber())
    self.hardness = clamp(range_hardness.min, range_hardness.max, properties['p_brush_hard']:getValueNumber())
    self.lazy_size = clamp(range_lazy.min, range_lazy.max, properties['p_brush_lazy']:getValueNumber())
    self.spacing = properties['p_brush_spacing']:getValueNumber()
    self.alpha_transp = properties['p_brush_alpha_transp']:getValueNumber()
end

function Brush:updateAlpha(alpha_id)
    self.alpha_original = li.newImageData("assets/alphas/".. alpha_id ..".png")
    self.alpha = li.newImageData("assets/alphas/".. alpha_id ..".png")
end

function updateAllAlphas(alpha_id)
    for _, brush in pairs(BRUSHES) do
        brush:updateAlpha(alpha_id)
    end
    WALKERS_MAIN.alpha_path = "assets/alphas/".. alpha_id ..".png"
end

function Brush:alignAlpha()

    --local abs_w, abs_h = lw.getDimensions()
    local w, h = self.alpha:getDimensions()
    local w_half = w/2
    local h_half = h/2
    local canvas = lg.newCanvas(w, h)
    local alpha = lg.newImage(self.alpha_original, {linear = true})
    local angle = vSetAngle(self.dir)
    --print(angle)
    --local angle = vSetAngle(self.dir)
    --local angle = 0

    canvas:renderTo( function()
        lg.setColor(1, 1, 1, 1)
        lg.draw(alpha, w_half, h_half, angle, 1, 1, w_half, h_half) end
    )

    self.alpha = canvas:newImageData()
    
end

function Brush:rotateAlpha()

    --local abs_w, abs_h = lw.getDimensions()
    local w, h = self.alpha:getDimensions()
    local w_half = w/2
    local h_half = h/2
    local canvas = lg.newCanvas(w, h)
    local alpha = lg.newImage(self.alpha_original, {linear = true})
    self.alpha_angle = self.alpha_angle + .1
    --print(angle)
    --local angle = vSetAngle(self.dir)
    --local angle = 0

    canvas:renderTo( function()
        lg.setColor(1, 1, 1, 1)
        lg.draw(alpha, w_half, h_half, self.alpha_angle, 1, 1, w_half, h_half) end
    )

    self.alpha = canvas:newImageData()
    
end

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

    if mouse_dist > self.lazy_size + self.spacing then

        -- Limit movement while drawing to steps defined in object to prevent gaps in stroke
        if self.active then
            self.pos = self.pos + normalize(mouse_vec) * math.min(mouse_dist - self.lazy_size, self.spacing)
        else
            self.pos = self.pos + normalize(mouse_vec) * math.min(mouse_dist - self.lazy_size)
        end
        self.dir = normalize(mouse_vec)

        if BRUSH_ALIGN.value then
            self:alignAlpha()
        end
        if BRUSH_ROTATE.value then
            self:rotateAlpha()
        end
    end
end


--- Draw brush outline to UI
---@param mPos table
function Brush:drawOutline(mPos)
    lg.setCanvas(CANVAS_UI_DYNAMIC)
    lg.setLineWidth(1.5)
    lg.setLineStyle('smooth')

    -- Add a circle if wraparound is used
    if self.wrap then
        lg.setColor(.15, .75, .15)

        local brush_wrap0 = toWindowSpace(wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, self.size, 'x'))
        local brush_wrap1 = toWindowSpace(wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, self.size, 'y'))
        local brush_wrap2 = toWindowSpace(wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, self.size, 'both'))

        lg.circle("line", brush_wrap0.x, brush_wrap0.y, self.size, 64)
        lg.circle("line", brush_wrap1.x, brush_wrap1.y, self.size, 64)
        lg.circle("line", brush_wrap2.x, brush_wrap2.y, self.size, 64)
    end

    -- Actual brush circle
    lg.setColor(.7, .15, .15)
    lg.circle("line", self.pos.x, self.pos.y, self.size, 64)

    -- Lazy mouse radius and line to mouse
    lg.setColor(.15, .15, .75)
    if self.mode == "lazy" then 
        lg.circle("line", self.pos.x, self.pos.y, self.lazy_size, 64)
        lg.line(self.pos.x, self.pos.y, mPos.x, mPos.y)
    end

    lg.setCanvas()
end


--- Main function for drawing
function Brush:draw(mode)
    if vLength(self.dir) == 0 then
        return
    end

    local draw_size = self.size * (1 / math.min(CANVAS_SCALES.x, CANVAS_SCALES.y))
    -- Set color from direction vector
    local col = toZeroOne(self.dir)

    -- Since drawing onto canvas, convert the position to canvas coordinates before drawing
    local pos_convert = toCanvasSpace(self.pos)
    self:drawToImgData(pos_convert, draw_size, col)

    if self.wrap then

        local oob = isOutOfBounds(pos_convert, SIZE_OUT.x, SIZE_OUT.y, draw_size)
        if oob.x then
            local pos_wrap_x = wrapped(pos_convert, SIZE_OUT.x, SIZE_OUT.y, draw_size, 'x')
            self:drawToImgData(pos_wrap_x, draw_size, col)
        end
        if oob.y then
            local pos_wrap_y = wrapped(pos_convert, SIZE_OUT.x, SIZE_OUT.y, draw_size, 'y')
            self:drawToImgData(pos_wrap_y, draw_size, col)
        end
        if oob.x and oob.y then
            local pos_wrap_both = wrapped(pos_convert, SIZE_OUT.x, SIZE_OUT.y, draw_size, 'both')
            self:drawToImgData(pos_wrap_both, draw_size, col)
        end

        -- Wraparound for the wraparound to handle cases where brush is wrapping OOB
        --local pos_wrap1 = wrapped(pos_wrap0, SIZE_OUT.x, SIZE_OUT.y, draw_size)
        --self:drawToImgData(pos_wrap1, draw_size, col)

    end
end


--- Modify pixels in imageData
---@param inVector table
---@param draw_size number 
---@param col table
function Brush:drawToImgData(inVector, draw_size, col, mode)

    -- Map pixel colors using image alpha
    local function pixelFunctionAlphaDraw(x, y, r, g, b, a)

        -- Coordinates on brush alpha image. Convert from global xy to local alpha xy
        local alpha_x = ((x - PIXEL_INPUT_CORNER.x) / PIXEL_INPUT_DIMS.x) * PIXEL_INPUT_ALPHADIMS.x
        local alpha_y = ((y - PIXEL_INPUT_CORNER.y) / PIXEL_INPUT_DIMS.y) * PIXEL_INPUT_ALPHADIMS.y

        -- If alpha pixel OOB, return 0, otherwise return pixel value from image
        local brush_alpha = 0
        if (alpha_x > 0 and alpha_y > 0) and (alpha_x <= PIXEL_INPUT_ALPHADIMS.x and alpha_y <= PIXEL_INPUT_ALPHADIMS.y) then
            brush_alpha = self.alpha:getPixel(alpha_x, alpha_y)
        end

        -- Smoothstep according to brush hardness value
        --brush_alpha = smoothStep(0, 1 - self.hardness, brush_alpha)
        local hardness = clamp(.001, .999, self.hardness)
        brush_alpha = (clamp(0, 1, hardness + brush_alpha) - hardness) * (1 / (1 - hardness))

        local new_r = PIXEL_INPUT_COL.r
        local new_g = PIXEL_INPUT_COL.g
        local new_b = PIXEL_INPUT_COL.b

        r = lerp(r, new_r, brush_alpha * self.alpha_transp)
        g = lerp(g, new_g, brush_alpha * self.alpha_transp)
        b = lerp(b, new_b, brush_alpha * self.alpha_transp)

        return r, g, b, a
    end

    -- Brush radius to diameter
    local brush_w = draw_size * 2 
    local brush_h = draw_size * 2 

    -- Brush_dim is basically lower right corner distance from draw area 0-edges
    -- Brush_loc is top left corner of brush area
    local brush_dim = SIZE_OUT - inVector + vec(draw_size)
    local brush_loc = inVector - vec(draw_size)

    -- Brush width/height either a square of size (draw_size * 2) or distance from 0-edge, whichever is lower, rounded up
    brush_w = math.min(brush_w, math.floor(brush_dim.x) + 1)
    brush_h = math.min(brush_h, math.floor(brush_dim.y) + 1)

    -- Cap location minimum to .1 to avoid random errors
    brush_loc.x = math.max(brush_loc.x, .01)
    brush_loc.y = math.max(brush_loc.y, .01)

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


