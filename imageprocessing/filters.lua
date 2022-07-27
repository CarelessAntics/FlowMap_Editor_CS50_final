-- Normalizes the whole image vectorfield
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
function filterBoxBlur(inImgData, inSamples, inSeparation)

    local function pixelFunction(x, y, r, g, b, a)
        local samples = inSamples
        local separation = inSeparation
        local kernel_size = samples * 2 + 1
        local samples_total = kernel_size * kernel_size
        local kernel = {}
        local pixels = {}

        for i = 0, kernel_size do
            kernel[i + 1] = (i - samples) * separation
        end

        local r_res = 0
        local g_res = 0
        local b_res = 0

        for i = 0, samples_total do
            local x_off = kernel[(i % kernel_size) + 1]
            local y_off = kernel[math.floor(i / kernel_size) + 1]

            --if (x + x_off < SIZE_OUT.x and x + x_off > 0) and (y + y_off < SIZE_OUT.y and y + y_off > 0) then
            local r0, g0, b0, _ = inImgData:getPixel((x + x_off) % SIZE_OUT.x, (y + y_off) % SIZE_OUT.y)
            
            r_res = r_res + (r0 * 2 - 1)
            g_res = g_res + (g0 * 2 - 1)
            b_res = b_res + (b0 * 2 - 1)
        end 

        r_res = r_res / samples_total
        g_res = g_res / samples_total
        b_res = b_res / samples_total

        return r_res*.5+.5, g_res*.5+.5, b_res*.5+.5, a
    end

    local temp = li.newImageData(SIZE_OUT.x, SIZE_OUT.y, "rgba16")
    temp:paste(inImgData, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)
    temp:mapPixel(pixelFunction)
    inImgData:paste(temp, 0, 0, 0, 0, SIZE_OUT.x, SIZE_OUT.y)
end