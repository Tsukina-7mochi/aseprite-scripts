---@param tag Tag
---@return Frame[]
local function getFrames (tag)
    local result = {}
    for i = tag.fromFrame, tag.toFrame do
        table.insert(result, tag.sprite.frames[i])
    end
    return result
end

return {
    getFrames = getFrames,
}
