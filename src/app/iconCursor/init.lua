local dialog = require("app.iconCursor.dialog")

local function main ()
    local params = dialog.show(app.sprite)
    if params == nil then
        -- canceled
        print("canceled")
        return
    end

    for k, v in pairs(params or {}) do
        print(k, v)
    end
end

return { main = main }
