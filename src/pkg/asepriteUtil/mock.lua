---Mock implementations of Aseprite APIs for testing

---Mock ColorMode enum
---@class ColorMode
local ColorMode = {
    RGB = 0,
    GRAY = 1,
    INDEXED = 2,
}

---Mock app.pixelColor API
---RGBA format: R=bits[0-7], G=bits[8-15], B=bits[16-23], A=bits[24-31]
local pixelColor = {
    ---Constructs a 32-bit RGBA pixel value
    ---@param r integer Red component (0-255)
    ---@param g integer Green component (0-255)
    ---@param b integer Blue component (0-255)
    ---@param a? integer Alpha component (0-255), defaults to 255
    ---@return integer
    rgba = function (r, g, b, a)
        a = a or 255
        return r | (g << 8) | (b << 16) | (a << 24)
    end,

    ---Extracts red component from RGBA pixel
    ---@param pixel integer
    ---@return integer
    rgbaR = function (pixel)
        return pixel & 0xFF
    end,

    ---Extracts green component from RGBA pixel
    ---@param pixel integer
    ---@return integer
    rgbaG = function (pixel)
        return (pixel >> 8) & 0xFF
    end,

    ---Extracts blue component from RGBA pixel
    ---@param pixel integer
    ---@return integer
    rgbaB = function (pixel)
        return (pixel >> 16) & 0xFF
    end,

    ---Extracts alpha component from RGBA pixel
    ---@param pixel integer
    ---@return integer
    rgbaA = function (pixel)
        return (pixel >> 24) & 0xFF
    end,
}

---Mock app object
local app = {
    pixelColor = pixelColor,
}

---Creates a mock Image object for testing
---@param width integer Image width in pixels
---@param height integer Image height in pixels
---@param pixelData integer[] Array of RGBA pixel values (length = width * height)
---@return table Mock Image object
local function createImage (width, height, pixelData)
    return {
        width = width,
        height = height,
        colorMode = ColorMode.RGB,
        bytesPerPixel = 4,
        rowStride = width * 4,
        ---Gets pixel at x,y coordinates
        ---@param x integer
        ---@param y integer
        ---@return integer
        getPixel = function (self, x, y)
            return pixelData[y * width + x + 1]
        end,
    }
end

return {
    ColorMode = ColorMode,
    app = app,
    createImage = createImage,
}
