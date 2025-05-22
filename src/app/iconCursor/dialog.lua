local ParamsDef = require("app.iconCursor.params") -- Used for @class/@type annotations

---@class DialogHandler
local DialogHandler = {}

--- Creates a dialog, waits for user confirmation, parses dialog data to Params,
--- and prompts the user to re-input if parsing/validation fails.
---@param sprite Sprite The active sprite.
---@param initialParams Params The initial parameters to populate the dialog.
---@param layerList string[] List of layer options for the dialog.
---@param frameList string[] List of frame options for the dialog.
---@return Params The parameters gathered from the dialog. `params.canceled` will be true if the user canceled.
function DialogHandler.getParamsFromDialog(sprite, initialParams, layerList, frameList)
    -- Create a working copy of params to modify and return
    ---@type Params
    local params = {}
    for k, v in pairs(initialParams) do
        params[k] = v
    end
    params.canceled = false -- Ensure it's false unless dialog is explicitly canceled

    local fileTypes = { "ico", "cur", "ani" }
    local paramTypesVisibility = {
        icoSeparator = { "ico" },
        curSeparator = { "cur" },
        aniSeparator = { "ani" },
        hotSpotX = { "cur", "ani" },
        hotSpotY = { "cur", "ani" },
        frame = { "ico", "cur", "ani" },
        layer = { "ico", "cur", "ani" },
        framerate = { "ani" }
    }

    local dialog = Dialog()

    local function updateDialogElementVisibility()
        ---@type string
        for id, paramRule in pairs(paramTypesVisibility) do
            local visible = false
            for _, p in ipairs(paramRule) do
                if p == dialog.data.filetype then
                    visible = true
                end
            end
            dialog:modify {
                id = id,
                visible = visible
            }
        end
    end

    dialog:combobox {
        id = "filetype",
        label = "Type",
        option = params.filetype,
        options = fileTypes,
        onchange = function()
            -- update extension of filename
            local currentFilename = app.fs.filePathAndTitle(dialog.data.filename --[[@as string]])
            currentFilename = currentFilename .. "." .. dialog.data.filetype

            dialog:modify {
                id = "filename",
                filename = currentFilename
            }

            -- update frame selection
            if (dialog.data.filetype --[[@as string]]) == "ani" then
                if (dialog.data.frame --[[@as string]]):sub(1, 7) == "Frame: " then
                    dialog:modify {
                        id = "frame",
                        option = "All"
                    }
                end
            end
            updateDialogElementVisibility()
        end
    }
    :file {
        id = "filename",
        label = "Filename",
        title = "Export as...",
        save = true,
        filename = params.filename,
        filetypes = { "ico" } -- Kept static as per original script's behavior
    }
    :separator { id = "icoSeparator", text = ".ico file option" }
    :separator { id = "curSeparator", text = ".cur file option" }
    :separator { id = "aniSeparator", text = ".ani file option" }
    :combobox {
        id = "layer",
        label = "Layers",
        option = layerList[1], -- Default to first option in layerList
        options = layerList
    }
    :combobox {
        id = "frame",
        label = "Frames",
        option = "Frame: 1", -- Hardcoded default as in original
        options = frameList
    }
    :number {
        id = "hotSpotX",
        label = "HotSpot",
        text = tostring(params.hotSpotX)
    }
    :number {
        id = "hotSpotY",
        text = tostring(params.hotSpotY)
    }
    :number {
        id = "framerate",
        label = "Framerate (1/60s)",
        text = tostring(params.framerate),
        onchange = function()
            dialog:modify {
                id = "framerate",
                text = math.min(0, dialog.data.framerate --[[@as number]]) -- Kept as per original
            }
        end
    }
    :check {
        id = "showCompleted", -- Corresponds to params.showCompleted
        label = "",
        text = "Show dialog when succeeded",
        selected = params.showCompleted
    }
    :button { id = "ok", text = "&Export", focus = true }
    :button { id = "cancel", text = "&Cancel" }

    updateDialogElementVisibility() -- Initial visibility setup

    repeat
        local retype = false
        dialog:show()

        local d = dialog.data -- Shorthand for dialog.data

        assert(type(d.filetype) == "string", "filetype must be string, got" .. type(d.filetype))
        assert(type(d.filename) == "string", "filename must be string, got" .. type(d.filename))
        assert(type(d.layer) == "string", "layer must be string, got" .. type(d.layer))
        assert(type(d.frame) == "string", "frame must be string, got" .. type(d.frame))
        assert(type(d.hotSpotX) == "number", "hotSpotX must be number, got" .. type(d.hotSpotX))
        assert(type(d.hotSpotY) == "number", "hotSpotY must be number, got" .. type(d.hotSpotY))
        assert(type(d.framerate) == "number", "framerate must be number, got" .. type(d.framerate))
        assert(type(d.showCompleted) == "boolean", "showCompleted must be boolean, got" .. type(d.showCompleted))

        if not d.ok then
            params.canceled = true
            break
        end

        if d.filetype ~= "ico" and d.filetype ~= "cur" and d.filetype ~= "ani" then
            retype = true
            app.alert { title = "Invalid configuration", text = "The file type " .. d.filetype .. " is not supported" }
        else
            params.filetype = d.filetype --[[@as "ico" | "cur" | "ani"]]
        end

        params.filename = d.filename

        params.excludedLayers = {}
        if d.layer == "Visible layers" then
            for _, layer in ipairs(sprite.layers) do
                if not layer.isVisible then
                    params.excludedLayers[#params.excludedLayers + 1] = layer.name
                end
            end
        elseif d.layer == "Active layer" then
            for _, layer in ipairs(sprite.layers) do
                if layer.name ~= app.activeLayer.name then -- Compare with activeLayer.name
                    params.excludedLayers[#params.excludedLayers + 1] = layer.name
                end
            end
        elseif d.layer:sub(1, 7) == "Layer: " then
            local layerName = d.layer:sub(8)
            for _, layer in ipairs(sprite.layers) do
                if layer.name ~= layerName then
                    params.excludedLayers[#params.excludedLayers + 1] = layer.name
                end
            end
        end

        params.includedFrames = {}
        if d.frame == "All" then
            for _, frame in ipairs(sprite.frames) do
                params.includedFrames[#params.includedFrames + 1] = frame.frameNumber
            end
        elseif d.frame:sub(1, 7) == "Frame: " then
            params.includedFrames[1] = tonumber(d.frame:sub(8))
        elseif d.frame:sub(1, 5) == "Tag: " then
            local tagName = d.frame:sub(6)
            for _, tag in ipairs(sprite.tags) do
                if tag.name == tagName then
                    for i = tag.fromFrame.frameNumber, tag.toFrame.frameNumber do
                        params.includedFrames[#params.includedFrames + 1] = i
                    end
                end
            end
        end

        if d.hotSpotX < 0 then
            retype = true
            app.alert { title = "Invalid configuration", text = "Hot spot x is too small." }
        elseif d.hotSpotX >= sprite.width then
            retype = true
            app.alert { title = "Invalid configuration", text = "Hot spot x is too big." }
        else
            params.hotSpotX = d.hotSpotX
        end

        if d.hotSpotY < 0 then
            retype = true
            app.alert { title = "Invalid configuration", text = "Hot spot y is too small." }
        elseif d.hotSpotY >= sprite.height then
            retype = true
            app.alert { title = "Invalid configuration", text = "Hot spot y is too big." }
        else
            params.hotSpotY = d.hotSpotY
        end
        
        local framerateFromDialog = math.floor(d.framerate)
        if framerateFromDialog < 1 then
            retype = true
            app.alert { title = "Invalid configuration", text = "The frame rate is too small." }
        else
            params.framerate = framerateFromDialog
        end

        params.showCompleted = d.showCompleted

    until not retype

    -- If the loop was broken by cancel, params.canceled is already true.
    -- If the loop finished because retype is false, params.canceled remains its initial value (false).
    -- The `if not d.ok then params.canceled = true; break end` handles explicit cancel.
    
    return params
end

return DialogHandler
