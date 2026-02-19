local parameter = require("app.iconCursor.parameter")
local util = require("pkg.asepriteUtil")

local PROPERTY_KEY = "icon-and-cursor.dialog"
local FILETYPE_OPTIONS = {
    { option = "Icon", value = "ico" },
    { option = "Cursor", value = "cur" },
    { option = "Animated Cursor", value = "ani" },
}
local LAYER_OPTIONS = {
    { option = "Visible", value = "visible" },
    { option = "Selected", value = "selected" },
}
local TAG_OPTION_PREFIX = "Tag: "
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

---@param options { option: string, value: any }[]
---@return string | nil
local function getOptionValue (options, option)
    for _, item in ipairs(options) do
        if item.option == option then
            return item.value
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
        local isCursor = filetype == "CUR" or filetype == "ANI"
        local isAnimated = filetype == "ANI"
        dialog:modify({ id = ID.hotspotX, visible = isCursor })
        dialog:modify({ id = ID.hotspotY, visible = isCursor })
        dialog:modify({ id = ID.framerate, visible = isAnimated })
    end

    local function updateFilename ()
        local filename = dialog.data[ID.filename] --[[ @as string ]]
        local filetype = dialog.data[ID.filetype] --[[ @as string ]]
        local newFilename = app.fs.filePathAndTitle(filename) .. "." .. filetype
        dialog.data[ID.filename] = newFilename
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
            filetype = getOptionValue(FILETYPE_OPTIONS, dialog.data.filetype),
            filename = dialog.data.filename,
            hotSpotX = dialog.data.hotspotX,
            hotSpotY = dialog.data.hotspotY,
            framerate = dialog.data.framerate,
            tag = getOptionValue(tagOptions, dialog.data.tag),
            layers = getOptionValue(LAYER_OPTIONS, dialog.data.layers),
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
