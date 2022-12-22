-- TODO: Frame
-- TODO: Contains multiple objects with positions relative to Frame
-- TODO: Frame can be moved
-- TODO: Ordering objects inside frame

Frame = {   contents = {},
            pos = vec(0), -- Position offset relative to window and alignment
            bBox = {vec(0), vec(0)}, -- Frame bounding box absolute position values
            dimensions = vec(0),
            grid_dimensions = vec(0),
            padding = 0,
            align = 'right',
            state = true,
            current_dropdown = nil,
            parent = nil,
            id = ''
        }

function Frame:new(o, id, inPos, padding, alignment)
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
    o.parent = nil
    o.grid_dimensions = vec(0)
    o.id = id or 'none'

    return o
end


function Frame:absolute(v)
    return v + self.bBox[1] 
end


function Frame:relative(v)
    return v - self.bBox[1]
end


-- Add an element into frame and position it accordingly
function Frame:addElement(element, placement, UI_ref)
    UI_ref.elements[element.id] = element
    element.pos = self:relative(vCopy(self.bBox[1] + vec(self.padding)))
    element.parent = self
    element.grid_location = vec(-1)

    if element.subframe ~= nil then
        element.subframe.parent = self
    end

    local padding2x = self.padding * 2
    placement = placement or 'bottom left'
    
    local placements = splitString(placement, ' ')
    placements[2] = placements[2] or 'left'

    placement = table.concat(placements, ' ')

    local column_size_x = 0
    local column_size_y = 0
    local column_count = 0
    local row_count = 0
    local nudge = 0

    -- Place item in the frame based on instructions
    if placement == 'top left' then
        -- Set element's position relative to frame
        element.pos = self:relative(vec(self.bBox[1].x + self.padding, self.bBox[1].y + self.padding))
        element.grid_location.x = 0
        element.grid_location.y = 0

        column_size_x = element.size.x + padding2x
        column_size_y = element.size.y + padding2x

        -- Go through already inserted elements. Since inputting on the left side, nudge every other element in the same row 1 space to the right
        -- Same process for when inserting from the top
        -- At the same time, sum up the current row's/column's size, and increment the count of elements on current row/column
        for _, other in pairs(self.contents) do
            if other.grid_location.x == element.grid_location.x then
                other.pos.y = other.pos.y + element.size.y
                other.grid_location.y = other.grid_location.y + 1
                column_size_y = column_size_y + other.size.y + self.padding
                column_count = column_count + 1
            end

            if other.grid_location.y == element.grid_location.y then
                other.pos.x = other.pos.x + element.size.x
                other.grid_location.x = other.grid_location.x + 1
                column_size_x = column_size_y + other.size.x + self.padding
                row_count = row_count + 1
            end
        end

    elseif placement == 'bottom left' then

        element.pos = self:relative(vec(self.bBox[1].x + self.padding, self.bBox[2].y + self.padding))
        element.grid_location.x = 0
        element.grid_location.y = self.grid_dimensions.y

        column_size_x = element.size.x + padding2x
        column_size_y = element.size.y + padding2x

        for _, other in pairs(self.contents) do
            if other.grid_location.x == element.grid_location.x then
                column_size_y = column_size_y + other.size.y + self.padding
                column_count = column_count + 1
            end

            if other.grid_location.y == element.grid_location.y then
                other.pos.x = other.pos.x + element.size.x
                other.grid_location.x = other.grid_location.x + 1
                column_size_x = column_size_y + other.size.x + self.padding
                row_count = row_count + 1
            end
        end

    elseif placement == 'top right' then

        element.pos = self:relative(vec(self.bBox[2].x - element.size.x - padding2x, self.bBox[1].y + self.padding))
        element.grid_location.x = self.grid_dimensions.x
        element.grid_location.y = 0

        for _, other in pairs(self.contents) do
            if other.grid_location.x == element.grid_location.x then
                other.pos.y = other.pos.y + element.size.y
                other.grid_location.y = other.grid_location.y + 1
                column_size_y = column_size_y + other.size.y + self.padding
                column_count = column_count + 1
            end

            if other.grid_location.y == element.grid_location.y then
                column_size_x = column_size_x + other.size.x + self.padding
                row_count = row_count + 1
            end
        end

        if element.pos.x < column_size_x then
            nudge = (column_size_x - element.pos.x) + padding2x
            element.pos.x = element.pos.x + nudge
        end

        column_size_x = column_size_x + element.size.x + padding2x
        column_size_y = column_size_y + element.size.y + padding2x

    elseif placement == 'bottom right' then
        
        element.pos = self:relative(vec(self.bBox[2].x - element.size.x - padding2x, self.bBox[2].y + self.padding))
        element.grid_location.x = self.grid_dimensions.x
        element.grid_location.y = 0

        for _, other in pairs(self.contents) do
            if other.grid_location.x == element.grid_location.x then
                column_size_y = column_size_y + other.size.y + self.padding
                column_count = column_count + 1
            end

            if other.grid_location.y == element.grid_location.y then
                column_size_x = column_size_x + other.size.x + self.padding
                row_count = row_count + 1
                
            end
        end

        if element.pos.x < column_size_x then
            nudge = element.pos.x + (column_size_x - element.pos.x) + padding2x
            element.pos.x = element.pos.x + nudge
        end

        column_size_x = column_size_x + element.size.x + padding2x
        column_size_y = column_size_y + element.size.y + padding2x
    end

    -- Update the grid maximums. Needed when inserting elements from left or bottom
    self.grid_dimensions.x = math.max(self.grid_dimensions.x, row_count + 1)
    self.grid_dimensions.y = math.max(self.grid_dimensions.y, column_count + 1)

    -- Resize the bounding box to contain new element
    if self.dimensions.x < column_size_x + nudge then
        local diff = column_size_x - self:relative(self.bBox[2]).x
        self.bBox[2].x = self.bBox[2].x + diff
    end

    if self.dimensions.y < column_size_y then
        self.bBox[2].y = self.bBox[2].y + (element.size.y + padding2x)
    end
            
    self.contents[element.id] = element
    local new_dims = self.bBox[2] - self.bBox[1]
    self.dimensions = vec(math.abs(new_dims.x), math.abs(new_dims.y))

    self:updateAbsolutePos(0,0)
