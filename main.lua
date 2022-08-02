if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

lf = love.filesystem
lg = love.graphics
lw = love.window
lm = love.math
li = love.image
lt = love.timer

require "./helpers/vector"
require "./helpers/helpers"
require "./objects/brush"
require "./objects/walker"
require "./imageprocessing/filters"
require "./UI/element"
require "./UI/frame"
require "./UI/UI_main"

-- TODO: Brush 
-- TODO: UI
--      Frames
--      preview window
-- TODO: Orbiters
-- TODO: Saving image
-- TODO: Layers
-- TODO: Image processing, blurs, filters etc
-- TODO: Switch from drawing circles to canvases to writing into imagedata


--[[-----------------------------------------

GLOBALS START

--]]-----------------------------------------

-- Different Drawing modes
mode_RANDOMWALK = false
mode_DRAW = true
mode_ORBIT = false

-- Random walk params
WALKERS = {}
WALKERS_RESPAWN = true

-- Drawing mode params
BRUSH_SIZE = 60
BRUSH_LAZY_RADIUS = 100
-- CURRENTLY_DRAWING = false

-- Canvas and window params
--WIDTH = 1024
--HEIGHT = 1024
SIZE_OUT = vec(1024)
CANVAS_SCALE = 1

-- Minimum space between draw area and window edge
PADDING_min = vec(300, 200)
PADDING = vCopy(PADDING_min)
PADDING_HALF = PADDING / 2

lw.setMode(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2, {resizable = true})
IMGDATA_MAIN = li.newImageData(SIZE_OUT.x, SIZE_OUT.y, "rgba16")
DISPLAY_IMAGE = lg.newImage(IMGDATA_MAIN)
CANVAS_IMAGE = lg.newCanvas(SIZE_OUT.x, SIZE_OUT.y)
CANVAS_UI = lg.newCanvas(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2)

UI_DATA = li.newImageData(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2, "rgba8")
UI_IMAGE = lg.newImage(UI_DATA)

-- TextBox params
TEXTBOX_SELECTED = nil

-- Export params
-- Save location in %appdata%/Roaming/LOVE/
OUTDIR = "output/"
OUTFILE = "outfile.png"

-------------------------------------------
-- 
-- LOVE FUNCTIONS
-- 
-------------------------------------------

function love.conf(t)
    t.console = true
end

function love.load()

    lg.setBackgroundColor(.2, .2, .2, 1)
    UI_init()
    windowManager()

    -- Initialize the image to 0-vectors (or 0.5-vectors since they need to encode -1...1 data)
    local function pixelInit(x, y, r, g, b, a)
        return 0.5, 0.5, 0, 1
    end
    IMGDATA_MAIN:mapPixel(pixelInit)

    lg.setCanvas(CANVAS_IMAGE)
    lg.clear(.5, .5, 0, 1)
    lg.setCanvas()

    for i = 0, 5 do
        WALKERS[i] = Walker:new(nil, vec(math.random(SIZE_OUT.x), math.random(SIZE_OUT.y)), 50)
    end
    drawing_brush = Brush:new(nil, vec(50), BRUSH_SIZE)
    --drawing_brush = TestBrush:new(nil, vec(50), BRUSH_SIZE)
end

function love.update()

    windowManager()

    -- Return mouse position
    mousePos = mouseHandler()

    --[[
    -- Update UI
    local function clearImgData(x, y, r, g, b, a)
        return 0, 0, 0, 0
    end
    UI_DATA:mapPixel(clearImgData)

    for _, frame in pairs(UI) do
        frame:generateImg(UI_DATA)
    end]]

    -- Random Walker mode
    if mode_RANDOMWALK then
        for i = 0, #WALKERS do
            if WALKERS[i] ~= nil then
                WALKERS[i]:walk()
                WALKERS[i]:draw()
            end
            if WALKERS[i] ~= nil and WALKERS[i].dead and not WALKERS_RESPAWN then
                WALKERS[i] = nil
            end
        end

    -- Drawing mode
    elseif mode_DRAW then
        drawing_brush:moveToLazy(mousePos)
        if drawing_brush.drawing and (drawing_brush.pos ~= drawing_brush.prev_pos) then
            drawing_brush:draw()
        end
        --drawing_brush:moveTo(mousePos)
    end
end


