FRAME_PADDING = 1


-- Main UI structure
UI = {content = {}, frames = {}, properties = {}, elements = {}}


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

    local button_size = 50

    -----------------------------------------
    -- Left sidebar content
    -----------------------------------------

    -- Top level dropdowns
    dd_filters = Dropdown:new(nil, "afilters_dropdown", button_size, vec(0, 0), 'Various image processing filters')
    dd_drawing = Dropdown:new(nil, "drawing_dropdown", button_size, vec(6, 0), 'Vector Painting Tools')

    -- Frames under dropdowns
    frame_filters = Frame:new(nil, 'frame_filters', vec(0), FRAME_PADDING, 'right')
    frame_drawing = Frame:new(nil, 'frame_drawing', vec(0), FRAME_PADDING, 'right')

    -- Elements for dd_filters
    btn_normalize = Button:new(nil, "filter_normalize", button_size, filterNormalize, {self}, vec(2, 0), 'Normalize vectors')

    btn_blur = Button:new(nil, "filter_blur", button_size, filterBoxBlur, {self}, vec(4, 0), 'Box blur')
    btn_blur:setProperties('f_blur_properties', 'right', self,
                            {label = "Blur Radius", id = "p_blur_rad", value = 10, size = vec(4, 1)},
                            {label = "Blur Samples", id = "p_blur_samples", value = 4, size = vec(4, 1)})

    -- Add Elements to frame_filters
    frame_filters:addElement(btn_normalize, 'bottom', self)
    frame_filters:addElement(btn_blur, 'bottom', self)

    -- Elements for dd_drawing
    -- Button for drawing mode and properties
    btn_mode_draw = Button:new(nil, "brush_drawing", button_size, function() mode_DRAW = true mode_RANDOMWALK = false end, {}, vec(6, 0), 'Draw with a brush')
    btn_mode_draw:setProperties('brush_drawing_properties', 'right', self, 
                                {label = "Brush Radius", id = "p_brush_rad", value = 50, size = vec(4, 1)},
                                {label = "Brush Hardness", id = "p_brush_hard", value = 0, size = vec(4, 1)},
                                {label = "Lazy Radius", id = "p_brush_lazy", value = 100, size = vec(4, 1)},
                                {label = "Spacing", id = "p_brush_spacing", value = 10, size = vec(4, 1)},
                                {label = "Alpha", id = "p_brush_alpha_transp", value = 1, size = vec(4, 1)})

    -- Walker button and properties
    btn_mode_walker = Button:new(nil, "brush_walker_1", button_size, function() mode_DRAW = false mode_RANDOMWALK = true WALKERS_MAIN:createWalkers() end, {}, vec(4, 4), 'Random walkers')
    btn_mode_walker:setProperties('random_walker_properties', 'right', self, 
                                {label = "Walker Count", id = "p_walker_count", value = 5, size = vec(4, 1)},
                                {label_header = 'Walker size range', id = "walker_rad_header",
                                    {label = "Min", id = "p_walker_rad_min", value = 10, size = vec(4, 1)},
                                    {label = "Max", id = "p_walker_rad_max", value = 50, size = vec(4, 1)}},
                                {label = "Turn Range (deg)", id = "p_walker_turn_range", value = 180, size = vec(4, 1)},
                                {label = "Turn Rate (rad/s)", id = "p_walker_turn_rate", value = 1, size = vec(4, 1)},
                                {label = "Change Rate", id = "p_walker_change_rate", value = 1, size = vec(4, 1)},
                                {label = "Spacing", id = "p_walker_spacing", value = 1, size = vec(4, 1)},
                                {label = "Alpha", id = "p_walker_alpha_transp", value = 1, size = vec(4, 1)})
    --btn_wide_test = ButtonWide:new(nil, "wide_test", button_size, button_size, 'Test Label', nil, {}, vec(0, 2))
    --textbox_test = TextBox:new(nil, "text_test", 'number', nil, vec(4, 1), "label123")

    dd_alphas = Dropdown:new(nil, 'brush_alphas', button_size, vec(2, 4), 'Select brush alpha')
    frame_alphas = Frame:new(Frame:new(nil, 'frame_alphas', vec(0), FRAME_PADDING, 'right'))
    self:createAlphaButtons(frame_alphas, 8)

    dd_alphas:setContent(frame_alphas)

    chk_align = CheckBox:new(nil, "chk_align_to_dir", button_size, 'Align brush to direction', {BRUSH_ALIGN}, BRUSH_ALIGN.value, vec(0, 4))
    chk_rotate = CheckBox:new(nil, "chk_rotate_while_drawing", button_size, 'Rotate Brush', {BRUSH_ROTATE}, BRUSH_ROTATE.value, vec(0, 4))
    --textbox_test2 = TextBox:new(nil, "text_test2", 'number', vec(4, 1), "labeladdasdsd")

    -- Add Elements to frame_drawing
    frame_drawing:addElement(btn_mode_walker, 'bottom', self)
    frame_drawing:addElement(btn_mode_draw, 'bottom', self)
    frame_drawing:addElement(dd_alphas, 'bottom', self)
    --frame_drawing:addElement(btn_wide_test, 'bottom', self)
    --frame_drawing:addElement(textbox_test, 'bottom', self)
    frame_drawing:addElement(chk_align, 'bottom', self)
    frame_drawing:addElement(chk_rotate, 'bottom', self)
    --frame_drawing:addElement(textbox_test2, 'bottom')

    -- Insert frames to dropdowns
    dd_filters:setContent(frame_filters)
    dd_drawing:setContent(frame_drawing)

    -----------------------------------------
    -- File Operations
    -----------------------------------------

    -- TODO: File load
    -- TODO: Open save location

    dd_fileops = Dropdown:new(nil, "fileops_dropdown", button_size, vec(4,1), 'File operations')

    frame_fileops = Frame:new(nil, 'frame_fileops', vec(0), FRAME_PADDING, 'right')

    --[[btn_save = Button:new(nil, 'fileops_save', button_size, saveScreen, {}, vec(0,1))
    btn_save:setProperties('fileops_save_properties', 'right', self, 
                            {label="File Name", id="p_save_filename", value="", size=vec(10, 1)})]]
    dd_new = Dropdown:new(nil, 'fileops_new', button_size, vec(6,1), 'New image')
    dd_save = Dropdown:new(nil, 'fileops_save', button_size, vec(0,1), 'Save image')
    dd_open = Dropdown:new(nil, 'fileops_open', button_size, vec(2,1), 'Open file')
    dd_resize = Dropdown:new(nil, 'fileops_resize', button_size, vec(6,2), 'Resize canvas')

    frame_new = Frame:new(nil, 'frame_new', vec(0), FRAME_PADDING, 'right')
    frame_open = Frame:new(nil, 'frame_open', vec(0), FRAME_PADDING, 'right')
    frame_save = Frame:new(nil, 'frame_save', vec(0), FRAME_PADDING, 'right')
    frame_resize = Frame:new(nil, 'frame_resize', vec(0), FRAME_PADDING, 'right')

    txt_newsize_x = TextBox:new(nil, "text_new_x", 'number', tostring(SIZE_OUT.x), vec(5, 1), "Size X:", nil, 4)
    txt_newsize_y = TextBox:new(nil, "text_new_y", 'number', tostring(SIZE_OUT.y), vec(5, 1), "Size Y:", nil, 4)
    btn_new = ButtonWide:new(nil, 'fileops_new', 40, 60, 'New Image', newImage, {txt_newsize_x, txt_newsize_y}, vec(0,2), '')

    frame_new:addElement(txt_newsize_x, 'bottom', self)
    frame_new:addElement(txt_newsize_y, 'top right', self)
    frame_new:addElement(btn_new, 'bottom', self)

    txt_resize_x = TextBox:new(nil, "text_resize_x", 'number', tostring(SIZE_OUT.x), vec(5, 1), "Size X:", nil, 4)
    txt_resize_y = TextBox:new(nil, "text_resize_y", 'number', tostring(SIZE_OUT.y), vec(5, 1), "Size Y:", nil, 4)
    btn_resize = ButtonWide:new(nil, 'fileops_resize', 40, 60, 'Resize Image', resizeImage, {txt_resize_x, txt_resize_y}, vec(0,2))

    frame_resize:addElement(txt_resize_x, 'bottom', self)
    frame_resize:addElement(txt_resize_y, 'top right', self)
    frame_resize:addElement(btn_resize, 'bottom', self)

    txt_save = TextBox:new(nil, "text_save", 'string', nil, vec(10, 1), "File Name")
    btn_save = ButtonWide:new(nil, 'fileops_save', 40, 10, 'Save', saveScreen, {txt_save}, vec(0,2))

    frame_save:addElement(txt_save, 'bottom', self)
    frame_save:addElement(btn_save, 'bottom', self)

    self:refreshFileList(frame_open, button_size)
    -- This is a bit hacky
    self.elements["fileops_open_refresh"]:setPressed(false)

    dd_new:setContent(frame_new)
    dd_open:setContent(frame_open)
    dd_save:setContent(frame_save)
    dd_resize:setContent(frame_resize)

    --[[btn_open:setProperties('fileops_open_properties', 'right', self, 
                            {label="File Name", id="p_open_filename", value="", size=vec(10, 1)})]]

    frame_fileops:addElement(dd_new, 'bottom', self)
    frame_fileops:addElement(dd_save, 'bottom', self)
    frame_fileops:addElement(dd_open, 'bottom', self)
    frame_fileops:addElement(dd_resize, 'bottom', self)

    dd_fileops:setContent(frame_fileops)

    -----------------------------------------
    -- Complete sidebars
    -----------------------------------------

    --sidebar_right = Frame:new(nil, 'f_side_right', vec(50, 0), FRAME_PADDING, 'right')
    sidebar_left = Frame:new(nil, 'f_side_left', vec(50, 300), FRAME_PADDING, 'left')

    self.content[1] = sidebar_left
    self.content[1]:addElement(dd_fileops, 'bottom', self)
    self.content[1]:addElement(dd_filters, 'bottom', self)
    self.content[1]:addElement(dd_drawing, 'bottom', self)

    --[[
    self.content[2] = sidebar_left
    self.content[2]:addElement(dd_fileops, 'bottom', self)]]

    --self.frames[#self.frames + 1] = filters_frame
    --self.frames[#self.frames + 1] = drawing_frame
    --self.frames[#self.frames + 1] = sidebar_right
end


-- Refresh open file list
function UI:refreshFileList(parent_frame, button_size)

    -- Clear old open file dialogue. Create a refresh button and initialise the frame with it
    parent_frame:clear()
    -- Create a list of openable files
    local open_btns = self:createFileListButtons(OUTDIR, 40)
    local btn_refresh = Button:new(nil, "fileops_open_refresh", button_size, self.refreshFileList, {self, parent_frame, button_size}, vec(6, 3))
    local btn_folder = ButtonWide:new(nil, "fileops_open_folder", button_size, 130, 'Open Save Location', function() os.execute("start " .. lfs.getSaveDirectory() .. '/' .. OUTDIR) end, {}, vec(0, 2))

    parent_frame:addElement(btn_refresh, 'bottom', self)

    -- deepPrint(open_btns)
    for _, btn in pairs(open_btns) do
        parent_frame:addElement(btn, 'bottom', self)
    end
    btn_refresh:setPressed(true)

    parent_frame:addElement(btn_folder, 'top right', self)

end

-- Create buttons for the Open dropdown
function UI:createFileListButtons(savepath, size, btn_count)
    local btns = {}
    local max_length = 30
    local files = lfs.getDirectoryItems(savepath)
    local char_length = FONT_GLOBAL:getHeight() / 3
    btn_count = btn_count or 0

    for i, filename in ipairs(files) do
        local filepath = savepath .. filename

        if lfs.getInfo(filepath).type == 'directory' then
            local new_btns, new_count = self:createFileListButtons(filepath .. '/', size, btn_count)
            btns = table_concat(btns, new_btns)
            btn_count = btn_count + new_count

        else
            local label = string.gsub(filepath, OUTDIR, '')
            local path_length = string.len(filepath)
            btn_count = btn_count + 1
            
            if path_length > max_length then
                label = '...' .. string.sub(filepath, path_length - max_length + 3, path_length)
            end
           table.insert(btns, ButtonWide:new(nil, "open_file_".. btn_count, size, max_length * char_length, label, loadImage, {filepath}, vec(0, 2)))
        end
    end

    return btns, btn_count
end


function UI:createAlphaButtons(parent_frame, alphaCount)
    local btns = {}
    for i=1, alphaCount do
        local sprite_coord_x = ((i-1) % 2) * 2
        local sprite_coord_y = math.floor((i-1) / 2)
        btns[i] =  Button:new(nil, "brush_alpha_"..i, 100, updateAllAlphas, {i}, vec(sprite_coord_x, sprite_coord_y), nil, ALPHA_SET)
    end

    for i, btn in pairs(btns) do
        local grid_coord_x = (i-1) % 4
        local grid_coord_y = math.floor((i-1) / 4)
        parent_frame:addElementToGrid(btn, vec(grid_coord_x, grid_coord_y), self)
    end
end


function UI:drawFrames()
    ICON_SET.batch:clear()
    ALPHA_SET.batch:clear()
    lg.setCanvas(CANVAS_UI_BACKGROUND)
    lg.clear(0,0,0,0)
    lg.setCanvas(CANVAS_UI_STATIC)
    lg.clear(0,0,0,0)
    lg.setCanvas()

    for _, frame in pairs(self.frames) do
        --frame:drawDebug()
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
