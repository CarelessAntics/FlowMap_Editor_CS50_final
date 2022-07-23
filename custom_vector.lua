
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

-- Convert vector from window to canvas space
function toCanvasSpace(v)
    return vec(v.x - PADDING_HALF, v.y - PADDING_HALF)
end

-- And vice versa
function toWindowSpace(v)
    return vec(v.x + PADDING_HALF, v.y + PADDING_HALF)
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