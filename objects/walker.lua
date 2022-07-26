function createWalker(inPos)
    local Walker = {  pos = inPos,
                dir = vec(0, 1),
                vel = 2,
                size = 50,
                rot_rate = 0.003,
                seed = math.random(32000),
                dead = false,
            }

    function Walker:walk()
        modifier_rot = lm.noise(self.seed) * 2 - 1
        modifier_size = lm.noise(self.seed * 2) * 2 - 1

        self.size = clamp(30, 90, self.size + modifier_size * 1)
        self.dir = vRot(self.dir, self.rot_rate * modifier_rot)

        -- Constrain direction vector
        self.dir.y = math.abs(self.dir.y)
        self.dir.x = clamp(-.7, .7, self.dir.x)
        self.dir = normalize(self.dir)

        velocity = vScalarMult(self.dir, self.vel)
        self.pos = vAdd(self.pos, velocity)
        --self.pos.x = (self.pos.x % WIDTH)
        --self.pos.y = (self.pos.y % (HEIGHT))
        --if (self.pos.x > WIDTH + self.size) or (self.pos.x < -self.size) or (self.pos.y > HEIGHT + self.size) then

        --Wraparound on x
        if self.pos.x > WIDTH + self.size/2 then
            self.pos.x = -self.size/2
        elseif self.pos.x < -self.size/2 then
            self.pos.x = WIDTH + self.size/2
        end

        --Wraparound on y
        if self.pos.y > HEIGHT + self.size/2 then
            if WALKERS_RESPAWN then
                self.pos.y = -self.size/2
            else
                self.dead = true
            end
        elseif self.pos.y < -self.size/2 then
            self.pos.y = WIDTH + self.size/2
        end

        self.seed = self.seed + .001
    end

    function Walker:draw()
        lg.setCanvas(CANVAS_IMAGE)
        lg.setColor(self.dir.x*0.5+0.5, self.dir.y*0.5+0.5, 0)
        lg.circle("fill", self.pos.x, self.pos.y, self.size, 64)
        lg.setCanvas()
    end

    return Walker
end

--[[
function clamp(min, max, val)
    if val > max then
        return max
    elseif val < min then
        return min
    else 
        return val
    end
end]]--