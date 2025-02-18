package.manifest = {
    name = "aseprite-scripts/lcd-pixel-filter",
    description = "Applies filter like LCD.",
    version = "v0.1.1",
    author = "Mooncake Sugar",
    license = "MIT",
    homepage = "https://github.com/Tsukina-7mochi/aseprite-scripts/blob/master/lcd-pixel-filter/"
}

if not app then return end

-- function alias
local pc = app.pixelColor

-- duplicate sprite
if not app.activeSprite then
    return app.alert("No active sprite.")
end

-- config
local colorTable = {
    R = "G",
    G = "B",
    B = "K",
    K = "R"
}
local buttons = { "R", "G", "B", "R", "G", "B", "R", "G", "B" }

local dialog = Dialog("LCD Pixel Filter")

for i = 1, #buttons do
    dialog:button {
        id = "button" .. i,
        text = buttons[i],
        onclick = function()
            buttons[i] = colorTable[buttons[i]]
            dialog:modify {
                id = "button" .. i,
                text = buttons[i]
            }
        end
    }

    if i % 3 == 0 then
        dialog:newrow()
    end
end

dialog:button {
    id = "ok",
    text = "&OK",
    focus = true
}:button {
    id = "cancel",
    text = "&Cancel"
}

dialog:show()


if not dialog.data.ok then return end


local sprite = Sprite(app.activeSprite)
sprite:flatten()

local cel     = sprite.cels[1]
local image   = cel.image
local sBounds = sprite.bounds
local iBounds = cel.bounds

if not cel then
    return app.alert("No valid cel.")
end
if not image then
    return app.alert("No valid image.")
end

-- create image data array
imgData = {}

for i = 1, #sprite.cels do
    cel = sprite.cels[i]
    image = cel.image

    if not image then
        imgData[i] = nil
    else
        -- scan image
        local data = {}
        for y = 0, iBounds.height - 1 do
            local arr = {}
            for x = 0, iBounds.width - 1 do
                local pVal = image:getPixel(x, y)
                arr[#arr + 1] = pVal
            end
            data[#data + 1] = arr
        end

        imgData[i] = data
    end
end

-- scale
sprite:resize(iBounds.width * 3, iBounds.height * 3)


-- draw
for i = 1, #sprite.cels do
    cel = sprite.cels[i]
    image = cel.image

    for y = 0, iBounds.height - 1 do
        for x = 0, iBounds.width - 1 do
            local colors = {
                R = pc.rgba(pc.rgbaR(imgData[i][y + 1][x + 1]), 0, 0),
                G = pc.rgba(0, pc.rgbaG(imgData[i][y + 1][x + 1]), 0),
                B = pc.rgba(0, 0, pc.rgbaB(imgData[i][y + 1][x + 1])),
                K = pc.rgba(0, 0, 0)
            }
            image:drawPixel(x * 3 + 0, y * 3 + 0, colors[buttons[1]])
            image:drawPixel(x * 3 + 1, y * 3 + 0, colors[buttons[2]])
            image:drawPixel(x * 3 + 2, y * 3 + 0, colors[buttons[3]])
            image:drawPixel(x * 3 + 0, y * 3 + 1, colors[buttons[4]])
            image:drawPixel(x * 3 + 1, y * 3 + 1, colors[buttons[5]])
            image:drawPixel(x * 3 + 2, y * 3 + 1, colors[buttons[6]])
            image:drawPixel(x * 3 + 0, y * 3 + 2, colors[buttons[7]])
            image:drawPixel(x * 3 + 1, y * 3 + 2, colors[buttons[8]])
            image:drawPixel(x * 3 + 2, y * 3 + 2, colors[buttons[9]])
        end
    end
end
