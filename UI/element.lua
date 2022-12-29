-----------------------------------------
-- 
-- Base UI element object
--
-----------------------------------------

Element = {  pos = vec(0), -- Position will be top-left corner
            size = vec(1),
            id = nil,
            type = 'button', -- 'button, dropdown, textbox'
            state = false,
            parent = nil,
            tooltip = "",
            tooltip_dimensions = vec(0),
            subframe = nil,
            alignment = nil, -- Alignment inside parent frame grid
            grid_location = vec(0), -- parent frame grid coords
            sprite = nil,
        }


function Element:new(o)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    o.alignment = nil -- Alignment inside parent frame grid
    o.grid_location = vec(0) -- parent frame grid coords

    return o
end


-- Toggles the subframe on and off. Logic taken from dropdowns and put into the base Element Class
function Element:toggleSubFrame()
    -- Update the location with every toggle
    self:setSubFrameLocation()
    if self.type == 'dropdown' then
        self:setPressed(false)
    end

    -- If the parent frame already has a different subframe open, toggle that off and set this one on
    if self.parent.current_dropdown ~= nil and self.parent.current_dropdown ~= self then
        self.parent.current_dropdown:toggleSubFrame()
        self.parent.current_dropdown = self

    -- If no subframes open
    elseif self.parent.current_dropdown == nil then
        self.parent.current_dropdown = self

    -- If this is the current open subframe, close it
    elseif self.parent.current_dropdown == self then
        self.parent.current_dropdown = nil
    end

    -- Turn off subframes any children might have open
    if self.subframe.current_dropdown ~= nil then
        self.subframe.current_dropdown:toggleSubFrame()
    end

    -- Toggle states
    self.state = not self.state
    self.subframe.state = not self.subframe.state

    if self.type == 'dropdown'then
        self:setPressed(self.state)
    end
end


-- Move content frame relative to current location
function Element:setSubFrameLocation()
    if self.parent == nil then
        return
    end

    local window_w, window_h = lg.getDimensions()
    --self.subframe:updateAbsolutePos(self.parent.bBox[1].x,self.parent.bBox[1].y, self.subframe.dimensions.x, self.subframe.dimensions.y)
    self.subframe:updateAbsolutePos()
end


-- Create properties-frame for Element
-- Takes in a variable amount of tables with the following template:
-- {label = text, id = text, value = any, size = vector}
-- For grouped properties:
-- {label_header = text, id = any, {}, {}, {}, ...}
function Element:setProperties(frameId, alignment, UI_ref, ... )
    -- Create a new subframe and initialize its state to false
    self.subframe = Frame:new(nil, frameId, vec(0), 10, alignment)
    self.subframe.state = false
    self.subframe.parent = self.parent

    local arg = {...}

    -- Put the processing code to one place to avoid copypaste
    -- Just creates a different textbox based on input type
    function processProperty(property)
            
        local newProperty
        if type(property.value) == 'number' then
            newProperty = TextBox:new(nil, property.id, 'number', tostring(property.value), property.size, property.label, nil)
            --newProperty.text = tostring(property.value)

        elseif type(property.value) == 'string' then
            newProperty = TextBox:new(nil, property.id, 'string', tostring(property.value), property.size, property.label, nil)
            --newProperty.text = tostring(property.value)

        else
            newProperty = TextBox:new(nil, property.id, 'number', nil, property.size, property.label, nil)
            newProperty.text = "Something Went Wrong"
        end

        return newProperty
    end

    local row_count = 0
    -- Iterate over input properties and make UI elements for them
    for i, property in pairs(arg) do

        -- If a given property is multiple tables, or has a property called label header
        -- Give them a header label and arrange them in one row in the frame
        if onlyContains('table', property) or property.label_header ~= nil then
            local header = Label:new(nil, property.id, property.label_header)
            header:overflow('allow')
            local col_count = 0
            self.subframe:addElementToGrid(header, vec(col_count, row_count), UI_ref, {colspan = 1})

            for _, p in pairs(property) do
                if type(p) == 'table' then
                    local new_p = processProperty(p)
                    self.subframe:addElementToGrid(new_p, vec(col_count, row_count + 1), UI_ref)
                    col_count = col_count + 1
                end
            end

            row_count = row_count + 2
        else
            local new_p = processProperty(property)
            self.subframe:addElementToGrid(new_p, vec(0, row_count), UI_ref)
            row_count = row_count + 1
        end
    end
    UI_ref.properties[frameId] = self.subframe
end

