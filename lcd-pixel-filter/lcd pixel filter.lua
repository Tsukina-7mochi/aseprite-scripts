-- applys filter like LCD
-- DO NOT redistribute this code
--
-- see: https://github.com/Tsukina-7mochi/aseprite-scripts
------------------------------------------------------------

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
  dialog:button{
    id = "button" .. i,
    text = buttons[i],
    onclick = function()
      buttons[i] = colorTable[buttons[i]]
      dialog:modify{
        id = "button" .. i,
        text = buttons[i]
      }
    end
  }

  if i % 3 == 0 then
    dialog:newrow()
  end
end

dialog:button{
  id = "ok",
  text = "&OK",
  focus = true
}:button{
  id = "cancel",
  text="&Cancel"
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
for y = 0, iBounds.height - 1 do
  local arr = {}
  for x = 0, iBounds.width - 1 do
    local pVal = image:getPixel(x, y)
    arr[#arr + 1] = pVal
  end
  imgData[#imgData + 1] = arr
end

-- scale
sprite:resize(iBounds.width * 3, iBounds.height * 3)
image = cel.image   -- update image

-- draw
local pc = app.pixelColor

for y = 0, iBounds.height - 1 do
  for x = 0, iBounds.width - 1 do
    local colors = {
      R = pc.rgba(pc.rgbaR(imgData[y + 1][x + 1]), 0, 0),
      G = pc.rgba(0, pc.rgbaG(imgData[y + 1][x + 1]), 0),
      B = pc.rgba(0, 0, pc.rgbaB(imgData[y + 1][x + 1])),
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
