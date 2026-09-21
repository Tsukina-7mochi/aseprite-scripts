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
        pack.u8(width % 256),
        pack.u8(height % 256),
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
---@param sizes Size[]
---@return string
local function createIcon (params, targetLayers, targetFrames, sizes)
    local fileHeader = createFileHeader(params.filetype, #targetFrames * #sizes)

    ---@type string[]
    local iconHeaders = {}
    ---@type string[]
    local imageData = {}
    local dataSizeSum = 0
    for _, frame in ipairs(targetFrames) do
        local frameImage = util.frame.mergeLayerImages(frame, targetLayers)

        for _, size in ipairs(sizes) do
            -- Scale by the largest integer factor that fits into the target size
            local scale =
                math.max(1, math.floor(math.min(size.width / frameImage.width, size.height / frameImage.height)))
            local bounds = Rectangle(0, 0, frameImage.width * scale, frameImage.height * scale)
            local image = util.image.scaleInto(frameImage, size, bounds)
            local bitmap = bitmaps.createWithAlphaMask(image)

            local dataSize = #bitmap.infoHeader + #bitmap.pixelData
            -- offset = (size of file header) + (number of images) * (size of icon header = 16) + dataSizeSum
            local dataOffset = #fileHeader + (#targetFrames * #sizes * 16) + dataSizeSum
            local header = createIconHeader(
                image.width,
                image.height,
                params.filetype == "ico" and 0 or params.hotSpotX * scale,
                params.filetype == "ico" and 0 or params.hotSpotY * scale,
                dataSize,
                dataOffset
            )

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
    end

    return table.concat({
        fileHeader,
        table.concat(iconHeaders),
        table.concat(imageData),
    }, "")
end

return {
    create = createIcon,
}
