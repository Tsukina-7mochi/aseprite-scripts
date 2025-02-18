---@alias Payload (string | Chunk)[]

---@class Chunk
---@field id string
---@field payload Payload
---@overload fun(id: string, payload: Payload | string): Chunk
local chunk = {}

---@return string
function chunk.tostring(self)
    ---@type string[]
    local payload = {}
    local size = 0
    for _, v in ipairs(self.payload) do
        if type(v) ~= "string" then
            v = v:tostring()
        end
        table.insert(payload, v)
        size = size + #v
    end

    local padding = ""
    if size % 2 == 1 then
        padding = "\0"
    end

    return ("c4<I4"):pack(self.id, size) .. table.concat(payload) .. padding
end

setmetatable(chunk --[[ @as unknown ]], {
    ---@param id string
    ---@param payload Payload | string
    __call = function(_, id, payload)
        if type(payload) == "string" then
            payload = { payload }
        end

        local value = {
            id = id,
            payload = payload,
        }
        setmetatable(value, { __index = chunk })

        return value
    end,
})

return { chunk = chunk }
