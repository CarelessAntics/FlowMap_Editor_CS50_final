UI = {content = {}, frames = {}}

function UI_init()
    window_w, window_h = lg.getDimensions()

    local button_size = 40

    dd_filters = Dropdown:new(nil, "filters_dropdown", vec(button_size), "assets/icons/i_dd_filters.png")
    dd_drawing = Dropdown:new(nil, "drawing_dropdown", vec(button_size))

    filters_frame = Frame:new(nil, vec(0), 5, 'right')
    drawing_frame = Frame:new(nil, vec(0), 5, 'right')

    btn_normalize = Button:new(nil, "filter_normalize", vec(button_size), filterNormalize, "assets/icons/i_normalize.png")
    btn_blur = Button:new(nil, "filter_blur", vec(button_size), filterBoxBlur, "assets/icons/i_blur.png")

    filters_frame:addElement(btn_normalize, 'bottom')
    filters_frame:addElement(btn_blur, 'bottom')

    btn_modedraw = Button:new(nil, "filter_normalize2", vec(button_size), function() mode_DRAW = true mode_RANDOMWALK = false end, "assets/icons/i_normalize.png")
    btn_modewalker = Button:new(nil, "filter_blur2", vec(button_size), function() mode_DRAW = false mode_RANDOMWALK = true end, "assets/icons/default.png")
    textbox_test = TextBox:new(nil, "text_test", vec(4, 2))

    drawing_frame:addElement(btn_modewalker, 'bottom')
    drawing_frame:addElement(btn_modedraw, 'bottom')
    drawing_frame:addElement(textbox_test, 'bottom')

    dd_filters:setContent(filters_frame)
    dd_drawing:setContent(drawing_frame)

    sidebar_right = Frame:new(nil, vec(100, 0), 5, 'right')
    UI.content[1] = sidebar_right
    UI.content[1]:addElement(dd_filters, 'bottom')
    UI.content[1]:addElement(dd_drawing, 'bottom')

    UI.frames[#UI.frames + 1] = filters_frame
    UI.frames[#UI.frames + 1] = drawing_frame
    UI.frames[#UI.frames + 1] = sidebar_right
end