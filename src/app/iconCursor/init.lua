local dialog = require("app.iconCursor.dialog")
local util = require("pkg.asepriteUtil")

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

    local params = dialog.show(sprite)
    if params == nil then
        -- canceled or validation error
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
    else
        local tag = util.sprite.getTag(sprite, params.tag)
        if tag == nil then
            util.alert({ text = "The specified tag was not found." })
            return
        end

        targetFrames = util.tag.getFrames(tag)
    end
end

return { main = main }
