-----------------------------------------
-- 
-- Vector Arithmetic
-- 
-----------------------------------------

function vAdd(a, b)
    return vec(a.x + b.x, a.y + b.y)
end

function vSub(a, b)
    return vec(a.x - b.x, a.y - b.y)
end

function vMul(a, b)
    return vec(a.x * b.x, a.y * b.y)
end

function vDiv(a, b)
    return vec(a.x / b.x, a.y / b.y)
end

function vScalarMult(a, scalar)
    return vec(a.x * scalar, a.y * scalar)
end

function vScalarDiv(a, scalar)
    return vec(a.x / scalar, a.y / scalar)
end

-----------------------------------------
-- 
-- Other operations and utilities
-- 
-----------------------------------------

-- Rotate 2D vector
function vRot(v, a)
    -- Convert angle to radians
    a = a * math.pi * 2
    -- 2D rotation matrix from google
    local x = v.x * math.cos(a) - v.y * math.sin(a)
    local y = v.x * math.sin(a) + v.y * math.cos(a)

    return vec(x, y)
end

-- Return angle in radians between 2 vectors
function vAngle(a, b)
    local angle = math.atan2(a.y, a.x) - math.atan2(b.y, b.x)
    return angle or 0
end

-- Return angle between vector and a reference angle, which is hard coded to (0, 1)
function vSetAngle(direction)
    local angle = vAngle(direction, vec(0,-1))
    return angle
end

-- Fast 90degree rotation, swap coords and negate other
function vRot_90Deg(v)
    return vec(v.y, -v.x)
end

-- Dot product
function vDot(a, b)
    return a.x * b.x + a.y * b.y
end


-- Returns length of vector
function vLength(vector)
    return math.sqrt(vDot(vector, vector))
end


-- Return a vector of length 1
function normalize(vector)
    local length = vLength(vector)
    if length ~= 0 then
        return vector / length
    else
        return vector
    end
end

-- Copies a vector
function vCopy(v)
    return vec(v.x, v.y)
end

-- Returns a wrapped around vector
function wrapped(inVec, in_width, in_height, in_size, axis)
    
    -- Initialize output components
    local outX = inVec.x
    local outY = inVec.y

    -- Check if a vector is out of bounds, include possible size for brushes etc
    if axis == 'x' or axis == 'both' then
        if inVec.x > in_width - in_size then
            outX = inVec.x - in_width
        elseif inVec.x < in_size then
            outX = inVec.x + in_width
        end
    end

    if axis == 'y' or axis == 'both' then
        if inVec.y > in_height - in_size then
            outY = inVec.y - in_height
        elseif inVec.y < in_size then
            outY = inVec.y + in_height
        end
    end

    -- if new vector is identical to input, no wraparound has happened. Return a garbage vector so that there's no double draw
    if inVec == vec(outX, outY) then
        return vec(-100000, -100000)
    else
        return vec(outX, outY)
    end
end

-- return vector on which axis the vector is out of bounds
function isOutOfBounds(inVec, in_width, in_height, in_size)
    
    -- Initialize output components
    local oobX = false
    local oobY = false

    -- Check if a vector is out of bounds, include possible size for brushes etc
    if inVec.x > in_width - in_size or inVec.x < in_size then
        oobX = true
    end

    if inVec.y > in_height - in_size or inVec.y < in_size then
        oobY = true
    end

    return vec(oobX, oobY)
end

-- Is input vector within a rectangle
function isHitRect(inVec, bBox0, bBox1)
    if (inVec.x > bBox0.x and inVec.x < bBox1.x) and (inVec.y > bBox0.y and inVec.y < bBox1.y) then
        return true
    else
        return false
    end
end

-- Is input vector within a circle
function isHitCirc(inVec, pos, r)
    local distance = vLength(inVec - pos)
    if distance < r then
        return true
    else 
        return false
    end
end


-- Convert vector from window to canvas space
-- Meaning the location is between 0 and canvas size, while the window itself has a padding around the canvas
function toCanvasSpace(v)
    return (v - vec(PADDING_X.x, PADDING_Y.x)) * (1 / CANVAS_SCALE)
end

-- And vice versa
function toWindowSpace(v)
    return (v * CANVAS_SCALE) + vec(PADDING_X.x, PADDING_Y.x)
end


-- Actual vector Object function
function vec(xIn, yIn)
    local V
    if yIn == nil then
        V = {x=xIn, y=xIn}
    else
        V = {x=xIn, y=yIn}
    end


    -- Metatable. Define functions for +-*/ etc operators
    local mt = {
        -- Addition
        __add = function (l, r)
            return vAdd(l, r)
        end,
        -- Subtraction
        __sub = function (l, r)
            return vSub(l, r)
        end,
        -- Multiplication, switch between scalar and vector multiplication based on operands
        __mul = function (l, r)
            if type(l) == "number" or type(r) == "number" then
                if type(l) == "number" then
                    return vScalarMult(r, l)
                else
                    return vScalarMult(l, r)
                end
            else
                return vMul(l, r)
            end
        end,
        -- Division, scalar and otherwise
        __div = function (l, r)
            if type(r) == "number" then
                return vScalarDiv(l, r)
            elseif type(l) == "number" then
                return vScalarDiv(r, l)
            else
                return vDiv(l, r)
            end
        end,
        -- Equals
        __eq = function(l, r)
            return (l.x == r.x) and (l.y == r.y)
        end,
        -- Less/greater than, compares vector lengths
        __lt = function(l, r)
            return vLength(l) < vLength(r)
        end,
        __gt = function(l, r)
            return vLength(l) > vLength(r)
        end

    }

    setmetatable(V, mt)
    return V
end