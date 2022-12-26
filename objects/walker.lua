
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
                    count = 0,
                    size_range = {1, 10},
                    turn_range = 180,
                    turn_rate = .1,
                    parent_system = nil
            }

-- A single random walker. Inherit from Brush
Walker = Brush:new(walker_params)

function Walker:new(o, inPos, inSize, parent)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    -- Instance parameters
    o.pos = toWindowSpace(inPos)
    o.size = inSize
    o.seed = math.random(32000)
    o.dead = false
    o.parent = parent

    return o
end

-- A parent object to house walkers and their parameters
WalkerSystem = {count = 0, 
                size_range = {1, 10}, 
                turn_range = 180, 
                turn_rate = .1, -- How much the walker turns per tick
                walkers = {}, 
                alpha_path = "",
                alpha_transp = 1,
                change_rate = .1 -- The rate of change for walker radius and turning
            }

function WalkerSystem:new(o)
    o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    o.count = 0
    o.size_range = {1, 10}
    o.turn_range = 180
    o.turn_rate = .1
    o.alpha_path = "assets/alphas/1.png"
    o.change_rate = .1

    return o
end



function WalkerSystem:createWalkers()
    self.walkers = {} -- Global table of all walkers
    self:updateWalkerFromProperties(UI_main)
    local brush_size = math.random(self.size_range[1], self.size_range[2])
    for i = 1, self.count do
        --WALKERS[i] = Walker:new(nil, vec(math.random(SIZE_OUT.x), math.random(SIZE_OUT.y)), 50)
        self.walkers[i] = Walker:new(nil, 
                                vec(math.random(SIZE_OUT.x - 50 * 2) + 50, 
                                math.random(SIZE_OUT.y - 50 * 2) + 50), 
                                math.random(self.size_range[1], self.size_range[2]), 
                                self)
        self.walkers[i]:updateWalkerAlpha()
    end
end

-- Get values from properties
function WalkerSystem:updateWalkerFromProperties(UI_ref)
    local properties_id = 'random_walker_properties'
    --print(UI_ref.properties)
    local properties = UI_ref.properties[properties_id].contents

    -- Properties:
    --  count
    --  size range
    --  turn range
    --  turn rate

    local range_count = {min = 1, max = 50}
    local range_size = {min = 1, max = 100}
    local range_turn = {min = 1, max = 360}
    local range_turn_rate = {min = .01, max = 999}
    local range_change_rate = {min = .1, max = 10}
    local range_spacing = {min = .01, max = 999}

    local property_sizemin = properties['p_walker_rad_min']:getValueNumber()
    local property_sizemax = properties['p_walker_rad_max']:getValueNumber()
    
    self.size_range = {clamp(range_size.min, range_size.max, properties['p_walker_rad_min']:getValueNumber()),
                       clamp(range_size.min, range_size.max, properties['p_walker_rad_max']:getValueNumber())}
    self.count = clamp(range_count.min, range_count.max, properties['p_walker_count']:getValueNumber())
    self.turn_range = clamp(range_turn.min, range_turn.max, properties['p_walker_turn_range']:getValueNumber())
    self.turn_rate = clamp(range_turn_rate.min, range_turn_rate.max, properties['p_walker_turn_rate']:getValueNumber())
    self.change_rate = clamp(range_turn_rate.min, range_turn_rate.max, properties['p_walker_change_rate']:getValueNumber())
    self.vel = clamp(range_spacing.min, range_spacing.max, properties['p_walker_spacing']:getValueNumber())
    self.alpha_transp = clamp(range_spacing.min, range_spacing.max, properties['p_walker_alpha_transp']:getValueNumber())
end

function WalkerSystem:update()

    for _, walker in pairs(self.walkers) do
        if walker ~= nil then
            walker:walk()
            walker:draw()
        end
    end
end


function Walker:walk()
    -- Get noise value based on a random seed unique to each 
    -- Use them as scalars to modify direction and size change
    local modifier_rot = toNegOneOne(lm.noise(self.seed))
    local modifier_size = toNegOneOne(lm.noise(self.seed * 2))

    -- Rotate walker direction, and constrain it to a cone aligned to a cardinal direction
    -- Currently the direction is down, but could be adapted to accept a user given direction
    local turned_dir = vRot(self.dir, (self.parent.turn_rate / TWOPI) * lt.getDelta() * modifier_rot)
    if not (((math.abs(vAngle(turned_dir, vec(0,1)))) / PI * 180  <= self.parent.turn_range / 2) or self.parent.turn_range >= 360) then
        turned_dir = self.dir
    end

    self.size = clamp(self.parent.size_range[1], self.parent.size_range[2], self.size + modifier_size * 1)
    self.dir = turned_dir

    self.alpha_transp = self.parent.alpha_transp 

    if BRUSH_ALIGN.value then
        self:alignAlpha()
    end
    if BRUSH_ROTATE.value then
        self:rotateAlpha()
    end

    -- Apply velocity along direction. multiply by spacing property and a 5th of brush radius 
    -- to keep a smooth draw regardless of variable brush size
    local velocity = self.dir * (self.size / 5) * self.parent.vel
    self.pos = self.pos + velocity
    local draw_size = self.size * (1 / CANVAS_SCALE) 

    local col = toZeroOne(self.dir)

    -- Get out of bounds axis/axes, and make wrap vectors for all cases
    local oob_wrap = isOutOfBounds(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, draw_size)
    local pos_wrap_x = wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, draw_size, 'x')
    local pos_wrap_y = wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, draw_size, 'y')
    local pos_wrap_both = wrapped(toCanvasSpace(self.pos), SIZE_OUT.x, SIZE_OUT.y, draw_size, 'both')
    
    if oob_wrap.x and not oob_wrap.y then
        self.pos = toWindowSpace(pos_wrap_x)
    elseif not oob_wrap.x and oob_wrap.y then
        self.pos = toWindowSpace(pos_wrap_y)
    elseif oob_wrap.x and oob_wrap.y then
        self.pos = toWindowSpace(pos_wrap_both)
    end

    -- Increment seed, which controls the rate of change in walkers
    self.seed = self.seed + self.parent.change_rate * .01
end

function Walker:updateWalkerAlpha()
    self.alpha_original = li.newImageData(self.parent.alpha_path)
    self.alpha = li.newImageData(self.parent.alpha_path)
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
        - The tool allows you to paint flowmaps by hand, or generatively using random walkers, and preview the results in real time

-   Show off features
    -   Drawing
    -   Random walkers
    -   filters
    -   Fundamental parts of the tool were made from ground up, such as
        - Vector Math library, which allows to use linear algebra that is used in pretty much every aspect of this project 
        - UI system as a whole
            - Frame objects, and the elements it contains, such as 
                -buttons
                -text input fields
                -checkboxes
                -dropdown menus
                -property menus
end]]--