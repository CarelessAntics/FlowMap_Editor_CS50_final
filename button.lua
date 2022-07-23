
function initButton(inPos, inID, inSize)
    local Button = {    pos = inPos,
                        size = inSize,
                        ID = inID,
                        state = false,
                        graphics = "",
                        btn_type = "rect"
                    }

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

    return Button
end