if arg[#arg] == "vsc_debug" then require("lldebugger").start() end
io.stdout:setvbuf('no')

lfs = love.filesystem
lf = love.font
lg = love.graphics
lw = love.window
lm = love.math
li = love.image
lt = love.timer

require "./conf"
require "./helpers/vector"
require "./helpers/helpers"
-- require "./functionality/resize"


-- TODO: Brush 
-- TODO: UI_main
--      Tooltips
--      Properties
--      preview window
-- TODO: Orbiters
-- TODO: implement image size change (also for loading images)
-- TODO: Layers
-- TODO: Image processing, blurs, filters etc
-- TODO: Switch from drawing circles to canvases to writing into imagedata

function initImage()
    DISPLAY_IMAGE = lg.newImage(IMGDATA_MAIN)
    CANVAS_IMAGE = lg.newCanvas(SIZE_OUT.x, SIZE_OUT.y)
end

function screenInit(size_x, size_y)

    local new_imgData = li.newImageData(size_x, size_y, "rgba16")
    -- new_imgData:paste(IMGDATA_MAIN, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)

    SIZE_OUT = vec(size_x, size_y)
    IMGDATA_MAIN = new_imgData

    initImage()

    -- Initialize the image to 0-vectors (or 0.5-vectors since they need to encode -1...1 data)
    local function pixelInit(x, y, r, g, b, a)
        return 0.5, 0.5, 0, 1
    end
    IMGDATA_MAIN:mapPixel(pixelInit)
end

--[[-----------------------------------------

 GLOBALS START

--]]-----------------------------------------

lfs.setIdentity('VectorMapPainter')
lw.setTitle('Vector Map Painter')

-- Different Drawing modes
mode_RANDOMWALK = false
mode_DRAW = true
mode_ORBIT = false

-- Brush globals
BRUSH_ALIGN = {value=true}
BRUSH_ROTATE = {value=true}

-- Random walk params
WALKERS = {}
WALKERS_RESPAWN = true

-- Drawing mode params
-- BRUSH_SIZE = 60
-- BRUSH_LAZY_RADIUS = 100
-- CURRENTLY_DRAWING = false

-- Canvas and window params
--WIDTH = 1024
--HEIGHT = 1024
SIZE_OUT = vec(1024)
CANVAS_SCALE = 1

-- Minimum space between draw area and window edge
PADDING_min = vec(300, 150)
PADDING = vCopy(PADDING_min)
PADDING_HALF = PADDING / 2

lw.setMode(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2, {resizable = true})

IMGDATA_MAIN = nil -- Main image where drawing happens
CANVAS_IMAGE = nil -- Main canvas where IMGDATA_MAIN is drawn on screen
screenInit(SIZE_OUT.x, SIZE_OUT.y)

CANVAS_UI_DYNAMIC = lg.newCanvas(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2)
CANVAS_UI_BACKGROUND = lg.newCanvas(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2)
CANVAS_UI_STATIC = lg.newCanvas(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2)
CANVAS_UI_OVERLAY = lg.newCanvas(SIZE_OUT.x + PADDING.x * 2, SIZE_OUT.y + PADDING.y * 2)

-- UI Icons
ICON_ATLAS = lg.newImage("assets/icons/icon_atlas.png")
ICON_SET = {
    batch = lg.newSpriteBatch(ICON_ATLAS, 50, 'static'),
    offset = 0.07,
    size_atlas = 512,
    size_icon = 64
}

--ICON_BATCH = lg.newSpriteBatch(ICON_ATLAS, 50, 'static')
--ICON_OFFSET = 0.07

ALPHA_ATLAS = lg.newImage("assets/alphas/alpha_atlas.png")
ALPHA_SET = {
    batch = lg.newSpriteBatch(ALPHA_ATLAS, 50, 'static'),
    offset = 0.04,
    size_atlas = 512,
    size_icon = 128
}
ALPHA_BATCH = lg.newSpriteBatch(ALPHA_ATLAS, 50, 'static')

-- TextBox params
TEXTBOX_SELECTED = nil
FONT_SIZE_REGULAR = 18
FONT_GLOBAL = lg.newFont("fonts/Bebas-Regular.ttf", FONT_SIZE_REGULAR)
FONT_GLOBAL:setFilter("nearest", "nearest", 1)

-- Export params
-- Save location in %appdata%/Roaming/LOVE/
OUTDIR = "output/"
OUTFILE = "outfile.png"

HOVER_TIMER = 0
HOVER_CURRENT = ''

--[[-----------------------------------------
 
 UI MODULES
 
--]]-----------------------------------------

require "./objects/brush"
require "./objects/walker"
require "./functionality/filters"
require "./functionality/fileops"

drawing_brush = Brush:new(nil, vec(50), 60)

require "./UI/element"
require "./UI/frame"
require "./UI/UI_main"

--[[-----------------------------------------
 
 LOVE FUNCTIONS
 
--]]-----------------------------------------

function love.load()

    lg.setBackgroundColor(.2, .2, .2, 1)
    lg.setFont(FONT_GLOBAL)

    UI_main = UI:new(nil)
    UI_main:init()

    windowManager()

    UI_main:updateFrames()
    UI_main:drawFrames()

    lg.setCanvas(CANVAS_IMAGE)
    lg.clear(.5, .5, 0, 1)
    lg.setCanvas()

    for i = 0, 5 do
        WALKERS[i] = Walker:new(nil, vec(math.random(SIZE_OUT.x), math.random(SIZE_OUT.y)), 50)
    end
    
    --drawing_brush = TestBrush:new(nil, vec(50), BRUSH_SIZE)
end

function love.update()

    --UI_main:updateFrames()
    windowManager()


    -- Return mouse position
    mousePos = mouseHandler()

    if HOVER_TIMER > 1 then
        for _, frame in pairs(UI_main.frames) do
            if isHitRect(mousePos, frame.bBox[1], frame.bBox[2]) and frame.state then
                frame:getHit(mousePos, nil, UI_main, false)
                goto continue
            end
        end

        HOVER_TIMER = 0
        HOVER_CURRENT = ''

        ::continue::
    else
        HOVER_TIMER = HOVER_TIMER + lt.getDelta()
    end

    --[[
    -- Update UI_main
    local function clearImgData(x, y, r, g, b, a)
        return 0, 0, 0, 0
    end
    UI_DATA:mapPixel(clearImgData)

    for _, frame in pairs(UI_main) do
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
        drawing_brush:updateFromProperties(UI_main)
        drawing_brush:moveToLazy(mousePos)
        if drawing_brush.active and (drawing_brush.pos ~= drawing_brush.prev_pos) then
            drawing_brush:draw('draw')
        end
        --drawing_brush:moveTo(mousePos)
    end
end


-- Main draw function
function love.draw()
    

    -- Drawing mode
    if mode_DRAW then
        drawing_brush:drawOutline(mousePos)
    end

    lg.setColor(1, 1, 1)
    DISPLAY_IMAGE:replacePixels(IMGDATA_MAIN)
    lg.draw(DISPLAY_IMAGE, PADDING.x, PADDING.y, 0, CANVAS_SCALE)

    --[[
    for _, frame in pairs(UI_main.frames) do
        --frame:drawDebug()
        frame:draw()
    end]]
    lg.draw(CANVAS_UI_BACKGROUND)
    lg.draw(CANVAS_UI_DYNAMIC)
    lg.draw(ICON_SET.batch)
    lg.draw(ALPHA_SET.batch)
    lg.draw(CANVAS_UI_STATIC)
    lg.draw(CANVAS_UI_OVERLAY)
    

    local scaled_canvas = CANVAS_SCALE * SIZE_OUT
    lg.print("Size: "..SIZE_OUT.x.." x "..SIZE_OUT.y, PADDING.x, PADDING.y + scaled_canvas.y)

    -- On screen debug printing
    mouseCanvas = toCanvasSpace(mousePos)
    lg.print(lfs.getSaveDirectory(), PADDING.x + 30, PADDING.y + 30)
    lg.print(mousePos.x .. ", " .. mousePos.y, PADDING.x + 30, PADDING.y + 30 + 15)
    lg.print(mouseCanvas.x .. ", " .. mouseCanvas.y, PADDING.x + 30, PADDING.y + 30 + 30)
    lg.print(drawing_brush.pos.x .. ", " .. drawing_brush.pos.y, PADDING.x + 30, PADDING.y + 30 + 45)
    lg.print(drawing_brush.prev_pos.x .. ", " .. drawing_brush.prev_pos.y, PADDING.x + 30, PADDING.y + 30 + 60)
    lg.print("FPS: " .. lt.getFPS(), PADDING.x + 30, PADDING.y + 30 + 75)
    lg.print(UI_main.content[1].bBox[1].x .. ", " .. UI_main.content[1].bBox[1].y .. ' | ' .. UI_main.content[1].bBox[2].x .. ", " .. UI_main.content[1].bBox[2].y, PADDING.x + 30, PADDING.y + 30 + 90)

    --[[
    for i = 0, WIDTH do
        local col = lerp(0, 1, i / WIDTH)
        lg.setColor(col, col, col)
        lg.circle('fill', i, PADDING.y + 550, 10, 32)
    end]]

    lg.setCanvas(CANVAS_UI_OVERLAY)
    lg.clear(0,0,0,0)
    lg.setCanvas(CANVAS_UI_DYNAMIC)
    lg.clear(0,0,0,0)
    lg.setCanvas()
end


function love.keypressed(key, scancode, isrepeat)
    if key == 'backspace' and TEXTBOX_SELECTED ~= nil then
        TEXTBOX_SELECTED:backspace()
    end
end


function love.mousepressed(x, y, button)

    -- Any click clears textbox selection. Will be reselected in this function if click hits
    selectTextBox(nil)

    -- Check for UI_main clicks. if UI_main click, return before taking any more inputs
    for _, frame in pairs(UI_main.frames) do
        if isHitRect(mousePos, frame.bBox[1], frame.bBox[2]) and frame.state then
            frame:getHit(mousePos, button, UI_main, true)
            UI_main:updateFrames()
            UI_main:drawFrames()
            return
        end
    end

    -- Mouse inputs happening on draw area
    if mode_DRAW then
        if button == 1 or button == 2 then
            drawing_brush.active = true
            if button == 2 then
                drawing_brush.erasing = true
            end
        end
            
    elseif mode_RANDOMWALK then
        WALKERS[#WALKERS+1] = Walker:new(nil, vec(x, y), 50)
    end
end


function love.mousereleased( x, y, button, istouch, presses)

    for _, frame in pairs(UI_main.frames) do
        if isHitRect(mousePos, frame.bBox[1], frame.bBox[2]) and frame.state then
            frame:getHit(mousePos, button, UI_main, false)
            UI_main:updateFrames()
            UI_main:drawFrames()
            return
        end
    end

    if mode_DRAW then
        if drawing_brush.active then
            drawing_brush.active = false
            drawing_brush.erasing = false
        end
    end
end


function love.textinput(t)
    if TEXTBOX_SELECTED ~= nil then
        if TEXTBOX_SELECTED:validate(t) then
            TEXTBOX_SELECTED.text = TEXTBOX_SELECTED.text .. t
            TEXTBOX_SELECTED:draw()
        end

        --[[
        if TEXTBOX_SELECTED.parent.id == 'f_brush_properties' then
            drawing_brush:updateFromProperties()
        end]]
    end
end

-------------------------------------------
-- 
-- CUSTOM FUNCTIONS
-- 
-------------------------------------------

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
    local ui_x, ui_y = CANVAS_UI_DYNAMIC:getDimensions()
    local window_size = vec(size_x, size_y)

    -- Refresh UI_main layer if dimension mismatch between it and window
    if ui_x ~= size_x or ui_y ~= size_y then

        -- Update root first, then the rest
        for _, frame in pairs(UI_main.content) do
            frame:updateAbsolutePos()
        end
        for _, frame in pairs(UI_main.frames) do
            frame:updateAbsolutePos()
        end

        CANVAS_UI_DYNAMIC = lg.newCanvas(size_x, size_y)
        CANVAS_UI_BACKGROUND = lg.newCanvas(size_x, size_y)
        CANVAS_UI_STATIC = lg.newCanvas(size_x, size_y)
        CANVAS_UI_OVERLAY = lg.newCanvas(size_x, size_y)
                
        ICON_BATCH:clear()
        for _, frame in pairs(UI_main.frames) do
            frame:draw()
        end
        
    end

    local scales = (window_size - (PADDING_min * 2)) / SIZE_OUT
    CANVAS_SCALE = math.min(scales.x, scales.y)

    PADDING.x = (size_x - SIZE_OUT.x * CANVAS_SCALE) / 2
    PADDING.y = (size_y - SIZE_OUT.y * CANVAS_SCALE) / 2

    PADDING_HALF = PADDING / 2
end