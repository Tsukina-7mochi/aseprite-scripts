---@class Params
---@field filetype "ico" | "cur" | "ani"
---@field filename string
---@field hotSpotX number
---@field hotSpotY number
---@field framerate number
---@field showCompleted boolean
---@field includedFrames integer[]
---@field excludedLayers string[]
---@field canceled boolean
---@field verbose boolean
local Params = {}

---Checks if the given object conforms to the Params class structure and types.
---@param obj any The object to validate.
---@return Params? The object if it is a valid Params object, otherwise nil.
function Params.parse(obj)
    if type(obj) ~= "table" then
        return nil
    end

    if not (obj.filetype == "ico" or obj.filetype == "cur" or obj.filetype == "ani") then
        return nil
    end

    if type(obj.filename) ~= "string" then
        return nil
    end

    if type(obj.hotSpotX) ~= "number" then
        return nil
    end

    if type(obj.hotSpotY) ~= "number" then
        return nil
    end

    if type(obj.framerate) ~= "number" then
        return nil
    end

    if type(obj.showCompleted) ~= "boolean" then
        return nil
    end

    if type(obj.includedFrames) ~= "table" then
        return nil
    end
    for _, v in ipairs(obj.includedFrames) do
        if type(v) ~= "number" then return nil end
    end

    if type(obj.excludedLayers) ~= "table" then
        return nil
    end
    for _, v in ipairs(obj.excludedLayers) do
        if type(v) ~= "string" then return nil end
    end

    if type(obj.canceled) ~= "boolean" then
        return nil
    end

    if type(obj.verbose) ~= "boolean" then
        return nil
    end

    return obj --[[@as Params]]
end

return Params
