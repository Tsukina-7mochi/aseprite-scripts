--- Return true if given number is an integer
---@param val any
---@return boolean
local function isInteger(val)
    if type(val) ~= "number" then
        return false
    end

    return val % 1 .. "" == "0"
end

return isInteger
