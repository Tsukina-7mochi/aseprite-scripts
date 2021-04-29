-- applies smoothing filter
-- DO NOT redistribute this code
--
-- see: https://github.com/Tsukina-7mochi/aseprite-scripts
------------------------------------------------------------

-- settings
local scale    = 9
local smooth   = 4
local vicinity = 4

local dlg = Dialog()
dlg:number{ id="scale", label="Scale", text="9" }
dlg:newrow()
dlg:number{ id="smooth", label="Smooth", text="4" }
dlg:newrow()
dlg:number{ id="vicinity", label="Background detection", text="4" }
dlg:newrow()
dlg:button{ id="ok", text="&OK" }
dlg:button{ id="cancel", text="&Cancel" }
dlg:show()

if not dlg.data.ok then return end

scale    = dlg.data.scale
smooth   = dlg.data.smooth
vicinity = dlg.data.vicinity

if smooth < 0 then
  smooth = 0
elseif smooth > math.floor(scale / 2) then
  smooth = math.floor(scale / 2)
end

if vicinity < 1 then
  vicinity = 1
end

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
sprite:resize(iBounds.width * scale, iBounds.height * scale)
image = cel.image   -- update image

-- smoothing
function drawTopLeft(x, y, col)
  -- top-left corner of enlarged pixel
  local ox, oy = (iBounds.x + x) * scale, (iBounds.y + y) * scale
  for i = 1, smooth do
    local rx, ry = i - 1, 0
    for j = 1, i do
      image:drawPixel(ox + rx, oy + ry, col)
      rx = rx - 1
      ry = ry + 1
    end
  end
end

function drawTopRight(x, y, col)
  -- top-right corner of enlarged pixel
  local ox, oy = (iBounds.x + x + 1) * scale - 1, (iBounds.y + y) * scale
  for i = 1, smooth do
    local rx, ry = -(i - 1), 0
    for j = 1, i do
      image:drawPixel(ox + rx, oy + ry, col)
      rx = rx + 1
      ry = ry + 1
    end
  end
end

function drawBottomLeft(x, y, col)
  -- bottom-left corner of enlarged pixel
  local ox, oy = (iBounds.x + x) * scale, (iBounds.y + y + 1) * scale
  for i = 1, smooth do
    local rx, ry = i - 1, 0
    for j = 1, i do
      image:drawPixel(ox + rx, oy + ry, col)
      rx = rx - 1
      ry = ry - 1
    end
  end
end

function drawBottomRight(x, y, col)
  -- bottom-right corner of enlarged pixel
  local ox, oy = (iBounds.x + x + 1) * scale - 1, (iBounds.y + y + 1) * scale - 1
  for i = 1, smooth do
    local rx, ry = -(i - 1), 0
    for j = 1, i do
      image:drawPixel(ox + rx, oy + ry, col)
      rx = rx + 1
      ry = ry - 1
    end
  end
end

for y = 0, iBounds.height- 2 do
  for x = 0, iBounds.width - 2 do
    -- process by 2x2 square
    local pTopLeft, pTopRight, pBottomLeft, pBottomRight = -1, -1, -1, -1

    pTopLeft     = imgData[y+1][x+1]
    pTopRight    = imgData[y+1][x+2]
    pBottomLeft  = imgData[y+2][x+1]
    pBottomRight = imgData[y+2][x+2]

    -- AB
    -- CA
    if pTopLeft == pBottomRight and pTopRight ~= pBottomLeft then
      drawBottomLeft(x+1, y  , pTopLeft)  -- B
      drawTopRight  (x  , y+1, pTopLeft)  -- C
    end

    -- BA
    -- AC
    if pTopRight == pBottomLeft and pTopLeft ~= pBottomRight then
      drawBottomRight(x  , y  , pTopRight) -- B
      drawTopLeft    (x+1, y+1, pTopRight) -- C
    end

    -- AB
    -- BA
    if pTopRight == pBottomLeft and pTopLeft == pBottomRight then
      -- count colors in (2 * vicinity) x (2 * vicinity) square
      local cc1, cc2 = 0, 0
      for j = y - vicinity + 1, y + vicinity do
        for i = x - vicinity + 1, x + vicinity do
          if 0 <= j and j < iBounds.height - 1 and 0 <= i and i < iBounds.width - 1 then
            local c = imgData[j+1][i+1]
            if c == pTopLeft then
              cc1 = cc1 + 1
            elseif c == pTopRight then
              cc2 = cc2 + 1
            end
          end
        end
      end

      if cc1 > cc2 then
        -- regard top-left and bottom-right as background
        drawBottomRight(x  , y  , pTopRight)
        drawTopLeft    (x+1, y+1, pTopRight)
      elseif cc1< cc2 then
        -- regard top-right and bottom-left as background
        drawBottomLeft(x+1, y  , pTopLeft)
        drawTopRight  (x  , y+1, pTopLeft)
      end
    end
  end
end
