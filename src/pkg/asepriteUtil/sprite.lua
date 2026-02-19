---@param sprite Sprite
---@param perdicate (fun(layer: Layer): boolean) | nil
---@return Layer[]
local function getNonGroupLayers (sprite, perdicate)
    ---@type Layer
    local result = {}

    local function traverse (layer)
        if perdicate ~= nil and not perdicate(layer) then
            return
        end

        if layer.isGroup then
            for _, child in ipairs(layer.layers) do
                traverse(child)
            end
        else
            table.insert(result, layer)
        end
    end

    for _, layer in ipairs(sprite.layers) do
        traverse(layer)
    end

    return result
end

---@param sprite Sprite
---@return Layer[]
local function getSelectedNonGroupLayers (sprite)
    return getNonGroupLayers(sprite, function (layer)
        return app.range:contains(layer)
    end)
end

---@param sprite Sprite
---@param name string
---@return Tag | nil
local function getTag (sprite, name)
    for _, tag in ipairs(sprite.tags) do
        if tag.name == name then
            return tag
        end
    end

    return nil
end

---@param sprite Sprite
---@return Layer[]
local function getVisibleLayers (sprite)
    return getNonGroupLayers(sprite, function (layer)
        return layer.isVisible
    end)
end

return {
    getNonGroupLayers = getNonGroupLayers,
    getSelectedLayers = getSelectedNonGroupLayers,
    getVisibleLayers = getVisibleLayers,
    getTag = getTag,
}
