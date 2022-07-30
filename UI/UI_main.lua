UI = {}

function UI_init()
    window_w, window_h = lg.getDimensions()
    btn_normalize = Button:new(nil, vec(0), "filter_normalize", vec(50), filterNormalize, "assets/icons/i_normalize.png")
    btn_blur = Button:new(nil, vec(0), "filter_blur", vec(50), filterBoxBlur, "assets/icons/default.png")

    UI = {Frame:new(nil, vec(100, 0), 'right')}
    --UI = Frame:new(nil, SIZE_OUT)
    UI[1]:addElement(btn_normalize, 'bottom')
    UI[1]:addElement(btn_blur, 'bottom')
end