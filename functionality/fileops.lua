--- Save image
function saveScreen(name_field)

    local outfile = name_field:getValueText() .. '.png'
    getPath(outfile)

    --[[local properties_id = 'fileops_save_properties'
    local properties = UI_main.properties[properties_id].contents
    local outfile = properties['p_save_filename']:getValueText() .. '.png']]

    if outfile == '.png' or outfile == ' .png' then
        outfile = OUTFILE
    end

    if lfs.createDirectory(OUTDIR) then
        if lfs.getInfo(OUTDIR .. outfile) ~= nil then
            lfs.newFile(OUTDIR .. outfile)
        end

        -- local image_out = CANVAS_IMAGE:newImageData()
        IMGDATA_MAIN:encode("png", OUTDIR .. outfile)
    end
end

function getPath(filepath)
    local directories = {}
    for str in string.gmatch(filepath, '([^/]+)') do
        table.insert(directories, str)
    end
    deepPrint(directories)
end

--- load image
---@param filename string
function loadImage(filename)
    -- TODO: implement image size change
    local new_image = li.newImageData(filename)
    local new_w, new_h = new_image:getDimensions()

    screenInit(new_w, new_h)
    IMGDATA_MAIN = new_image
    DISPLAY_IMAGE = lg.newImage(IMGDATA_MAIN)
end

function newImage(size_button_x, size_button_y)
    local size_x = size_button_x:getValueNumber()
    local size_y = size_button_y:getValueNumber() ~= 0 and size_button_y:getValueNumber() or size_x

    screenInit(size_x, size_y)
end

function resizeImage(size_button_x, size_button_y)

    local new_w = size_button_x:getValueNumber()
    local new_h = size_button_y:getValueNumber() ~= 0 and size_button_y:getValueNumber() or new_w

    SIZE_OUT = vec(new_w, new_h)

    local old_img = lg.newImage(IMGDATA_MAIN)
    local format_old = old_img:getFormat()
    local old_w, old_h = old_img:getDimensions()

    local scale_x = new_w / old_w
    local scale_y = new_h / old_h

    local temp_canvas = lg.newCanvas(new_w, new_h, {format = format_old})
    lg.setCanvas(temp_canvas)
    lg.draw(old_img, 0, 0, 0, scale_x, scale_y)
    lg.setCanvas()

    local new_img = temp_canvas:newImageData(format)
    IMGDATA_MAIN = new_img

    initImage()
end