-- TODO: Frame
-- TODO: Contains multiple objects with positions relative to Frame
-- TODO: Frame can be moved
-- TODO: Ordering objects inside frame

function init_frame(inPos, bBox0, bBox1)

    local Frame = {   content = {},
                pos = inPos,
                bBox = {bBox0, bBox1},
                dimensions = {},
                align = 'left' -- Where to align frame elements 'left', 'right', 'top', 'bottom', 'fill'
            }

    local dims = bBox0 - bBox1
    Frame.dimensions = {width = math.abs(dims.x), math.abs(dims.y)}

    -- TODO: Add an element into frame and position it accordingly
    function Frame:addElement()
        return
    end

    function Frame:drawDebug()
        return
    end

    return Frame
end