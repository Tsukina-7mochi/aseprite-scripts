local isInteger = require("pkg.number.isInteger")

---@alias AlertInit { title?: string, text: string | string[], buttons?: string[] }

---Prints an alert message to the UI if available, otherwise print to the console.
---@param init AlertInit
---@return integer
local function alert(init)
    local title = init.title
    local text = init.text
    local buttons = init.buttons

    if title == nil then
        title = ""
    end
    if buttons == nil or #buttons == 0 then
        buttons = { "&Ok" }
    end

    if app.isUIAvailable then
        return app.alert { title = title, text = text, buttons = buttons }
    else
        if title ~= "" then
            print(title)
        end

        if type(text) == "string" then
            print(text)
        else
            print(table.concat(text, "\n"))
        end

        if #buttons <= 1 then
            --Just receive keyboard input
            local _ = io.stdin:read("l")
            return 1
        else
            --Print list of buttons with index
            local len = #("" .. #buttons)
            local formatString = "%" .. len .. "d: %s"
            for i, buttonText in ipairs(buttons) do
                --Remove the first "&"
                local amp = buttonText:find("&")
                if amp ~= nil then
                    buttonText = buttonText:sub(0, amp - 1) .. buttonText:sub(amp + 1)
                end
                print(string.format(formatString, i, buttonText))
            end
            io.stdin:flush()

            while true do
                io.stdout:write("> ")
                io.stdout:flush()

                local answer = tonumber(io.stdin:read("l"))
                if isInteger(answer) and 1 <= answer and answer <= #buttons then
                    return answer --[[ @as integer ]]
                end
            end
        end
    end
end

return alert
