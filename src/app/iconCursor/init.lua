local dialog = require("app.iconCursor.dialog")
local parameter = require("app.iconCursor.parameter")
local createIcon = require("app.iconCursor.icon").create
local createAnimCursor = require("app.iconCursor.anim-cursor").create
local util = require("pkg.asepriteUtil")

local function getParamsFromArgs ()
    local params = parameter.default(app.sprite)
    if app.params.filetype ~= nil then
        params.filetype = app.params.filetype
    end
    if app.params.filename ~= nil then
        params.filename = app.params.filename
    end
    if app.params["hot-spot-x"] ~= nil then
        params.hotSpotX = assert(tonumber(app.params["hot-spot-x"]))
    end
    if app.params["hot-spot-y"] ~= nil then
        params.hotSpotY = assert(tonumber(app.params["hot-spot-y"]))
    end
    if app.params.framerate ~= nil then
        params.framerate = assert(tonumber(app.params.framerate))
    end
    if app.params.layers ~= nil then
        params.layers = app.params.layers
    end
    if app.params.tag ~= nil then
        params.tag = tonumber(app.params.tag) or app.params.tag
    end

    local valid, validationError = parameter.validate(params, app.sprite)
    if not valid then
        error("Error: " .. (validationError or "Unknown validation error"))
    end

    return params
end

local function getParams ()
    if app.isUIAvailable then
        return dialog.show(app.sprite)
    else
        return getParamsFromArgs()
    end
end

local function main ()
    if app.apiVersion < 1 then
        util.alert({ text = "This script requires Aseprite v1.2.10-beta3 or above." })
        return
    end

    local sprite = app.sprite
    if sprite == nil then
        util.alert({ text = "There is no active sprite to export." })
        return
    end

    local params = getParams()
    if params == nil then
        return
    end

    local targetLayers = {}
    if params.layers == "selected" then
        targetLayers = util.sprite.getSelectedLayers(sprite)
    elseif params.layers == "visible" then
        targetLayers = util.sprite.getVisibleLayers(sprite)
    end

    local targetFrames = {}
    if params.tag == nil then
        targetFrames = sprite.frames
    elseif type(params.tag) == "number" then
        targetFrames = { sprite.frames[params.tag] }
    else
        local tag = util.sprite.getTag(sprite, params.tag)
        if tag == nil then
            error("The specified tag was not found.")
            return
        end

        targetFrames = util.tag.getFrames(tag)
    end

    local fileData = ""
    if params.filetype == "ani" then
        fileData = createAnimCursor(params, targetLayers, targetFrames)
    else
        fileData = createIcon(params, targetLayers, targetFrames)
    end

    local file = io.open(params.filename, "wb")
    if not file then
        util.alert({ text = "Failed to open the file to export." })
        return
    end

    file:write(fileData)

    file:close()

    if app.isUIAvailable and params.showCompleted then
        util.alert({ title = "Export Complete", text = "Exported to " .. params.filename })
    end
end

return { main = main }
