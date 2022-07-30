
Button = {  pos = vec(0), -- Position will be top-left corner
            size = 1,
            id = nil,
            type = 'button',
            state = false,
            graphics = nil,
            btn_shape = "rect",
            action = nil -- function: what happens when button is clicked
        }

function Button:new(o, inPos, inID, inSize, actionFunc, inIcon)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Initialize instance params
    o.pos = inPos
    o.size = inSize
    o.id = inID
    o.type = 'button'
    o.state = false
    o.graphics = lg.newImage(inIcon or "assets/icons/default.png")
    o.btn_shape = "rect"
    o.action = actionFunc -- function: what happens when button is clicked

    return o
end


function Button:isHitRect(inVec)
    if (inVec.x > self.pos.x or inVec.x < self.pos.x + self.size.x) or (inVec.y > self.pos.y or inVec.y < self.pos.y + self.size.y) then
        return true
    else
        return false
    end
end


function Button:isHitCirc(inVec)
    distance = vLength(inVec - self.pos)
    if distance < self.size then
        return true
    else 
        return false
    end
end


function Button:draw(inImgData)
    lg.setCanvas(CANVAS_UI)

    if self.btn_shape == "rect" then
        
    end

    lg.setCanvas()
end

Slider = Button:new()

function Slider:new(o, inPos, inID, inSize, actionFunc, inIcon)
-- TODO: Slider object inheriting from button
return
end