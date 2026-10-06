-- Validates manifests of all scripts.
--
-- Usage:
--   lua check-manifest.lua

local targets = require("targets")

local VERSION_PATTERN = "^(%d%d%d%d)%.(%d%d)%.(%d%d)$"

---@param target { entry: string, dir: string, file: string }
---@return string
local function entryPath (target)
    return "src/" .. target.entry:gsub("%.", "/") .. ".lua"
end

---@param source string
---@param chunkName string
---@return table?
local function loadManifest (source, chunkName)
    -- entry scripts define `package.manifest` and return early when `app` is absent
    local env = { package = {} }
    local chunk, err = load(source, chunkName, "t", env)
    if not chunk then
        error(err)
    end
    chunk()
    return env.package.manifest
end

---@param target { entry: string, dir: string, file: string }
---@return table?
local function readManifest (target)
    local path = entryPath(target)
    local file = assert(io.open(path, "r"))
    local source = file:read("a")
    file:close()
    return loadManifest(source, "@" .. path)
end

local function check ()
    local ok = true
    for _, target in ipairs(targets) do
        local path = entryPath(target)
        local manifest = readManifest(target)

        if type(manifest) ~= "table" then
            print(path .. ": package.manifest is not defined")
            ok = false
        else
            if type(manifest.name) ~= "string" then
                print(path .. ": manifest.name is not a string")
                ok = false
            end

            local version = manifest.version
            local year, month, day = nil, nil, nil
            if type(version) == "string" then
                year, month, day = version:match(VERSION_PATTERN)
            end
            local valid = year ~= nil
                and tonumber(month) >= 1
                and tonumber(month) <= 12
                and tonumber(day) >= 1
                and tonumber(day) <= 31
            if not valid then
                print(path .. ": manifest.version must be yyyy.mm.dd, got " .. tostring(version))
                ok = false
            end
        end
    end

    if not ok then
        os.exit(1)
    end
    print("All manifests are valid.")
end

check()
