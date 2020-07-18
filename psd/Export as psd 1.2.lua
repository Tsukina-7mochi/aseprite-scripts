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

-- write string (for multi-byte character)
function writeStr(file, str)
  if not file then return end
  if not str then return end

  for i = 1, #str do
    file:write(string.format("%c", str:byte(i)))
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

--local dialog =
--  Dialog():entry { id="filename", label="Filename: ", text=filename }
--          :number{ id="frameNum", label="Frame number: ", text=string.format("%d", frameNum)}
--          :button{ id="ok", text="&OK", focus=true }
--          :button{ id="cancel", text="&Cancel" }
--dialog:show()

--if not dialog.data.ok then return end
--filename = dialog.data.filename
--frameNum = dialog.data.frameNum
--if not filename then return end

if not isInteger(frameNum) then
  app.alert("Frame number is not valid.")
  return
end
if frameNum < 1 or #sprite.frames < frameNum then
  app.alert("The frame number " .. frameNum .. " is out of range.")
  return
end

file = io.open(filename, "wb")
if not file then
  app.alert("Failed to open the file to export.")
  return
end

-- File Header
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
-- Color Mode Data
local cm = {
  size = 0;
}
-- Image Resources
local ir = {
  size = 0
}
-- Layer and Mask Information
local lm = {
  size = 0,
  layer = {
    size = 2,   -- size of layer count
    count = 0,
    records = {},
    image = {}
  },
  mask = {},
  addition = {}
}
-- Image data
local id = {
  compression = 1,
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

-- called recursively to explore layer tree
function setLayerInfo(group)
  for i, layer in ipairs(group) do
    local layerName = layer.name:sub(1 ,127)
    if layer.isGroup then
      -- close folder
      local lr = {
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
        name = {
          length = 0,
          name = "",
          padding = 3
        },
        adjustment = {
          {
            signature = "8BIM",
            key = "lsct",
            size = 4,
            data = 3
          }
        }
      }

      -- mask: 4 + blendingRange: 4 + name: 4 + adjustment: (4 + 4 + 4 + 4)
      lr.exFieldSize = 28
      -- bound: 4x4 + channelCount:2 + channels: 4*6 + blendSig: 4 + blendMode: 4 +
      --   opacity: 1 + clipping: 1 + flags: 1 + filler: 1 + exFieldSize: 4 + [exFieldSize]
      --   imageData: 24
      lm.layer.size = lm.layer.size + 58 + lr.exFieldSize + 24
      lm.layer.count = lm.layer.count + 1
      table.insert(lm.layer.records, lr)
      table.insert(lm.layer.image, {
        r = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
        g = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
        b = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
        a = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
      })

      -- explore group
      setLayerInfo(layer.layers)

      -- open folder
      local lr2 = {
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
        name = {
          length = #layerName,
          name = layerName,
          padding = 3 - #layerName % 4 -- (4 - (nameLength + 1 + 16)% 4)% 4
        },
        adjustment = {
          {
            signature = "8BIM",
            key = "lsct",
            size = 4,
            data = 1
          }
        }
      }

      if not layer.isExpanded then
        -- open group
        lr2.adjustment[1].data = 2
      end
      if not layer.isVisible then
        -- visualize
        lr2.flags = lr2.flags | 2
      end
      -- mask: 4 + blendingRange: 4 + name: (1 + [length] + [padding]) + adjustment: (4 + 4 + 4 + 4)
      lr2.exFieldSize = 25 + lr2.name.length + lr2.name.padding
      -- bound: 4x4 + channelCount:2 + channels: 4*6 + blendSig: 4 + blendMode: 4 +
      --   opacity: 1 + clipping: 1 + flags: 1 + filler: 1 + exFieldSize: 4 + [exFieldSize]
      --   imageData: 24
      lm.layer.size = lm.layer.size + 58 + lr2.exFieldSize + 24
      lm.layer.count = lm.layer.count + 1
      table.insert(lm.layer.records, lr2)
      table.insert(lm.layer.image, {
        r = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
        g = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
        b = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
        a = {
          compression = 1,
          size = { 2 },
          data = {{ 0, 0 }}
        },
      })
    else
      local cel = layer:cel(frameNum)
      if cel then
        -- not a empty layer
        local image = cel.image
        -- create image datas
        local imageData = {
          r = {
            compression = 1,
            size = {},
            data = {}
          },
          g = {
            compression = 1,
            size = {},
            data = {}
          },
          b = {
            compression = 1,
            size = {},
            data = {}
          },
          a = {
            compression = 1,
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
            local color = { r = 0, g = 0, b = 0, a = 0 }
            local pixel = image:getPixel(x, y)
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
            table.insert(row.r, color.r)
            table.insert(row.g, color.g)
            table.insert(row.b, color.b)
            table.insert(row.a, color.a)
          end
          row.r = packBits(row.r)
          row.g = packBits(row.g)
          row.b = packBits(row.b)
          row.a = packBits(row.a)
          table.insert(imageData.r.data, row.r)
          table.insert(imageData.g.data, row.g)
          table.insert(imageData.b.data, row.b)
          table.insert(imageData.a.data, row.a)
          table.insert(imageData.r.size, #row.r)
          table.insert(imageData.g.size, #row.g)
          table.insert(imageData.b.size, #row.b)
          table.insert(imageData.a.size, #row.a)
        end

        local imageSize = {
          r = sum(imageData.r.size) + #imageData.r.size * 2 + 2,
          g = sum(imageData.g.size) + #imageData.g.size * 2 + 2,
          b = sum(imageData.b.size) + #imageData.b.size * 2 + 2,
          a = sum(imageData.a.size) + #imageData.a.size * 2 + 2
        }

        local lr = {
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
          name = {
            length = #layerName,
            name = layerName,
            padding = 3 - #layerName % 4
          },
          adjustment = {
          }
        }

        print("size r: " .. lr.channels[1].size)
        print("size g: " .. lr.channels[2].size)
        print("size b: " .. lr.channels[3].size)
        print("size a: " .. lr.channels[4].size)

        if not layer.isVisible then
          -- visualize
          lr.flags = lr.flags | 2
        end
        -- mask: 4 + blendingRange: 4 + name: (1 + [length] + [padding]) + adjustment: 0
        lr.exFieldSize = 9 + lr.name.length + lr.name.padding
        -- bound: 4x4 + channelCount:2 + channels: 4*6 + blendSig: 4 + blendMode: 4 +
        --   opacity: 1 + clipping: 1 + flags: 1 + filler: 1 + exFieldSize: 4 + [exFieldSize]
        --   imageData: ([channels[1].size] + [channels[2].size] + ... +[channels[4].size])
        lm.layer.size = lm.layer.size + 58 + lr.exFieldSize + lr.channels[1].size + lr.channels[2].size + lr.channels[3].size + lr.channels[4].size
        lm.layer.count = lm.layer.count + 1
        table.insert(lm.layer.records, lr)
        table.insert(lm.layer.image, imageData)
      else
        -- insert empty layer
        local lr = {
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
          name = {
            length = #layerName,
            name = layerName,
            padding = 3 - #layerName % 4
          },
          adjustment = {
          }
        }

        if not layer.isVisible then
          -- visualize
          lr.flags = lr.flags | 2
        end
        -- mask: 4 + blendingRange: 4 + name: (1 + [length] + [padding]) + adjustment: 0
        lr.exFieldSize = 9 + lr.name.length + lr.name.padding
        -- bound: 4x4 + channelCount:2 + channels: 4*6 + blendSig: 4 + blendMode: 4 +
        --   opacity: 1 + clipping: 1 + flags: 1 + filler: 1 + exFieldSize: 4 + [exFieldSize] +
        --   imageData: 24
        lm.layer.size = lm.layer.size + 58 + lr.exFieldSize + 24
        lm.layer.count = lm.layer.count + 1
        table.insert(lm.layer.records, lr)
        table.insert(lm.layer.image, {
          r = {
            compression = 1,
            size = { 2 },
            data = {{ 0, 0 }}
          },
          g = {
            compression = 1,
            size = { 2 },
            data = {{ 0, 0 }}
          },
          b = {
            compression = 1,
            size = { 2 },
            data = {{ 0, 0 }}
          },
          a = {
            compression = 1,
            size = { 2 },
            data = {{ 0, 0 }}
          },
        })
      end
    end
  end
end
setLayerInfo(sprite.layers)

-- [layer info size] + mask:4 + addition: 0
lm.size = lm.layer.size + 4


-- image data
local fsprite = Sprite(sprite)
local fcel = sprite.cels[1]
local fimage = fcel.image
fsprite:flatten()
for y = 0, fsprite.height-1 do
  local row = {
    r = {},
    g = {},
    b = {},
    a = {}
  }
  for x = 0, fsprite.width-1 do
    local color = { r = 0, g = 0, b = 0, a = 0 }
    if fcel.bounds.x <= x and x < fcel.bounds.x + fcel.bounds.width and fcel.bounds.y <= y and y < fcel.bounds.y + fcel.bounds.height then
      local pixel = fimage:getPixel(x - fcel.bounds.x, y - fcel.bounds.y)
      if fimage.colorMode == ColorMode.RGB then
        color.r = app.pixelColor.rgbaR(pixel)
        color.g = app.pixelColor.rgbaG(pixel)
        color.b = app.pixelColor.rgbaB(pixel)
        color.a = app.pixelColor.rgbaA(pixel)
      elseif fimage.colorMode == ColorMode.GRAY then
        color.r = app.pixelColor.grayaV(pixel)
        color.g = app.pixelColor.grayaV(pixel)
        color.b = app.pixelColor.grayaV(pixel)
        color.a = app.pixelColor.grayaA(pixel)
      elseif fimage.colorMode == ColorMode.INDEXED then
        local c = fsprite.palettes[1]:getColor(pixel)
        color.r = c.red
        color.g = c.green
        color.b = c.blue
        if pixel == 0 then color.a = 0 else color.a = c.alpha end
      end
    end
    table.insert(row.r, color.r)
    table.insert(row.g, color.g)
    table.insert(row.b, color.b)
    table.insert(row.a, color.a)
  end
  row.r = packBits(row.r)
  row.g = packBits(row.g)
  row.b = packBits(row.b)
  row.a = packBits(row.a)
  table.insert(id.r.data, row.r)
  table.insert(id.g.data, row.g)
  table.insert(id.b.data, row.b)
  table.insert(id.a.data, row.a)
  table.insert(id.r.size, #row.r)
  table.insert(id.g.size, #row.g)
  table.insert(id.b.size, #row.b)
  table.insert(id.a.size, #row.a)
end
fsprite:close()



-- export to file
print("0")
-- File Header
file:write(fh.signature)
write(file, 2, fh.version)
write(file, 6, fh.reserved)
write(file, 2, fh.channels)
write(file, 4, fh.height)
write(file, 4, fh.width)
write(file, 2, fh.depth)
write(file, 2, fh.colorMode)

-- Color Mode Data
write(file, 4, cm.size)

-- Image Resources
write(file, 4, ir.size)

print("1")
-- Layer and Mask Information
write(file, 4, lm.size)
write(file, 4, lm.layer.size)
write(file, 2, lm.layer.count)
print("2")
for i, record in ipairs(lm.layer.records) do
  print("3." .. i)
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
  write(file, 1, record.name.length)
  writeStr(file, record.name.name)
  write(file, record.name.padding, 0)
  for i, d in ipairs(record.adjustment) do
    file:write(d.signature)
    file:write(d.key)
    write(file, 4, d.size)
    write(file, d.size, d.data)
  end
end
print("4")

function exportImageData(file, data)
  write(file, 2, data.compression)
  for i, s in ipairs(data.size) do
    write(file, 2, s)
  end
  for i, row in ipairs(data.data) do
    for i, d in ipairs(row) do
      write(file, 1, d)
    end
  end
end
for i, data in ipairs(lm.layer.image) do
  exportImageData(file, data.r)
  exportImageData(file, data.g)
  exportImageData(file, data.b)
  exportImageData(file, data.a)
end
print("5")

--image data section
write(file, 2, id.compression)
for i, s in ipairs(id.r.size) do
  write(file, 2, s)
end
for i, s in ipairs(id.g.size) do
  write(file, 2, s)
end
for i, s in ipairs(id.b.size) do
  write(file, 2, s)
end
for i, s in ipairs(id.a.size) do
  write(file, 2, s)
end
for i, row in ipairs(id.r.data) do
  for i, d in ipairs(row) do
    write(file, 1, d)
  end
end
for i, row in ipairs(id.g.data) do
  for i, d in ipairs(row) do
    write(file, 1, d)
  end
end
for i, row in ipairs(id.b.data) do
  for i, d in ipairs(row) do
    write(file, 1, d)
  end
end
for i, row in ipairs(id.a.data) do
  for i, d in ipairs(row) do
    write(file, 1, d)
  end
end

file:close()

print("succeeded")
--app.alert("PSD file saved as " .. filename)
