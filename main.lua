require "./custom_vector"
require "./helpers"
require "./walker"
require "./brush"
require "./button"

lf = love.filesystem
lg = love.graphics
lw = love.window
lm = love.math

-- Different Drawing modes
mode_RANDOMWALK = false
mode_DRAW = true
mode_ORBIT = false

-- Random walk params
WALKERS = {}
WALKERS_RESPAWN = true

-- Drawing mode params
BRUSH_SIZE = 30
BRUSH_LAZY_RADIUS = 100
-- CURRENTLY_DRAWING = false

-- Canvas params
WIDTH = 1024
HEIGHT = 1024
PADDING = vec(500, 200)
PADDING_HALF = PADDING / 2
lw.setMode(WIDTH + PADDING.x, HEIGHT + PADDING.y, {resizable = false})
CANVAS_IMAGE = lg.newCanvas(WIDTH, HEIGHT)
CANVAS_UI = lg.newCanvas(WIDTH + PADDING.x, HEIGHT + PADDING.y)

-- Export params
-- Save location in %appdata%/Roaming/LOVE/
OUTDIR = "output/"
OUTFILE = "outfile.png"

--mousePos = vec(0, 0)

-- TODO Brush 
-- TODO UI
-- TODO Orbiters
-- TODO Saving image

function love.conf(t)
    t.console = true
end

function love.load()

    lg.setCanvas(CANVAS_IMAGE)
    lg.clear(.5, .5, 0, 1)
    lg.setCanvas()

    for i = 0, 20 do
        WALKERS[i] = createWalker(vec(math.random(WIDTH), math.random(HEIGHT)))
    end
    brush = initBrush(0, 0, BRUSH_SIZE)
end

function love.update()

    -- Return mouse position
    mousePos = mouseHandler()

    -- Random Walker mode
    if mode_RANDOMWALK then
        for i = 0, #WALKERS do
            if WALKERS[i] ~= nil and not WALKERS[i].dead then
                WALKERS[i]:walk()
            end
        end

    -- Drawing mode
    elseif mode_DRAW then
        brush:moveToLazy(mousePos)
        --brush:moveTo(mousePos)
    end
end

function love.draw()
    
    lg.setCanvas(CANVAS_UI)
    lg.clear(0,0,0,0)
    lg.setCanvas()

    -- Random Walker mode
    if mode_RANDOMWALK then
        for i = 0, #WALKERS do
            if WALKERS[i] ~= nil then
                WALKERS[i]:draw()
            end
        end

    -- Drawing mode
    elseif mode_DRAW then
        if brush.drawing then
            brush:draw()
        end
        brush:drawOutline(mousePos)
    end

    lg.setColor(1, 1, 1)
    lg.draw(CANVAS_IMAGE, PADDING_HALF.x, PADDING_HALF.y)
    lg.draw(CANVAS_UI)


    vec1 = vec(1, .5)
    vec2 = vec(.5, 2)
    mouseCanvas = toCanvasSpace(mousePos)
    lg.print(lf.getIdentity(), WIDTH/2, HEIGHT/2)
    lg.print(mousePos.x .. ", " .. mousePos.y, WIDTH/2, HEIGHT/2 + 15)
    lg.print(type(vec(0,0)) .. ", " .. type(4), WIDTH/2, HEIGHT/2 + 30)
    lg.print(mouseCanvas.x .. ", " .. mouseCanvas.y, WIDTH/2, HEIGHT/2 + 45)
    lg.print((vec1 / vec2).x .. ", " .. (vec1 / vec2).y, WIDTH/2, HEIGHT/2 + 60)
    lg.print((vec1 * 2).x .. ", " .. (vec1 * 2).y, WIDTH/2, HEIGHT/2 + 75)
    lg.print((vec1 / 2).x .. ", " .. (vec1 / 2).y, WIDTH/2, HEIGHT/2 + 90)
end

function love.keypressed(key, scancode, isrepeat)
    if key == 's' and not isrepeat then
        saveScreen()
    end
    if key == 'c' then
        WALKERS_RESPAWN = false
    end
end

function love.mousepressed(x, y, button)
    if mode_DRAW then
        if button == 1 and not brush.drawing then
            brush.drawing = true
        end
    elseif mode_RANDOMWALK then
        WALKERS[#WALKERS+1] = createWalker(vec(x, y))
    end
end

function love.mousereleased( x, y, button, istouch, presses)
    if mode_DRAW then
        if button == 1 and brush.drawing then
            brush.drawing = false
        end
    end
end

function saveScreen()
    if lf.createDirectory(OUTDIR) then
        if lf.getInfo(OUTDIR .. OUTFILE) ~= nil then
            lf.newFile(OUTDIR .. OUTFILE)
        end

        local image_out = CANVAS_IMAGE:newImageData()
        image_out:encode("png", OUTDIR .. OUTFILE)
    end
end

function clearWalkers()
    WALKERS = {}
end

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