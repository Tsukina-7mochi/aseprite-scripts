-- export sprite as psd file
------------------------------------------------------------

ScriptInfo = {
    version = Version("1.3.0-alpha"),
    remote = "https://github.com/Tsukina-7mochi/aseprite-scripts/tree/master/psd"
}

--- Return whether given number is an integer
---@param val any
---@return boolean
function IsInteger(val)
    if type(val)~="number" then
        return false
    end

    return val % 1 .. "" == "0"
end

--- Compress binary data with PackBits
---@param data string
---@return string
function PackBits(data)
    if #data == 0 then
        return data
    end

    local result = ""
    -- buffer stack
    local stack = ""

    -- -1: undetermined
    --  0: continuous value
    --  1: discontinuous value
    local state = -1
    local index = 1
    while index <= #data do
        local currentData = data:sub(index, index)
        local stackTop = stack:sub(1, 1)

        if state == -1 then
            if #stack ~= 0 then
                -- descide state
                if stackTop == currentData then
                    state = 0
                else
                    state = 1
                end
            end

            stack = currentData .. stack
        elseif state == 0 then
            if stackTop == currentData then
                -- just push value
                stack = currentData .. stack
            else
                -- write out buffer contents and reset state
                result = result .. ('B'):pack(256 - (#stack - 1)) .. stackTop
                stack = currentData
                state = -1
            end
        elseif state == 1 then
            if stackTop ~= currentData then
                -- just push value
                stack = currentData .. stack
            else
                -- write out buffer contents and change state
                result = result .. ('B'):pack(#stack - 2) .. stack:sub(2, -1):reverse()
                stack = currentData .. currentData
                state = 0
            end
        end

        if #stack > 0x7F then
            -- write out buffer contents
            if state == 0 then
                result = result .. ('B'):pack(256 - (#stack - 1)) .. stackTop
            elseif state == 1 or state == -1 then
                result = result .. ('B'):pack(#stack - 1) .. stack:reverse()
            end

            -- reset state
            state = -1
            stack = ""
        end

        index = index + 1
    end

    if #stack > 0 then
        -- write out buffer contents
        if state == 0 then
            result = result .. ('B'):pack(256 - (#stack - 1)) .. stack:sub(1, 1)
        elseif state == 1 or state == -1 then
            result = result .. ('B'):pack(#stack - 1) .. stack:reverse()
        end
    end
    -- print(result:byte(1, -1))

    return result
end

Util = {}

-- shows alert with failure message
function Util.failAlert(text)
  app.alert{
    title = "Export Failed",
    text = text,
    buttons = "OK"
  }
end

--------------------------------------------------
-- ENTRY
--------------------------------------------------
if app.apiVersion < 1 then
  Util.failAlert("This script requires Aseprite v1.2.10-beta3 or above.")
  return
end

local sprite = app.activeSprite
if not sprite then
  Util.failAlert("No sprite selected.")
  return
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

-- show dialog to select output file
local filename = app.fs.filePathAndTitle(sprite.filename) .. ".psd"
local frameAllString = "All frames as group"
local frameList = { frameAllString }
for i = 1, #sprite.frames do
  table.insert(frameList, "" .. i)
end
local showCompleated = false

local dialog = Dialog()
dialog:file{
  id = "filename",
  label = "Filename",
  title = "Save as...",
  save = true,
  filename = filename,
  filetypes = { "psd" },
}:combobox{
  id = "frameNum",
  label = "Frame",
  option = frameList[1],
  options = frameList
}:check{
  id = "showCompleated",
  label = "",
  text = "Show dialog when succeeded",
  selected = true
}:button{
  id = "ok",
  text = "&Export",
  focus = true
}:button{
  id = "cancel",
  text="&Cancel"
}
dialog:show()

if not dialog.data.ok then return end

filename = dialog.data.filename             --[[@as string]]
---@type string | number
local frameNum = dialog.data.frameNum       --[[@as string]]
if frameNum ~= frameAllString then
    frameNum = tonumber(frameNum)           --[[@as number]]
end
showCompleated = dialog.data.showCompleated --[[@as boolean]]

if not IsInteger(frameNum) then
  Util.failAlert("The frame number " .. frameNum .. " is not valid.")
  return
end
if frameNum ~= frameAllString and (frameNum < 1 or #sprite.frames < frameNum) then
  Util.failAlert("The frame number " .. frameNum .. " is out of range.")
  return
end

local file = io.open(filename, "wb")
if not file then
  Util.failAlert("Failed to open the file to export.")
  return
end

function PackU32BE(data)
    return (">4"):pack(data)
end

function PackU16BE(data)
    return (">2"):pack(data)
end

function PackU8(data)
    return ("B"):pack(data)
end

function ToPascalString(str, padBase, maxLength)
    local str_ = ""
    if type(maxLength) == "number" then
        str_ = str:sub(1, maxLength - 1)
    else
        str_ = str
    end
    return PackU8(#str_) .. str_ .. PackU8(0):rep(padBase - 1 - #str_ % padBase)
end

-- ==============================
-- File Header Section
-- ==============================
local fileHeaderData = table.concat({
    -- signature
    "8BPS",
    -- version = 1
    PackU16BE(1),
    -- resevered = 0
    (">6"):pack(0),
    -- channels = 4 (RGBA)
    PackU16BE(4),
    -- height
    PackU32BE(sprite.height),
    -- width
    PackU32BE(sprite.width),
    -- depth = 8
    PackU16BE(8),
    -- color mode = 3 (RGB)
    PackU16BE(3),
})
file:write(fileHeaderData)

-- ==============================
-- Color Mode Data Section
-- ==============================
local colorModeData = table.concat({
    -- size = 0
    PackU32BE(0)
})
file:write(colorModeData)

-- ==============================
-- Image Resources Section
-- ==============================
local imageResourcesData = table.concat({
    -- size = 0
    PackU32BE(0)
})
file:write(imageResourcesData)

-- ==============================
-- Layer and Mask Information Section
-- ==============================

local layerAndMaskDataBuffer = {
    -- size TBD
    "",
    -- layer info: size TBD
    "",
    -- layer info: layer count: TBD (due to the groups),
    "",
}
local lmSizeIndex = 0
local lmLiSizeIndex = 1
local lmLiLayerCountIndex = 2
local layerCount = 0

-- layer info -> laye records
---@param layerGroup Layer[]
---@param frameNum integer
---@return string layerRecord
---@return string imageData
---@return integer layerCount
local function createLayerRecordAndImageData(layerGroup, frameNum)
    ---@param image Image
    ---@return string
    local function createImageData(image)
        ---@param pixelValue any
        ---@return integer red
        ---@return integer green
        ---@return integer blue
        ---@return integer alpha
        local function getRGBColor(pixelValue)
            if image.colorMode == ColorMode.RGB then
                return app.pixelColor.rgbaR(pixelValue),
                    app.pixelColor.rgbaG(pixelValue),
                    app.pixelColor.rgbaB(pixelValue),
                    app.pixelColor.rgbaA(pixelValue)
            elseif image.colorMode == ColorMode.GRAY then
                return app.pixelColor.grayaV(pixelValue),
                    app.pixelColor.grayaV(pixelValue),
                    app.pixelColor.grayaV(pixelValue),
                    app.pixelColor.grayaA(pixelValue)
            elseif image.colorMode == ColorMode.INDEXED then
                local color = sprite.palettes[1]:getColor(pixelValue)
                return color.red, color.green, color.blue, color.alpha * (pixelValue == 0)
            end
        end

        local buffer = { r = {}, g = {}, b = {}, a = {} }
        for y = 0, image.width do
            local rowBuffer = { r = {}, g = {}, b = {}, a = {} }
            for x = 0, image.height do
                local r, g, b, a = getRGBColor(image:getPixel(x, y))
                rowBuffer.r[#rowBuffer.r + 1] = PackU8(r)
                rowBuffer.g[#rowBuffer.g + 1] = PackU8(g)
                rowBuffer.b[#rowBuffer.b + 1] = PackU8(b)
                rowBuffer.a[#rowBuffer.a + 1] = PackU8(a)
            end
            buffer.r[#buffer.r + 1] = PackBits(table.concat(rowBuffer.r))
            buffer.g[#buffer.r + 1] = PackBits(table.concat(rowBuffer.g))
            buffer.b[#buffer.r + 1] = PackBits(table.concat(rowBuffer.b))
            buffer.a[#buffer.r + 1] = PackBits(table.concat(rowBuffer.a))
        end

        return table.concat({
            -- compression = 1 (RLE)
            (">2>2>2>2"):pack(1, 1, 1, 1),
            -- size
            (">2>2>2>2"):pack(
                #buffer.r + 2 * image.height + 2,
                #buffer.g + 2 * image.height + 2,
                #buffer.b + 2 * image.height + 2,
                #buffer.a + 2 * image.height + 2
            ),
            -- data
            table.concat(buffer)
        })
    end

    local layerCount = 0
    local dataBuffer = {}
    for _, layer in ipairs(layerGroup) do
        local flags = 0
        if layer.isVisible then
            flags = flags | 2
        end

        if not layer.isGroup then
            -- a normal layer
            local cel = layer:cel(frameNum)
            if not cel then
                -- an empty layer
                local buffer = {
                    -- top
                    PackU32BE(0),
                    -- left
                    PackU32BE(0),
                    -- botom
                    PackU32BE(1),
                    -- right
                    PackU32BE(1),
                    -- channel count
                    PackU16BE(4),
                    -- channel information (id, size) x4
                    (">2>4"):pack(0, 6),
                    (">2>4"):pack(1, 6),
                    (">2>4"):pack(2, 6),
                    (">2>4"):pack(0xFFFF, 6),
                    -- blend mode signature
                    "8BIM",
                    -- blend mode
                    "norm",
                    -- opacity
                    PackU8(255),
                    -- clipping
                    PackU8(0),
                    -- flags
                    PackU8(flags),
                    -- filler
                    PackU8(0),
                    -- extra data field size: TBD
                    "",
                    -- layer mask: size = 0
                    PackU32BE(0),
                    -- blending ranges data: size = 0
                    PackU32BE(0),
                    -- layer name
                    ToPascalString(layer.name, 128)
                }

                -- set extra data field size
                buffer[16] = PackU32BE(4 + 4 + #buffer[19])

                dataBuffer[#dataBuffer + 1] = table.concat(buffer)
            else
                -- a layer with content
                local buffer = {
                    -- top
                    PackU32BE(cel.bounds.y),
                    -- left
                    PackU32BE(cel.bounds.x),
                    -- botom
                    PackU32BE(cel.bounds.y + cel.bounds.height),
                    -- right
                    PackU32BE(cel.bounds.x + cel.bounds.width),
                    -- channel count
                    PackU16BE(4),
                    -- channel information (id, size) x4
                    (">2>4"):pack(0, 6),
                    (">2>4"):pack(1, 6),
                    (">2>4"):pack(2, 6),
                    (">2>4"):pack(0xFFFF, 6),
                    -- blend mode signature
                    "8BIM",
                    -- blend mode
                    "norm",
                    -- opacity
                    PackU8(255),
                    -- clipping
                    PackU8(0),
                    -- flags
                    PackU8(flags),
                    -- filler
                    PackU8(0),
                    -- extra data field size: TBD
                    "",
                    -- layer mask: size = 0
                    PackU32BE(0),
                    -- blending ranges data: size = 0
                    PackU32BE(0),
                    -- layer name
                    ToPascalString(layer.name, 128)
                }

                -- set extra data field size
                buffer[16] = PackU32BE(4 + 4 + #buffer[19])

                dataBuffer[#dataBuffer + 1] = table.concat(buffer)
            end
        else
            -- a group
        end
    end
end

createLayerRecordAndImageData(sprite.layers, 1)

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
            if image.colorModeData == ColorMode.RGB then
              color.r = app.pixelColor.rgbaR(pixel)
              color.g = app.pixelColor.rgbaG(pixel)
              color.b = app.pixelColor.rgbaB(pixel)
              color.a = app.pixelColor.rgbaA(pixel)
            elseif image.colorModeData == ColorMode.GRAY then
              color.r = app.pixelColor.grayaV(pixel)
              color.g = app.pixelColor.grayaV(pixel)
              color.b = app.pixelColor.grayaV(pixel)
              color.a = app.pixelColor.grayaA(pixel)
            elseif image.colorModeData == ColorMode.INDEXED then
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
      if fimage.colorModeData == ColorMode.RGB then
        color.r = app.pixelColor.rgbaR(pixel)
        color.g = app.pixelColor.rgbaG(pixel)
        color.b = app.pixelColor.rgbaB(pixel)
        color.a = app.pixelColor.rgbaA(pixel)
      elseif fimage.colorModeData == ColorMode.GRAY then
        color.r = app.pixelColor.grayaV(pixel)
        color.g = app.pixelColor.grayaV(pixel)
        color.b = app.pixelColor.grayaV(pixel)
        color.a = app.pixelColor.grayaA(pixel)
      elseif fimage.colorModeData == ColorMode.INDEXED then
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

-- Layer and Mask Information
write(file, 4, lm.size)
write(file, 4, lm.layer.size)
write(file, 2, lm.layer.count)
for i, record in ipairs(lm.layer.records) do

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

if showCompleated then
  local result = app.alert{
    title = "Export Succeeded",
    text = "PSD successfully exported as " .. filename,
    buttons = "OK"
  }
end