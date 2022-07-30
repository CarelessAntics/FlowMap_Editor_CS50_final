-- TODO: Frame
-- TODO: Contains multiple objects with positions relative to Frame
-- TODO: Frame can be moved
-- TODO: Ordering objects inside frame

Frame = {   contents = {},
            pos = vec(0), -- Position offset relative to window and alignment
            bBox = {vec(0), vec(0)},
            dimensions = vec(0),
            padding = 0,
            align = 'right'
        }

function Frame:new(o, inPos, padding, alignment) --, bBox0, bBox1)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Set Instance defaults
    o.contents = {}
    o.pos = inPos
    o.padding = padding

    local window_w, window_h = lg.getDimensions()

    local bBox0 = vec(0)
    local bBox1 = vec(0)

    if alignment == 'right' then
        bBox0 = vec(window_w - inPos.x, (window_h / 2) - inPos.y)
        bBox1 = vCopy(bBox0)
    elseif alignment == 'left' then
        bBox0 = vec(inPos.x, (window_h / 2) - inPos.y)
        bBox1 = vCopy(bBox0)
    elseif alignment == 'top' then
        bBox0 = vec((window_w / 2) - inPos.x, inPos.y)
        bBox1 = vCopy(bBox0)
    elseif alignment == 'bottom' then
        bBox0 = vec((window_w / 2) - inPos.x, window_h - inPos.y)
        bBox1 = vCopy(bBox0)
    end

    o.bBox = {bBox0, bBox1}

    local dims = o.bBox[2] - o.bBox[1]
    o.dimensions = vec(math.abs(dims.x), math.abs(dims.y))
    o.align = alignment -- Where to align frame relative to window 'left', 'right', 'top', 'bottom', 'fill'

    return o
end


function Frame:absolute(v)
    return v + self.bBox[1] 
end


function Frame:relative(v)
    return v - self.bBox[1]
end


-- TODO: Add an element into frame and position it accordingly
function Frame:addElement(element, placement)
    self.contents[element.id] = element
    local padding_total = self.padding * 2

    if placement == 'bottom' then
        -- Make the element position relative to frame
        self.contents[element.id].pos = self:relative(vec(self.bBox[1].x, self.bBox[2].y))

        -- Resize the bounding box to contain new element
        if self.dimensions.x < element.size.x then
            self.bBox[2].x = self.bBox[2].x + element.size.x
        end
        self.bBox[2].y = self.bBox[2].y + element.size.y
    end

    local dims = self.bBox[2] - self.bBox[1]
    self.dimensions = vec(math.abs(dims.x), math.abs(dims.y))
end


function Frame:updateRelativePos()
    local window_w, window_h = lg.getDimensions()

    local bBox0 = vec(0)
    local bBox1 = vec(0)

    if self.align == 'right' then
        bBox0 = vec(window_w - self.pos.x, (window_h / 2) - self.pos.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'left' then
        bBox0 = vec(self.pos.x, (window_h / 2) - self.pos.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'top' then
        bBox0 = vec((window_w / 2) - self.pos.x, self.pos.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'bottom' then
        bBox0 = vec((window_w / 2) - self.pos.x, window_h - self.pos.y)
        bBox1 = bBox0 + self.dimensions
    end

    self.bBox = {bBox0, bBox1}
    --self:updateContentPos()
end


function Frame:getHit(mPos)
    for _, element in pairs(self.contents) do
        local abs = self:absolute(element.pos)
        if isHitRect(mPos, abs, abs + element.size) then
            element.action(IMGDATA_MAIN)
        end
    end
end


function Frame:draw()
    local frame_data = li.newImageData(self.dimensions.x, self.dimensions.y)
    for _, element in pairs(self.contents) do
        local icon_w, icon_h = element.graphics:getDimensions()
        local scales = element.size / vec(icon_w, icon_h)
        local abs = self:absolute(element.pos)
        
        lg.setColor(1, 1, 1, 1)
        lg.draw(element.graphics, abs.x, abs.y, 0, scales.x, scales.y)
    end
end


function Frame:drawDebug()
    lg.setCanvas(CANVAS_UI)
    lg.setColor(1, 0, 0, 1)

    lg.setLineWidth(2)
    lg.rectangle('line', self.bBox[1].x, self.bBox[1].y, self.dimensions.x, self.dimensions.y)

    lg.setColor(1, 1, 0, 1)
    lg.setLineWidth(1)
    for _, v in pairs(self.contents) do
        local abs = self:absolute(v.pos)
        lg.rectangle('line', abs.x, abs.y, v.size.x, v.size.y)
    end

    lg.setCanvas()
end

