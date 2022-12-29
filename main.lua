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

-- Nice to have:
-- TODO: Orbiters
-- TODO: Layers
-- TODO: More image processing, blurs, filters etc

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

-- Canvas and window params
--WIDTH = 1024
--HEIGHT = 1024
SIZE_OUT = vec(1024)
SIZE_SHADER = vec(512)
CANVAS_SCALE = 1
CANVAS_SCALES = vec(1)

-- Minimum space between draw area and window edge
--PADDING_min = vec(300, 150)
--PADDING = vCopy(PADDING_min)
PADDING_X_min = vec(300, 520)
PADDING_Y_min = vec(150)

PADDING_X = vCopy(PADDING_X_min)
PADDING_Y = vCopy(PADDING_Y_min)

PADDING_X_TOTAL = PADDING_X_min.x + PADDING_X_min.y
PADDING_Y_TOTAL = PADDING_Y_min.x + PADDING_Y_min.y

PADDING_X_HALF = PADDING_X / 2
PADDING_Y_HALF = PADDING_Y / 2

lw.setMode(SIZE_OUT.x + PADDING_X_TOTAL, SIZE_OUT.y + PADDING_Y_TOTAL, {resizable = true})

IMGDATA_MAIN = nil -- Main image where drawing happens
CANVAS_IMAGE = nil -- Main canvas where IMGDATA_MAIN is drawn on screen
screenInit(SIZE_OUT.x, SIZE_OUT.y)

CANVAS_UI_DYNAMIC = lg.newCanvas(SIZE_OUT.x + PADDING_X_TOTAL, SIZE_OUT.y + PADDING_Y_TOTAL)
CANVAS_UI_BACKGROUND = lg.newCanvas(SIZE_OUT.x + PADDING_X_TOTAL, SIZE_OUT.y + PADDING_Y_TOTAL)
CANVAS_UI_STATIC = lg.newCanvas(SIZE_OUT.x + PADDING_X_TOTAL, SIZE_OUT.y + PADDING_Y_TOTAL)
CANVAS_UI_OVERLAY = lg.newCanvas(SIZE_OUT.x + PADDING_X_TOTAL, SIZE_OUT.y + PADDING_Y_TOTAL)
CANVAS_SHADER = lg.newCanvas(SIZE_SHADER.x, SIZE_SHADER.y)

-- ALPHA_GLOBAL = li.newImageData("assets/alphas/1.png")
BRUSHES = {}

-- UI Icons
-- Icon set objects contain the size of the atlas texture and the icon's 'offset' when clicked, in addition to the sprite batch itself
-- The offset helps center the icon in the UI. The number is percentage away from center, i.e. 0.07 = 7%
ICON_ATLAS = lg.newImage("assets/icons/icon_atlas.png")
ICON_SET = {
    batch = lg.newSpriteBatch(ICON_ATLAS, 50, 'static'),
    offset = 0.07,
    size_atlas = 512,
    size_icon = 64
}

ALPHA_ATLAS = lg.newImage("assets/alphas/alpha_atlas.png")
ALPHA_SET = {
    batch = lg.newSpriteBatch(ALPHA_ATLAS, 50, 'static'),
    offset = 0.04,
    size_atlas = 512,
    size_icon = 128
}
--ALPHA_BATCH = lg.newSpriteBatch(ALPHA_ATLAS, 50, 'static')

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
require "./UI/element"
require "./UI/frame"
require "./UI/UI_main"

--[[-----------------------------------------
 
 LOVE FUNCTIONS
 
--]]-----------------------------------------

