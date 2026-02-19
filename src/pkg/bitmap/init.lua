local pack = require("pkg.string.pack")
local BitmapFile = require("pkg.bitmap.bitmap").BitmapFile

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
---@param bitsPerPixel integer Bits per pixel (e.g., 24 for RGB)
---@param imageSize integer Size of pixel data in bytes
---@return string Binary header data
local function createInfoHeader (width, height, bitsPerPixel, imageSize)
    return table.concat({
        pack.u32LE(40), -- Header size
        pack.i32LE(width), -- Image width
        pack.i32LE(height), -- Image height
        pack.u16LE(1), -- Planes (always 1)
        pack.u16LE(bitsPerPixel), -- Bits per pixel
        pack.u32LE(0), -- Compression (0 = uncompressed)
        pack.u32LE(imageSize), -- Image size
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

---Encodes image alpha pixels to BMP 1-bit image data
---Converts RGB to BGR, processes bottom-to-top, adds row padding
---@param image Image Aseprite Image object
---@return string Binary pixel data
local function encodeAlphaMask (image)
    local width = image.width
    local height = image.height

    -- Calculate row padding to align to 4-byte boundary
    local bitsPerRow = width
    local bytesPerRow = math.ceil(bitsPerRow / 8)
    local padding = (4 - (bytesPerRow % 4)) % 4

    local maskData = ""

    -- Process rows from bottom to top (BMP format)
    for y = height - 1, 0, -1 do
        local mask = 0
        local bitCount = 0

        -- Process pixels from left to right
        for x = 0, width - 1 do
            local pixel = image:getPixel(x, y)
            local alpha = app.pixelColor.rgbaA(pixel)

            -- Set bit to 1 if pixel is transparent (alpha == 0)
            local transparentBit = (alpha == 0) and 1 or 0

            -- Pack bit into current byte (MSB first)
            mask = (mask << 1) | transparentBit
            bitCount = bitCount + 1

            -- When we've packed 8 bits, write the byte
            if bitCount == 8 then
                maskData = maskData .. pack.u8(mask)
                mask = 0
                bitCount = 0
            end
        end

        -- Handle remaining bits in the row (if width is not multiple of 8)
        if bitCount ~= 0 then
            -- Shift remaining bits to MSB position
            mask = mask << (8 - bitCount)
            maskData = maskData .. pack.u8(mask)
        end

        -- Add padding bytes to align row to 4-byte boundary
        maskData = maskData .. ("\x00"):rep(padding)
    end

    return maskData
end

---Creates a BitmapFile from an Aseprite Image
---@param image Image Aseprite RGB Image object
---@return BitmapFile
local function create (image)
    if image.colorMode ~= ColorMode.RGB then
        error("Only RGB images are supported for BMP export")
    end

    local pixelData = encodePixels(image)
    local infoHeader = createInfoHeader(image.width, image.height, 24, #pixelData)
    local fileSize = 14 + #infoHeader + #pixelData -- 14: file header
    local fileHeader = createFileHeader(fileSize)
    return BitmapFile(fileHeader, infoHeader, pixelData)
end

---Creates a BitmapFile with alpha mask from an Aseprite Image
---@param image Image Aseprite RGB Image object
local function createWithAlphaMask (image)
    if image.colorMode ~= ColorMode.RGB then
        error("Only RGB images are supported for BMP export")
    end

    local pixelData = encodePixels(image)
    local alphaMaskData = encodeAlphaMask(image)
    local infoHeader = createInfoHeader(
        image.width,
        image.height * 2, -- double the height for alpha mask
        24,
        #pixelData -- not include alpha mask data in image size
    )
    local fileSize = 14 + #infoHeader + #pixelData + #alphaMaskData -- 14: file header
    local fileHeader = createFileHeader(fileSize)

    return BitmapFile(fileHeader, infoHeader, pixelData .. alphaMaskData)
end

return {
    create = create,
    createWithAlphaMask = createWithAlphaMask,
}