end

-- Similar to addElement, but instead uses explicit grid location.
function Frame:addElementToGrid(element, gridPos, UI_ref)
    UI_ref.elements[element.id] = element
    element.pos = self:relative(vCopy(self.bBox[1] + vec(self.padding)))
    element.parent = self
    element.grid_location = gridPos

    if element.subframe ~= nil then
        element.subframe.parent = self
    end

    local padding2x = self.padding * 2
    local column_size_x = 0
    local column_size_y = 0

    self.grid_dimensions.x = math.max(self.grid_dimensions.x, gridPos.x)
    self.grid_dimensions.y = math.max(self.grid_dimensions.y, gridPos.y)

    for _, other in pairs(self.contents) do
        if other.grid_location.x == gridPos.x then
            if other.grid_location.y < gridPos.y then
                column_size_y = column_size_y + other.size.y + self.padding
            elseif other.grid_location.y > gridPos.y then
                other.pos.y = other.pos.y + element.size.y + self.padding
            else
                print("CELL OCCUPIED")
            end
        end

        if other.grid_location.y == gridPos.y then
            if other.grid_location.x < gridPos.x then
                column_size_x = column_size_x + other.size.x + self.padding
            elseif other.grid_location.x > gridPos.x then
                other.pos.x = other.pos.x + element.size.x + self.padding
            else
                print("CELL OCCUPIED")
            end   
        end
    end

    element.pos = vec(column_size_x, column_size_y)

    column_size_x = column_size_x + element.size.x + self.padding
    column_size_y = column_size_y + element.size.y + self.padding

    -- Resize the bounding box to contain new element
    if self.dimensions.x < column_size_x then
        local diff = column_size_x - self:relative(self.bBox[2]).x
        self.bBox[2].x = self.bBox[2].x + diff
    end

    if self.dimensions.y < column_size_y then
        self.bBox[2].y = self.bBox[2].y + (element.size.y + padding2x)
    end
            
    self.contents[element.id] = element
    local new_dims = self.bBox[2] - self.bBox[1]
    self.dimensions = vec(math.abs(new_dims.x), math.abs(new_dims.y))

    self:updateAbsolutePos(0,0)


end



function Frame:clear()

    self.contents = {}
    self.dimensions = vec(0)
    self.grid_dimensions = vec(0)
    self.bBox = {self.bBox[1], vCopy(self.bBox[1])}

end


