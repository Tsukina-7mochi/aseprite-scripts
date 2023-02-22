-- export sprite as psd file
------------------------------------------------------------

ScriptInfo = {
    version = Version("1.3.0-alpha"),
    remote = "https://github.com/Tsukina-7mochi/aseprite-scripts/tree/master/psd"
}

--- Return whether given number is an integer
---@param val any
---@return boolean
function IsInteger(val)
    if type(val)~="number" then
        return false
    end

    return val % 1 .. "" == "0"
end

--- Compress binary data with PackBits
---@param data string
---@return string
function PackBits(data)
    if #data == 0 then
        return data
    end

    local result = ""
    -- buffer stack
    local stack = ""

    -- -1: undetermined
    --  0: continuous value
    --  1: discontinuous value
    local state = -1
    local index = 1
    while index <= #data do
        local currentData = data:sub(index, index)
        local stackTop = stack:sub(1, 1)

        if state == -1 then
            if #stack ~= 0 then
                -- descide state
                if stackTop == currentData then
                    state = 0
                else
                    state = 1
                end
            end

            stack = currentData .. stack
        elseif state == 0 then
            if stackTop == currentData then
                -- just push value
                stack = currentData .. stack
            else
                -- write out buffer contents and reset state
                result = result .. ('B'):pack(256 - (#stack - 1)) .. stackTop
                stack = currentData
                state = -1
            end
        elseif state == 1 then
            if stackTop ~= currentData then
                -- just push value
                stack = currentData .. stack
            else
                -- write out buffer contents and change state
                result = result .. ('B'):pack(#stack - 2) .. stack:sub(2, -1):reverse()
                stack = currentData .. currentData
                state = 0
            end
        end

        if #stack > 0x7F then
            -- write out buffer contents
            if state == 0 then
                result = result .. ('B'):pack(256 - (#stack - 1)) .. stackTop
            elseif state == 1 or state == -1 then
                result = result .. ('B'):pack(#stack - 1) .. stack:reverse()
            end

            -- reset state
            state = -1
            stack = ""
        end

        index = index + 1
    end

    if #stack > 0 then
        -- write out buffer contents
        if state == 0 then
            result = result .. ('B'):pack(256 - (#stack - 1)) .. stack:sub(1, 1)
        elseif state == 1 or state == -1 then
            result = result .. ('B'):pack(#stack - 1) .. stack:reverse()
        end
    end

    return result
end

---@param data integer
function PackU32BE(data)
    return (">I4"):pack(data)
end

---@param data integer
function PackI32BE(data)
    return (">i4"):pack(data)
end

---@param data integer
function PackU16BE(data)
    return (">I2"):pack(data)
end

---@param data integer
function PackU8(data)
    return ("B"):pack(data)
end

function ToPascalString(str, padBase, maxLength)
    local str_ = ""
    if type(maxLength) == "number" then
        str_ = str:sub(1, maxLength - 1)
    else
        str_ = str
    end
    return PackU8(#str_) .. str_ .. PackU8(0):rep(padBase - 1 - #str_ % padBase)
end

---Exports sprite into file
---@param sprite Sprite
---@param filename string
---@param frameNum integer
---@return boolean
---@return string | nil
function ExportToPsd(sprite, filename, frameNum)
    local blendModeTable = {
        [BlendMode.NORMAL]         = "norm",
        [BlendMode.MULTIPLY]       = "mul ",
        [BlendMode.SCREEN]         = "scrn",
        [BlendMode.OVERLAY]        = "over",
        [BlendMode.DARKEN]         = "dark",
        [BlendMode.LIGHTEN]        = "lite",
        [BlendMode.COLOR_DODGE]    = "div ",
        [BlendMode.COLOR_BURN]     = "idiv",
        [BlendMode.HARD_LIGHT]     = "hLit",
        [BlendMode.SOFT_LIGHT]     = "sLit",
        [BlendMode.DIFFERENCE]     = "diff",
        [BlendMode.EXCLUSION]      = "smud",
        [BlendMode.HSL_HUE]        = "hue ",
        [BlendMode.HSL_SATURATION] = "sat ",
        [BlendMode.HSL_COLOR]      = "colr",
        [BlendMode.HSL_LUMINOSITY] = "lum ",
        [BlendMode.ADDITION]       = "lddg",
        [BlendMode.SUBTRACT]       = "fsub",
        [BlendMode.DIVIDE]         = "fdiv",
    }

    ---Returns RGBA pixel color at the given point in the given image
    ---@param image Image
    ---@param x integer
    ---@param y integer
    ---@return integer red
    ---@return integer green
    ---@return integer blue
    ---@return integer alpha
    local function getRGBColor(image, x, y)
        local pixelValue = image:getPixel(x, y)

        if image.colorMode == ColorMode.RGB then
            return app.pixelColor.rgbaR(pixelValue),
                app.pixelColor.rgbaG(pixelValue),
                app.pixelColor.rgbaB(pixelValue),
                app.pixelColor.rgbaA(pixelValue)
        elseif image.colorMode == ColorMode.GRAY then
            return app.pixelColor.grayaV(pixelValue),
                app.pixelColor.grayaV(pixelValue),
                app.pixelColor.grayaV(pixelValue),
                app.pixelColor.grayaA(pixelValue)
        elseif image.colorMode == ColorMode.INDEXED then
            if pixelValue == sprite.transparentColor then
                return 0, 0, 0, 0
            end

            local sprite = image.cel.sprite
            local color = sprite.palettes[1]:getColor(pixelValue)

            return color.red, color.green, color.blue, color.alpha
        end

        return 0, 0, 0, 0
    end

    ---returns whether the given point is in the given bounds
    ---@param bounds Rectangle
    ---@param x integer
    ---@param y integer
    local function pointInBounds(bounds, x, y)
        return bounds.x <= x and x < bounds.x + bounds.width and bounds.y <= y and y < bounds.y + bounds.height
    end

    local file = io.open(filename, "wb")
    if not file then
        return false, "Failed to open the file to export."
    end

    -- ==============================
    -- File Header Section
    -- ==============================
    local fileHeaderData = table.concat({
        "8BPS",                   -- signature
        PackU16BE(1),             -- version = 1
        (">I6"):pack(0),           -- resevered = 0
        PackU16BE(4),             -- channels = 4 (RGBA)
        PackU32BE(sprite.height), -- height
        PackU32BE(sprite.width),  -- width
        PackU16BE(8),             -- depth = 8
        PackU16BE(3),             -- color mode = 3 (RGB)
    })
    file:write(fileHeaderData)

    -- ==============================
    -- Color Mode Data Section
    -- ==============================
    local colorModeData = table.concat({
        PackU32BE(0), -- size = 0
    })
    file:write(colorModeData)

    -- ==============================
    -- Image Resources Section
    -- ==============================
    local imageResourcesData = table.concat({
        PackU32BE(0), -- size = 0
    })
    file:write(imageResourcesData)

    -- ==============================
    -- Layer and Mask Information Section
    -- ==============================
    ---@param image Image
    ---@return string
    ---@return {r: integer, g: integer, b: integer, a: integer}
    local function createImageData(image)
        local sizeBufferR = {} --[[ @type string[] ]]
        local sizeBufferG = {} --[[ @type string[] ]]
        local sizeBufferB = {} --[[ @type string[] ]]
        local sizeBufferA = {} --[[ @type string[] ]]
        local bufferR = {} --[[ @type string[] ]]
        local bufferG = {} --[[ @type string[] ]]
        local bufferB = {} --[[ @type string[] ]]
        local bufferA = {} --[[ @type string[] ]]

        for y = 0, image.height - 1 do
            local rowBufferR = {} --[[ @type string[] ]]
            local rowBufferG = {} --[[ @type string[] ]]
            local rowBufferB = {} --[[ @type string[] ]]
            local rowBufferA = {} --[[ @type string[] ]]

            for x = 0, image.width - 1 do
                local r, g, b, a = getRGBColor(image, x, y)
                rowBufferR[#rowBufferR + 1] = PackU8(r)
                rowBufferG[#rowBufferG + 1] = PackU8(g)
                rowBufferB[#rowBufferB + 1] = PackU8(b)
                rowBufferA[#rowBufferA + 1] = PackU8(a)
            end

            local rowDataR = PackBits(table.concat(rowBufferR))
            local rowDataG = PackBits(table.concat(rowBufferG))
            local rowDataB = PackBits(table.concat(rowBufferB))
            local rowDataA = PackBits(table.concat(rowBufferA))

            if #rowDataR % 2 == 1 then
                rowDataR = rowDataR .. "\x80"
            end
            if #rowDataG % 2 == 1 then
                rowDataG = rowDataG .. "\x80"
            end
            if #rowDataB % 2 == 1 then
                rowDataB = rowDataB .. "\x80"
            end
            if #rowDataA % 2 == 1 then
                rowDataA = rowDataA .. "\x80"
            end

            sizeBufferR[#sizeBufferR + 1] = PackU16BE(#rowDataR)
            sizeBufferG[#sizeBufferG + 1] = PackU16BE(#rowDataG)
            sizeBufferB[#sizeBufferB + 1] = PackU16BE(#rowDataB)
            sizeBufferA[#sizeBufferA + 1] = PackU16BE(#rowDataA)
            bufferR[#bufferR + 1] = rowDataR
            bufferG[#bufferG + 1] = rowDataG
            bufferB[#bufferB + 1] = rowDataB
            bufferA[#bufferA + 1] = rowDataA
        end

        local sizeDataR = table.concat(sizeBufferR)
        local sizeDataG = table.concat(sizeBufferG)
        local sizeDataB = table.concat(sizeBufferB)
        local sizeDataA = table.concat(sizeBufferA)
        local dataR = table.concat(bufferR)
        local dataG = table.concat(bufferG)
        local dataB = table.concat(bufferB)
        local dataA = table.concat(bufferA)

        local sizeR = 2 + #sizeDataR + #dataR
        local sizeG = 2 + #sizeDataG + #dataG
        local sizeB = 2 + #sizeDataB + #dataB
        local sizeA = 2 + #sizeDataA + #dataA

        local data = table.concat({
            -- compression = 1(RLE), size, data
            PackU16BE(1), sizeDataR, dataR,
            PackU16BE(1), sizeDataG, dataG,
            PackU16BE(1), sizeDataB, dataB,
            PackU16BE(1), sizeDataA, dataA,
        })

        return data, { r = sizeR, g = sizeG, b = sizeB, a = sizeA }
    end

    ---@param layerGroup Layer[]
    ---@param frameNum integer
    ---@return string layerRecord
    ---@return string imageData
    ---@return integer layerCount
    local function createLayerRecordAndImageData(layerGroup, frameNum)
        local emptyImageData = "\x00\x00\x00\x00\x00\x00\x00\x00"
        local emptyImageDataSize = { r = 2, g = 2, b = 2, a = 2}
        local emptyLayerName = "\x00\x00\x00\x00"

        local layerCount = 0
        local lrBuffer = {}
        local idBuffer = {}
        for _, layer in ipairs(layerGroup) do
            local layerName = ToPascalString(layer.name, 4, 128)
            local flags = 0
            if not layer.isVisible then
                flags = flags | 2
            end

            if not layer.isGroup then
                -- a normal layer
                local cel = layer:cel(frameNum)
                layerCount = layerCount + 1

                if not cel then
                    -- an empty layer
                    lrBuffer[#lrBuffer + 1] = table.concat({
                        PackU32BE(0), -- top
                        PackU32BE(0), -- left
                        PackU32BE(0), -- bottom
                        PackU32BE(0), -- right
                        PackU16BE(4), -- channel count
                        -- channel information (id, size) x4
                        (">I2>I4"):pack(0x0000, emptyImageDataSize.r),
                        (">I2>I4"):pack(0x0001, emptyImageDataSize.g),
                        (">I2>I4"):pack(0x0002, emptyImageDataSize.b),
                        (">I2>I4"):pack(0xFFFF, emptyImageDataSize.a),
                        "8BIM",                        -- blend mode signature
                        "norm",                        -- blend mode
                        PackU8(layer.opacity),         -- opacity
                        PackU8(0),                     -- clipping
                        PackU8(flags),                 -- flags
                        PackU8(0),                     -- filler
                        PackU32BE(4 + 4 + #layerName), -- extra data field size
                        PackU32BE(0),                  -- layer mask: size = 0
                        PackU32BE(0),                  -- blending ranges data: size = 0
                        layerName,                     -- layer name
                    })
                    idBuffer[#idBuffer + 1] = emptyImageData
                else
                    -- a layer with content
                    local imageData, imageDataSize = createImageData(cel.image)

                    lrBuffer[#lrBuffer + 1] = table.concat({
                        PackI32BE(cel.bounds.y),                     -- top
                        PackI32BE(cel.bounds.x),                     -- left
                        PackI32BE(cel.bounds.y + cel.bounds.height), -- bottom
                        PackI32BE(cel.bounds.x + cel.bounds.width),  -- right
                        PackU16BE(4),                                -- channel count
                        -- channel information (id, size) x4
                        (">I2>I4"):pack(0x0000, imageDataSize.r),
                        (">I2>I4"):pack(0x0001, imageDataSize.g),
                        (">I2>I4"):pack(0x0002, imageDataSize.b),
                        (">I2>I4"):pack(0xFFFF, imageDataSize.a),
                        "8BIM",                              -- blend mode signature
                        blendModeTable[cel.layer.blendMode], -- blend mode
                        PackU8(layer.opacity),               -- opacity
                        PackU8(0),                           -- clipping
                        PackU8(flags),                       -- flags
                        PackU8(0),                           -- filler
                        PackU32BE(4 + 4 + #layerName),       -- extra data field size: TBD
                        PackU32BE(0),                        -- layer mask: size = 0
                        PackU32BE(0),                        -- blending ranges data: size = 0
                        layerName,                           -- layer name
                    })
                    idBuffer[#idBuffer + 1] = imageData
                end
            else
                -- a group
                local closerName = ToPascalString("</Layer " .. layer.name .. " >", 4, 128)

                -- group closer
                lrBuffer[#lrBuffer + 1] = table.concat({
                    PackU32BE(0), -- top
                    PackU32BE(0), -- left
                    PackU32BE(0), -- bottom
                    PackU32BE(0), -- right
                    PackU16BE(4), -- channel count
                    -- channel information (id, size) x4
                    (">I2>I4"):pack(0x0000, emptyImageDataSize.r),
                    (">I2>I4"):pack(0x0001, emptyImageDataSize.g),
                    (">I2>I4"):pack(0x0002, emptyImageDataSize.b),
                    (">I2>I4"):pack(0xFFFF, emptyImageDataSize.a),
                    "8BIM",                                  -- blend mode signature
                    "norm",                                  -- blend mode
                    PackU8(255),                             -- opacity
                    PackU8(0),                               -- clipping
                    PackU8(flags),                           -- flags
                    PackU8(0),                               -- filler
                    PackU32BE(4 + 4 + #closerName + 16),     -- extra data field size
                    PackU32BE(0),                            -- layer mask: size = 0
                    PackU32BE(0),                            -- blending ranges data: size = 0
                    closerName,                              -- layer name
                    "8BIM",                                  -- additional layer information: signature
                    "lsct",                                  -- additional layer information: key = lsct (section devider)
                    PackU32BE(4),                            -- additional layer information: length = 4
                    PackU32BE(3),                            -- additional layer information: data = 3 (bounding section devider)
                })
                idBuffer[#idBuffer + 1] = emptyImageData

                -- encode group recursively
                local childLrData, childIdData, childLayerCount = createLayerRecordAndImageData(layer.layers, frameNum)
                lrBuffer[#lrBuffer + 1] = childLrData
                idBuffer[#idBuffer + 1] = childIdData

                layerCount = layerCount + 2 + childLayerCount

                -- group opener
                local additionalInfoData = 1
                if not layer.isExpanded then
                    additionalInfoData = 2
                end

                lrBuffer[#lrBuffer + 1] = table.concat({
                    PackU32BE(0), -- top
                    PackU32BE(0), -- left
                    PackU32BE(0), -- bottom
                    PackU32BE(0), -- right
                    PackU16BE(4), -- channel count
                    -- channel information (id, size) x4
                    (">I2>I4"):pack(0x0000, emptyImageDataSize.r),
                    (">I2>I4"):pack(0x0001, emptyImageDataSize.g),
                    (">I2>I4"):pack(0x0002, emptyImageDataSize.b),
                    (">I2>I4"):pack(0xFFFF, emptyImageDataSize.a),
                    "8BIM",                                  -- blend mode signature
                    "norm",                                  -- blend mode
                    PackU8(255),                             -- opacity
                    PackU8(0),                               -- clipping
                    PackU8(flags),                           -- flags
                    PackU8(0),                               -- filler
                    PackU32BE(4 + 4 + #layerName + 16),      -- extra data field size
                    PackU32BE(0),                            -- layer mask: size = 0
                    PackU32BE(0),                            -- blending ranges data: size = 0
                    layerName,                               -- layer name
                    "8BIM",                                  -- additional layer information: signature
                    "lsct",                                  -- additional layer information: key = lsct (section devider)
                    PackU32BE(4),                            -- additional layer information: length = 4
                    PackU32BE(additionalInfoData),           -- additional layer information: data = 3 (bounding section devider)
                })
                idBuffer[#idBuffer + 1] = emptyImageData
            end
        end

        return table.concat(lrBuffer), table.concat(idBuffer), layerCount
    end

    local lrData, idData, layerCount = createLayerRecordAndImageData(sprite.layers, frameNum)
    local padLayerAndMask = false
    local layerInfoSize = 2 + #lrData + #idData
    if layerInfoSize % 2 == 1 then
        padLayerAndMask = true
        layerInfoSize = layerInfoSize + 1
    end
    local layerAndMaskData = table.concat({
        PackU32BE(4 + layerInfoSize), -- size
        PackU32BE(layerInfoSize),     -- layer info: size TBD
        PackU16BE(layerCount),        -- layer info: layer count
        lrData,                       -- layer records
        idData,                       -- channel image data
    })
    file:write(layerAndMaskData)
    if padLayerAndMask then
        file:write(PackU8(0))
    end

    -- ==============================
    -- Image Data Section
    -- ==============================
    local tempSprite = Sprite(sprite)
    for _, layer in ipairs(tempSprite.layers) do
        if not layer.isVisible then
            tempSprite:deleteLayer(layer)
        end
    end
    tempSprite:flatten()
    local tempCel = tempSprite.cels[1]
    local tempImage = tempCel.image

    local imageDataSizeBufferR = {} --[[ @type string[] ]]
    local imageDataSizeBufferG = {} --[[ @type string[] ]]
    local imageDataSizeBufferB = {} --[[ @type string[] ]]
    local imageDataSizeBufferA = {} --[[ @type string[] ]]
    local imageDataBufferR = {} --[[ @type string[] ]]
    local imageDataBufferG = {} --[[ @type string[] ]]
    local imageDataBufferB = {} --[[ @type string[] ]]
    local imageDataBufferA = {} --[[ @type string[] ]]
    for y = 0, tempSprite.height - 1 do
        local rowBufferR = {} --[[ @type string[] ]]
        local rowBufferG = {} --[[ @type string[] ]]
        local rowBufferB = {} --[[ @type string[] ]]
        local rowBufferA = {} --[[ @type string[] ]]

        for x = 0, tempSprite.width - 1 do
            if pointInBounds(tempCel.bounds, x, y) then
                local r, g, b, a = getRGBColor(tempImage, x, y)
                rowBufferR[#rowBufferR + 1] = PackU8(r)
                rowBufferG[#rowBufferG + 1] = PackU8(g)
                rowBufferB[#rowBufferB + 1] = PackU8(b)
                rowBufferA[#rowBufferA + 1] = PackU8(a)
            else
                rowBufferR[#rowBufferR + 1] = "\x00"
                rowBufferG[#rowBufferG + 1] = "\x00"
                rowBufferB[#rowBufferB + 1] = "\x00"
                rowBufferA[#rowBufferA + 1] = "\x00"
            end
        end

        local rowDataR = PackBits(table.concat(rowBufferR))
        local rowDataG = PackBits(table.concat(rowBufferG))
        local rowDataB = PackBits(table.concat(rowBufferB))
        local rowDataA = PackBits(table.concat(rowBufferA))

        if #rowDataR % 2 == 1 then
            rowDataR = rowDataR .. "\x80"
        end
        if #rowDataG % 2 == 1 then
            rowDataG = rowDataG .. "\x80"
        end
        if #rowDataB % 2 == 1 then
            rowDataB = rowDataB .. "\x80"
        end
        if #rowDataA % 2 == 1 then
            rowDataA = rowDataA .. "\x80"
        end

        imageDataSizeBufferR[#imageDataSizeBufferR + 1] = PackU16BE(#rowDataR)
        imageDataSizeBufferG[#imageDataSizeBufferG + 1] = PackU16BE(#rowDataG)
        imageDataSizeBufferB[#imageDataSizeBufferB + 1] = PackU16BE(#rowDataB)
        imageDataSizeBufferA[#imageDataSizeBufferA + 1] = PackU16BE(#rowDataA)
        imageDataBufferR[#imageDataBufferR + 1] = rowDataR
        imageDataBufferG[#imageDataBufferG + 1] = rowDataG
        imageDataBufferB[#imageDataBufferB + 1] = rowDataB
        imageDataBufferA[#imageDataBufferA + 1] = rowDataA
    end

    tempSprite:close()

    local imageSizeDataR = table.concat(imageDataSizeBufferR)
    local imageSizeDataG = table.concat(imageDataSizeBufferG)
    local imageSizeDataB = table.concat(imageDataSizeBufferB)
    local imageSizeDataA = table.concat(imageDataSizeBufferA)
    local imageDataR = table.concat(imageDataBufferR)
    local imageDataG = table.concat(imageDataBufferG)
    local imageDataB = table.concat(imageDataBufferB)
    local imageDataA = table.concat(imageDataBufferA)

    local imageData = table.concat({
        -- compression = 1 (RLE)
        PackU16BE(1),
        -- size
        imageSizeDataR,
        imageSizeDataG,
        imageSizeDataB,
        imageSizeDataA,
        -- data
        imageDataR,
        imageDataG,
        imageDataB,
        imageDataA,
    })
    file:write(imageData)

    return true
end

-- if app.apiVersion < 1 then
--     Util.failAlert("This script requires Aseprite v1.2.10-beta3 or above.")
--     return
-- end
--
-- local sprite = app.activeSprite
-- if not sprite then
--     Util.failAlert("No sprite selected.")
--     return
-- end

-- -- show dialog to select output file
-- local filename = app.fs.filePathAndTitle(sprite.filename) .. ".psd"
-- local frameAllString = "All frames as group"
-- local frameList = { frameAllString }
-- for i = 1, #sprite.frames do
--   table.insert(frameList, "" .. i)
-- end
-- local showCompleated = false
--
-- local dialog = Dialog()
-- dialog:file{
--   id = "filename",
--   label = "Filename",
--   title = "Save as...",
--   save = true,
--   filename = filename,
--   filetypes = { "psd" },
-- }:combobox{
--   id = "frameNum",
--   label = "Frame",
--   option = frameList[1],
--   options = frameList
-- }:check{
--   id = "showCompleated",
--   label = "",
--   text = "Show dialog when succeeded",
--   selected = true
-- }:button{
--   id = "ok",
--   text = "&Export",
--   focus = true
-- }:button{
--   id = "cancel",
--   text="&Cancel"
-- }
-- dialog:show()
--
-- if not dialog.data.ok then return end
--
-- filename = dialog.data.filename             --[[@as string]]
-- ---@type string | number
-- local frameNum = dialog.data.frameNum       --[[@as string]]
-- if frameNum ~= frameAllString then
--     frameNum = tonumber(frameNum)           --[[@as number]]
-- end
-- showCompleated = dialog.data.showCompleated --[[@as boolean]]
--
-- if not IsInteger(frameNum) then
--   Util.failAlert("The frame number " .. frameNum .. " is not valid.")
--   return
-- end
-- if frameNum ~= frameAllString and (frameNum < 1 or #sprite.frames < frameNum) then
--   Util.failAlert("The frame number " .. frameNum .. " is out of range.")
--   return
-- end

local succeeded, message = ExportToPsd(app.activeSprite, app.activeSprite.filename .. ".psd", 1)
if not succeeded then
    print(message)
end

-- if showCompleated then
--   local result = app.alert{
--     title = "Export Succeeded",
--     text = "PSD successfully exported as " .. filename,
--     buttons = "OK"
--   }
-- end