-- Get the dimensions of tooltip box contents for drawing
function Element:setTooltipDims(font)

    local font_width = font:getWidth(self.tooltip)
    local font_height = font:getHeight()

    local width = 0
    local _, count = string.gsub(self.tooltip, '\n', '')
    local height = (count + 1) * font_height

    for str in string.gmatch(self.tooltip, '([^\n]+)') do
        width = math.max(width, font:getWidth(str))
    end

    self.tooltip_dimensions = vec(width, height)

end

function Element:drawTooltip(mousePos)

    lg.setCanvas(CANVAS_UI_OVERLAY)
    lg.setColor(.2, .2, .2, 1)

    local padding = 3
    local padding2x = padding * 2

    -- local text_width = FONT_GLOBAL:getWidth(self.tooltip)
    -- local text_height = FONT_GLOBAL:getHeight()

    local text_width = self.tooltip_dimensions.x
    local text_height = self.tooltip_dimensions.y

    local window_w = lg.getDimensions()

    local pos_x = mousePos.x
    local pos_y = mousePos.y - text_height - padding

    if pos_x + text_width > window_w then
        pos_x = pos_x - text_width - padding
    end

    lg.rectangle('fill', pos_x, pos_y, text_width + padding2x, text_height + padding2x)
    lg.setColor(.3, .3, .3, 1)
    lg.rectangle('line', pos_x, pos_y, text_width + padding2x, text_height + padding2x)

    lg.setColor(1, 1, 1, 1)
    lg.print(self.tooltip, pos_x + padding, pos_y + padding)

    lg.setCanvas()

end

-----------------------------------------
-- 
-- Label object
--
-----------------------------------------

label_params = {label = "No label"}
Label = Element:new(label_params)

-- A label object. No functionality, only text
function Label:new(o, inID, inLabel, inFont)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    o.pos = vec(0)
    o.id = inID
    o.label = inLabel or "no label found"
    o.font = inFont or FONT_GLOBAL

    local label_width = FONT_GLOBAL:getWidth(o.label)
    local label_height = FONT_GLOBAL:getHeight()

    o.size = vec(label_width, label_height)
    o.type = 'label'

    return o
end
    
-- To prevent labels resizing grids uselessly, set element.size.x to 0 or back to label width
function Label:overflow(style)
    if style == 'none' then
        self.size.x = self.font:getWidth(self.label)
    elseif style == 'allow' then
        self.size.x = 0
    end
end

-----------------------------------------
-- 
-- Button object
--
-----------------------------------------

button_params = {action = nil, parameters = {}, hover = false, pressed = false, icon_set = nil}
Button = Element:new(button_params)

-- Button object has an icon graphic and stored function which activates when button is clicked
function Button:new(o, inID, inSize, actionFunc, parameters, inSprite, inTooltip, inIconSet)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    o.icon_set = inIconSet or ICON_SET

    inSprite = inSprite or vec(0, 7)
    local icon_size = o.icon_set.size_icon
    local atlas_size = o.icon_set.size_atlas

    -- Initialize instance params
    o.pos = vec(0)
    o.size = vec(inSize)
    o.id = inID
    o.type = 'button'
    o.state = false
    --o.graphics = vec(0)--lg.newImage(inIcon or "assets/icons/default.png")
    o.sprite = lg.newQuad(inSprite.x * icon_size, inSprite.y * icon_size, icon_size, icon_size, atlas_size, atlas_size)
    o.hover = false
    o.pressed = false
    o.action = actionFunc or function() print("No function specified") end -- function: what happens when button is activated
    o.parameters = parameters or {}
    o.tooltip = inTooltip or ""
    o:setTooltipDims(FONT_GLOBAL)
    return o
end

-- Reset graphics based on a new icon set
function Button:setIcons(icon_set, new_sprite)
    
    local x, y, w, h = self.sprite:getViewport()
    local icon_size = icon_set.icon_size
    local atlas_size = icon_set.atlas_size

    new_sprite = new_sprite or vec(x / w, y / h)
    self.icon_set = icon_set
    self.sprite = lg.newQuad(new_sprite.x * icon_size, new_sprite.y * icon_size, icon_size, icon_size, atlas_size, atlas_size)
end

function Button:press()
    local x, y, w, h = self.sprite:getViewport()
    if self.pressed then
        self.sprite:setViewport(x - w, y, w, h)
    else
        self.sprite:setViewport(x + w, y, w, h)
    end
    self.pressed = not self.pressed
end

function Button:setPressed(state)
    if self.pressed ~= state then
        self:press()
    end
end

-----------------------------------------
-- 
-- Wide button (custom label) object
--
-----------------------------------------

buttonWide_params = {width = 0, label = ''}
ButtonWide = Button:new(buttonWide_params)

