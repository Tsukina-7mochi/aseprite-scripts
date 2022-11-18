-- shows alert with failure message
function FailAlert(text)
  app.alert{
    title = "Export Failed",
    text = text,
    buttons = "OK"
  }
end

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

local frameList = {"All"}
for i = 1, #sprite.frames do
  table.insert(frameList, "" .. i)
end
local tagList = {"All"}
for _, tag in ipairs(sprite.tags) do
    table.insert(tagList, tag.name .. " ")
end

local fileTypes = { "ico", "cur", "ani" }
local paramTypes = {
    icoSeparator={ "ico" },
    curSeparator={ "cur" },
    aniSeparator={ "ani" },
    hotSpotX={ "cur", "ani" },
    hotSpotY={ "cur", "ani" },
    frame={ "ico", "cur" },
    framerate={ "ani" },
    tag={"ani"}
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
        dialog:modify{
            id=id,
            visible=visible
        }
    end
end

dialog:combobox{
    id="filetype",
    label="Type",
    option=fileTypes[1],
    options=fileTypes,
    onchange=function()
        -- update extension of filename
        local filename = app.fs.filePathAndTitle(dialog.data.filename --[[@as string]])
        filename = filename .. "." .. dialog.data.filetype

        dialog:modify{
            id="filename",
            filename=filename
        }
        -- update visibility of each dialog element

        updateDialogElementVisibility()
    end
}:file{
    id="filename",
    label="Filename",
    title="Export as...",
    save=true,
    filename=app.fs.filePathAndTitle(sprite.filename) .. ".ico",
    filetypes={"ico"}
}:separator{
    id="icoSeparator",
    text=".ico file option"
}:separator{
    id="curSeparator",
    text=".cur file option"
}:separator{
    id="aniSeparator",
    text=".ani file option"
}:combobox{
    id="frame",
    label="Frame",
    option="1",
    options=frameList
}:combobox{
    id="tag",
    label="Tag of All",
    option="1",
    options=tagList
}:number{
    id="hotSpotX",
    label="HotSpot",
    text="0"
}:number{
    id="hotSpotY",
    text="0"
}:number{
    id="framerate",
    label="Framerate (1/60s)",
    text="" .. math.floor(sprite.frames[1].duration * 60),
    onchange=function()
        dialog:modify{
            id="framerate",
            text=math.min(0, dialog.data.framerate --[[@as number]])
        }
    end
}:check{
    id="showCompleated",
    label="",
    text="Show dialog when succeeded",
    selected=true
}:button{
    id="ok",
    text="&Export",
    focus=true
}:button{
    id="cancel",
    text="&Cancel"
}

updateDialogElementVisibility()

local filetype = dialog.data.filetype   --[[@as string]]
local filename = dialog.data.filename   --[[@as string]]
local frame = dialog.data.frame         --[[@as string]]
local tag = dialog.data.tag            --[[@as string]]
local hotSpotX = dialog.data.hotSpotX   --[[@as number]]
local hotSpotY = dialog.data.hotSpotY   --[[@as number]]
local framerate = dialog.data.framerate --[[@as number]]
local showCompleated = dialog.data.showCompleated --[[@as boolean]]

repeat
    local retype = false
    dialog:show()

    filetype = dialog.data.filetype   --[[@as string]]
    filename = dialog.data.filename   --[[@as string]]
    frame = dialog.data.frame         --[[@as string]]
    tag = dialog.data.tag            --[[@as string]]
    hotSpotX = dialog.data.hotSpotX   --[[@as number]]
    hotSpotY = dialog.data.hotSpotY   --[[@as number]]
    framerate = dialog.data.framerate --[[@as number]]
    showCompleated = dialog.data.showCompleated --[[@as boolean]]

    if dialog.data.cancel then break end

    if hotSpotX < 0 then
        retype  = true
        app.alert{
            title="Value error",
            text="Hot spot x is too small."
        }
    end
    if hotSpotX >= sprite.width then
        retype  = true
        app.alert{
            title="Value error",
            text="Hot spot x is too big."
        }
    end
    if hotSpotY < 0 then
        retype  = true
        app.alert{
            title="Value error",
            text="Hot spot y is too small."
        }
    end
    if hotSpotY >= sprite.height then
        retype  = true
        app.alert{
            title="Value error",
            text="Hot spot y is too big."
        }
    end
until not retype

if not dialog.data.ok then return end

sprite = Sprite(app.activeSprite)
for _, layer in ipairs(sprite.layers) do
    if not layer.isVisible then
        sprite:deleteLayer(layer)
    end
end
sprite:flatten()

local targetCels = {}
if filetype == "ani" then
    if tag == "All" then
        targetCels = sprite.cels
    else
        local tagname = tag:sub(1, #tag - 1)
        for _, tag in ipairs(sprite.tags) do
            if tag.name == tagname then
                for i = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
                    targetCels[#targetCels + 1] = sprite.cels[i]
                end
            end
        end
    end
else
    if frame == "All" then
        targetCels = sprite.cels
    else
        targetCels = { sprite.cels[tonumber(frame)] }
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

        local color = sprite.setPalette[1]:getColor(pixel).rgbaPixel

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
            color=colorData,
            mask=maskData
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
            dataOffset = 0  -- deside later
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

        local curData = CreateIcoOrCur({cel}, 2, hotSpotX, hotSpotY)
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

app.alert{
    title = "Export Finished",
    text = "File is successfully exported.",
    buttons = "OK"
}