-- Main draw function
function love.draw()
    
    lg.setCanvas(CANVAS_UI)
    lg.clear(0,0,0,0)
    lg.setCanvas()

    -- Drawing mode
    if mode_DRAW then
        drawing_brush:drawOutline(mousePos)
    end

    for _, frame in pairs(UI.content) do
        --frame:drawDebug()
        frame:draw()
    end

    lg.setColor(1, 1, 1)
    DISPLAY_IMAGE:replacePixels(IMGDATA_MAIN)
    lg.draw(DISPLAY_IMAGE, PADDING.x, PADDING.y, 0, CANVAS_SCALE)
    lg.draw(CANVAS_UI)


    vec1 = vec(1, .5)
    vec2 = vec(.5, 2)
    mouseCanvas = toCanvasSpace(mousePos)
    lg.print(lf.getIdentity(), PADDING.x + 30, PADDING.y + 30)
    lg.print(mousePos.x .. ", " .. mousePos.y, PADDING.x + 30, PADDING.y + 30 + 15)
    lg.print(mouseCanvas.x .. ", " .. mouseCanvas.y, PADDING.x + 30, PADDING.y + 30 + 30)
    lg.print(drawing_brush.pos.x .. ", " .. drawing_brush.pos.y, PADDING.x + 30, PADDING.y + 30 + 45)
    lg.print(drawing_brush.prev_pos.x .. ", " .. drawing_brush.prev_pos.y, PADDING.x + 30, PADDING.y + 30 + 60)
    lg.print("FPS: " .. lt.getFPS(), PADDING.x + 30, PADDING.y + 30 + 75)
    lg.print(UI.content[1].bBox[1].x .. ", " .. UI.content[1].bBox[1].y .. ' | ' .. UI.content[1].bBox[2].x .. ", " .. UI.content[1].bBox[2].y, PADDING.x + 30, PADDING.y + 30 + 90)

    --[[
    for i = 0, WIDTH do
        local col = lerp(0, 1, i / WIDTH)
        lg.setColor(col, col, col)
        lg.circle('fill', i, PADDING.y + 550, 10, 32)
    end]]
end

function love.keypressed(key, scancode, isrepeat)
    if key == 's' and not isrepeat then
        saveScreen()
    end
    if key == 'c' then
        WALKERS_RESPAWN = false
    end
    if key == 'n' then
        filterNormalize(IMGDATA_MAIN)
    end
    if key == 'b' then
        filterBoxBlur(IMGDATA_MAIN)
    end
    if key == 'backspace' and TEXTBOX_SELECTED ~= nil then
        TEXTBOX_SELECTED:backspace()
    end
end

function love.mousepressed(x, y, button)

    -- Any click clears textbox selection. Will be reselected in this function if click hits
    selectTextBox(nil)

    -- Check for UI clicks. if UI click, return before taking any more inputs
    for _, frame in pairs(UI.frames) do
        if isHitRect(mousePos, frame.bBox[1], frame.bBox[2]) and frame.state then
            frame:getHit(mousePos)
            return
        end
    end

    -- Mouse inputs happening on draw area
    if mode_DRAW then
        if button == 1 and not drawing_brush.drawing then
            drawing_brush.drawing = true
        end
    elseif mode_RANDOMWALK then
        WALKERS[#WALKERS+1] = Walker:new(nil, vec(x, y), 50)
    end
end

function love.mousereleased( x, y, button, istouch, presses)
    if mode_DRAW then
        if button == 1 and drawing_brush.drawing then
            drawing_brush.drawing = false
        end
    end
end


function love.textinput(t)
    if TEXTBOX_SELECTED ~= nil then
        if TEXTBOX_SELECTED:validate(t) then
            TEXTBOX_SELECTED.text = TEXTBOX_SELECTED.text .. t
        end
    end
end

-------------------------------------------
-- 
-- CUSTOM FUNCTIONS
-- 
-------------------------------------------

--- Save image
function saveScreen()
    if lf.createDirectory(OUTDIR) then
        if lf.getInfo(OUTDIR .. OUTFILE) ~= nil then
            lf.newFile(OUTDIR .. OUTFILE)
        end

        -- local image_out = CANVAS_IMAGE:newImageData()
        IMGDATA_MAIN:encode("png", OUTDIR .. OUTFILE)
    end
end

function clearWalkers()
    WALKERS = {}
end

--- Return mouse position, or 0 if nil
function mouseHandler()
    local mX, mY = love.mouse.getPosition()
    if mX == nil then
        mX = 0
    end
    if mY == nil then
        mY = 0
    end

    return vec(mX, mY)
end

--- Manages scaling and positioning of canvases when window size changes
function windowManager()
    local size_x, size_y = lg.getDimensions()
    local ui_x, ui_y = CANVAS_UI:getDimensions()
    local window_size = vec(size_x, size_y)

    -- Refresh UI layer if dimension mismatch between it and window
    if ui_x ~= size_x or ui_y ~= size_y then
        for _, frame in pairs(UI.frames) do
            frame:updateAbsolutePos(size_x, size_y)
        end
        CANVAS_UI = lg.newCanvas(size_x, size_y)
        UI_DATA = li.newImageData(size_x, size_y, 'rgba8')
    end

    local scales = (window_size - (PADDING_min * 2)) / SIZE_OUT
    CANVAS_SCALE = math.min(scales.x, scales.y)

    PADDING.x = (size_x - SIZE_OUT.x * CANVAS_SCALE) / 2
    PADDING.y = (size_y - SIZE_OUT.y * CANVAS_SCALE) / 2

    PADDING_HALF = PADDING / 2
end