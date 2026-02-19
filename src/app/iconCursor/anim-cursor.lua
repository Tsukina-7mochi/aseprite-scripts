local createIcon = require("app.iconCursor.icon").create
local pack = require("pkg.string..pack")
local riff = require("pkg.riff")

local function createAnimHeader (numFrames, framerate)
    return table.concat({
        pack.u32LE(36), -- size of this header
        pack.u32LE(numFrames), -- numFrames
        pack.u32LE(numFrames), -- numSteps
        pack.u32LE(0), -- width (0 = use frame width)
        pack.u32LE(0), -- height (0 = use frame height)
        pack.u32LE(0), -- bitCount (0 = use frame bit depth)
        pack.u32LE(1), -- numPlanes
        pack.u32LE(framerate), -- displayRate
        pack.u32LE(1), -- flags (0b01, frames are icon data)
    })
end

---@param params IconCursorParams
---@param targetLayers Layer[]
---@param targetFrames Frame[]
---@return string
local function createAnimCursor (params, targetLayers, targetFrames)
    ---@type RiffChunk[]
    local iconChunks = {}
    for _, frame in ipairs(targetFrames) do
        local icon = createIcon(params, targetLayers, { frame })

        table.insert(iconChunks, riff.chunk("icon", icon))
    end

    local file = riff.riffChunk("ACON", {
        riff.chunk("anih", createAnimHeader(#targetFrames, params.framerate)),
        riff.listChunk("fram", iconChunks),
    })

    return tostring(file)
end

return {
    create = createAnimCursor,
}
