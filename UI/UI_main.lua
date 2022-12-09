
-- Main UI structure
UI = {content = {}, frames = {}, properties = {}}


function UI:new(o)
    local o = o or {}
    local mt = {__index = self}
    setmetatable(o, mt)

    o.content = {}
    o.frames = {}
    o.properties = {}

    return o
end


-- Initialize main UI
function UI:init()
    window_w, window_h = lg.getDimensions()

    local button_size = 60

    -----------------------------------------
    -- Left sidebar content
    -----------------------------------------

    -- Top level dropdowns
    dd_filters = Dropdown:new(nil, "afilters_dropdown", vec(button_size), vec(0, 0))
    dd_drawing = Dropdown:new(nil, "drawing_dropdown", vec(button_size), vec(2, 0))

    -- Frames under dropdowns
    frame_filters = Frame:new(nil, 'frame_filters', vec(0), 0, 'left')
    frame_drawing = Frame:new(nil, 'frame_drawing', vec(0), 0, 'left')

    -- Elements for dd_filters
    btn_normalize = Button:new(nil, "filter_normalize", vec(button_size), filterNormalize, vec(2, 0))

    btn_blur = Button:new(nil, "filter_blur", vec(button_size), filterBoxBlur, vec(4, 0))
    btn_blur:setProperties('f_blur_properties', 'left', self,
                            {label = "Blur Radius", id = "p_blur_rad", value = 10, size = vec(4, 1)},
                            {label = "Blur Samples", id = "p_blur_samples", value = 4, size = vec(4, 1)})

    -- Add Elements to frame_filters
    frame_filters:addElement(btn_normalize, 'bottom')
    frame_filters:addElement(btn_blur, 'bottom')

    -- Elements for dd_drawing
    btn_mode_draw = Button:new(nil, "filter_normalize2", vec(button_size), function() mode_DRAW = true mode_RANDOMWALK = false end)
    btn_mode_draw:setProperties('f_brush_properties', 'left', self, 
                                {label = "Brush Radius", id = "p_brush_rad", value = 50, size = vec(4, 1)},
                                {label = "Brush Hardness", id = "p_brush_hard", value = .5, size = vec(4, 1)},
                                {label = "Lazy Radius", id = "p_brush_lazy", value = 100, size = vec(4, 1)},
                                {label = "Spacing", id = "p_brush_spacing", value = 10, size = vec(4, 1)})

    btn_mode_walker = Button:new(nil, "filter_blur2", vec(button_size), function() mode_DRAW = false mode_RANDOMWALK = true end)
    textbox_test = TextBox:new(nil, "text_test", 'number', vec(4, 1), "label123")
    --textbox_test2 = TextBox:new(nil, "text_test2", 'number', vec(4, 1), "labeladdasdsd")

    -- Add Elements to frame_drawing
    frame_drawing:addElement(btn_mode_walker, 'bottom')
    frame_drawing:addElement(btn_mode_draw, 'bottom')
    frame_drawing:addElement(textbox_test, 'bottom')
    --frame_drawing:addElement(textbox_test2, 'bottom')

    -- Insert frames to dropdowns
    dd_filters:setContent(frame_filters)
    dd_drawing:setContent(frame_drawing)

    -----------------------------------------
    -- Right sidebar content
    -----------------------------------------

    -- TODO: File load
    -- TODO: Open save location

    dd_fileops = Dropdown:new(nil, "fileops_dropdown", vec(button_size), vec(0,0))

    frame_fileops = Frame:new(nil, 'frame_fileops', vec(0), 0, 'right')

    btn_save = Button:new(nil, 'fileops_save', vec(button_size), saveScreen, vec(0,1))
    btn_save:setProperties('fileops_save_properties', 'right', self, 
                            {label="File Name", id="p_save_filename", value="", size=vec(10, 1)})

    btn_open = Button:new(nil, 'fileops_open', vec(button_size), saveScreen, vec(2,1))
    btn_open:setProperties('fileops_open_properties', 'right', self, 
                            {label="File Name", id="p_open_filename", value="", size=vec(10, 1)})

    frame_fileops:addElement(btn_save, 'bottom')
    frame_fileops:addElement(btn_open, 'bottom')

    dd_fileops:setContent(frame_fileops)

    -----------------------------------------
    -- Complete sidebars
    -----------------------------------------

    sidebar_right = Frame:new(nil, 'f_side_right', vec(100, 0), 0, 'right')
    sidebar_left = Frame:new(nil, 'f_side_left', vec(50, 0), 0, 'left')

    self.content[1] = sidebar_right
    self.content[1]:addElement(dd_filters, 'bottom')
    self.content[1]:addElement(dd_drawing, 'bottom')

    self.content[2] = sidebar_left
    self.content[2]:addElement(dd_fileops, 'bottom')

    --self.frames[#self.frames + 1] = filters_frame
    --self.frames[#self.frames + 1] = drawing_frame
    --self.frames[#self.frames + 1] = sidebar_right
end


function UI:drawFrames()
    ICON_BATCH:clear()
    lg.setCanvas(CANVAS_UI_STATIC)
    lg.clear(0,0,0,0)
    lg.setCanvas()
    for _, frame in pairs(self.frames) do
        frame:drawDebug()
        frame:draw()
    end
end


-- Update the list of visible frames recursively
function UI:updateFrames()
    -- Initialize a temporary empty table
    local frames = {}
    
    -- Search function to go through the UI tree and add any Frame that has state = true to temp table
    local function frameSearch(inFrame)
        local next = next
        -- Check if a frame has any children
        if next(inFrame.contents) ~= nil then

            -- Cycle through the children's subframes, if any exist
            for _, element in pairs(inFrame.contents) do
                if element.subframe ~= nil then
                    frameSearch(element.subframe)
                end
            end

            -- Append temp table
            if inFrame.state then
                frames[inFrame.id] = inFrame
            end
        end
    end

    -- Assuming all top level items in UI tree are frames
    for _, item in pairs(self.content) do
        frameSearch(item)
    end
    
    self.frames = frames
end
