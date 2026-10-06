local neblua = require("lib.neblua")
local targets = require("targets")

local preInitCode = [[
    local function snapshot(target)
        local addedKeys = {}
        setmetatable(target, {
            __newindex = function (t, k, v)
                table.insert(addedKeys, k)
                rawset(t, k, v)
            end,
        })

        local rollback = function()
            for _, k in ipairs(addedKeys) do
                rawset(target, k, nil)
            end
            setmetatable(target, nil)
        end

        return rollback
    end

    local rollbackLoaded = snapshot(package.loaded)
    local rollbackPreload = snapshot(package.preload)
    local rollbackSearchers = snapshot(package.searchers)
]]

local postRunCode = [[
    rollbackLoaded()
    rollbackPreload()
    rollbackSearchers()
]]

for _, target in ipairs(targets) do
    neblua.bundle({
        entry = target.entry,
        output = "./" .. target.dir .. "/" .. target.file,
        include = {
            "./" .. target.entry:gsub("%.", "/") .. ".lua",
        },
        rootDir = "./src",
        fallbackStderr = true,
        preInitCode = preInitCode,
        postRunCode = postRunCode,
    })
end
