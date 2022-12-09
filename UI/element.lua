

-- Base UI element
Element = {  pos = vec(0), -- Position will be top-left corner
            size = vec(1),
            id = nil,
            type = 'button', -- 'button, dropdown'
            state = false,
            parent = nil,
            tooltip = "",
            subframe = nil,
            sprite = nil
        }


function Element:new(o)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    return o
end


-- Toggles the subframe on and off. Logic taken from dropdowns and put into the base Element Class
function Element:toggleSubFrame()
    -- Update the location with every toggle
    self:setSubFrameLocation()

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
end


-- Move content frame relative to current location
function Element:setSubFrameLocation()
    if self.parent == nil then
        return
    end

    local window_w, window_h = lg.getDimensions()
    --self.subframe:updateAbsolutePos(self.parent.bBox[1].x,self.parent.bBox[1].y, self.subframe.dimensions.x, self.subframe.dimensions.y)
    self.subframe:updateAbsolutePos()
    --[[if self.subframe.align == 'right' then
        self.subframe:updateAbsolutePos(self.bBox[1].x,0)
    elseif self.subframe.align == 'left' then
        self.subframe:updateAbsolutePos(self.bBox[1].x,0)
    end]]
end


-- Create properties-frame for Element
-- Takes in a variable amount of tables with the following template:
-- {label = text, id = text, value = any, size = vector}
function Element:setProperties(frameId, alignment, UI_ref, ... )
    -- Create a new subframe and initialize its state to false
    self.subframe = Frame:new(nil, frameId, vec(0), 10, alignment)
    self.subframe.state = false
    self.subframe.parent = self.parent

    local arg = {...}

    for i, property in pairs(arg) do
        local newProperty
        -- o, inID, inValueType, inSize, inLabel, inFont
        if type(property.value) == 'number' then
            newProperty = TextBox:new(nil, property.id, 'number', property.size, property.label, nil)
            newProperty.text = tostring(property.value)

        elseif type(property.value) == 'string' then
            newProperty = TextBox:new(nil, property.id, 'string', property.size, property.label, nil)
            newProperty.text = tostring(property.value)

        else
            newProperty = TextBox:new(nil, property.id, 'number', property.size, property.label, nil)
            newProperty.text = "Something Went Wrong"
        end

        self.subframe:addElement(newProperty, 'bottom')
    end
    UI_ref.properties[frameId] = self.subframe
end

-----------------------------------------
-- 
-- Button object
--
-----------------------------------------

button_params = {action = nil, graphics = nil}
Button = Element:new(button_params)


function Button:new(o, inID, inSize, actionFunc, inSprite)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    inSprite = inSprite or vec(0, 7)

    -- Initialize instance params
    o.pos = vec(0)
    o.size = inSize
    o.id = inID
    o.type = 'button'
    o.state = false
    --o.graphics = vec(0)--lg.newImage(inIcon or "assets/icons/default.png")
    o.sprite = lg.newQuad(inSprite.x * 64, inSprite.y * 64, 64, 64, 512, 512)
    o.action = actionFunc -- function: what happens when button is activated
    return o
end


-----------------------------------------
-- 
-- Dropdown object
--
-----------------------------------------

dropdown_params = {graphics = nil}
Dropdown = Element:new(dropdown_params)


-- This could be deleted and merged to base Element at some point
function Dropdown:new(o, inID, inSize, inSprite)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    inSprite = inSprite or vec(0, 7)
    -- Initialize instance params
    o.pos = vec(0)
    o.size = inSize
    o.id = inID
    o.type = 'dropdown'
    o.state = false
    --o.graphics = lg.newImage(inIcon or "assets/icons/default.png")
    o.sprite = lg.newQuad(inSprite.x * 64, inSprite.y * 64, 64, 64, 512, 512)
    o.content = nil -- Contained frame
    o.parent = nil
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
-- TextBox object
--
-----------------------------------------

textbox_params = {text = "", label = "", valuetype = "", padding = 2.5, font = nil, box_size = vec(0)}
TextBox = Element:new(textbox_params)

-- Initialize textbox instance
function TextBox:new(o, inID, inValueType, inSize, inLabel, inFont)
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
    o.text = ""
    
    o.valuetype = inValueType or "any" -- 'number', 'letter' or 'any'
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
    if self.valuetype == 'number' then
        -- Check for decimal points in whole text. Prevent adding more if one exists
        if string.match(self.text, "[.]+") then
            return string.match(t, "%d+") ~= nil
        else
            return string.match(t, "%d?[.]?") ~= nil
        end
    elseif self.valuetype == 'letter' then
        return string.match(t, "%a+") ~= nil
    else
        return true
    end
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
        lg.setColor(1, 0, 1, 1)
        lg.rectangle('line', absPos.x, absPos.y + box_height, self.box_size.x, box_height)
    end

    -- Print contents
    lg.setColor(0, 0, 0, 1)
    lg.print(self.text, absPos.x + self.padding, absPos.y + self.padding + box_height)

    lg.setColor(1, 1, 1, 1)
    lg.setCanvas()
    --lg.draw(temp, absPos.x, absPos.y)
end


Slider = Element:new()

function Slider:new(o, inPos, inID, inSize, actionFunc, inIcon)
    -- TODO: Slider object inheriting from button
    return
end

