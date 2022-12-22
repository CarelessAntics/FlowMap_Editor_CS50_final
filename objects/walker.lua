
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
    o.alpha_transp = 1
    o.alpha = li.newImageData("assets/alphas/1.png")

    return o
end

-- TODO: Fix wrapping
-- TODO: Set properties
function Walker:walk()
    local modifier_rot = lm.noise(self.seed) * 2 - 1
    local modifier_size = lm.noise(self.seed * 2) * 2 - 1

    --self.size = clamp(30, 90, self.size + modifier_size * 1)
    --self.dir = vRot(self.dir, self.rot_rate * modifier_rot)

    -- Constrain direction vector
    --[[self.dir.y = math.abs(self.dir.y)
    self.dir.x = clamp(-.7, .7, self.dir.x)
    self.dir = normalize(self.dir)]]

    self.dir = normalize(vec(modifier_rot, 1)) * self.rot_rate

    local velocity = self.dir * self.vel
    self.pos = self.pos + velocity
    local draw_size = self.size * (1 / CANVAS_SCALE) 
    --local OOB_x = (self.pos.x > -draw_size and self.pos.x < SIZE_OUT.x * CANVAS_SCALE + draw_size)
    --local OOB_y = (self.pos.y > -draw_size and self.pos.y < SIZE_OUT.y * CANVAS_SCALE + draw_size)

    local col = toZeroOne(self.dir)

    -- Differentiate between being slightly or completely out of bounds
    local oob_wrap = isOutOfBounds(self.pos, SIZE_OUT.x, SIZE_OUT.y, draw_size)
    local oob_completely = isOutOfBounds(self.pos, SIZE_OUT.x, SIZE_OUT.y, -draw_size)

    -- If slightly oob, just draw some wrapped brushes
    if oob_wrap.x then
        local pos_wrap_x = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, draw_size, 'x')
        self:drawToImgData(pos_wrap_x, draw_size, col)
        self.pos = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, -draw_size, 'x')
    end
    if oob_wrap.y then
        local pos_wrap_y = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, draw_size, 'y')
        self:drawToImgData(pos_wrap_y, draw_size, col)
        self.pos = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, -draw_size, 'y')
    end
    if oob_wrap.x and oob_wrap.y then
        local pos_wrap_both = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, draw_size, 'both')
        self:drawToImgData(pos_wrap_both, draw_size, col)
        self.pos = wrapped(self.pos, SIZE_OUT.x, SIZE_OUT.y, -draw_size, 'both')
    end

    self.seed = self.seed + .01
end


--[[
CS50 final project video script

INTRODUCTION
-   Who I am, what I do, why I took the course

-   Why make this
    -   Short description of shaders, flow shader in particular
        - Shaders are pieces of code that manipulate pixels on screen, or vertices in a 3D mesh
        - A flow shader takes in a vector map, and pushes pixels around in a texture to create the illusion of continuous flow
        - A vector map is a regular image, with 2D vectors encoded to red and green channels

    -   When making a vector map from noise, you get unnatural looking results
        - [Demonstration file perlin]

-   Show off features
    -   Drawing
    -   filters
    -   UI system
end]]--