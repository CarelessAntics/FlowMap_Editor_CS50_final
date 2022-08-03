-- TODO: Frame
-- TODO: Contains multiple objects with positions relative to Frame
-- TODO: Frame can be moved
-- TODO: Ordering objects inside frame

Frame = {   contents = {},
            pos = vec(0), -- Position offset relative to window and alignment
            bBox = {vec(0), vec(0)},
            dimensions = vec(0),
            padding = 0,
            align = 'right',
            state = true,
            current_dropdown = nil
        }

function Frame:new(o, inPos, padding, alignment)
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

    -- Init bounding box as a point, fixed offset from selected window edge
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
    o.state = true
    o.current_dropdown = nil

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
    self.contents[element.id].parent = self
    local padding_total = self.padding * 2

    if placement == 'bottom' then
        -- Make the element position relative to frame
        self.contents[element.id].pos = self:relative(vec(self.bBox[1].x + self.padding, self.bBox[2].y + self.padding))

        -- Resize the bounding box to contain new element
        if self.dimensions.x < element.size.x + padding_total then
            self.bBox[2].x = self.bBox[2].x + element.size.x + padding_total
        end
        self.bBox[2].y = self.bBox[2].y + element.size.y + padding_total
    end

    local dims = self.bBox[2] - self.bBox[1]
    self.dimensions = vec(math.abs(dims.x), math.abs(dims.y))
end


-- Update Frame position relative to window
function Frame:updateAbsolutePos(rel_w, rel_h)

    local bBox0 = vec(0)
    local bBox1 = vec(0)

    if self.align == 'right' then
        bBox0 = vec(rel_w - self.pos.x, (rel_h / 2) - self.pos.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'left' then
        bBox0 = vec(self.pos.x, (rel_h / 2) - self.pos.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'top' then
        bBox0 = vec((rel_w / 2) - self.pos.x, self.pos.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'bottom' then
        bBox0 = vec((rel_w / 2) - self.pos.x, rel_h - self.pos.y)
        bBox1 = bBox0 + self.dimensions
    end

    self.bBox = {bBox0, bBox1}
    --self:updateContentPos()
end


-- Hit detection for Frame elements
function Frame:getHit(mPos)
    for _, element in pairs(self.contents) do
        local abs = self:absolute(element.pos)
        if isHitRect(mPos, abs, abs + element.size) then

            -- TODO: think of a way to make button actions better
            if element.type == 'button' then
                element.action(IMGDATA_MAIN)
            elseif element.type == 'dropdown' then
                element:toggleContent()
            elseif element.type == 'textbox' then
                selectTextBox(element)
            end
        end
    end
end


-- Draw Frame elements on screen
function Frame:draw()
    for _, element in pairs(self.contents) do

        local abs = self:absolute(element.pos)

        if element.type == 'dropdown' and element.state then
            element.content:draw()
        elseif element.type == 'textbox' then
            element:draw(abs)
            goto continue -- Why is lua weird
        end

        local icon_w, icon_h = element.graphics:getDimensions()
        local scales = element.size / vec(icon_w, icon_h)

        lg.setColor(1, 1, 1, 1)
        lg.draw(element.graphics, abs.x, abs.y, 0, scales.x, scales.y)
        
        ::continue::
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
        if v.type == 'dropdown' and v.state then
            v.content:drawDebug()
        end
        local abs = self:absolute(v.pos)
        lg.rectangle('line', abs.x, abs.y, v.size.x, v.size.y)
    end

    lg.setCanvas()
end