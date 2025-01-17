local neblua = require("lib.neblua")

local distDir = os.getenv("DIST_DIR")

neblua.bundle {
    entry = "main",
    output = distDir .. "/Export as psd.lua",
    include = {
        "./main.lua",
    },
    rootDir = "./psd",
}
