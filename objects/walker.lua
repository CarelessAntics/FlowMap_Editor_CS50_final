
--[[walker_params = {   pos = vec(0),
                    dir = vec(0, 1),
                    vel = 2,
                    size = size,
                    rot_rate = 0.003,
                    seed = math.random(32000),
                    dead = false,
                    brush = nil
                }]]

walker_params = {   vel = 10,
                    rot_rate = 0.5,
                    seed = math.random(32000),
                    dead = false,
            }

-- Inherit from Brush
Walker = Brush:new(walker_params)

function Walker:new(o, inPos, inSize)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Instance parameters
    o.pos = inPos
    o.size = inSize
    o.seed = math.random(32000)
    o.dead = false

    return o
end


function Walker:walk()
    local modifier_rot = lm.noise(self.seed) * 2 - 1
    local modifier_size = lm.noise(self.seed * 2) * 2 - 1

    self.size = clamp(30, 90, self.size + modifier_size * 1)
    --self.dir = vRot(self.dir, self.rot_rate * modifier_rot)

    -- Constrain direction vector
    --[[self.dir.y = math.abs(self.dir.y)
    self.dir.x = clamp(-.7, .7, self.dir.x)
    self.dir = normalize(self.dir)]]

    self.dir = normalize(vec(modifier_rot, 1) * self.rot_rate)

    velocity = vScalarMult(self.dir, self.vel)
    self.pos = vAdd(self.pos, velocity)
    local draw_size = self.size * (1 / CANVAS_SCALE) * 2
    local OOB_x = (self.pos.x > -draw_size and self.pos.x < SIZE_OUT.x * CANVAS_SCALE + draw_size)
    local OOB_y = (self.pos.y > -draw_size and self.pos.y < SIZE_OUT.y * CANVAS_SCALE + draw_size)

    if OOB_x and OOB_y then
        self.dead = false
    else
        self.pos = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, self.size)
        self.dead = true
    end

    self.seed = self.seed + .01
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