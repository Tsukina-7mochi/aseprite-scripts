---Parameters for icon/cursor export
---@class IconCursorParams
---@field filetype "ico" | "cur" | "ani"
---@field filename string
---@field hotSpotX integer
---@field hotSpotY integer
---@field framerate integer
---@field tag string | integer | nil
---@field layers "visible" | "selected"

---Creates default parameters for icon/cursor export
---@param sprite Sprite
---@return IconCursorParams
local function default (sprite)
    local defaultFiletype = "ico"
    local defaultFilename = app.fs.filePathAndTitle(sprite.filename) .. "." .. defaultFiletype
    local defaultFramerate = math.floor(sprite.frames[1].duration * 60)

    return {
        filetype = defaultFiletype,
        filename = defaultFilename,
        hotSpotX = 0,
        hotSpotY = 0,
        framerate = defaultFramerate,
        showCompleted = true,
        tag = nil,
        layers = "visible",
    }
end

---Validates icon/cursor export parameters
---@param params IconCursorParams
---@param sprite Sprite
---@return boolean valid
---@return string? errorMessage
local function validate (params, sprite)
    -- Validate filetype
    if type(params.filetype) ~= "string" then
        return false, "filetype must be a string"
    end
    if params.filetype ~= "ico" and params.filetype ~= "cur" and params.filetype ~= "ani" then
        return false, "filetype must be 'ico', 'cur', or 'ani'"
    end

    -- Validate filename
    if type(params.filename) ~= "string" then
        return false, "filename must be a string"
    end
    if params.filename == "" then
        return false, "filename cannot be empty"
    end

    -- Validate hotSpotX
    if type(params.hotSpotX) ~= "number" then
        return false, "hotSpotX must be a number"
    end
    if params.hotSpotX ~= math.floor(params.hotSpotX) then
        return false, "hotSpotX must be an integer"
    end
    if params.hotSpotX < 0 then
        return false, "hotSpotX must be >= 0"
    end
    if params.hotSpotX >= sprite.width then
        return false, "hotSpotX must be < sprite width (" .. sprite.width .. ")"
    end

    -- Validate hotSpotY
    if type(params.hotSpotY) ~= "number" then
        return false, "hotSpotY must be a number"
    end
    if params.hotSpotY ~= math.floor(params.hotSpotY) then
        return false, "hotSpotY must be an integer"
    end
    if params.hotSpotY < 0 then
        return false, "hotSpotY must be >= 0"
    end
    if params.hotSpotY >= sprite.height then
        return false, "hotSpotY must be < sprite height (" .. sprite.height .. ")"
    end

    -- Validate framerate
    if type(params.framerate) ~= "number" then
        return false, "framerate must be a number"
    end
    if params.framerate ~= math.floor(params.framerate) then
        return false, "framerate must be an integer"
    end
    if params.framerate < 1 then
        return false, "framerate must be >= 1"
    end

    -- Validate tag (nil means all frames, string means specific tag, number means frame index)
    if type(params.tag) == "string" then
        if type(params.tag) ~= "string" then
            return false, "tag must be a string, integer or nil"
        end
        if params.tag == "" then
            return false, "tag cannot be empty string"
        end
        -- Validate it's a valid tag name
        local tagFound = false
        for _, tag in ipairs(sprite.tags) do
            if tag.name == params.tag then
                tagFound = true
                break
            end
        end
        if not tagFound then
            return false, "tag must be nil or a valid tag name"
        end
    elseif type(params.tag) == "number" then
        if params.tag ~= math.floor(params.tag) then
            return false, "tag must be an integer, string, or nil"
        end
        if params.tag < 1 then
            return false, "tag must be >= 1 if it's a number"
        end
        if params.tag > #sprite.frames then
            return false, "tag must be <= number of frames (" .. #sprite.frames .. ") if it's a number"
        end
    end

    -- Validate layers
    if type(params.layers) ~= "string" then
        return false, "layers must be a string"
    end
    if params.layers ~= "visible" and params.layers ~= "selected" then
        return false, "layers must be 'visible' or 'selected'"
    end

    return true, nil
end

return {
    default = default,
    validate = validate,
}
