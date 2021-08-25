-- returns whether given value is integer
function isInteger(inVal)
  if type(inVal)~="number" then
      return false
  else
      return inVal%1 ..""=="0"
  end
end

-- writes data with little endian
function write(file, size, data)
  if not file then return end
  if not isInteger(size) then return end
  if size < 1 then return end

  local d = data
  for i = 1, size do
    file:write(string.format("%c", d & 0xFF))
    d = d >> 8
  end
end

-- writes string (for multi-byte character)
function writeStr(file, str)
  if not file then return end
  if not str then return end

  for i = 1, #str do
    file:write(string.format("%c", str:byte(i)))
  end
end

-- Compresses with RLE (PackBits)
function packBits(arr)
  local size = 0xFF

  if #arr == 0 then
    return arr
  end

  local result = {}
  local buff = {}
  local flag = -1

  local i = 1
  while i <= #arr do
    if flag == 0 then
      -- continuous
      if buff[#buff] == arr[i] then
        buff[#buff+1] = arr[i]
      else
        result[#result+1] = size - (#buff - 2)
        result[#result+1] = buff[1]
        buff = { arr[i] }
        flag = -1
      end
    elseif flag == 1 then
      -- discontinuous
      if buff[#buff] ~= arr[i] then
        buff[#buff+1] = arr[i]
      else
        result[#result+1] = #buff - 2
        for j = 1, #buff-1 do result[#result+1] = buff[j] end
        buff = { arr[i], arr[i] }
        flag = 0
      end
    else
      -- undetermined
      if #buff ~= 0 then
        if buff[#buff] == arr[i] then
          flag = 0
        else
          flag = 1
        end
      end
      buff[#buff+1] = arr[i]
    end

    if #buff > size/2 then
      if flag == 0 then
        result[#result+1] = size - (#buff - 2)
        result[#result+1] = buff[1]
      else
        result[#result+1] = #buff - 1
        for j = 1, #buff do result[#result+1] = buff[j] end
      end
      buff = {}
      flag = -1
    end

    i = i + 1
  end

  if #buff ~= 0 then
    if flag == 0 then
      result[#result+1] = size - (#buff - 2)
      result[#result+1] = buff[1]
    else
      result[#result+1] = #buff - 1
      for j = 1, #buff do result[#result+1] = buff[j] end
    end
  end

  return result
end

-- get RGB value of pixel
function getRGB(pixel, colorMode)
  local color = { r = 0, g = 0, b = 0, a = 0 }
  if colorMode == ColorMode.RGB then
    color.r = app.pixelColor.rgbaR(pixel)
    color.g = app.pixelColor.rgbaG(pixel)
    color.b = app.pixelColor.rgbaB(pixel)
    color.a = app.pixelColor.rgbaA(pixel)
  elseif colorMode == ColorMode.GRAY then
    color.r = app.pixelColor.grayaV(pixel)
    color.g = app.pixelColor.grayaV(pixel)
    color.b = app.pixelColor.grayaV(pixel)
    color.a = app.pixelColor.grayaA(pixel)
  elseif colorMode == ColorMode.INDEXED then
    local c = sprite.palettes[1]:getColor(pixel)
    color.r = c.red
    color.g = c.green
    color.b = c.blue
    color.a = c.alpha
  end
  return color
end

-- shows alert with failure message
function failAlert(text)
  app.alert{
    title = "Export Failed",
    text = text,
    buttons = "OK"
  }
end





------------------------------
-- ENTRY
------------------------------

if app.apiVersion < 1 then
  failAlert("This script requires Aseprite v1.2.10-beta3 or above.")
  return
end

if not app.activeSprite then
  failAlert("No sprite selected.")
  return
end
local sprite = Sprite(app.activeSprite)
-- sprite:flatten()
local layer = sprite.layers[1]

local filename = app.fs.filePathAndTitle(sprite.filename) .. ".ico"
local file = io.open(filename, "wb")
if not file then
  failAlert("Failed to open the file to export.")
  return
end

local dpi = 96

---- FILE HEADER
local writeFileHeader = function(data)
  write(file, 2, 0)
  write(file, 2, data.resourceType)
  write(file, 2, data.resourceCount)
end
writeFileHeader{
  -- 1: icon, 2: cursor
  resourceType = 1,
  resourceCount = #sprite.frames,
}

-- ICON
-- cache icon data because icon info header requires offset to
-- corresponding icon data
local icons = {}

for _, frame in ipares(sprite.frames) do
  -- make pallet of frame
  local pallet = {}
  local image = layer:cel(frame.frameNumber).image

  for x = 0, image.width - 1 do
    for y = 0, image.height - 1 do
      local pixel = getRGB(image:getPixel(x, y), image.colorMode)
      local color = pixel.r << 16 + pixel.g << 8 + pixel.b
      pallet[color] = true
    end
  end


  local infoHeader = {
    width = sprite.width,
    height = sprite.height,
    colorCount = #pallet,
    bitmapSize = -1,             -- deside later
    bitmapOffset = -1            -- deside later
  }
  local bitmapInfoHeader = {
    headerSize = 40,
    width = sprite.width,
    height = sprite.height,
    planes = 1,
    pixelSize = 8,
    compression = 1,              -- RLE
    bitmapSize = -1,             -- deside later
    resolution = dpi * 39.375,
    colorCount = #pallet,
    imporantColorCount = 0
  }
end

file:close()

app.alert(filename)