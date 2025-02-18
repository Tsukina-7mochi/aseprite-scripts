local neblua = require("lib.neblua")

local distDir = os.getenv("DIST_DIR")

neblua.bundle {
    entry = "main",
    output = distDir .. "/LCD Pixel Filter.lua",
    include = {
        "./main.lua",
    },
    rootDir = "./lcd-pixel-filter",
    fallbackStderr = true,
}
