---@param frame Frame
---@param layers Layer[] | nil
---@return Image
local function mergeLayerImages (frame, layers)
    if layers == nil then
        layers = frame.sprite.layers
    end

    local result = Image(frame.sprite.width, frame.sprite.height, ColorMode.RGB)
    for _, layer in ipairs(layers) do
        local cel = layer:cel(frame)
        if cel ~= nil then
            result:drawImage(cel.image, cel.bounds.origin, layer.opacity, layer.blendMode)
        end
    end

    return result
end

return {
    mergeLayerImages = mergeLayerImages,
}
