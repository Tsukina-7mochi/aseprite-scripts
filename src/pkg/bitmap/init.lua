local pack = require("pkg.string.pack")
local BitmapFile = require("pkg.bitmap.bitmap").BitmapFile

---Generates BMP file header
---@param fileSize integer Total file size in bytes
---@param dataOffset integer? Offset of the pixel data (default: 54 = 14 + 40)
---@return string Binary header data
local function createFileHeader (fileSize, dataOffset)
    return table.concat({
        "BM", -- Signature
        pack.u32LE(fileSize), -- File size
        pack.u32LE(0), -- Reserved
        pack.u32LE(dataOffset or 54), -- Data offset (14 + 40 + color table)
    })
end

---Generates bitmap info header
---@param width integer Image width in pixels
---@param height integer Image height in pixels
---@param bitsPerPixel integer Bits per pixel (e.g., 24 for RGB)
---@param imageSize integer Size of pixel data in bytes
---@param colorsUsed integer? Number of color table entries (default: 0 = all colors)
---@return string Binary header data
local function createInfoHeader (width, height, bitsPerPixel, imageSize, colorsUsed)
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
        pack.u32LE(colorsUsed or 0), -- Colors used (0 = all colors)
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

---Returns the color table key of a pixel: colors are distinguished by their RGB
---value only, since a color table entry has no alpha.
---@param pixel integer RGBA pixel value
---@return integer
local function colorKeyOf (pixel)
    if app.pixelColor.rgbaA(pixel) == 0 then
        return app.pixelColor.rgba(0, 0, 0, 255)
    end

    return app.pixelColor.rgba(
        app.pixelColor.rgbaR(pixel),
        app.pixelColor.rgbaG(pixel),
        app.pixelColor.rgbaB(pixel),
        255
    )
end

---Collects the colors of an image into a color table
---@param image Image Aseprite RGB Image object
---@return integer[] colors Color table entries as RGBA values
---@return table<integer, integer> indexOf Maps a color key to its color table index (0-based)
local function collectColors (image)
    local colors = {}
    local indexOf = {}

    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            local key = colorKeyOf(image:getPixel(x, y))

            if indexOf[key] == nil then
                table.insert(colors, key)
                indexOf[key] = #colors - 1
            end
        end
    end

    return colors, indexOf
end

---Returns the smallest bits per pixel that can index the given number of colors,
---or nil if a BMP color table cannot hold that many colors
---@param colorCount integer
---@return integer?
local function bitsPerPixelFor (colorCount)
    if colorCount <= 2 then
        return 1
    elseif colorCount <= 16 then
        return 4
    elseif colorCount <= 256 then
        return 8
    end
    return nil
end

---Encodes a color table to BMP format (RGBQUAD: blue, green, red, reserved)
---@param colors integer[] Color table entries as RGBA values
---@return string Binary color table data
local function encodeColorTable (colors)
    local entries = {}

    for _, color in ipairs(colors) do
        table.insert(
            entries,
            table.concat({
                pack.u8(app.pixelColor.rgbaB(color)),
                pack.u8(app.pixelColor.rgbaG(color)),
                pack.u8(app.pixelColor.rgbaR(color)),
                pack.u8(0), -- Reserved
            })
        )
    end

    return table.concat(entries)
end

---Encodes image pixels to indexed BMP format
---Processes bottom-to-top, packs indices MSB first, adds row padding
---@param image Image Aseprite RGB Image object
---@param indexOf table<integer, integer> Maps a color key to its color table index
---@param bitsPerPixel integer Bits per pixel (1, 4 or 8)
---@return string Binary pixel data
local function encodeIndexedPixels (image, indexOf, bitsPerPixel)
    local width = image.width
    local height = image.height
    local pixelsPerByte = 8 // bitsPerPixel
    local bytesPerRow = math.ceil(width / pixelsPerByte)
    local padding = (4 - (bytesPerRow % 4)) % 4
    local rows = {}

    -- Process rows from bottom to top
    for y = height - 1, 0, -1 do
        local row = {}
        local byte = 0
        local count = 0

        for x = 0, width - 1 do
            byte = (byte << bitsPerPixel) | indexOf[colorKeyOf(image:getPixel(x, y))]
            count = count + 1

            if count == pixelsPerByte then
                table.insert(row, pack.u8(byte))
                byte = 0
                count = 0
            end
        end

        -- Handle remaining pixels in the row
        if count ~= 0 then
            table.insert(row, pack.u8(byte << ((pixelsPerByte - count) * bitsPerPixel)))
        end

        -- Add padding bytes to align row to 4-byte boundary
        table.insert(row, ("\x00"):rep(padding))

        table.insert(rows, table.concat(row))
    end

    return table.concat(rows)
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

---Creates a BitmapFile with a color table and an alpha mask from an Aseprite Image
---@param image Image Aseprite RGB Image object
---@return BitmapFile? bitmap nil if the image has more than 256 colors
local function createWithAlphaMaskPaletted (image)
    if image.colorMode ~= ColorMode.RGB then
        error("Only RGB images are supported for BMP export")
    end

    local colors, indexOf = collectColors(image)
    local bitsPerPixel = bitsPerPixelFor(#colors)
    if bitsPerPixel == nil then
        return nil
    end

    local colorTable = encodeColorTable(colors)
    local pixelData = encodeIndexedPixels(image, indexOf, bitsPerPixel)
    local alphaMaskData = encodeAlphaMask(image)
    local infoHeader = createInfoHeader(
        image.width,
        image.height * 2, -- double the height for alpha mask
        bitsPerPixel,
        #pixelData, -- not include alpha mask data in image size
        #colors
    )
    local dataOffset = 14 + #infoHeader + #colorTable -- 14: file header
    local fileSize = dataOffset + #pixelData + #alphaMaskData
    local fileHeader = createFileHeader(fileSize, dataOffset)

    return BitmapFile(fileHeader, infoHeader, pixelData .. alphaMaskData, colorTable)
end

return {
    create = create,
    createWithAlphaMask = createWithAlphaMask,
    createWithAlphaMaskPaletted = createWithAlphaMaskPaletted,
}
