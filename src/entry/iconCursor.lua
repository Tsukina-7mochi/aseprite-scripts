package.manifest = {
    name = "aseprite-scripts/icon-and-cursor",
    description = "Export sprite as windows icon and cursor.",
    version = "v0.1.1",
    author = "Mooncake Sugar",
    license = "MIT",
    homepage = "https://github.com/Tsukina-7mochi/aseprite-scripts/blob/master/icon-and-cursor/"
}

if not app then return end

-- shows alert with failure message
function FailAlert(text)
    if app.isUIAvailable then
        app.alert {
            title = "Export Failed",
            text = text,
            buttons = "OK"
        }
    else
        io.stdout:write("[Export failed] " .. text)
    end
end

util = {
    ---split string by `sep`
    ---@param str string
    ---@param sep string
    split = function(str, sep)
        if sep == nil then
            sep = "%s"
        end

        local result = {}
        for s in str:gmatch("([" .. sep .. "]+)") do
            table.insert(result, s)
        end

        return result
    end
}

------------------------------
-- ENTRY
------------------------------

if app.apiVersion < 1 then
    FailAlert("This script requires Aseprite v1.2.10-beta3 or above.")
    return
end

if not app.activeSprite then
    FailAlert("No sprite selected.")
    return
end

local sprite = app.activeSprite

local layerList = { "Visible layers", "Active layer" }
for _, layer in ipairs(sprite.layers) do
    table.insert(layerList, "Layer: " .. layer.name)
end
local frameList = { "All" }
for _, tag in ipairs(sprite.tags) do
    table.insert(frameList, "Tag: " .. tag.name)
end
for i = 1, #sprite.frames do
    table.insert(frameList, "Frame: " .. i)
end

---@type "ico" | "cur" | "ani"
local filetype = "ico"
---@type string
local filename = app.fs.filePathAndTitle(sprite.filename) .. "." .. filetype
---@type number
local hotSpotX = 0
---@type number
local hotSpotY = 0
---@type number
local framerate = math.floor(sprite.frames[1].duration * 60)
---@type boolean
local showCompleated = true
---@type integer[]
local targetframeNums = {}
---@type string[]
local excludedLayerNames = {}
---@type boolean
local exitScript = false
---@type boolean
local printProcessInfo = false

