
-- Clamp
function clamp(min, max, val)
    return math.max(min, math.min(max, val))
end

-- Smoothstep
function smoothStep(edge0, edge1, val)
    if val < edge0 then
        return 0
    elseif val >= edge1 then
        return 1
    else
        val = clamp(0, 1, (val - edge0) / (edge1 - edge0))
        return val * val * (3 - 2 * val)
    end
end

-- Linear interpolation
function lerp(a, b, t)
    -- If a and b are vectors
    if type(a) == "table" and type(b) == "table" then
        local outX = lerp(a.x, b.x, t) 
        local outY = lerp(a.y, b.y, t)
        return vec(outX, outY)
    else
        return a + (b - a) * t
    end
end

-- convert from -1...1 to 0...1
function toZeroOne(n)
    -- If vectors
    if type(n) == "table" then
        local outX = toZeroOne(n.x) 
        local outY = toZeroOne(n.y)
        return vec(outX, outY)
    else
        return n * .5 + .5
    end
end

-- convert from 0...1 to -1...1
function toNegOneOne(n)
    -- If vectors
    if type(n) == "table" then
        local outX = toZeroOne(n.x) 
        local outY = toZeroOne(n.y)
        return vec(outX, outY)
    else
        return n * 2 + 1
    end
end