-- Update absolute Frame position relative to window
function Frame:updateAbsolutePos(offset_x, offset_y)

    local window_w, window_h = lg.getDimensions()
    offset_x = offset_x or 0
    offset_y = offset_y or 0

    local pos_rel = self.pos
    local parent_x = window_w
    local parent_y = window_h

    if self.parent ~= nil then
        if self.align == 'right' then
            parent_x = self.parent.bBox[1].x + self.parent.dimensions.x
        elseif self.align == 'left' then
            parent_x = self.parent.bBox[1].x - self.dimensions.x
        end
        
    else
        if self.align == 'right' then
            parent_x = window_w - self.dimensions.x
        elseif self.align == 'left' then
            parent_x = 0
        elseif self.align == 'top' then
            parent_x = 0
        elseif self.align == 'bottom' then
            parent_x = window_h
        end
    end

    local bBox0 = vec(0)
    local bBox1 = vec(0)

    if self.align == 'right' then
        bBox0 = vec(parent_x - pos_rel.x, (parent_y / 2) - pos_rel.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'left' then
        bBox0 = vec(parent_x + pos_rel.x, (parent_y / 2) - pos_rel.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'top' then
        bBox0 = vec((window_w / 2) - pos_rel.x, parent_y + pos_rel.y)
        bBox1 = bBox0 + self.dimensions
    elseif self.align == 'bottom' then
        bBox0 = vec((window_w / 2) - pos_rel.x, parent_y - pos_rel.y)
        bBox1 = bBox0 + self.dimensions
    end

    self.bBox = {bBox0, bBox1}
    --self:updateContentPos()
end


-- Hit detection for Frame elements
function Frame:getHit(mPos, mButton, UI_ref, key_pressed)
    for _, element in pairs(self.contents) do
        local abs = self:absolute(element.pos)
        local hovering = true
        if isHitRect(mPos, abs, abs + element.size) then

            -- if no mouse button specified, hover detected
            if mButton == nil then
                if HOVER_CURRENT == element.id and element.tooltip ~= '' then
                    element:drawTooltip(mPos)
                else
                    HOVER_CURRENT = element.id
                    HOVER_TIMER = 0
                end
                return
            end

            if key_pressed then
                if mButton == 1 then

                    -- TODO: think of a way to make button actions better
                    if element.type == 'button' or element.type == 'button_wide'then
                        element.action(unpack(element.parameters))
            
                    elseif element.type == 'dropdown' then
                        element:toggleSubFrame()

                    elseif element.type == 'checkbox' then
                        element:toggleCheckbox(unpack(element.parameters))
            
                    elseif element.type == 'textbox' then
                        selectTextBox(element)
                    end
            
                elseif mButton == 2 then
                    if element.subframe ~= nil then
                        element:toggleSubFrame()
                    end
                end
            end

            -- Make sure a sprite property exists
            if element.sprite ~= nil and element.type ~= 'dropdown' then
                element:press()           
            end
        end
    end
end


-- Draw Frame elements on screen
function Frame:draw()

    -- Frame background
    lg.setCanvas(CANVAS_UI_BACKGROUND)
    lg.setColor(.3, .3, .3, 1)

    local padding = 3
    local padding2x = padding * 2

    local pos_x = self.bBox[1].x - padding
    local pos_y = self.bBox[1].y - padding

    local frame_width = self.dimensions.x
    local frame_height = self.dimensions.y

    lg.rectangle('fill', pos_x, pos_y, frame_width + padding, frame_height + padding)
    lg.setColor(.4, .4, .4, 1)
    lg.rectangle('line', pos_x, pos_y, frame_width + padding, frame_height + padding)

    lg.setCanvas()

    for _, element in pairs(self.contents) do

        local abs = self:absolute(element.pos)
        
        -- TextBox doesn't have graphics, so skip the rest of the loop
        if element.type == 'textbox' then
            element:draw()
            goto continue
        end

        local icon_size = element.icon_set.size_icon
        local atlas_size = element.icon_set.size_atlas
        local dd_tri = lg.newQuad(7 * icon_size, 7 * icon_size, icon_size, icon_size, atlas_size, atlas_size)

        local scales
        if element.type == 'button_wide' or 'CheckBox' then
            scales = vec(element.size.y) / vec(icon_size)
        else
            scales = element.size / vec(icon_size)
        end

        if element.type == 'button_wide' then
            element.icon_set.batch:add(element.sprite[1], abs.x, abs.y, 0, scales.x, scales.y)
            element.icon_set.batch:add(element.sprite[2], abs.x + element.size.y, abs.y, 0, scales.x + element.width, scales.y)
            element.icon_set.batch:add(element.sprite[3], abs.x + element.size.y + element.width, abs.y, 0, scales.x, scales.y)

            local icon_offset = element.icon_set.offset
            local font_offset = FONT_GLOBAL:getHeight()

            lg.setCanvas(CANVAS_UI_STATIC)
            lg.setColor(1, 1, 1, 1)
            if not element.pressed then
                lg.print(element.label, abs.x + font_offset + (element.size.y * icon_offset / 2), abs.y + (element.size.y / 2) - (font_offset / 2) - (element.size.y * icon_offset / 2))
            else
                lg.print(element.label, abs.x + font_offset - (element.size.y * icon_offset / 2), abs.y + (element.size.y / 2) - (font_offset / 2) + (element.size.y * icon_offset / 2))
            end
            lg.setCanvas()
        else
            element.icon_set.batch:add(element.sprite, abs.x, abs.y, 0, scales.x, scales.y)
        end

        if element.type == 'checkbox' then
            element:draw()
        end

        -- In case of a dropdown, add in a small triangle
        if element.type == 'dropdown' then
            element.icon_set.batch:add(dd_tri, abs.x, abs.y, 0, scales.x, scales.y)
        end

        -- Draw dropdown contents
        if element.state and element.subframe ~= nil then
            element.subframe:draw()
        end
        
        
        ::continue::
    end
end


function Frame:drawDebug()
    lg.setCanvas(CANVAS_UI_STATIC)
    lg.setColor(1, 0, 0, 1)

    lg.setLineWidth(2)
    lg.rectangle('line', self.bBox[1].x, self.bBox[1].y, self.dimensions.x, self.dimensions.y)

    lg.setColor(1, 1, 0, 1)
    lg.setLineWidth(1)
    for _, v in pairs(self.contents) do
        if v.type == 'dropdown' and v.state then
            v.subframe:drawDebug()
        end
        local abs = self:absolute(v.pos)
        lg.rectangle('line', abs.x, abs.y, v.size.x, v.size.y)
    end

    lg.setCanvas()
end