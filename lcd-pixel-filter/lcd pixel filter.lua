--------------------
-- LCD Piexl Filter
--
-- Tsukina_7mochi
--------------------

-- duplicate sprite
if not app.activeSprite then
  return app.alert("No active sprite.")
end

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
    local colR = pc.rgba(pc.rgbaR(imgData[y + 1][x + 1]), 0, 0)
    local colG = pc.rgba(0, pc.rgbaG(imgData[y + 1][x + 1]), 0)
    local colB = pc.rgba(0, 0, pc.rgbaB(imgData[y + 1][x + 1]))
    image:drawPixel(x * 3 + 0, y * 3 + 0, colR)
    image:drawPixel(x * 3 + 0, y * 3 + 1, colR)
    image:drawPixel(x * 3 + 0, y * 3 + 2, colR)
    image:drawPixel(x * 3 + 1, y * 3 + 0, colG)
    image:drawPixel(x * 3 + 1, y * 3 + 1, colG)
    image:drawPixel(x * 3 + 1, y * 3 + 2, colG)
    image:drawPixel(x * 3 + 2, y * 3 + 0, colB)
    image:drawPixel(x * 3 + 2, y * 3 + 1, colB)
    image:drawPixel(x * 3 + 2, y * 3 + 2, colB)
  end
end
