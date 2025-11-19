local bitmaps = require("pkg.bitmap")
local pack = require("pkg.string..pack")
local util = require("pkg.asepriteUtil")

---@param filetype "ico" | "cur" | "ani"
---@param numImages integer
---@return string
local function createFileHeader (filetype, numImages)
    -- icon: 1, cursor: 2
    local resourceType = 1
    if filetype == "cur" or filetype == "ani" then
        resourceType = 2
    end

    return table.concat({
        pack.u16LE(0), -- reserved
        pack.u16LE(resourceType),
        pack.u16LE(numImages),
    }, "")
end

---@param width integer
---@param height integer
---@param hotSpotX integer
---@param hotSpotY integer
---@param imageDataSize integer
---@param imageDataOffset integer
---@return string
local function createIconHeader (width, height, hotSpotX, hotSpotY, imageDataSize, imageDataOffset)
    return table.concat({
        pack.u8(width),
        pack.u8(height),
        pack.u8(0), -- number of colors in palette (0 = no palette)
        pack.u8(0), -- reserved
        pack.u16LE(hotSpotX),
        pack.u16LE(hotSpotY),
        pack.u32LE(imageDataSize),
        pack.u32LE(imageDataOffset),
    })
end

---@param params IconCursorParams
---@param targetLayers Layer[]
---@param targetFrames Frame[]
local function createIcon (params, targetLayers, targetFrames)
    local images = {}
    for _, frame in ipairs(targetFrames) do
        local image = util.frame.mergeLayerImages(frame, targetLayers)
        table.insert(images, image)
    end

    local fileHeader = createFileHeader(params.filetype, #targetFrames)

    ---@type string[]
    local iconHeaders = {}
    ---@type string[]
    local imageData = {}
    local dataSizeSum = 0
    for _, frame in ipairs(targetFrames) do
        local image = util.frame.mergeLayerImages(frame, targetLayers)
        local bitmap = bitmaps.createWithAlphaMask(image)

        local dataSize = #bitmap.infoHeader + #bitmap.pixelData
        -- offset = (size of file header) + (number of images) * (size of icon header = 16) + dataSizeSum
        local dataOffset = #fileHeader + (#targetFrames * 16) + dataSizeSum
        local header =
            createIconHeader(image.width, image.height, params.hotSpotX, params.hotSpotY, dataSize, dataOffset)

        table.insert(iconHeaders, header)
        table.insert(
            imageData,
            table.concat({
                bitmap.infoHeader,
                bitmap.pixelData,
            }, "")
        )
        dataSizeSum = dataSizeSum + dataSize
    end

    return table.concat({
        fileHeader,
        table.unpack(iconHeaders),
        table.unpack(imageData),
    }, "")
end

return {
    create = createIcon,
}