function love.load()

    -- Init preview shader
    SHADER_PREVIEW = lg.newShader("shader/flow.glsl")
    SHADER_BACKGROUND = lg.newImage("assets/other/harvard.png")
    --SHADER_PREVIEW:send('iResolution', {SIZE_SHADER.x, SIZE_SHADER.y})

    lg.setBackgroundColor(.2, .2, .2, 1)
    lg.setFont(FONT_GLOBAL)

    UI_main = UI:new(nil)
    UI_main:init()

    windowManager()

    UI_main:updateFrames()
    UI_main:drawFrames()

    -- Initialize Drawing brush
    drawing_brush = Brush:new(nil, vec(50), 60)
    table.insert(BRUSHES, drawing_brush)

    -- Initialize random walkers
    WALKERS_MAIN = WalkerSystem:new()
    WALKERS_MAIN:updateWalkerFromProperties(UI_main)

    lg.setCanvas(CANVAS_IMAGE)
    lg.clear(.5, .5, 0, 1)
    lg.setCanvas()

end


function love.update()

    --UI_main:updateFrames()
    windowManager()

    -- Return mouse position
    mousePos = mouseHandler()

    -- Hovering function to display tooltips
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

    -- Random Walker mode
    if mode_RANDOMWALK then
        --WALKERS_MAIN:updateWalkerFromProperties(UI_main)
        WALKERS_MAIN:update()

    -- Drawing mode
    elseif mode_DRAW then
        drawing_brush:updateBrushFromProperties(UI_main)
        drawing_brush:moveToLazy(mousePos)
        if drawing_brush.active and (drawing_brush.pos.x ~= drawing_brush.prev_pos.x and drawing_brush.pos.y ~= drawing_brush.prev_pos.y) then
            drawing_brush:draw('draw')
        end
        --drawing_brush:moveTo(mousePos)
    end
end


