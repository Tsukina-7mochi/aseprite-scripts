package.manifest = {
    name = "aseprite-scripts/icon-and-cursor",
    description = "Export sprite as windows icon and cursor.",
    version = "v0.2.0",
    author = "Mooncake Sugar",
    license = "MIT",
    homepage = "https://github.com/Tsukina-7mochi/aseprite-scripts/blob/master/icon-and-cursor/",
}

if not app then
    return
end

require("app.iconCursor.init").main()
