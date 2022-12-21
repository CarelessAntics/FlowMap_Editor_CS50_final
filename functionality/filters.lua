--- Normalize whole image vectorfield
---@param inImgData any
function filterNormalize(UI_ref)

    local function pixelFunction(x, y, r, g, b, a)
        local nR = r * 2 - 1
        local nG = g * 2 - 1
        
        local length = math.sqrt(nR * nR + nG * nG)

        if length > 0.001 then
            nR = nR / length
            nG = nG / length
        else
            return r, g, b, a
        end

        nR = nR * .5 + .5
        nG = nG * .5 + .5

        return nR, nG, b, a
    end

    IMGDATA_MAIN:mapPixel(pixelFunction)
end

-- Box blur implementation. 
-- inSamples: more = better quality
-- inSeparation: more = larger blur radius
function filterBoxBlur(UI_ref)

    -- Retrieve filter properties from UI
    local properties_id = 'f_blur_properties'
    local properties = UI_ref.properties[properties_id].contents

    local separation = properties['p_blur_rad']:getValueNumber()
    local samples = properties['p_blur_samples']:getValueNumber()

    samples = clamp(1, 10, samples)
    separation = math.max(samples, clamp(1, 100, separation))

    local kernel_size = samples * 2 + 1
    local samples_total = kernel_size * kernel_size

    local kernel = {}

    -- Assemble kernel. Create a table from -samples...samples and scale it by separation
    -- samples = 2, separation = 3: {-2, -1, 0, 1, 2} -> {-6, -3, 0, 3, 6}
    for i = 0, kernel_size do
        kernel[i + 1] = (i - samples) * separation
    end

    -- Per pixel function
    local function pixelFunction(x, y, r, g, b, a)

        -- The length of a kernel's "side" e.g. {-9, -6, -3, 0, 3, 6, 9} = 3 * 2 + 1 -> 7^2 = samples_total
        local kernel_size = samples * 2 + 1
        local samples_total = kernel_size * kernel_size

        -- Init tables for kernel and pixel data
        
        local pixels = {}

        -- Init new color values to 0
        local r_res = 0
        local g_res = 0
        local b_res = 0

        -- 1D loop through kernel values and sum the pixel values
        for i = 0, kernel_size do
            for j = 0, kernel_size do
                -- Get pixel offsets by converting 1D index to 2D values
                --local x_off = kernel[(i % kernel_size) + 1]
                --local y_off = kernel[math.floor(i / kernel_size) + 1]

                local x_off = kernel[j + 1]
                local y_off = kernel[i + 1]

                -- Get new pixel values from original image data. For edge pixels, wrap the offsets around
                local r0, g0, b0, _ = IMGDATA_MAIN:getPixel((x + x_off) % SIZE_OUT.x, (y + y_off) % SIZE_OUT.y)
                
                -- Converting pixel values to -1...1 seems to help with image brightening
                r_res = r_res + (r0 * 2 - 1)
                g_res = g_res + (g0 * 2 - 1)
                b_res = b_res + (b0 * 2 - 1)
            end
        end 

        -- Divide by total samples to get the average value
        r_res = r_res / samples_total
        g_res = g_res / samples_total
        b_res = b_res / samples_total

        -- Return modified values and convert back to 0...1
        return r_res*.5+.5, g_res*.5+.5, b_res*.5+.5, a
    end

    local temp = li.newImageData(SIZE_OUT.x, SIZE_OUT.y, "rgba16")
    temp:paste(IMGDATA_MAIN, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)
    temp:mapPixel(pixelFunction)
    IMGDATA_MAIN:paste(temp, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)
end