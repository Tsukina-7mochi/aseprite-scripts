---Packs 32-bit unsigned integer into a big-endian encoded binary string
---@param data integer
---@return string
local function u32BE(data)
    return (">I4"):pack(data)
end

---Packs 32-bit signed integer into a big-endian encoded binary string
---@param data integer
---@return string
local function i32BE(data)
    return (">i4"):pack(data)
end

---Packs 16-bit unsigned integer into a big-endian encoded binary string
---@param data integer
---@return string
local function u16BE(data)
    return (">I2"):pack(data)
end

---Packs 8-bit unsigned integer into a binary string
---@param data integer
---@return string
local function u8(data)
    return ("B"):pack(data)
end

return {
    u32BE = u32BE,
    i32BE = i32BE,
    u16BE = u16BE,
    u8 = u8,
}
