---------- ByteStreamBuffer ----------
ByteStreamBuffer = {
    prototype = {},
    meta = {},
    util = {},
    init = function()
        -- returns true when v is integer
        ByteStreamBuffer.util.isInteger = function(v)
            return type(v) == "number" and v % 1 .. "" == "0"
        end
        -- returns true if v is byte number
        ByteStreamBuffer.util.isByte = function(v)
            return ByteStreamBuffer.util.isInteger(v) and 0 <= v and v <= 0xFF
        end
        -- returns true if v is ByteStreamBuffer
        ByteStreamBuffer.util.isByteStreamBuffer = function(v)
            return type(v) == "table" and v.array ~= nil and getmetatable(v) == ByteStreamBuffer.meta
        end
        -- assert with level
        ByteStreamBuffer.util.assert = function(value, msg, level)
            if not value then
            error(msg, level + 1)
            end
            return value
        end
        -- check type and assert with level
        ByteStreamBuffer.util.assertType = function(value, targetType, msgPrefix, level)
            local assert = false
            if targetType == "byte" then
            assert = not ByteStreamBuffer.util.isByte(value)
            elseif targetType == "ByteStreamBuffer" then
            assert = not ByteStreamBuffer.util.isByteStreamBuffer(value)
            elseif targetType == "integer" then
            assert = not ByteStreamBuffer.util.isInteger(value)
            else
            assert = type(value) ~= targetType
            end

            if assert then
            error(msgPrefix .. "(" .. targetType .. " expected, got " .. type(value) .. ")", level + 1)
            end
        end

        -- append value
        ByteStreamBuffer.prototype.append = function(bsb, ...)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'append' ", 2)

            for i, data in ipairs({...}) do
            if ByteStreamBuffer.util.isByte(data) then
                bsb:appendByte(data)
            elseif type(data) == "string" then
                bsb:appendString(data)
            elseif ByteStreamBuffer.util.isByteStreamBuffer(data) then
                bsb:appendByteStreamBuffer(data)
            else
                error("bad argument #" .. (i + 1) .. " to append (byte, string or ByteStreamBuffer expected, got " .. type(data) .. ")")
            end
            end
        end
        -- append byte number
        ByteStreamBuffer.prototype.appendByte = function(bsb, data)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'appendByte' ", 2)
            ByteStreamBuffer.util.assertType(data, "byte", "bad argument #2 to 'appendByte' ", 2)

            bsb[#bsb + 1] = data
        end
        -- append number in little endian
        ByteStreamBuffer.prototype.appendMultiByteLE = function(bsb, data, size)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'appendMultiByteLE' ", 2)
            ByteStreamBuffer.util.assertType(data, "integer", "bad argument #2 to 'appendMultiByteLE' ", 2)
            ByteStreamBuffer.util.assertType(size, "integer", "bad argument #3 to 'appendMultiByteLE' ", 2)
            ByteStreamBuffer.util.assert(size > 0, "bad argument #3 to 'appendMultiByteLE' (size must be grater than 0)", 2)

            if data < 0 then
            data = 1 << (size * 8) + data
            end

            local d = data
            for i = 1, size do
            bsb[#bsb + 1] = d & 0xFF
            d = d >> 8
            end
        end
        -- append number in big endian
        ByteStreamBuffer.prototype.appendMultiByteBE = function(bsb, data, size)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'appendMultiByteBE' ", 2)
            ByteStreamBuffer.util.assertType(data, "integer", "bad argument #2 to 'appendMultiByteBE' ", 2)
            ByteStreamBuffer.util.assertType(size, "integer", "bad argument #3 to 'appendMultiByteBE' ", 2)
            ByteStreamBuffer.util.assert(size > 0, "bad argument #3 to 'appendMultiByteBE' (size must be grater than 0)", 2)

            if data < 0 then
            data = 1 << (size * 8) + data
            end

            local mask = 0xFF << ((size - 1) * 8)
            local shift = size - 1
            for i = 1, size do
            bsb[#bsb + 1] = (data & mask) >> (shift * 8)
            mask = mask >> 8
            shift = shift - 1
            end
        end
        -- append string sa byte sequence
        ByteStreamBuffer.prototype.appendString = function(bsb, data)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'appendString' ", 2)
            ByteStreamBuffer.util.assertType(data, "string", "bad argument #2 to 'appendString' ", 2)

            for _, byte in ipairs({ data:byte(1, -1) }) do
            bsb[#bsb + 1] = byte
            end
        end
        -- append string as pascal string
        ByteStreamBuffer.prototype.appendPascalString = function(bsb, data)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'appendPascalString' ", 2)
            ByteStreamBuffer.util.assertType(data, "string", "bad argument #2 to 'appendPascalString' ", 2)

            bsb[#bsb + 1] = #data
            for _, byte in ipairs({ data:byte(1, -1) }) do
            bsb[#bsb + 1] = byte
            end
        end
        -- append slice of ByteStreamBuffer
        ByteStreamBuffer.prototype.appendByteStreamBuffer = function(bsb, bsb2)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'appendByteStreamBuffer' ", 2)
            ByteStreamBuffer.util.assertType(bsb2, "ByteStreamBuffer", "bad argument #2 to 'appendByteStreamBuffer' ", 2)

            for i = 1, #bsb2 do
            bsb[#bsb + 1] = bsb2[i]
            end
        end
        -- clear buffer
        ByteStreamBuffer.prototype.clear = function(bsb)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'clear' ", 2)
            bsb.array = {}
        end
        -- convert to string
        ByteStreamBuffer.prototype.tostring = function(bsb)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'tostring' ", 2)

            local str = ""
            for i = 1, #bsb do
            str = str .. string.format("%c", bsb[i])
            end

            return str
        end
        -- returns slice of buffer
        ByteStreamBuffer.prototype.slice = function(bsb, startIndex, lastIndex)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'slice' ", 2)
            ByteStreamBuffer.util.assertType(startIndex, "integer", "bad argument #2 to 'slice' ", 2)
            ByteStreamBuffer.util.assertType(lastIndex, "integer", "bad argument #3 to 'slice' ", 2)

            if startIndex < 1 then
            startIndex = #bsb + startIndex
            end
            if lastIndex < 1 then
            lastIndex = #bsb + lastIndex
            end

            local result = ByteStreamBuffer()
            for i = startIndex, lastIndex do
            result[#result + 1] = bsb[i]
            end

            return result
        end
        -- compress buffer with pack bits and return new buffer
        ByteStreamBuffer.prototype.packBits = function(bsb)
            ByteStreamBuffer.util.assertType(bsb, "ByteStreamBuffer", "bad argument #1 to 'packBits' ", 2)
            if #bsb == 0 then
            return ByteStreamBuffer()
            end

            local result = ByteStreamBuffer()
            local buff = ByteStreamBuffer()
            local flag = -1
            local size = 0xFF

            local i = 1
            while i <= #bsb do
            if flag == 0 then
                -- continuous
                if buff[#buff] == bsb[i] then
                buff[#buff + 1] = bsb[i]
                else
                result[#result + 1] = size - (#buff - 2)
                result[#result + 1] = buff[1]
                buff:clear()
                buff[1] = bsb[i]
                flag = -1
                end
            elseif flag == 1 then
                -- discontinuous
                if buff[#buff] ~= bsb[i] then
                buff[#buff+1] = bsb[i]
                else
                result[#result+1] = #buff - 2
                result:appendByteStreamBuffer(buff, 1, -1)
                buff:clear()
                buff[1] = bsb[i]
                buff[2] = bsb[i]
                flag = 0
                end
            else
                -- undetermined
                if #buff ~= 0 then
                if buff[#buff] == bsb[i] then
                    flag = 0
                else
                    flag = 1
                end
                end
                buff[#buff+1] = bsb[i]
            end

            if #buff > size/2 then
                if flag == 0 then
                result[#result+1] = size - (#buff - 2)
                result[#result+1] = buff[1]
                else
                result[#result+1] = #buff - 1
                result:appendByteStreamBuffer(buff)
                end
                buff = {}
                flag = -1
            end

            i = i + 1
            end

            if #buff ~= 0 then
            if flag == 0 then
                result[#result+1] = size - (#buff - 2)
                result[#result+1] = buff[1]
            else
                result[#result+1] = #buff - 1
                result.appendByteStreamBuffer(buff)
            end
            end

            return result
        end

        ByteStreamBuffer.meta.__index = function(bsb, index)
            if ByteStreamBuffer.util.isInteger(index) then
            return bsb.array[index]
            else
            return ByteStreamBuffer.prototype[index]
            end
        end
        ByteStreamBuffer.meta.__newindex = function(bsb, index, value)
            if not ByteStreamBuffer.util.isByte(value) then
            error("Value must be byte number, got " .. value, 2)
            end
            if ByteStreamBuffer.util.isInteger(index) then
            bsb.array[index] = value
            end
        end
        ByteStreamBuffer.meta.__len = function(bsb)
            return #bsb.array
        end
        ByteStreamBuffer.meta.__tostring = function(bsb)
            local str = "ByteStreamBuffer[" .. #bsb.array .. "] { "

            for i = 1, #bsb.array do
            if i ~= 1 then
                str = str .. ", "
            end
            str = str .. bsb.array[i]
            end

            str = str .. " }"
            return str
        end
        ByteStreamBuffer.meta.__concat = function(bsb1, bsb2)
            local bsb = ByteStreamBuffer()
            for i = 1, #bsb1 do
            bsb.array[#bsb.array + 1] = bsb1[i]
            end
            for i = 1, #bsb2 do
            bsb.array[#bsb.array + 1] = bsb2[i]
            end
            return bsb
        end

        setmetatable(ByteStreamBuffer, {
            __call = function()
            -- create new ByteStreamBuffer
            local bsb = {
                array = {}
            }
            setmetatable(bsb, ByteStreamBuffer.meta)

            return bsb
            end
        })
    end
}

ByteStreamBuffer.init()
---------- ByteStreamBuffer ----------

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
local sprite = Sprite(app.activeSprite)
sprite:flatten()

local targetCels = sprite.cels

local frameList = {"All"}
for i = 1, #sprite.frames do
  table.insert(frameList, "" .. i)
end
local fileTypes = { "ico", "cur", "ani" }
local paramTypes = {
    icoSeparator={ "ico" },
    curSeparator={ "cur" },
    aniSeparator={ "ani" },
    hotSpotX={ "cur", "ani" },
    hotSpotY={ "cur", "ani" },
    frame={ "ico", "cur" },
    framerate={ "ani" }
}

local dialog = Dialog()
local function updateDialogElementVisibility()
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
        local filename = app.fs.filePathAndTitle(dialog.data.filename)
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
    filetypes="ico"
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
    option=frameList[2],
    options=frameList
}:number{
    id="hotSpotX",
    label="HotSpot",
    text="0",
    onchange=function()
        dialog:modify{
            id="hotSpotX",
            text=math.max(0, math.min(sprite.width - 1, dialog.data.hotSpotX))
        }
    end
}:number{
    id="hotSpotY",
    text="0",
    onchange=function()
        dialog:modify{
            id="hotSpotY",
            text=math.max(0, math.min(sprite.width - 1, dialog.data.hotSpotY))
        }
    end
}:number{
    id="framerate",
    label="Framerate (1/60s)",
    text="60",
    onchange=function()
        dialog:modify{
            id="framerate",
            text=math.min(0, dialog.data.framerate)
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

dialog:show()

sprite:close()

if true then return end
-- if dialog.data.ok then return end

local filetype = dialog.data.filetype
local filename = dialog.data.filename
local frame = dialog.data.frame
local hotSpotX = dialog.data.hotSoptX
local hotSpotY = dialog.data.hotSpotY
local framerate = dialog.data.framerate
local showCompleated = dialog.data.showCompleated
local targetCels = {}
if frame == "all" then
    targetCels = sprite.cels
else
    targetCels = { tonumber(frame) }
end

local dpi = 96
local fileHeaderSize = 6
local iconInfoHeaderSize = 16
local bitmapInfoHeaderSize = 40

local transparent = { r=0, g=0, b=0, a=0 }
function GetColorSpriteSpace(x, y, cel)
    if x < cel.bounds.x then
        return transparent
    end
    if y < cel.bounds.y then
        return transparent
    end
    if x >= cel.bounds.x + cel.bounds.width then
        return transparent
    end
    if y >= cel.bounds.y + cel.bounds.height then
        return transparent
    end

    pixel = cel.image:getPixel(x - cel.bounds.x, y - cel.bounds.y)
    if cel.image.colorMode == ColorMode.RGB then
        return {
            r=app.pixelColor.rgbaR(pixel),
            g=app.pixelColor.rgbaG(pixel),
            b=app.pixelColor.rgbaB(pixel),
            a=app.pixelColor.rgbaA(pixel)
        }
    elseif cel.image.colorMode == ColorMode.GRAY then
        return {
            r=app.pixelColor.grayaV(color),
            g=app.pixelColor.grayaV(color),
            b=app.pixelColor.grayaV(color),
            a=app.pixelColor.grayaA(color)
        }
    elseif cel.image.colorMode == ColorMode.INDEXED then
        local c = sprite.palettes[1]:getColor(pixel)
        return {
            r=c.red,
            g=c.green,
            b=c.blue,
            a=c.alpha
        }
    end

    return transparent
end

function CreateIcoOrCur(targetCels, resourceType, hotSpotX, hotSpotY)
    local images = {}
    for i, cel in ipairs(targetCels) do
        local colorData = ByteStreamBuffer()
        local maskData = ByteStreamBuffer()
        local mask = 0
        local maskCount = 0

        for y = sprite.height - 1, 0, -1 do
            mask = 0
            maskCount = 0

            for x = 0, sprite.width - 1 do
                local color = GetColorSpriteSpace(x, y, cel)
                colorData:appendByte(color.b)
                colorData:appendByte(color.g)
                colorData:appendByte(color.r)
                colorData:appendByte(0)
                local alphaFlag = 0
                if color.a == 0 then
                    alphaFlag = 1
                end

                mask = mask << 1 | alphaFlag
                maskCount = maskCount + 1
                if maskCount == 8 then
                    maskData:appendByte(mask)
                    mask = 0
                    maskCount = 0
                end
            end

            if maskCount ~= 0 then
                maskData:appendByte(mask << (8 - maskCount))
            end

            if #colorData % 4 ~= 0 then
                colorData:appendMultiByteLE(0, 4 - #colorData % 4)
            end
            if #maskData % 4 ~= 0 then
                maskData:appendMultiByteLE(0, 4 - #maskData % 4)
            end
        end

        images[i] = {
            color=colorData,
            mask=maskData
        }
    end

    local data = ByteStreamBuffer()

    -- file header
    ---- reserved
    data:appendMultiByteLE(0, 2)
    ---- resource type (1: icon / 2: cursor)
    data:appendMultiByteLE(resourceType, 2)
    ---- number of images
    data:appendMultiByteLE(#targetCels, 2)

    -- icon header
    -- record offset of icon header to update info later
    local offsetAddresses = {}
    for index, frame in ipairs(targetCels) do
        ---- width and height
        data:appendByte(sprite.width)
        data:appendByte(sprite.height)
        ---- color count
        data:appendByte(0)
        ---- resevered
        data:appendByte(0)
        ---- hotspot x, y for cursor, reserverd for ico
        data:appendMultiByteLE(hotSpotX, 2)
        data:appendMultiByteLE(hotSpotY, 2)
        ---- icon data size
        dataSize = bitmapInfoHeaderSize + #images[index].color + #images[index].mask
        data:appendMultiByteLE(dataSize, 4)
        ---- offset until bitmap info header, deside later
        offsetAddresses[index] = #data
        data:appendMultiByteLE(0, 4)
    end

    -- each icon (or cursor)
    for index, frame in ipairs(targetCels) do
        -- set offset in icon header
        offset = ByteStreamBuffer()
        offset:appendMultiByteLE(#data, 4)
        data[offsetAddresses[index] + 1] = offset[1]
        data[offsetAddresses[index] + 2] = offset[2]
        data[offsetAddresses[index] + 3] = offset[3]
        data[offsetAddresses[index] + 4] = offset[4]

        -- bitmap info header
        data:appendMultiByteLE(bitmapInfoHeaderSize, 4)
        -- width and height
        -- NOTE: why the height doubled?
        data:appendMultiByteLE(sprite.width, 4)
        data:appendMultiByteLE(sprite.height * 2, 4)
        -- planes
        data:appendMultiByteLE(1, 2)
        -- bit per pixel: 32bit
        data:appendMultiByteLE(32, 2)
        -- compression: 0 (BI_RGB)
        data:appendMultiByteLE(0, 4)
        -- image size
        -- NOTE: is it correct?
        data:appendMultiByteLE(#images[index].color, 4)
        -- pixel per meter, horizontal and vertical
        data:appendMultiByteLE(0, 4)
        data:appendMultiByteLE(0, 4)
        -- N of pallets
        data:appendMultiByteLE(0, 4)
        -- N of important colors
        data:appendMultiByteLE(0, 4)

        -- there is no palettes

        -- pixel data
        data:appendByteStreamBuffer(images[index].color)

        -- mask data data
        data:appendByteStreamBuffer(images[index].mask)
    end

    return data
end

local fileData = ByteStreamBuffer()

if filetype == "ico" then
    fileData = CreateIcoOrCur(targetCels, 1, 0, 0)
elseif filetype == "cur" then
    fileData = CreateIcoOrCur(targetCels, 2, hotSpotX, hotSpotY)
elseif filetype == "ani" then
    -- todo
else
    FailAlert("The format \"" .. filetype "\" is not implemented.")
    return
end

sprite:close()

local file = io.open(filename, "wb")
if not file then
  FailAlert("Failed to open the file to export.")
  return
end

for i = 1, #fileData do
    file:write(string.format("%c", fileData[i]))
end

file:close()

-- app.alert{
--     title = "Export Finished",
--     text = "File is exported successfully.",
--     buttons = "OK"
-- }
