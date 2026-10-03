-- Release helper.
--
-- Usage:
--   lua release.lua check          Validate manifests of all scripts.
--   lua release.lua changed [ref]  Print "true" if any script version differs from that at `ref`, otherwise "false".
--   lua release.lua notes [ref]    Print release notes comparing script versions with those at `ref`.
--
-- `ref` is a git revision (e.g. the previous release tag). Omitting it means there is no previous release.

local targets = require("targets")

local VERSION_PATTERN = "^(%d%d%d%d)%.(%d%d)%.(%d%d)$"

---@param target { entry: string, file: string }
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

---@param target { entry: string, file: string }
---@param ref string?
---@return table?
local function readManifest (target, ref)
    local path = entryPath(target)
    local source

    if ref == nil then
        local file = assert(io.open(path, "r"))
        source = file:read("a")
        file:close()
    else
        local pipe = assert(io.popen(string.format("git show '%s:%s' 2>/dev/null", ref, path), "r"))
        source = pipe:read("a")
        if not pipe:close() then
            -- the script did not exist at `ref`
            return nil
        end
    end

    return loadManifest(source, "@" .. path)
end

---@param ref string?
local function validateRef (ref)
    if ref ~= nil and not ref:match("^[%w%._/%-]+$") then
        error("Invalid ref: " .. ref)
    end
end

---@param ref string?
---@return { target: table, manifest: table, previous: table? }[]
local function compare (ref)
    validateRef(ref)

    local result = {}
    for _, target in ipairs(targets) do
        local previous = nil
        if ref ~= nil then
            previous = readManifest(target, ref)
        end
        table.insert(result, {
            target = target,
            manifest = assert(readManifest(target), "Manifest not found: " .. entryPath(target)),
            previous = previous,
        })
    end
    return result
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

---@param ref string?
local function changed (ref)
    for _, item in ipairs(compare(ref)) do
        if item.previous == nil or item.previous.version ~= item.manifest.version then
            print("true")
            return
        end
    end
    print("false")
end

---@param ref string?
local function notes (ref)
    -- file names are the release asset names, in which spaces are replaced with periods
    print("| Script | File | Version | Status |")
    print("| --- | --- | --- | --- |")

    for _, item in ipairs(compare(ref)) do
        local status
        if item.previous == nil then
            status = "**New**"
        elseif item.previous.version ~= item.manifest.version then
            status = string.format("**Updated** (from %s)", tostring(item.previous.version))
        else
            status = "Unchanged"
        end

        print(
            string.format(
                "| %s | `%s` | %s | %s |",
                item.manifest.name,
                (item.target.file:gsub(" ", ".")),
                item.manifest.version,
                status
            )
        )
    end

    if ref ~= nil then
        print("")
        print("Previous release: " .. ref)
    end
end

local command, ref = arg[1], arg[2]
if ref == "" then
    ref = nil
end

if command == "check" then
    check()
elseif command == "changed" then
    changed(ref)
elseif command == "notes" then
    notes(ref)
else
    io.stderr:write("Usage: lua release.lua <check|changed|notes> [ref]\n")
    os.exit(1)
end