function ButtonWide:new(o, inID, inSize, inWidth, inLabel, actionFunc, parameters, inSprite, inTooltip, inIconSet)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    inSprite = inSprite or vec(0, 7)
    o.icon_set = inIconSet or ICON_SET
    local icon_size = o.icon_set.size_icon
    local atlas_size = o.icon_set.size_atlas

    -- Initialize instance params
    o.pos = vec(0)
    o.width = inWidth or 0
    o.size = vec((inSize*2) + o.width, inSize)
    o.label = inLabel or 'noLabel'
    o.id = inID
    o.type = 'button_wide'
    o.state = false
    --o.graphics = vec(0)--lg.newImage(inIcon or "assets/icons/default.png")
    o.sprite = {lg.newQuad(inSprite.x * icon_size, inSprite.y * icon_size, icon_size, icon_size, atlas_size, atlas_size),
                lg.newQuad((inSprite.x + 1) * icon_size, inSprite.y * icon_size, 1, icon_size, atlas_size, atlas_size),
                lg.newQuad((inSprite.x + 2) * icon_size, inSprite.y * icon_size, icon_size, icon_size, atlas_size, atlas_size)}
    o.hover = false
    o.pressed = false
    o.action = actionFunc or function() print("No function specified") end -- function: what happens when button is activated
    o.parameters = parameters or {}
    o.tooltip = inTooltip or ""
    o:setTooltipDims(FONT_GLOBAL)
    return o
end

function ButtonWide:press()
    for _, sprite_part in pairs(self.sprite) do
        local x, y, w, h = sprite_part:getViewport()
        if self.pressed then
            sprite_part:setViewport(x, y - h, w, h)
        else
            sprite_part:setViewport(x, y + h, w, h)
        end
    end
    self.pressed = not self.pressed
end

-----------------------------------------
-- 
-- Dropdown object
--
-----------------------------------------

dropdown_params = {graphics = nil}
Dropdown = Button:new(dropdown_params)


-- This could be deleted and merged to base Element at some point
function Dropdown:new(o, inID, inSize, inSprite, inTooltip, inIconSet)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    inSprite = inSprite or vec(0, 7)
    o.icon_set = inIconSet or ICON_SET
    local icon_size = o.icon_set.size_icon
    local atlas_size = o.icon_set.size_atlas

    -- Initialize instance params
    o.pos = vec(0)
    o.size = vec(inSize)
    o.id = inID
    o.type = 'dropdown'
    o.state = false
    --o.graphics = lg.newImage(inIcon or "assets/icons/default.png")
    o.sprite = lg.newQuad(inSprite.x * icon_size, inSprite.y * icon_size, icon_size, icon_size, atlas_size, atlas_size)
    o.content = nil -- Contained frame
    o.parent = nil
    o.tooltip = inTooltip or ""
    o:setTooltipDims(FONT_GLOBAL)
    return o
end


-- Insert the frame which the dropdown button will open
function Dropdown:setContent(inContent)
    self.subframe = inContent
    self.subframe.parent = self.parent
    self.subframe.state = false
end

-----------------------------------------
-- 
-- Checkbox object
--
-----------------------------------------

checkbox_params = {label = ""}
CheckBox = Button:new(checkbox_params)

function CheckBox:new(o, inID, inSize, inLabel, parameters, defaultState, inSprite, inTooltip, inIconSet)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    inSprite = inSprite or vec(0, 7)
    o.icon_set = inIconSet or ICON_SET
    local icon_size = o.icon_set.size_icon
    local atlas_size = o.icon_set.size_atlas

    local char_dims = vec(FONT_GLOBAL:getHeight() / 1.5, FONT_GLOBAL:getHeight())

    -- Initialize instance params
    o.pos = vec(0)
    o.size = vec(inSize)
    o.id = inID
    o.type = 'checkbox'
    o.state = defaultState
    o.label = inLabel or "Checkbox"
    o.size.x = o.size.x + FONT_GLOBAL:getWidth(o.label) + o.size.y
    o.sprite = lg.newQuad(inSprite.x * icon_size, inSprite.y * icon_size, icon_size, icon_size, atlas_size, atlas_size)
    o.hover = false
    o.pressed = false
    o.action = actionFunc or function() print("No function specified") end -- function: what happens when button is activated
    o.parameters = parameters or {}
    o.tooltip = inTooltip or ""
    o:setPressed(defaultState)
    o:setTooltipDims(FONT_GLOBAL)
    return o
end

