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
        r = { 0, 2, 0, 0 },
        g = { 0, 2, 0, 0 },
        b = { 0, 2, 0, 0 },
        a = { 0, 2, 0, 0 }
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
        r = { 0, 2, 0, 0 },
        g = { 0, 2, 0, 0 },
        b = { 0, 2, 0, 0 },
        a = { 0, 2, 0, 0 }
      }

      lmi.layerInfo.count = lmi.layerInfo.count + #layer.layers + 1
    else
      local cel = layer:cel(frameNum)
      if cel then
        local image = cel.image
        -- image size:  8 * w * h / 8
        local imageSize = cel.bounds.width * cel.bounds.height
        local layerRecords = {
          top = cel.bounds.y,
          left = cel.bounds.x,
          bottom = cel.bounds.y + cel.bounds.height,
          right = cel.bounds.x + cel.bounds.width,
          channelCount = 4,
          channels = {
            {id = 0, size = imageSize + 2},
            {id = 1, size = imageSize + 2},
            {id = 2, size = imageSize + 2},
            {id = 0xFFFF, size = imageSize + 2}
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
        lmi.layerInfo.size = lmi.layerInfo.size + 58 + layerRecords.exFieldSize + (imageSize + 2) * 4
        lmi.layerInfo.records[#lmi.layerInfo.records + 1] = layerRecords

        local imageData = {
          compression ={
            r = 0,
            g = 0,
            b = 0,
            a = 0
          },
          r = {},
          g = {},
          b = {},
          a = {}
        }
        for y = 0, cel.bounds.height-1 do
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
            imageData.r[#imageData.r + 1] = color.r
            imageData.g[#imageData.g + 1] = color.g
            imageData.b[#imageData.b + 1] = color.b
            imageData.a[#imageData.a + 1] = color.a
          end
        end
        lmi.layerInfo.imageData[#lmi.layerInfo.imageData + 1] = imageData
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
          r = { 0, 2, 0, 0 },
          g = { 0, 2, 0, 0 },
          b = { 0, 2, 0, 0 },
          a = { 0, 2, 0, 0 }
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

for i, data in ipairs(lmi.layerInfo.imageData) do
  write(file, 2, data.compression.r)
  for i, r in ipairs(data.r) do
    write(file, 1, r)
  end

  write(file, 2, data.compression.g)
  for i, g in ipairs(data.g) do
    write(file, 1, g)
  end

  write(file, 2, data.compression.b)
  for i, b in ipairs(data.b) do
    write(file, 1, b)
  end

  write(file, 2, data.compression.a)
  for i, a in ipairs(data.a) do
    write(file, 1, a)
  end
end

--image data section
for i, data in ipairs(lmi.layerInfo.imageData) do
  write(file, 2, data.compression.r)
  for i, r in ipairs(data.r) do
    write(file, 1, r)
  end

  write(file, 2, data.compression.g)
  for i, g in ipairs(data.g) do
    write(file, 1, g)
  end

  write(file, 2, data.compression.b)
  for i, b in ipairs(data.b) do
    write(file, 1, b)
  end

  write(file, 2, data.compression.a)
  for i, a in ipairs(data.a) do
    write(file, 1, a)
  end
end

file:close()

app.alert("PSD file saved as " .. filename)
