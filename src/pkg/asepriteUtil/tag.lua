---@param tag Tag
---@return Frame[]
local function getFrames (tag)
    local result = {}
    for i = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
        table.insert(result, tag.sprite.frames[i])
    end
    return result
end

return {
    getFrames = getFrames,
}
