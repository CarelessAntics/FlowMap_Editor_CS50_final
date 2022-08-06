
--- Clamps input between min and max
---@param min number
---@param max number
---@param val number
function clamp(min, max, val)
    return math.max(min, math.min(max, val))
end

--- Smoothstep function. Smoothly fits value between 0...1 based on val. edge0 determines where 0 starts and edge1 where 1 ends
---@param edge0 number
---@param edge1 number
---@param val number
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

--- Linear interpolation. Linearly interpolates (duh) value between a...b based on value t
---@param a number or table
---@param b number or table
---@param t number
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

--- Converts value n from -1...1 to 0...1
---@param n number or table
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

--- Converts value n from 0...1 to -1...1
---@param n number or table
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

-- Update Global variable marking which textbox is currently selected
function selectTextBox(inTextBox)
    if TEXTBOX_SELECTED ~= nil then
        TEXTBOX_SELECTED.state = false
    end

    -- Reset selection with a nil input
    if inTextBox == nil then
        TEXTBOX_SELECTED = nil
        return
    end

    inTextBox.state = true
    TEXTBOX_SELECTED = inTextBox
end

-- A table concatenation function which may or may not work as intended
function table_concat(a, b)
    local out = {table.unpack(a)}
    for _, v in pairs(b) do
        table.insert(out, v)
    end
    return out
end

-- Print out nested tables. Breaks into infinite loop if a table has a reference to its parent
function deepPrint(tbl)
    local function helper(tbl)
        if tbl == nil then return 'nil' end
        local str = "{ "
        for k, v in pairs(tbl) do
            if type(v) == 'table' then
                local newstr = helper(v)
                str = str .. (newstr or 'nil')
            elseif v == nil then
                str = str .. 'nil' .. ' '
            else
                str = str .. tostring(v) .. ' '
            end
        end
        return str .. " }"
    end
    print(helper(tbl))
end