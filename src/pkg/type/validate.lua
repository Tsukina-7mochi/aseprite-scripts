local isInteger = require("pkg.type.isType").isInteger

---@alias Primitive "nil" | "number" | "string" | "boolean"
---@alias PrimitiveValidator { type: Primitive } | { type: "integer" }
---@alias ArrayValidator { type: "array", values: Validator }
---@alias TableValidator { type: "table", values: table<string | number, Validator> }
---@alias ValueValidator { type: "value", value: any }
---@alias Validator PrimitiveValidator | TableValidator | ValueValidator

---Validates a value against a validator.
---@param value any
---@param validator Validator
---@return boolean
local function isValid(value, validator)
    if validator.type == "value" then
        return value == validator.value
    elseif validator.type == "integer" then
        return isInteger(value)
    elseif validator.type == "array" then
        if type(value) ~= "table" then
            return false
        end

        for i, v in ipairs(value) do
            if not isValid(v, validator.values) then
                return false
            end
        end

        return true
    elseif validator.type == "table" then
        if type(value) ~= "table" then
            return false
        end

        for k, v in pairs(validator.values) do
            if not isValid(value[k], v) then
                return false
            end
        end

        return true
    else
        return type(value) == validator.type
    end
end

return { isValid = isValid }
