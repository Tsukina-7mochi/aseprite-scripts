--- Compresses binary data with PackBits
---@param data string
---@return string
local packBits = function(data)
    if #data == 0 then
        return data
    end

    local result = ""
    -- buffer stack
    local stack = ""

    -- -1: undetermined
    --  0: continuous value
    --  1: discontinuous value
    local state = -1
    local index = 1
    while index <= #data do
        local currentData = data:sub(index, index)
        local stackTop = stack:sub(1, 1)

        if state == -1 then
            if #stack ~= 0 then
                if stackTop == currentData then
                    state = 0
                else
                    state = 1
                end
            end

            stack = currentData .. stack
        elseif state == 0 then
            if stackTop == currentData then
                -- just push value
                stack = currentData .. stack
            else
                -- write out buffer contents and reset state
                result = result .. ('B'):pack(256 - (#stack - 1)) .. stackTop
                stack = currentData
                state = -1
            end
        elseif state == 1 then
            if stackTop ~= currentData then
                -- just push value
                stack = currentData .. stack
            else
                -- write out buffer contents and change state
                result = result .. ('B'):pack(#stack - 2) .. stack:sub(2, -1):reverse()
                stack = currentData .. currentData
                state = 0
            end
        end

        if #stack > 0x7F then
            -- write out buffer contents
            if state == 0 then
                result = result .. ('B'):pack(256 - (#stack - 1)) .. stackTop
            elseif state == 1 or state == -1 then
                result = result .. ('B'):pack(#stack - 1) .. stack:reverse()
            end

            -- reset state
            state = -1
            stack = ""
        end

        index = index + 1
    end

    if #stack > 0 then
        -- write out buffer contents
        if state == 0 then
            result = result .. ('B'):pack(256 - (#stack - 1)) .. stack:sub(1, 1)
        elseif state == 1 or state == -1 then
            result = result .. ('B'):pack(#stack - 1) .. stack:reverse()
        end
    end

    return result
end

local function inject()
    string.packBits = packBits
end

return {
    packBits = packBits,
    inject = inject
}
