local parameter = require("app.iconCursor.parameter")

local TAG_PREFIX = "Tag: "
local ALL_FRAMES_LABEL = "All Frames"

---Creates and shows the icon/cursor export dialog
---@param sprite Sprite
---@return IconCursorParams? params Returns nil if cancelled
local function show (sprite)
    local fileType = "ico"
    local initialFilename = app.fs.filePathAndTitle(sprite.filename) .. ".ico"

    -- Build tag options list
    local tagOptions = { ALL_FRAMES_LABEL }
    for _, tag in ipairs(sprite.tags) do
        table.insert(tagOptions, TAG_PREFIX .. tag.name)
    end

    local dialog = Dialog("Export Icon/Cursor")
    if dialog == nil then
        error("Failed to create dialog, UI may not be available")
    end

    -- Update field visibility based on selected file type
    local function updateVisibility ()
        local isCursor = fileType == "cur" or fileType == "ani"
        local isAnimated = fileType == "ani"

        dialog:modify({ id = "hotspotX", visible = isCursor })
        dialog:modify({ id = "hotspotY", visible = isCursor })
        dialog:modify({ id = "framerate", visible = isAnimated })
    end

    -- Update filename extension to match selected file type
    local function updateFilenameExtension ()
        local currentFilename = dialog.data.filename
        if type(currentFilename) == "string" then
            local baseFilename = app.fs.filePathAndTitle(currentFilename)
            local newFilename = baseFilename .. "." .. fileType
            dialog:modify({ id = "filename", filename = newFilename })
        end
    end

    dialog
        :combobox({
            id = "filetype",
            label = "File Type",
            option = "ICO",
            options = { "ICO", "CUR", "ANI" },
            onchange = function ()
                local selected = dialog.data.filetype --[[@as string]]
                if selected then
                    fileType = selected:lower()
                    updateVisibility()
                    updateFilenameExtension()
                end
            end,
        })
        :combobox({
            id = "layers",
            label = "Layers",
            option = "Visible",
            options = { "Visible", "Selected" },
        })
        :combobox({
            id = "tag",
            label = "Frames",
            option = ALL_FRAMES_LABEL,
            options = tagOptions,
        })
        :number({
            id = "framerate",
            label = "Framerate (1/60s)",
            text = tostring(math.floor(sprite.frames[1].duration * 60)),
        })
        :number({
            id = "hotspotX",
            label = "Hot Spot",
            text = "0",
            decimals = 0,
        })
        :number({
            id = "hotspotY",
            text = "0",
            decimals = 0,
        })
        :separator({ text = "Output" })
        :file({
            id = "filename",
            label = "Filename",
            title = "Export as...",
            save = true,
            filename = initialFilename,
            filetypes = { "ico", "cur", "ani" },
        })
        -- Buttons
        :button({
            id = "ok",
            text = "&Export",
            focus = true,
        })
        :button({
            id = "cancel",
            text = "&Cancel",
        })

    updateVisibility()
    dialog:show()

    -- Check if cancelled
    if not dialog.data.ok then
        return nil
    end

    -- Parse layers option
    local layers = "visible"
    if dialog.data.layers == "Selected" then
        layers = "selected"
    end

    -- Parse tag option
    local tag = nil
    if dialog.data.tag ~= ALL_FRAMES_LABEL then
        -- Extract tag name from "Tag: {name}" prefix
        tag = (dialog.data.tag --[[@as string]]):sub(#TAG_PREFIX + 1)
    end

    -- Build params table
    local params = {
        filetype = fileType,
        filename = dialog.data.filename,
        hotSpotX = dialog.data.hotspotX,
        hotSpotY = dialog.data.hotspotY,
        framerate = dialog.data.framerate,
        tag = tag,
        layers = layers,
    }

    -- Validate params
    local valid, validationError = parameter.validate(params, sprite)
    if not valid then
        app.alert({
            title = "Invalid Parameters",
            text = validationError or "Unknown validation error",
            buttons = "OK",
        })
        return nil
    end

    return params --[[@as IconCursorParams]]
end

return {
    show = show,
}
