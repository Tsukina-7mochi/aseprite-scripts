---Converts `str` into pascal string
---@param str string
---@param align? number pad result string with 0 to make result length to be multiple of `align`
---@param max_length? number max length of result string
---@return string
local toPascalString = function(str, align, max_length)
    if type(max_length) == "number" then
        str = str:sub(1, max_length - 1)
    end
    if type(align) ~= "number" then
        align = 1
    end

    return ("!" .. align .. "s1Xi"):pack(str)
end

return toPascalString
