-- export as psd file
-- created by Tsukina_7mochi
-- DO NOT redistribute this code
------------------------------------------------------------

-- returns whether given value is integer
function isInteger(inVal)
    if type(inVal)~="number" then
        return false
    else
        return inVal%1 ..""=="0"
    end
end

-- write data with big endian
function write(file, size, data)
  if not file then return end
  if not isInteger(size) then return end
  if size < 1 then return end

  local mask = 0xff << (8 * (size - 1))
  for i = 1, size do
    file:write(string.format("%c", (data & mask) >> (8 * (size - i))))
    mask = mask >> 8
  end
end

-- returns the sum of the table value
function sum(arr)
  local result = 0
  for i, n in ipairs(arr) do
    if type(n) == "number" then
      result = result + n
    end
  end

  return result
end

-- Compress with RLE (PackBits)
function packBits(arr)
  local size = 0xFF

  if #arr == 0 then
    return arr
  end

  local result = {}
  local buff = { arr[1] }
  local flag = -1

  local i = 2
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
      if buff[#buff] == arr[i] then
        flag = 0
      else
        flag = 1
      end
      buff[#buff+1] = arr[i]
    end
    i = i + 1
  end

  if flag == 0 then
    result[#result+1] = size - (#buff - 2)
    result[#result+1] = buff[1]
  else
    result[#result+1] = #buff - 1
    for j = 1, #buff do result[#result+1] = buff[j] end
  end

  return result
end

--------------------------------

if app.apiVersion < 1 then
  return app.alert("This script requires Aseprite v1.2.10-beta3")
end

local sprite = app.activeSprite
if not sprite then
  return app.alert("There is no active sprite")
end

local blendModeTable = {}
blendModeTable[BlendMode.NORMAL] = "norm"
blendModeTable[BlendMode.MULTIPLY] = "mul "
blendModeTable[BlendMode.SCREEN] = "scrn"
blendModeTable[BlendMode.OVERLAY] = "over"
blendModeTable[BlendMode.DARKEN] = "dark"
blendModeTable[BlendMode.LIGHTEN] = "lite"
blendModeTable[BlendMode.COLOR_DODGE] = "div "
blendModeTable[BlendMode.COLOR_BURN] = "idiv"
blendModeTable[BlendMode.HARD_LIGHT] = "hLit"
blendModeTable[BlendMode.SOFT_LIGHT] = "sLit"
blendModeTable[BlendMode.DIFFERENCE] = "diff"
blendModeTable[BlendMode.EXCLUSION] = "smud"
blendModeTable[BlendMode.HSL_HUE] = "hue "
blendModeTable[BlendMode.HSL_SATURATION] = "sat "
blendModeTable[BlendMode.HSL_COLOR] = "colr"
blendModeTable[BlendMode.HSL_LUMINOSITY] = "lum "
blendModeTable[BlendMode.ADDITION] = "lddg"
blendModeTable[BlendMode.SUBTRACT] = "fsub"
blendModeTable[BlendMode.DIVIDE] = "fdiv"

-- open file
local filename = sprite.filename .. ".psd"
local frameNum = 1

local dialog =
  Dialog():entry { id="filename", label="Filename: ", text=filename }
          :number{ id="frameNum", label="Frame number: ", text=string.format("%d", frameNum)}
          :button{ id="ok", text="&OK", focus=true }
          :button{ id="cancel", text="&Cancel" }
dialog:show()

if not dialog.data.ok then return end
filename = dialog.data.filename
frameNum = dialog.data.frameNum
if not filename then return end
if not isInteger(frameNum) then
  app.alert("Frame number is not valid.")
  return
end
if frameNum < 1 or #sprite.frames < frameNum then
  app.alert("The frame number " .. frameNum .. " is out of range.")
  return
end

file = io.open(filename, "wb")
if not file then return -1 end

-- File Header Section
local fh = {
  signature = "8BPS",
  version = 1,
  reserved = 0,
  channels = 4,
  height = sprite.height,
  width = sprite.width,
  depth = 8,
  colorMode = 3
}

file:write(fh.signature)
write(file, 2, fh.version)
write(file, 6, fh.reserved)
write(file, 2, fh.channels)
write(file, 4, fh.height)
write(file, 4, fh.width)
write(file, 2, fh.depth)
write(file, 2, fh.colorMode)

-- Color Mode Data
write(file, 4, 0)

-- Image Resources
write(file, 4, 0)

-- Layer and Mask Information
local lmi = {
  size = 0,
  layerInfo = {},
  globalLayerMaskInfo = {},   -- not used
  addition = {}               -- not used
}

lmi.layerInfo = {
  size = 2,
  count = #sprite.layers,
  records = {},
  imageData = {}
}

function setLayerInfo(group)
  for i, layer in ipairs(group) do
    if layer.isGroup then
      -- open folder
      local layerRecords = {
        top = 0,
        left = 1,
        bottom = 1,
        right = 2,
        channelCount = 4,
        channels = {
          {id = 0, size = 6},
          {id = 1, size = 6},
          {id = 2, size = 6},
          {id = 0xFFFF, size = 6}
        },
        blendSig = "8BIM",
        blendMode = "norm",
        opacity = 255,
        clipping = 0,
        flags = 0,
        filler = 0,
        exFieldSize = 0,
        mask = {
          size = 0
        },
        blendingRange = {
          size = 0
        },
        nameLength = 0,
        name = "",
        padding = 3,
        adjustment = {
          {
            signature = "8BIM",
            key = "lsct",
            size = 4,
            data = 3
          }
        },
      }
      if layerRecords.nameLength > 127 then
        layerRecords.nameLength = 127
      end
      layerRecords.exFieldSize = 8 + 1 + layerRecords.nameLength + layerRecords.padding + 16
      lmi.layerInfo.size = lmi.layerInfo.size + 58 + layerRecords.exFieldSize + 24
      lmi.layerInfo.records[#lmi.layerInfo.records + 1] = layerRecords
      lmi.layerInfo.imageData[#lmi.layerInfo.imageData + 1] = {
        compression ={
          r = 1,
          g = 1,
          b = 1,
          a = 1
        },
        r = {
          size = { 2 },
          data = {{ 0, 0 }}
        },
        g = {
          size = { 2 },
          data = {{ 0, 0 }}
        },
        b = {
          size = { 2 },
          data = {{ 0, 0 }}
        },
        a = {
          size = { 2 },
          data = {{ 0, 0 }}
        }
      }
      --

      setLayerInfo(layer.layers)

      -- close folder
      local layerRecords2 = {
        top = 0,
        left = 0,
        bottom = 1,
        right = 1,
        channelCount = 4,
        channels = {
          {id = 0, size = 6},
          {id = 1, size = 6},
          {id = 2, size = 6},
          {id = 0xFFFF, size = 6}
        },
        blendSig = "8BIM",
        blendMode = "pass",
        opacity = 255,
        clipping = 0,
        flags = 0,
        filler = 0,
        exFieldSize = 0,
        mask = {
          size = 0
        },
        blendingRange = {
          size = 0
        },
        nameLength = string.len(layer.name),
        name = layer.name:sub(0, 127),
        padding = 3,
        adjustment = {
          {
            signature = "8BIM",
            key = "lsct",
            size = 4,
            data = 1
          }
        },
      }
      if not layer.isExpanded then layerRecords2.adjustment[1].data = 2 end
      if not layer.isVisible then layerRecords2.flags = layerRecords2.flags | 2 end
      layerRecords2.padding = (3 - layerRecords2.nameLength % 4)    -- (4 - (nameLength + 1 + 16)% 4)% 4
      layerRecords2.exFieldSize = 8 + 1 + layerRecords2.nameLength + layerRecords2.padding + 16
      lmi.layerInfo.size = lmi.layerInfo.size + 58 + layerRecords2.exFieldSize + 24
      lmi.layerInfo.records[#lmi.layerInfo.records + 1] = layerRecords2
      lmi.layerInfo.imageData[#lmi.layerInfo.imageData + 1] = {
        compression ={
          r = 1,
          g = 1,
          b = 1,
          a = 1
        },
        r = {
          size = { 2 },
          data = {{ 0, 0 }}
        },
        g = {
          size = { 2 },
          data = {{ 0, 0 }}
        },
        b = {
          size = { 2 },
          data = {{ 0, 0 }}
        },
        a = {
          size = { 2 },
          data = {{ 0, 0 }}
        }
      }

      lmi.layerInfo.count = lmi.layerInfo.count + #layer.layers + 1
    else
      local cel = layer:cel(frameNum)
      if cel then
        local image = cel.image

        local imageData = {
          compression ={
            r = 1,
            g = 1,
            b = 1,
            a = 1
          },
          r = {
            size = {},
            data = {}
          },
          g = {
            size = {},
            data = {}
          },
          b = {
            size = {},
            data = {}
          },
          a = {
            size = {},
            data = {}
          }
        }
        for y = 0, cel.bounds.height-1 do
          local row = {
            r = {},
            g = {},
            b = {},
            a = {}
          }
          for x = 0, cel.bounds.width-1 do
            local color = { r=0, g=0, b=0, a=0 }
            local pixel = image:getPixel(x , y)
            if image.colorMode == ColorMode.RGB then
              color.r = app.pixelColor.rgbaR(pixel)
              color.g = app.pixelColor.rgbaG(pixel)
              color.b = app.pixelColor.rgbaB(pixel)
              color.a = app.pixelColor.rgbaA(pixel)
            elseif image.colorMode == ColorMode.GRAY then
              color.r = app.pixelColor.grayaV(pixel)
              color.g = app.pixelColor.grayaV(pixel)
              color.b = app.pixelColor.grayaV(pixel)
              color.a = app.pixelColor.grayaA(pixel)
            elseif image.colorMode == ColorMode.INDEXED then
              local c = sprite.palettes[1]:getColor(pixel)
              color.r = c.red
              color.g = c.green
              color.b = c.blue
              if pixel == 0 then color.a = 0 else color.a = c.alpha end
            end
            row.r[#row.r + 1] = color.r
            row.g[#row.g + 1] = color.g
            row.b[#row.b + 1] = color.b
            row.a[#row.a + 1] = color.a
          end
          imageData.r.data[#imageData.r.data + 1] = packBits(row.r)
          imageData.g.data[#imageData.g.data + 1] = packBits(row.g)
          imageData.b.data[#imageData.b.data + 1] = packBits(row.b)
          imageData.a.data[#imageData.a.data + 1] = packBits(row.a)
          imageData.r.size[#imageData.r.size + 1] = #imageData.r.data[#imageData.r.data]
          imageData.g.size[#imageData.g.size + 1] = #imageData.g.data[#imageData.g.data]
          imageData.b.size[#imageData.b.size + 1] = #imageData.b.data[#imageData.b.data]
          imageData.a.size[#imageData.a.size + 1] = #imageData.a.data[#imageData.a.data]
        end
        lmi.layerInfo.imageData[#lmi.layerInfo.imageData + 1] = imageData

        local imageSize = {
          r = sum(imageData.r.size) + #imageData.r.size * 2 + 2,
          g = sum(imageData.g.size) + #imageData.g.size * 2 + 2,
          b = sum(imageData.b.size) + #imageData.b.size * 2 + 2,
          a = sum(imageData.a.size) + #imageData.a.size * 2 + 2
        }

        local layerRecords = {
          top = cel.bounds.y,
          left = cel.bounds.x,
          bottom = cel.bounds.y + cel.bounds.height,
          right = cel.bounds.x + cel.bounds.width,
          channelCount = 4,
          channels = {
            {id = 0, size = imageSize.r},
            {id = 1, size = imageSize.g},
            {id = 2, size = imageSize.b},
            {id = 0xFFFF, size = imageSize.a}
          },
          blendSig = "8BIM",
          blendMode = blendModeTable[cel.layer.blendMode],
          opacity = cel.layer.opacity,
          clipping = 0,
          flags = 0,
          filler = 0,
          exFieldSize = 0,
          mask = {
            size = 0
          },
          blendingRange = {
            size = 0
          },
          nameLength = string.len(cel.layer.name),
          name = cel.layer.name:sub(0, 127),
          padding = 0
        }
        if layerRecords.nameLength > 127 then
          layerRecords.nameLength = 127
        end
        if not layer.isVisible then layerRecords.flags = layerRecords.flags | 2 end
        layerRecords.padding = (3 - layerRecords.nameLength % 4)    -- (4 - (nameLength + 1)% 4)% 4
        layerRecords.exFieldSize = 8 + 1 + layerRecords.nameLength + layerRecords.padding
        lmi.layerInfo.size = lmi.layerInfo.size + 58 + layerRecords.exFieldSize + imageSize.r + imageSize.g + imageSize.b + imageSize.a
        lmi.layerInfo.records[#lmi.layerInfo.records + 1] = layerRecords
      else
        -- insert empty layer
        local layerRecords = {
          top = 0,
          left = 0,
          bottom = 1,
          right = 1,
          channelCount = 4,
          channels = {
            {id = 0, size = 6},
            {id = 1, size = 6},
            {id = 2, size = 6},
            {id = 0xFFFF, size = 6}
          },
          blendSig = "8BIM",
          blendMode = "norm",
          opacity = 255,
          clipping = 0,
          flags = 0,
          filler = 0,
          exFieldSize = 0,
          mask = {
            size = 0
          },
          blendingRange = {
            size = 0
          },
          nameLength = string.len(layer.name),
          name = layer.name:sub(0, 127),
          padding = 0
        }
        if layerRecords.nameLength > 127 then
          layerRecords.nameLength = 127
        end
        if not layer.isVisible then layerRecords.flags = layerRecords.flags | 2 end
        layerRecords.padding = (3 - layerRecords.nameLength % 4)    -- (4 - (nameLength + 1)% 4)% 4
        layerRecords.exFieldSize = 8 + 1 + layerRecords.nameLength + layerRecords.padding
        lmi.layerInfo.size = lmi.layerInfo.size + 58 + layerRecords.exFieldSize + 24
        lmi.layerInfo.records[#lmi.layerInfo.records + 1] = layerRecords
        lmi.layerInfo.imageData[#lmi.layerInfo.imageData + 1] = {
          compression ={
            r = 1,
            g = 1,
            b = 1,
            a = 1
          },
          r = {
            size = { 2 },
            data = {{ 0, 0 }}
          },
          g = {
            size = { 2 },
            data = {{ 0, 0 }}
          },
          b = {
            size = { 2 },
            data = {{ 0, 0 }}
          },
          a = {
            size = { 2 },
            data = {{ 0, 0 }}
          }
        }
      end
    end
  end
end
setLayerInfo(sprite.layers)
lmi.size = lmi.layerInfo.size + 4

write(file, 4, lmi.size)
write(file, 4, lmi.layerInfo.size)
write(file, 2, lmi.layerInfo.count)
for i, record in ipairs(lmi.layerInfo.records) do
  write(file, 4, record.top)
  write(file, 4, record.left)
  write(file, 4, record.bottom)
  write(file, 4, record.right)
  write(file, 2, record.channelCount)
  for i, channel in ipairs(record.channels) do
    write(file, 2, channel.id)
    write(file, 4, channel.size)
  end
  file:write(record.blendSig)
  file:write(record.blendMode)
  write(file, 1, record.opacity)
  write(file, 1, record.clipping)
  write(file, 1, record.flags)
  write(file, 1, record.filler)
  write(file, 4, record.exFieldSize)
  write(file, 4, record.mask.size)
  write(file, 4, record.blendingRange.size)
  write(file, 1, record.nameLength)
  file:write(record.name)
  write(file, record.padding, 0)
  if record.adjustment then
    for i, d in ipairs(record.adjustment) do
      file:write(d.signature)
      file:write(d.key)
      write(file, 4, d.size)
      write(file, d.size, d.data)
    end
  end
end

function exportImageData(file, compression, data)
  write(file, 2, compression)
  if compression == 0 then
    for i, d in ipairs(data) do
      write(file, 1, d)
    end
  elseif compression == 1 then
    for i, d in ipairs(data.size) do
      write(file, 2, d)
    end
    for i, row in ipairs(data.data) do
      for i, d in ipairs(row) do
        write(file, 1, d)
      end
    end
  end
end

for i, data in ipairs(lmi.layerInfo.imageData) do
  exportImageData(file, data.compression.r, data.r)
  exportImageData(file, data.compression.g, data.g)
  exportImageData(file, data.compression.b, data.b)
  exportImageData(file, data.compression.a, data.a)
end

--image data section
for i, data in ipairs(lmi.layerInfo.imageData) do
  exportImageData(file, data.compression.r, data.r)
  exportImageData(file, data.compression.g, data.g)
  exportImageData(file, data.compression.b, data.b)
  exportImageData(file, data.compression.a, data.a)
end

file:close()

app.alert("PSD file saved as " .. filename)
