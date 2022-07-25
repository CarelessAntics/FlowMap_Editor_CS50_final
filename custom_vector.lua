
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

-- Rotate 2D vector
function vRot(v, a)
    -- Convert angle to radians
    a = a * math.pi * 2
    -- 2D rotation matrix from google
    x = v.x * math.cos(a) - v.y * math.sin(a)
    y = v.x * math.sin(a) + v.y * math.cos(a)

    return vec(x, y)
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
    length = vLength(vector)
    if length ~= 0 then
        return vector / length
    else
        return vector
    end
end

-- Returns a wrapped around vector
function wrapped(inVec, in_width, in_height, in_size)
    
    -- Initialize output components
    local outX = inVec.x
    local outY = inVec.y

    -- Check if a vector is out of bounds, include possible size for brushes etc
    if inVec.x > in_width - in_size then
        outX = inVec.x - in_width
    elseif inVec.x < in_size then
        outX = inVec.x + in_width
    end

    if inVec.y > in_height - in_size then
        outY = inVec.y - in_height
    elseif inVec.y < in_size then
        outY = inVec.y + in_height
    end

    -- if new vector is identical to input, no wraparound has happened. Return a garbage vector so that there's no double draw
    if inVec == vec(outX, outY) then
        return vec(-100000, -100000)
    else
        return vec(outX, outY)
    end
end

-- Convert vector from window to canvas space
-- Meaning the location is between 0 and canvas size, while the window itself has a padding around the canvas
function toCanvasSpace(v)
    return v - PADDING_HALF
end

-- And vice versa
function toWindowSpace(v)
    return v + PADDING_HALF
end

function vec(xIn, yIn)
    V = {x=xIn, y=yIn}

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