---@class BitmapFile
---@field fileHeader string BMP file header (14 bytes)
---@field infoHeader string Bitmap info header (40 bytes)
---@field colorTable string Binary color table, empty when the image has no palette
---@field pixelData string Binary pixel data
---@overload fun(fileHeader: string, infoHeader: string, pixelData: string, colorTable: string?): BitmapFile
local BitmapFile = {}

---Converts the bitmap file to a binary string
---@param bitmap BitmapFile
---@return string
local function tostring (bitmap)
    return table.concat({
        bitmap.fileHeader,
        bitmap.infoHeader,
        bitmap.colorTable,
        bitmap.pixelData,
    })
end

BitmapFile.tostring = tostring

setmetatable(BitmapFile --[[ @as table ]], {
    __call = function (_, fileHeader, infoHeader, pixelData, colorTable)
        local value = {
            fileHeader = fileHeader,
            infoHeader = infoHeader,
            colorTable = colorTable or "",
            pixelData = pixelData,
        }

        setmetatable(value, {
            __index = BitmapFile,
            __tostring = tostring,
        })

        return value
    end,
})

return { BitmapFile = BitmapFile }
