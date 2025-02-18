local neblua = require("lib.neblua")

local distDir = os.getenv("DIST_DIR")

neblua.bundle {
    entry = "main",
    output = distDir .. "/Smooth Filter.lua",
    include = {
        "./main.lua",
    },
    rootDir = "./smooth-filter",
    fallbackStderr = true,
}
