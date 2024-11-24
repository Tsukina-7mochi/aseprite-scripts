--- Print an alert message to the UI if available, otherwise print to the console.
---@param text string
local function alert(text)
    if app.isUIAvailable then
        app.alert(text)
    else
        print(text)
    end
end

return alert