function CheckBox:draw()
    local absPos = self.parent:absolute(self.pos)
    local char_dims = vec(FONT_GLOBAL:getHeight() / 1.5, FONT_GLOBAL:getHeight())
    lg.setCanvas(CANVAS_UI_STATIC)

    local padding = 2.5
    lg.setColor(1, 1, 1, 1)

    if self.label ~= nil then
        -- self.size.x includes the label as well, so only use size.y for offsets
        lg.print(self.label, absPos.x + padding + self.size.y, absPos.y + self.size.y / 2 - char_dims.y / 2)
    end
    lg.setCanvas()
end

function CheckBox:toggleCheckbox(target)
    self.state = not self.state
    target.value = self.state
    self:setPressed(self.state)
end

-----------------------------------------
-- 
-- TextBox object
--
-----------------------------------------

textbox_params = {text = "", label = "", valuetype = "", padding = 2.5, font = nil, box_size = vec(0), max_length = nil}
TextBox = Element:new(textbox_params)

-- Initialize textbox instance
function TextBox:new(o, inID, inValueType, initValue, inSize, inLabel, inFont, inLength)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    o.font = inFont or FONT_GLOBAL

    local char_dims = vec(o.font:getHeight() / 1.5, o.font:getHeight() + self.padding * 2)

    -- Set the element size according to label or content, whichever is bigger
    o.label = inLabel
    if o.label ~= nil then
        local width_label = o.font:getWidth(o.label) + self.padding * 2
        local element_size = (inSize + vec(0, 1)) * char_dims
        local element_width = math.max(element_size.x, o.font:getWidth(o.label) + self.padding * 2)
        o.size = vec(element_width, element_size.y)
    else
        o.size = inSize * char_dims
    end

    o.box_size = inSize * char_dims -- Input box size, independent of element itself
    o.pos = vec(SIZE_OUT)
    o.id = inID
    o.type = 'textbox'
    o.state = false -- writing or not
    o.text = initValue or ""
    o.max_length = inLength or -1
    
    o.valuetype = inValueType or "any" -- 'number', 'letters', 'string'
    return o
end


-- Backspace functionality
function TextBox:backspace()
    if string.len(self.text) > 0 then
        self.text = self.text:sub(1, -2) or ''
        self:draw()
    end
end


-- Returns the contained text as number
function TextBox:getValueNumber()
    if string.len(self.text) > 0 then
        if self.text == '.' or self.text == '' then
            return 0.
        else
            return tonumber(self.text) + 0.
        end
    else
        return 0.
    end
end

function TextBox:getValueText()
    if string.len(self.text) > 0 then
        return self.text
    else
        return ' '
    end
end


-- Validate text input to match valuetype
function TextBox:validate(t)

    local decimal = true
    local digit = true
    local letters = true
    local length = true

    -- Check for decimal points in whole text. Prevent adding more if one exists
    -- At the same time, ensure input is only digits
    if self.valuetype == 'number' then
        if string.match(self.text, "[%.]+") then
            decimal = string.match(t, "%d+") ~= nil
        else
            decimal = string.match(t, "[%d%.]+") ~= nil
        end

    -- Check that input is letters only
    elseif self.valuetype == 'letters' then
        return string.match(t, "%a+") ~= nil
    else
        return true
    end

    -- Check for maximum string length
    if string.len(self.text .. t) > self.max_length and self.max_length > 0 then
        length = false
    end

    return decimal and letters and length and digit
end


function TextBox:draw()
    --local temp = lg.newCanvas(self.size.x, self.size.y)
    local absPos = self.parent:absolute(self.pos)
    lg.setCanvas(CANVAS_UI_STATIC)

    local box_height = self.size.y
    local padding = 2.5
    lg.setColor(1, 1, 1, 1)

    if self.label ~= nil then
        box_height = self.size.y / 2
        lg.print(self.label, absPos.x + self.padding, absPos.y + self.padding)
    end

    -- Draw main box
    lg.rectangle('fill', absPos.x, absPos.y + box_height, self.box_size.x, box_height)

    -- Draw highlight
    if self.state then
        lg.setColor(1, .5, .5, 1)
        lg.rectangle('line', absPos.x, absPos.y + box_height, self.box_size.x, box_height)
    end

    -- Print contents
    lg.setColor(0, 0, 0, 1)
    lg.print(self.text, absPos.x + self.padding, absPos.y + self.padding + box_height)

    lg.setColor(1, 1, 1, 1)
    lg.setCanvas()
    --lg.draw(temp, absPos.x, absPos.y)
end


-- Maybe one day
Slider = Element:new()

function Slider:new(o, inPos, inID, inSize, actionFunc, inIcon)
    -- TODO: Slider object inheriting from button
    return
end

