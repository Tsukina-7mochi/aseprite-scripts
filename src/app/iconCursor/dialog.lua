local parameter = require("app.iconCursor.parameter")
local util = require("pkg.asepriteUtil")

local PROPERTY_KEY = "icon-and-cursor.dialog"
local FILETYPE_OPTIONS = {
    { option = "Icon", value = "ico", isCursor = false, isAnimated = false },
    { option = "Cursor", value = "cur", isCursor = true, isAnimated = false },
    { option = "Animated Cursor", value = "ani", isCursor = true, isAnimated = true },
}
local LAYER_OPTIONS = {
    { option = "Visible", value = "visible" },
    { option = "Selected", value = "selected" },
}
local TAG_OPTION_PREFIX = "Tag: "
local FRAME_OPTION_PREFIX = "Frame: "
local TAG_OPTION_ALL = "All Frames"

local ID = {
    filetype = "filetype",
    layers = "layers",
    tag = "tag",
    framerate = "framerate",
    hotspotX = "hotspotX",
    hotspotY = "hotspotY",
    filename = "filename",
    ok = "ok",
    cancel = "cancel",
    showCompleted = "showCompleted",
}

---@param options { option: string, value: any }[]
---@return string[]
local function optionLabels (options)
    local labels = {}
    for _, item in ipairs(options) do
        table.insert(labels, item.option)
    end
    return labels
end

---@generic T : { option: string }
---@param options T[]
---@return T
local function getOptionEntry (options, option)
    for _, item in ipairs(options) do
        if item.option == option then
            return item
        end
    end
    return nil
end

---Creates and shows the icon/cursor export dialog
---@param sprite Sprite
---@return IconCursorParams? params Returns nil if cancelled
local function show (sprite)
    local tagOptions = { { option = TAG_OPTION_ALL, value = nil } }
    for _, tag in ipairs(sprite.tags) do
        table.insert(tagOptions, { option = TAG_OPTION_PREFIX .. tag.name, value = tag.name })
    end
    for _, frame in ipairs(sprite.frames) do
        table.insert(tagOptions, { option = FRAME_OPTION_PREFIX .. frame.frameNumber, value = frame.frameNumber })
    end

    local savedData = {}
    if sprite.properties ~= nil and type(sprite.properties[PROPERTY_KEY]) == "table" then
        savedData = sprite.properties[PROPERTY_KEY]
    end

    local defaultFiletype = FILETYPE_OPTIONS[1].option
    local defaultFilename = app.fs.filePathAndTitle(sprite.filename) .. "." .. FILETYPE_OPTIONS[1].value
    local defaultFramerate = math.floor(sprite.frames[1].duration * 60)

    local dialog = Dialog("Export Icon/Cursor")
    if dialog == nil then
        error("Failed to create dialog, UI may not be available")
    end

    local function updateVisibility ()
        local filetype = dialog.data[ID.filetype]
        local isCursor = getOptionEntry(FILETYPE_OPTIONS, filetype).isCursor
        local isAnimated = getOptionEntry(FILETYPE_OPTIONS, filetype).isAnimated
        dialog:modify({ id = ID.hotspotX, visible = isCursor })
        dialog:modify({ id = ID.hotspotY, visible = isCursor })
        dialog:modify({ id = ID.framerate, visible = isAnimated })
    end

    local function updateFilename ()
        local filename = dialog.data[ID.filename] --[[ @as string ]]
        local filetype = dialog.data[ID.filetype] --[[ @as string ]]
        local newFilename = app.fs.filePathAndTitle(filename) .. "." .. getOptionEntry(FILETYPE_OPTIONS, filetype).value
        dialog.data[ID.filename] = newFilename
        dialog:modify({ id = ID.filename, filename = newFilename })
    end

    dialog
        :combobox({
            id = ID.filetype,
            label = "File Type",
            option = savedData[ID.filetype] or defaultFiletype,
            options = optionLabels(FILETYPE_OPTIONS),
            onchange = function ()
                updateVisibility()
                updateFilename()
            end,
        })
        :combobox({
            id = ID.layers,
            label = "Layers",
            option = savedData[ID.layers] or LAYER_OPTIONS["Visible"],
            options = optionLabels(LAYER_OPTIONS),
        })
        :combobox({
            id = ID.tag,
            label = "Frames",
            option = savedData[ID.tag] or TAG_OPTION_ALL,
            options = optionLabels(tagOptions),
        })
        :number({
            id = ID.framerate,
            label = "Framerate (1/60s)",
            text = tostring(savedData[ID.framerate]) or tostring(defaultFramerate),
        })
        :number({
            id = ID.hotspotX,
            label = "Hot Spot",
            text = tostring(savedData[ID.hotspotX]) or "0",
            decimals = 0,
        })
        :number({
            id = ID.hotspotY,
            text = tostring(savedData[ID.hotspotY]) or "0",
            decimals = 0,
        })
        :separator({ text = "Output" })
        :file({
            id = ID.filename,
            label = "Filename",
            title = "Export as...",
            save = true,
            filename = savedData[ID.filename] or defaultFilename,
        })
        :check({
            id = ID.showCompleted,
            text = "Show completion dialog",
            selected = savedData[ID.showCompleted] ~= false,
        })
        -- Buttons
        :button({ id = ID.ok, text = "&Export", focus = true })
        :button({ id = ID.cancel, text = "&Cancel" })

    while true do
        updateVisibility()
        dialog:show()

        -- Check if cancelled
        if not dialog.data[ID.ok] then
            return nil
        end

        -- Build params table
        local params = {
            filetype = getOptionEntry(FILETYPE_OPTIONS, dialog.data.filetype).value,
            filename = dialog.data.filename,
            hotSpotX = dialog.data.hotspotX or 0,
            hotSpotY = dialog.data.hotspotY or 0,
            framerate = dialog.data.framerate or 1,
            tag = getOptionEntry(tagOptions, dialog.data.tag).value,
            layers = getOptionEntry(LAYER_OPTIONS, dialog.data.layers).value,
            showCompleted = dialog.data.showCompleted,
        }

        -- Validate params
        local valid, validationError = parameter.validate(params, sprite)
        if valid then
            sprite.properties[PROPERTY_KEY] = dialog.data
            return params --[[@as IconCursorParams]]
        else
            util.alert({
                title = "Invalid Parameters",
                text = validationError or "Unknown validation error",
            })
        end
    end
end

return {
    show = show,
}
