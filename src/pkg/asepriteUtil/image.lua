---Creates a new image of the given size and draws the source image scaled into
---the given bounds using nearest-neighbor sampling.
---The area outside the bounds is left transparent (padding).
---@param image Image
---@param size Size Size of the resulting image
---@param bounds Rectangle Destination rectangle inside the resulting image
---@return Image
local function scaleInto (image, size, bounds)
    local result = Image(size.width, size.height, image.colorMode)

    for y = 0, bounds.height - 1 do
        local srcY = math.floor(y * image.height / bounds.height)
        for x = 0, bounds.width - 1 do
            local srcX = math.floor(x * image.width / bounds.width)
            result:drawPixel(bounds.x + x, bounds.y + y, image:getPixel(srcX, srcY))
        end
    end

    return result
end

return {
    scaleInto = scaleInto,
}