-- Main draw function
function love.draw()

    -- Draw brush outline if drawing mode is on
    if mode_DRAW then
        drawing_brush:drawOutline(mousePos)
    end

    local window_size_x, window_size_y = lg.getDimensions()

    lg.setColor(1, 1, 1)
    lg.setLineWidth(2)
    DISPLAY_IMAGE:replacePixels(IMGDATA_MAIN)

    -- Send drawn vectormap and current time to shader
    SHADER_PREVIEW:send('vectorMap', DISPLAY_IMAGE)
    SHADER_PREVIEW:send('iTime', lt.getTime())

    -- Draw main drawing canvas
    lg.draw(DISPLAY_IMAGE, PADDING_X.x, PADDING_Y.x, 0, CANVAS_SCALE)

    -- Apply preview shader to canvas
    CANVAS_SHADER:renderTo(
        function()
            lg.clear(0, 0, 0, 0)
            local w, h = SHADER_BACKGROUND:getDimensions()
            local self_w, self_h = CANVAS_SHADER:getDimensions()
            local line_w = 5

            lg.setShader(SHADER_PREVIEW)
            --lg.rectangle('fill', 0, 0, lg.getWidth(), lg.getHeight())
            lg.draw(SHADER_BACKGROUND, 0, 0, 0, SIZE_SHADER.x / w, SIZE_SHADER.y / h)
            lg.setShader()

            lg.setLineWidth(line_w)
            lg.setColor(0,0,0,1)
            lg.rectangle('line', line_w*.5, line_w*.5, self_w - line_w, self_h - line_w)
            lg.setColor(1, 1, 1, 1)
        end
    )

    lg.setLineWidth(2)

    -- Position and draw preview shader
    local canvas_right_side = (PADDING_X.x + SIZE_OUT.x * CANVAS_SCALE)
    local shader_pos_x = canvas_right_side + (window_size_x - canvas_right_side - SIZE_SHADER.x) * .5
    lg.draw(CANVAS_SHADER, shader_pos_x, window_size_y / 2 - SIZE_SHADER.y / 2, 0)

    -- Draw info text
    local scaled_canvas = CANVAS_SCALE * SIZE_OUT
    lg.print("Size: "..SIZE_OUT.x.." x "..SIZE_OUT.y, PADDING_X.x, PADDING_Y.y + scaled_canvas.y)
    lg.print("Preview:", shader_pos_x, window_size_y / 2 - SIZE_SHADER.y / 2 - FONT_GLOBAL:getHeight())
    lg.print("FPS: " .. lt.getFPS(), PADDING_X.x, PADDING_Y.x - FONT_GLOBAL:getHeight())

    local mouseCanvas = toCanvasSpace(mousePos)
    local mouse_pos_string = "Mouse location: " .. string.format('%.0f', mouseCanvas.x) .. ', ' .. string.format('%.0f', mouseCanvas.y)
    lg.print(mouse_pos_string, canvas_right_side - FONT_GLOBAL:getWidth(mouse_pos_string), PADDING_Y.x + scaled_canvas.y)

    -- Draw UI layers
    lg.draw(CANVAS_UI_DYNAMIC)
    lg.draw(CANVAS_UI_BACKGROUND)
    lg.draw(ICON_SET.batch)
    lg.draw(ALPHA_SET.batch)
    lg.draw(CANVAS_UI_STATIC)
    lg.draw(CANVAS_UI_OVERLAY)   

    --[[
    -- On screen debug printing
    lg.print(lfs.getSaveDirectory(), PADDING_X.x + 30, PADDING_Y.y + 30)
    lg.print(mousePos.x .. ", " .. mousePos.y, PADDING_X.x + 30, PADDING_Y.y + 30 + 15)
    lg.print(mouseCanvas.x .. ", " .. mouseCanvas.y, PADDING_X.x + 30, PADDING_Y.y + 30 + 30)
    lg.print(drawing_brush.pos.x .. ", " .. drawing_brush.pos.y, PADDING_X.x + 30, PADDING_Y.y + 30 + 45)
    lg.print(drawing_brush.prev_pos.x .. ", " .. drawing_brush.prev_pos.y, PADDING_X.x + 30, PADDING_Y.y + 30 + 60)
    lg.print("FPS: " .. lt.getFPS(), PADDING_X.x + 30, PADDING_Y.y + 30 + 75)
    lg.print(UI_main.content[1].bBox[1].x .. ", " .. UI_main.content[1].bBox[1].y .. ' | ' .. UI_main.content[1].bBox[2].x .. ", " .. UI_main.content[1].bBox[2].y, PADDING_X.x + 30, PADDING_Y.y + 30 + 90)
    ]]

    -- Clear some UI layers
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
        -- validate text input to prevent errors
        if TEXTBOX_SELECTED:validate(t) then
            TEXTBOX_SELECTED.text = TEXTBOX_SELECTED.text .. t
            TEXTBOX_SELECTED:draw()
        end
    end
end

-------------------------------------------
-- 
-- CUSTOM FUNCTIONS
-- 
-------------------------------------------

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
                
        ICON_SET.batch:clear()
        for _, frame in pairs(UI_main.frames) do
            frame:draw()
        end
        
    end

    CANVAS_SCALES = (window_size - (vec(PADDING_X_TOTAL, PADDING_Y_TOTAL))) / SIZE_OUT
    CANVAS_SCALE = math.min(CANVAS_SCALES.x, CANVAS_SCALES.y)

    --PADDING_X.x = (size_x - SIZE_OUT.x * CANVAS_SCALE) / 2
    --PADDING_Y.y = (size_y - SIZE_OUT.y * CANVAS_SCALE) / 2
    local padding_x_totals = (size_x - SIZE_OUT.x * CANVAS_SCALE) * .5
    local padding_y_totals = (size_y - SIZE_OUT.y * CANVAS_SCALE) * .5

    local x_ratio = PADDING_X_min.x / PADDING_X_min.y
    local y_ratio = PADDING_Y_min.x / PADDING_Y_min.y

    PADDING_X = vec(padding_x_totals * x_ratio, padding_x_totals * (1 / x_ratio))
    PADDING_Y = vec(padding_y_totals * y_ratio, padding_y_totals * (1 / y_ratio))
end