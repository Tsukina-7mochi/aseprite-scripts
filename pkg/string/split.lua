---split `str` by `sep`
---@param str string string to split
---@param sep string separator character classes
---@return string[]
local function split(str, sep)
    local result = {} --[[ @as string[] ]]
    for s in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, s)
    end

    return result
end

local function inject()
    string.split = split
end

return {
    split = split,
    inject = inject,
}
