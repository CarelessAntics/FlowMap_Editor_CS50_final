--- Normalize whole image vectorfield
---@param inImgData any
function filterNormalize(inImgData)

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

    inImgData:mapPixel(pixelFunction)
end

-- Box blur implementation. 
-- inSamples: more = better quality
-- inSeparation: more = larger blur radius
function filterBoxBlur(inImgData)

    local inSamples = 4
    local inSeparation = 8

    -- Per pixel function
    local function pixelFunction(x, y, r, g, b, a)
        local samples = inSamples
        local separation = inSeparation

        -- The length of a kernel's "side" e.g. {-9, -6, -3, 0, 3, 6, 9} = 3 * 2 + 1 -> 7^2 = samples_total
        local kernel_size = samples * 2 + 1
        local samples_total = kernel_size * kernel_size

        -- Init tables for kernel and pixel data
        local kernel = {}
        local pixels = {}

        -- Assemble kernel. Create a table from -samples...samples and scale it by separation
        -- samples = 2, separation = 3: {-2, -1, 0, 1, 2} -> {-6, -3, 0, 3, 6}
        for i = 0, kernel_size do
            kernel[i + 1] = (i - samples) * separation
        end

        -- Init new color values to 0
        local r_res = 0
        local g_res = 0
        local b_res = 0

        -- 1D loop through kernel values and sum the pixel values
        for i = 0, samples_total do
            -- Get pixel offsets by converting 1D index to 2D values
            local x_off = kernel[(i % kernel_size) + 1]
            local y_off = kernel[math.floor(i / kernel_size) + 1]

            -- Get new pixel values from original image data. For edge pixels, wrap the offsets around
            local r0, g0, b0, _ = inImgData:getPixel((x + x_off) % SIZE_OUT.x, (y + y_off) % SIZE_OUT.y)
            
            -- Converting pixel values to -1...1 seems to help with image brightening
            r_res = r_res + (r0 * 2 - 1)
            g_res = g_res + (g0 * 2 - 1)
            b_res = b_res + (b0 * 2 - 1)
        end 

        -- Divide by total samples to get the average value
        r_res = r_res / samples_total
        g_res = g_res / samples_total
        b_res = b_res / samples_total

        -- Return modified values and convert back to 0...1
        return r_res*.5+.5, g_res*.5+.5, b_res*.5+.5, a
    end

    local temp = li.newImageData(SIZE_OUT.x, SIZE_OUT.y, "rgba16")
    temp:paste(inImgData, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)
    temp:mapPixel(pixelFunction)
    inImgData:paste(temp, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)
end