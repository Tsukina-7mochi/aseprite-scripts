---@meta

local undefined

---@class ByteStreamBuffer: {[integer]: integer}
ByteStreamBuffer = {
    ---Appends value
    ---@param bsb ByteStreamBuffer
    ---@param ... integer | string | ByteStreamBuffer
    append=function(bsb, ...) end,

    ---Appends byte value
    ---@param bsb ByteStreamBuffer
    ---@param data integer
    appendByte=function(bsb, data) end,

    ---Appends multi-byte data with given size as little endian
    ---@param bsb ByteStreamBuffer
    ---@param data integer
    ---@param size integer
    appendMultiByteLE=function(bsb, data, size) end,

    ---Appends multi-byte data with given size as big endian
    ---@param bsb ByteStreamBuffer
    ---@param data integer
    ---@param size integer
    appendMultiByteBE=function(bsb, data, size) end,

    ---Appends string
    ---@param bsb ByteStreamBuffer
    ---@param data string
    appendString=function(bsb, data) end,

    ---Appends string as pascal string
    ---@param bsb ByteStreamBuffer
    ---@param data string
    appendPascalString=function(bsb, data) end,

    ---Appends slice of byte stream buffer
    ---@param bsb ByteStreamBuffer
    ---@param data ByteStreamBuffer
    ---@param beginIndex? integer
    ---@param endIndex? integer
    appendByteStreamBuffer=function(bsb, data, beginIndex, endIndex) end,

    ---Clears the buffer
    ---@param bsb ByteStreamBuffer
    clear=function(bsb) end,

    ---Converts the buffer into string
    ---@param bsb ByteStreamBuffer
    tostring=function(bsb) end,

    ---Returns slice of the buffer
    ---@param bsb ByteStreamBuffer
    ---@param beginIndex integer
    ---@param endIndex integer
    slice=function(bsb, beginIndex, endIndex) end,

    ---Returns packed buffer (not in-place)
    ---@param bsb ByteStreamBuffer
    packBits=function(bsb) end,

    ---@private
    util={
        ---@param v any
        ---@return boolean
        isInteger=function(v) end,

        ---@param v any
        ---@return boolean
        isByte=function(v) end,

        ---@param v any
        ---@return boolean
        isByteStreamBuffer=function(v) end,

        ---@param value any
        ---@param msg string
        ---@param level integer
        ---@return boolean
        assert=function(value, msg, level) end,

        ---@param value any
        ---@param targetType string
        ---@param msgPrefix string
        ---@param level integer
        ---@return boolean
        assertType=function(value, targetType, msgPrefix, level) end,
    },

    ---@private
    array=undefined --[[@as {[integer]: integer}]]
}

---@return ByteStreamBuffer
function ByteStreamBuffer() end
