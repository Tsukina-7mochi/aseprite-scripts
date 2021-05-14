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

-- shows alert with failure message
function failAlert(text)
  app.alert{
    title = "Export Failed",
    text = text,
    buttons = "OK"
  }
end



-- export file header
-- file: file
-- type: 1 if icon, 2 if cursor
-- count: number of image
function exportFileHeader(file, type, num)
  write(file, 2, 0)
  write(file, 2, type)
  write(file, 2, num)
end


------------------------------
-- ENTRY
------------------------------

if app.apiVersion < 1 then
  failAlert("This script requires Aseprite v1.2.10-beta3 or above.")
  return
end

local sprite = app.activeSprite
if not sprite then
  failAlert("No sprite selected.")
  return
end

local filename = app.fs.filePathAndTitle(sprite.filename) .. ".ico"
local file = io.open(filename, "wb")
if not file then
  failAlert("Failed to open the file to export.")
  return
end

exportFileHeader(file, 1, 1)

file:close()

app.alert(filename)