function SetParamFromDialog()
    local fileTypes = { "ico", "cur", "ani" }
    local paramTypes = {
        icoSeparator = { "ico" },
        curSeparator = { "cur" },
        aniSeparator = { "ani" },
        hotSpotX = { "cur", "ani" },
        hotSpotY = { "cur", "ani" },
        frame = { "ico", "cur", "ani" },
        layer = { "ico", "cur", "ani" },
        framerate = { "ani" }
    }

    local dialog = Dialog()
    local function updateDialogElementVisibility()
        ---@type string
        for id, param in pairs(paramTypes) do
            local visible = false
            for _, p in ipairs(param) do
                if p == dialog.data.filetype then
                    visible = true
                end
            end
            dialog:modify {
                id = id,
                visible = visible
            }
        end
    end

    dialog:combobox {
        id = "filetype",
        label = "Type",
        option = fileTypes[1],
        options = fileTypes,
        onchange = function()
            -- update extension of filename
            local filename = app.fs.filePathAndTitle(dialog.data.filename --[[@as string]])
            filename = filename .. "." .. dialog.data.filetype

            dialog:modify {
                id = "filename",
                filename = filename
            }

            -- update frame selection
            if (dialog.data.filetype --[[@as string]]) == "ani" then
                if (dialog.data.frame --[[@as string]]):sub(1, 7) == "Frame: " then
                    dialog:modify {
                        id = "frame",
                        option = "All"
                    }
                end
            end

            updateDialogElementVisibility()
        end
    }:file {
        id = "filename",
        label = "Filename",
        title = "Export as...",
        save = true,
        filename = filename,
        filetypes = { "ico" }
    }:separator {
        id = "icoSeparator",
        text = ".ico file option"
    }:separator {
        id = "curSeparator",
        text = ".cur file option"
    }:separator {
        id = "aniSeparator",
        text = ".ani file option"
    }:combobox {
        id = "layer",
        label = "Layers",
        option = layerList[1],
        options = layerList
    }:combobox {
        id = "frame",
        label = "Frames",
        option = "Frame: 1",
        options = frameList
    }:number {
        id = "hotSpotX",
        label = "HotSpot",
        text = "0"
    }:number {
        id = "hotSpotY",
        text = "0"
    }:number {
        id = "framerate",
        label = "Framerate (1/60s)",
        text = "" .. framerate,
        onchange = function()
            dialog:modify {
                id = "framerate",
                text = math.min(0, dialog.data.framerate --[[@as number]])
            }
        end
    }:check {
        id = "showCompleated",
        label = "",
        text = "Show dialog when succeeded",
        selected = true
    }:button {
        id = "ok",
        text = "&Export",
        focus = true
    }:button {
        id = "cancel",
        text = "&Cancel"
    }

    updateDialogElementVisibility()

    repeat
        local retype = false
        dialog:show()

        local filetype_ = dialog.data.filetype --[[@as string]]
        local filename_ = dialog.data.filename --[[@as string]]
        local layer_ = dialog.data.layer --[[@as string]]
        local frame_ = dialog.data.frame --[[@as string]]
        local hotSpotX_ = dialog.data.hotSpotX --[[@as number]]
        local hotSpotY_ = dialog.data.hotSpotY --[[@as number]]
        local framerate_ = dialog.data.framerate --[[@as number]]
        local showCompleated_ = dialog.data.showCompleated --[[@as boolean]]

        assert(type(filetype_) == "string", "filetype_ must be string, got" .. type(filetype_))
        assert(type(filename_) == "string", "filename_ must be string, got" .. type(filename_))
        assert(type(layer_) == "string", "layer_ must be string, got" .. type(layer_))
        assert(type(frame_) == "string", "frame_ must be string, got" .. type(frame_))
        assert(type(hotSpotX_) == "number", "hotSpotX_ must be number, got" .. type(hotSpotX_))
        assert(type(hotSpotY_) == "number", "hotSpotX_ must be number, got" .. type(hotSpotY_))
        assert(type(framerate_) == "number", "framerate_ must be number, got" .. type(framerate_))
        assert(type(showCompleated_) == "boolean", "showCompleated_ must be boolean, got" .. type(showCompleated_))

        if not dialog.data.ok then
            exitScript = true
            break
        end

        if filetype_ ~= "ico" and filetype_ ~= "cur" and filetype_ ~= "ani" then
            retype = true
            app.alert {
                title = "Invalid configuration",
                text = "The file type " .. filetype_ .. " is not supported"
            }
        else
            filetype = filetype_ --[[@as "ico" | "cur" | "ani"]]
        end

        filename = filename_

        excludedLayerNames = {}
        if layer_ == "Visible layers" then
            for _, layer in ipairs(sprite.layers) do
                if not layer.isVisible then
                    excludedLayerNames[#excludedLayerNames + 1] = layer.name
                end
            end
        elseif layer_ == "Active layer" then
            for _, layer in ipairs(sprite.layers) do
                if layer.name ~= app.activeLayer then
                    excludedLayerNames[#excludedLayerNames + 1] = layer.name
                end
            end
        elseif layer_:sub(1, 7) == "Layer: " then
            local layerName = layer_:sub(8)
            for _, layer in ipairs(sprite.layers) do
                if layer.name ~= layerName then
                    excludedLayerNames[#excludedLayerNames + 1] = layer.name
                end
            end
        end

        targetframeNums = {}
        if frame_ == "All" then
            for _, frame in ipairs(sprite.frames) do
                targetframeNums[#targetframeNums + 1] = frame.frameNumber
            end
        elseif frame_:sub(1, 7) == "Frame: " then
            targetframeNums[1] = tonumber(frame_:sub(8))
        elseif frame_:sub(1, 5) == "Tag: " then
            local tagName = frame_:sub(6)
            for _, tag in ipairs(sprite.tags) do
                if tag.name == tagName then
                    for i = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
                        targetframeNums[#targetframeNums + 1] = i
                    end
                end
            end
        end

        if hotSpotX_ < 0 then
            retype = true
            app.alert {
                title = "Invalid configuration",
                text = "Hot spot x is too small."
            }
        elseif hotSpotX_ >= sprite.width then
            retype = true
            app.alert {
                title = "Invalid configuration",
                text = "Hot spot x is too big."
            }
        else
            hotSpotX = hotSpotX_
        end

        if hotSpotY_ < 0 then
            retype = true
            app.alert {
                title = "Invalid configuration",
                text = "Hot spot y is too small."
            }
        elseif hotSpotY_ >= sprite.height then
            retype = true
            app.alert {
                title = "Invalid configuration",
                text = "Hot spot y is too big."
            }
        else
            hotSpotY = hotSpotY_
        end

        framerate_ = math.floor(framerate_)
        if framerate_ < 1 then
            retype = true
            app.alert {
                title = "Invalid configuration",
                text = "The frame rate is too small."
            }
        end

        showCompleated = showCompleated_
    until not retype

    if not dialog.data.ok then return end
end

function SetParamFromCLIArg()
    printProcessInfo = true

    for key, value in pairs(app.params) do
        key = key:lower()

        if key == "type" or "filetype" then
            if value == "ico" or value == "cur" or value == "ani" then
                filetype = value
            else
                io.stderr:write("[Export failed] Invalid file type " .. value)
            end
            exitScript = true
        elseif key == "out" or "filename" then
            filename = value
        elseif key == "hotspotX" then
            local num = tonumber(value)
            if type(num) ~= "number" then
                io.stderr:write("[Export failed] " .. value .. " is not valid for hot spot X")
                exitScript = true
            end
            if num < 0 or num >= sprite.width then
                io.stderr:write("[Export failed] " .. value .. " is out of range for hot spot X")
                exitScript = true
            end
            hotSpotX = num --[[@as number]]
        elseif key == "hotspotY" then
            local num = tonumber(value)
            if type(num) ~= "number" then
                io.stderr:write("[Export failed] " .. value .. " is not valid for hot spot Y")
                exitScript = true
            end
            if num < 0 or num >= sprite.height then
                io.stderr:write("[Export failed] " .. value .. " is out of range for hot spot Y")
                exitScript = true
            end
            hotSpotY = num --[[@as number]]
        elseif key == "framerate" then
            local num = tonumber(value)
            if type(num) ~= "number" then
                io.stderr:write("[Export failed] " .. value .. " is not valid for framerate")
                exitScript = true
            end
            if num < 0 then
                io.stderr:write("[Export failed] " .. value .. " is out of range for framerate")
                exitScript = true
            end
            framerate = num --[[@as number]]
        elseif key == "frames" then
            local s = util.split(value, ",")
            for _, str in ipairs(s) do
                local num = tonumber(str)
                if type(num) == "number" then
                    targetframeNums[#targetframeNums + 1] = num
                end
            end
        elseif key == "leyers" then
            if value == "__visible" then
                for _, layer in ipairs(sprite.layers) do
                    if not layer.isVisible then
                        excludedLayerNames[#excludedLayerNames + 1] = layer.name
                    end
                end
            else
                local included = util.split(value, ",")

                for _, layer in ipairs(sprite.layers) do
                    local toExclude = true
                    for _, name in ipairs(included) do
                        if layer.name == name then
                            toExclude = false
                        end
                    end
                    if toExclude then
                        excludedLayerNames[#excludedLayerNames + 1] = layer.name
                    end
                end
            end
        end
    end
end

if app.isUIAvailable then
    SetParamFromDialog()
else
    SetParamFromCLIArg()
end

if exitScript then
    return
end

if printProcessInfo then
    print("Filetype: " .. filetype)
    print("Filename: " .. filename)
    print("Hot Spot: (" .. hotSpotX .. ", " .. hotSpotY .. ")")
    print("Framerate: " .. framerate)
    print("Target cels: ")
    for _, layer in ipairs(sprite.layers) do
        local excluded = false
        for _, name in ipairs(excludedLayerNames) do
            if layer.name == name then
                excluded = true
            end
        end

        if not excluded then
            for _, index in ipairs(targetframeNums) do
                print("  " .. layer.name .. "[" .. index .. "]")
            end
        end
    end
end

if #targetframeNums < 1 then
    FailAlert("No frame to export.")
    return
end

if #sprite.layers - #excludedLayerNames < 1 then
    FailAlert("No layer to export.")
    return
end

sprite = Sprite(app.activeSprite)
for _, name in ipairs(excludedLayerNames) do
    sprite:deleteLayer(name)
end
sprite:flatten()

---@type Cel[]
local targetCels = {}
for _, cel in ipairs(sprite.cels) do
    local included = false
    for _, index in ipairs(targetframeNums) do
        if cel.frameNumber == index then
            included = true
        end
    end

    if included then
        targetCels[#targetCels + 1] = cel
    end
end

local bitmapInfoHeaderSize = 40

---`true` if the native endian is little endian, `false` otherwise
local isLittleEndian = string.pack("=I2", 1):byte(1) == 1

---Gets color from cel image in sprite space
---@param x integer
---@param y integer
---@param cel Cel
---@return string color BGRA color
function GetColorSpriteSpace(x, y, cel)
    if x < cel.bounds.x then
        return PackU32LE(0x00000000)
    end
    if y < cel.bounds.y then
        return PackU32LE(0x00000000)
    end
    if x >= cel.bounds.x + cel.bounds.width then
        return PackU32LE(0x00000000)
    end
    if y >= cel.bounds.y + cel.bounds.height then
        return PackU32LE(0x00000000)
    end

    local pixel = cel.image:getPixel(x - cel.bounds.x, y - cel.bounds.y)
    if cel.image.colorMode == ColorMode.RGB then
        if isLittleEndian then
            -- ordering: ABGR
            return (">I3I1"):pack(pixel & 0xFFFFFF, pixel & 0xFF)
        else
            -- ordering: RGBA
            return ("<I3I1"):pack(pixel >> 8, pixel & 0xFF)
        end
    elseif cel.image.colorMode == ColorMode.GRAY then
        local v = 0
        if isLittleEndian then
            -- ordering: AV
            v = pixel & 0xFF
        else
            -- ordering: VA
            v = (pixel & 0xFF00) >> 8
        end

        return ("I1I1I1I1"):pack(v, v, v, pixel & 0xFF)
    elseif cel.image.colorMode == ColorMode.INDEXED then
        if pixel == cel.image.spec.transparentColor then
            return PackU32LE(0x00000000)
        end

        local color = sprite.palettes[1]:getColor(pixel).rgbaPixel

        if isLittleEndian then
            -- ordering: ABGR
            return (">I3I1"):pack(color & 0xFFFFFF, color & 0xFF)
        else
            -- ordering: RGBA
            return ("<I3I1"):pack(color >> 8, color & 0xFF)
        end
    end

    return PackU32LE(0x00000000)
end

function PackU32LE(value)
    return ("<I4"):pack(value)
end

---Create ico or cur file data of given cels
---@param targetCels Cel[]
---@param resourceType integer
---@param hotSpotX integer
---@param hotSpotY integer
---@return string
function CreateIcoOrCur(targetCels, resourceType, hotSpotX, hotSpotY)
    -- create image data
    local images = {}
    for i, cel in ipairs(targetCels) do
        local colorData = ""
        local maskData = ""
        local mask = 0
        local maskCount = 0

        for y = sprite.height - 1, 0, -1 do
            mask = 0
            maskCount = 0

            for x = 0, sprite.width - 1 do
                local color = GetColorSpriteSpace(x, y, cel)
                colorData = colorData .. color:sub(1, 3) .. "\0"
                local alphaFlag = 0
                if color:byte(4) == 0 then
                    alphaFlag = 1
                end

                mask = mask << 1 | alphaFlag
                maskCount = maskCount + 1
                if maskCount == 8 then
                    maskData = maskData .. ("I1"):pack(mask)
                    mask = 0
                    maskCount = 0
                end
            end

            if maskCount ~= 0 then
                maskData = maskData .. ("I1"):pack(mask << (8 - maskCount))
            end

            if #colorData % 4 ~= 0 then
                colorData = colorData .. ("\0"):rep(4 - #colorData % 4)
            end
            if #maskData % 4 ~= 0 then
                maskData = maskData .. ("\0"):rep(4 - #maskData % 4)
            end
        end

        images[i] = {
            color = colorData,
            mask = maskData
        }
    end

    local data = ""

    -- file header
    local fileHeader = {
        resevered = 0,
        resourceType = resourceType,
        numOfImgs = #targetCels
    }
    data = data .. ("<I2<I2<I2"):pack(
        fileHeader.resevered,
        fileHeader.resourceType,
        fileHeader.numOfImgs
    )

    -- icon header
    -- record offset of icon header to update info later
    local offsetAddresses = {}
    for index, frame in ipairs(targetCels) do
        local iconHeader = {
            width = sprite.width,
            height = sprite.height,
            numOfColors = 0,
            resevered = 0,
            hotSpotX = hotSpotX,
            hotSpotY = hotSpotY,
            dataSize = bitmapInfoHeaderSize + #images[index].color + #images[index].mask,
            dataOffset = 0 -- deside later
        }

        data = data .. ("I1I1I1I1<I2<I2<I4<I4"):pack(
            iconHeader.width,
            iconHeader.height,
            iconHeader.numOfColors,
            iconHeader.resevered,
            iconHeader.hotSpotX,
            iconHeader.hotSpotY,
            iconHeader.dataSize,
            iconHeader.dataOffset
        )

        offsetAddresses[index] = #data - 4
    end

    -- each icon (or cursor)
    for index, frame in ipairs(targetCels) do
        -- set offset in icon header
        data = data:sub(1, offsetAddresses[index]) .. PackU32LE(#data) .. data:sub(offsetAddresses[index] + 5)

        local bitmapInfoHeader = {
            size = bitmapInfoHeaderSize,
            width = sprite.width,
            -- why doubled?
            height = sprite.height * 2,
            planes = 1,
            bitsPerPixel = 32,
            compression = 0,
            imageSize = #images[index].color,
            pixelPerMeterX = 0,
            pixelPerMeterY = 0,
            numOfPalettes = 0,
            numOfImportatntColors = 0
        }

        data = data .. ("<I4<I4<I4<I2<I2<I4<I4<I4<I4<I4<I4"):pack(
            bitmapInfoHeader.size,
            bitmapInfoHeader.width,
            bitmapInfoHeader.height,
            bitmapInfoHeader.planes,
            bitmapInfoHeader.bitsPerPixel,
            bitmapInfoHeader.compression,
            bitmapInfoHeader.imageSize,
            bitmapInfoHeader.pixelPerMeterX,
            bitmapInfoHeader.pixelPerMeterY,
            bitmapInfoHeader.numOfPalettes,
            bitmapInfoHeader.numOfImportatntColors
        )

        -- there is no palettes

        -- pixel data
        data = data .. images[index].color

        -- mask data data
        data = data .. images[index].mask
    end

    return data
end

---@type string
local fileData

if filetype == "ico" then
    fileData = CreateIcoOrCur(targetCels, 1, 0, 0)
elseif filetype == "cur" then
    fileData = CreateIcoOrCur(targetCels, 2, hotSpotX, hotSpotY)
elseif filetype == "ani" then
    fileData = ""

    local riffSizeIndex = 0
    local listSizeIndex = 0

    fileData = fileData .. "RIFF"
    -- size of file, deside later
    riffSizeIndex = #fileData
    fileData = fileData .. PackU32LE(0)
    -- signature
    fileData = fileData .. "ACON"

    -- animation header
    fileData = fileData .. "anih"
    -- ani header size
    fileData = fileData .. PackU32LE(36)
    -- data size?
    fileData = fileData .. PackU32LE(36)
    -- number of frames
    fileData = fileData .. PackU32LE(#targetCels)
    -- number of steps
    fileData = fileData .. PackU32LE(#targetCels)
    -- width and height
    -- store zeros because images are stored as icon format
    fileData = fileData .. PackU32LE(0)
    fileData = fileData .. PackU32LE(0)
    -- bits per pixel, as the same as width and height
    fileData = fileData .. PackU32LE(0)
    -- planes
    fileData = fileData .. PackU32LE(1)
    -- frame rate
    fileData = fileData .. PackU32LE(framerate)
    -- flags: 0b01 (no sequence data, ico file in LIST)
    fileData = fileData .. PackU32LE(1)

    -- LIST header
    fileData = fileData .. "LIST"
    -- LIST size
    listSizeIndex = #fileData
    fileData = fileData .. PackU32LE(0)
    -- signature
    fileData = fileData .. "fram"

    -- each image as cur
    for _, cel in ipairs(targetCels) do
        fileData = fileData .. "icon"

        local curData = CreateIcoOrCur({ cel }, 2, hotSpotX, hotSpotY)
        fileData = fileData .. PackU32LE(#curData)
        fileData = fileData .. curData
    end

    local listSize = #fileData - listSizeIndex - 4
    local sizeStr = PackU32LE(listSize)
    fileData = fileData:sub(1, listSizeIndex) .. sizeStr .. fileData:sub(listSizeIndex + 5)

    local riffSize = #fileData - riffSizeIndex - 4
    sizeStr = PackU32LE(riffSize)
    fileData = fileData:sub(1, riffSizeIndex) .. sizeStr .. fileData:sub(riffSizeIndex + 5)
else
    FailAlert("The format \"" .. filetype "\" is not implemented.")
    return
end

local file = io.open(filename, "wb")
if not file then
    FailAlert("Failed to open the file to export.")
    return
end

file:write(fileData)

file:close()
sprite:close()

if showCompleated then
    if app.isUIAvailable then
        app.alert {
            title = "Export Finished",
            text = "Successfully exported to " .. filename,
            buttons = "OK"
        }
    else
        print("Successfully exported to " .. filename)
    end
end
