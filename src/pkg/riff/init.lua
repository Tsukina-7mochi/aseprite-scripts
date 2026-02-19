---@class RiffChunk
---@field id string
---@field data string
local __chunk = {}

local __chunkMeta = {
    ---@param self RiffChunk
    __tostring = function (self)
        local padding = ""
        if #self.data % 2 == 1 then
            padding = "\0"
        end
        return ("c4<I4"):pack(self.id, #self.data) .. self.data .. padding
    end,
}

---@param id string
---@param data string
---@return RiffChunk
local function chunk (id, data)
    local obj = { id = id, data = data }
    setmetatable(obj, __chunkMeta)
    return obj
end

---@param identifier string
---@param data RiffChunk | RiffChunk[]
---@return RiffChunk
local function riffChunk (identifier, data)
    if type(data) == "table" and #data > 0 then
        local payloads = {}
        for _, d in ipairs(data) do
            table.insert(payloads, tostring(d))
        end

        return chunk("RIFF", identifier .. table.concat(payloads))
    end

    return chunk("RIFF", identifier .. tostring(data))
end

---@param identifier string
---@param items RiffChunk[]
---@return RiffChunk
local function listChunk (identifier, items)
    local itemsStr = {}
    for _, item in ipairs(items) do
        table.insert(itemsStr, tostring(item))
    end

    return chunk("LIST", identifier .. table.concat(itemsStr))
end

return {
    chunk = chunk,
    riffChunk = riffChunk,
    listChunk = listChunk,
}
