
Element = {  pos = vec(0), -- Position will be top-left corner
            size = vec(1),
            id = nil,
            type = 'button', -- 'button, dropdown'
            state = false,
            parent = nil
        }


function Element:new(o)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    return o
end

button_params = {action = nil, graphics = nil}
Button = Element:new(button_params)


function Button:new(o, inID, inSize, actionFunc, inIcon)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Initialize instance params
    o.pos = vec(0)
    o.size = inSize
    o.id = inID
    o.type = 'button'
    o.state = false
    o.graphics = lg.newImage(inIcon or "assets/icons/default.png")
    o.action = actionFunc -- function: what happens when button is activated
    return o
end


dropdown_params = {content = nil, graphics = nil}
Dropdown = Element:new(dropdown_params)

function Dropdown:new(o, inID, inSize, inIcon)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Initialize instance params
    o.pos = vec(0)
    o.size = inSize
    o.id = inID
    o.type = 'dropdown'
    o.state = false
    o.graphics = lg.newImage(inIcon or "assets/icons/default.png")
    o.content = nil -- Contained frame
    o.parent = nil
    return o
end

function Dropdown:setContent(inContent)
    self.content = inContent
    self.content.state = false
end

function Dropdown:toggleContent()
    self:setContentLocation()
    self.state = not self.state
    self.content.state = not self.content.state
end

function Dropdown:setContentLocation()
    if self.parent == nil then
        return
    end

    local window_w, window_h = lg.getDimensions()
    if self.parent.align == 'right' then
        self.content:updateAbsolutePos(self.parent.bBox[1].x - self.content.dimensions.x, window_h)
    end
end

textbox_params = {text = ""}
TextBox = Element:new(textbox_params)

function TextBox:new(o, inID, inSize)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    local char_dims = vec(10)

    o.pos = vec(SIZE_OUT)
    o.size = inSize * char_dims
    o.id = inID
    o.type = 'textbox'
    o.state = false -- writing or not
    o.text = ""
    return o
end


function TextBox:backSpace()
    if #self.text.len > 0 then
        self.text = self.text:sub(1, -2)
    end
end


function TextBox:draw(absPos)
    local temp = lg.newCanvas(self.size.x, self.size.y)
    lg.setCanvas(temp)

    lg.setColor(1, 1, 1, 1)
    lg.rectangle('fill', 0,0, self.size.x, self.size.y)

    if self.state then
        lg.setColor(1, 0, 1, 1)
        lg.rectangle('line', 0,0, self.size.x, self.size.y)
    end

    lg.setColor(0, 0, 0, 1)
    lg.print(self.text, 2.5, 2.5)

    lg.setColor(1, 1, 1, 1)
    lg.setCanvas()

    lg.draw(temp, absPos.x, absPos.y)
end


Slider = Element:new()

function Slider:new(o, inPos, inID, inSize, actionFunc, inIcon)
    -- TODO: Slider object inheriting from button
    return
end