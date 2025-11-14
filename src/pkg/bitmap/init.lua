local pack = require("pkg.string.pack")

---Generates BMP file header
---@param fileSize integer Total file size in bytes
---@return string Binary header data
local function createFileHeader (fileSize)
    return table.concat({
        "BM", -- Signature
        pack.u32LE(fileSize), -- File size
        pack.u32LE(0), -- Reserved
        pack.u32LE(54), -- Data offset (14 + 40)
    })
end

---Generates bitmap info header
---@param width integer Image width in pixels
---@param height integer Image height in pixels
---@return string Binary header data
local function createBitmapInfoHeader (width, height)
    return table.concat({
        pack.u32LE(40), -- Header size
        pack.i32LE(width), -- Image width
        pack.i32LE(height), -- Image height
        pack.u16LE(1), -- Planes (always 1)
        pack.u16LE(24), -- Bits per pixel
        pack.u32LE(0), -- Compression (0 = uncompressed)
        pack.u32LE(0), -- Image size (0 is valid for uncompressed)
        pack.i32LE(0), -- X pixels per meter (0 = not specified)
        pack.i32LE(0), -- Y pixels per meter (0 = not specified)
        pack.u32LE(0), -- Colors used (0 = all colors)
        pack.u32LE(0), -- Important colors (0 = all important)
    })
end

---Encodes image pixels to BMP format
---Converts RGB to BGR, processes bottom-to-top, adds row padding
---@param image Image Aseprite Image object
---@return string Binary pixel data
local function encodePixels (image)
    local width = image.width
    local height = image.height
    local padding = (4 - (width * 3) % 4) % 4
    local rows = {}

    -- Process rows from bottom to top
    for y = height - 1, 0, -1 do
        local row = {}

        for x = 0, width - 1 do
            local pixel = image:getPixel(x, y)

            -- Store as BGR
            table.insert(row, pack.u8(app.pixelColor.rgbaB(pixel)))
            table.insert(row, pack.u8(app.pixelColor.rgbaG(pixel)))
            table.insert(row, pack.u8(app.pixelColor.rgbaR(pixel)))
        end

        -- Add padding bytes to align row to 4-byte boundary
        table.insert(row, ("\x00"):rep(padding))

        table.insert(rows, table.concat(row))
    end

    return table.concat(rows)
end

---@class BitmapFile
---@field fileHeader string BMP file header (14 bytes)
---@field bitmapInfoHeader string Bitmap info header (40 bytes)
---@field pixelData string Binary pixel data
local BitmapFile = {}

---Converts the bitmap file to a binary string
---@return string
function BitmapFile.tostring (self)
    return table.concat({
        self.fileHeader,
        self.bitmapInfoHeader,
        self.pixelData,
    })
end

---Creates a BitmapFile from an Aseprite Image
---@param image Image Aseprite RGB Image object
---@return BitmapFile
local function createBitmap (image)
    if image.colorMode ~= ColorMode.RGB then
        error("Only RGB images are supported for BMP export")
    end

    -- Calculate sizes
    local rowSize = image.width * 3 + ((4 - (image.width * 3) % 4) % 4)
    local pixelDataSize = rowSize * image.height
    local fileSize = 54 + pixelDataSize -- 14 (file header) + 40 (info header) + pixel data

    -- Generate BMP components
    local fileHeader = createFileHeader(fileSize)
    local bitmapInfoHeader = createBitmapInfoHeader(image.width, image.height)
    local pixelData = encodePixels(image)

    local value = {
        fileHeader = fileHeader,
        bitmapInfoHeader = bitmapInfoHeader,
        pixelData = pixelData,
    }
    setmetatable(value, { __index = BitmapFile, __tostring = BitmapFile.tostring })

    return value
end

return { create = createBitmap }
