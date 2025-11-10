local neblua = require("lib.neblua")

local preInitCode = [[
    local function snapshot(target)
        local addedKeys = {}
        setmetatable(target, {
            __index = function(t, k)
                if k == "__unload" then
                    return function()
                        for _, k in ipairs(addedKeys) do
                            rawset(t, k, nil)
                        end
                    end
                end

                return rawget(t, k)
            end,
            __newindex = function (t, k, v)
                table.insert(addedKeys, k)
                rawset(t, k, v)
            end,
        })
        return target
    end

    rawset(package, "loaded", snapshot(package.loaded))
    rawset(package, "preload", snapshot(package.preload))
    rawset(package, "searchers", snapshot(package.searchers))
]]

local postRunCode = [[
    package.loaded.__unload()
    package.preload.__unload()
    package.searchers.__unload()

    setmetatable(package.loaded, nil)
    setmetatable(package.preload, nil)
    setmetatable(package.searchers, nil)
]]

neblua.bundle({
    entry = "entry.iconCursor",
    output = "./icon-and-cursor/Export as ico cur ani.lua",
    include = {
        "./entry/iconCursor.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
    preInitCode = preInitCode,
    postRunCode = postRunCode,
})

neblua.bundle({
    entry = "entry.lcdFilter",
    output = "./lcd-pixel-filter/LCD Pixel Filter.lua",
    include = {
        "./entry/lcdFilter.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
    preInitCode = preInitCode,
    postRunCode = postRunCode,
})

neblua.bundle({
    entry = "entry.psd",
    output = "./psd/Export as psd.lua",
    include = {
        "./entry/psd.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
    preInitCode = preInitCode,
    postRunCode = postRunCode,
})

neblua.bundle({
    entry = "entry.smoothFilter",
    output = "./smooth-filter/Smooth Filter.lua",
    include = {
        "./entry/smoothFilter.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
    preInitCode = preInitCode,
    postRunCode = postRunCode,
})
