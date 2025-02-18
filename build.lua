local neblua = require("lib.neblua")

neblua.bundle {
    entry = "entry.iconCursor",
    output = "./icon-and-cursor/Export as ico cur ani.lua",
    include = {
        "./entry/iconCursor.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
}

neblua.bundle {
    entry = "entry.lcdFilter",
    output = "./lcd-pixel-filter/LCD Pixel Filter.lua",
    include = {
        "./entry/lcdFilter.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
}


neblua.bundle {
    entry = "entry.psd",
    output = "./psd/Export as psd.lua",
    include = {
        "./entry/psd.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
}

neblua.bundle {
    entry = "entry.smoothFilter",
    output = "./smooth-filter/Smooth Filter.lua",
    include = {
        "./entry/smoothFilter.lua",
    },
    rootDir = "./src",
    fallbackStderr = true,
}
