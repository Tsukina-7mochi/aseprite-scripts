local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test

-- Set up mocks
local mock = require("pkg.asepriteUtil.mock")
_G.ColorMode = mock.ColorMode
_G.app = mock.app

local bitmap = require("pkg.bitmap")

describe("bitmap", function ()
    describe("create", function ()
        test("creates valid BMP file header", function ()
            -- 1x1 red pixel
            local pixels = { 0x000000FF } -- RGBA: red=255, green=0, blue=0, alpha=0
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap.create(image))

            -- Check BMP signature
            expect(bmp:sub(1, 2)):toBe("BM")

            -- File size: 54 (headers) + 4 (1 pixel * 3 bytes + 1 padding) = 58
            expect(bmp:sub(3, 6)):toBe("\x3A\x00\x00\x00")

            -- Reserved
            expect(bmp:sub(7, 10)):toBe("\x00\x00\x00\x00")

            -- Data offset should be 54
            expect(bmp:sub(11, 14)):toBe("\x36\x00\x00\x00")
        end)

        test("creates valid bitmap info header", function ()
            local pixels = { 0x00000000 } -- Black pixel
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap.create(image))

            -- Info header starts at byte 15
            -- Header size = 40
            expect(bmp:sub(15, 18)):toBe("\x28\x00\x00\x00")

            -- Width = 1
            expect(bmp:sub(19, 22)):toBe("\x01\x00\x00\x00")

            -- Height = 1
            expect(bmp:sub(23, 26)):toBe("\x01\x00\x00\x00")

            -- Planes = 1
            expect(bmp:sub(27, 28)):toBe("\x01\x00")

            -- Bits per pixel = 24
            expect(bmp:sub(29, 30)):toBe("\x18\x00")
        end)

        test("encodes pixels in BGR order", function ()
            -- Create a 1x1 image with red pixel (R=255, G=0, B=0)
            local pixels = { 0x000000FF }
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap.create(image))

            -- Pixel data starts at byte 55 (after 54-byte header)
            -- BGR order: B=0, G=0, R=255
            expect(bmp:sub(55, 57)):toBe("\x00\x00\xFF")
        end)

        test("adds correct row padding for width=1", function ()
            local pixels = { 0x00000000 }
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap.create(image))

            -- 1 pixel = 3 bytes, needs 1 byte padding to reach 4
            -- Pixel data: 3 bytes + 1 padding = 4 bytes total
            expect(#bmp):toBe(58)
            expect(bmp:sub(58, 58)):toBe("\x00") -- Padding byte
        end)

        test("adds correct row padding for width=2", function ()
            local pixels = { 0x00000000, 0x00000000 }
            local image = mock.createImage(2, 1, pixels)
            local bmp = tostring(bitmap.create(image))

            -- 2 pixels = 6 bytes, needs 2 bytes padding to reach 8
            expect(#bmp):toBe(62) -- 54 + 8
        end)

        test("adds no padding for width=4", function ()
            local pixels = {
                0x00000000,
                0x00000000,
                0x00000000,
                0x00000000,
            }
            local image = mock.createImage(4, 1, pixels)
            local bmp = tostring(bitmap.create(image))

            -- 4 pixels = 12 bytes, already aligned to 4, no padding needed
            expect(#bmp):toBe(66) -- 54 + 12
        end)

        test("stores rows bottom-to-top", function ()
            -- Create a 2x2 image:
            -- Top row (y=0):    Red(255,0,0)    Green(0,255,0)
            -- Bottom row (y=1): Blue(0,0,255)   White(255,255,255)
            local pixels = {
                0x000000FF, -- Top-left: Red
                0x0000FF00, -- Top-right: Green
                0x00FF0000, -- Bottom-left: Blue
                0x00FFFFFF, -- Bottom-right: White
            }
            local image = mock.createImage(2, 2, pixels)
            local bmp = tostring(bitmap.create(image))

            -- Pixel data starts at byte 55
            -- First row in BMP should be bottom row (y=1): Blue, White
            -- Blue in BGR: B=255, G=0, R=0
            expect(bmp:sub(55, 57)):toBe("\xFF\x00\x00")

            -- White in BGR: B=255, G=255, R=255
            expect(bmp:sub(58, 60)):toBe("\xFF\xFF\xFF")

            -- 2 pixels = 6 bytes, need 2 bytes padding
            expect(bmp:sub(61, 62)):toBe("\x00\x00")

            -- Second row in BMP should be top row (y=0): Red, Green
            -- Red in BGR: B=0, G=0, R=255
            expect(bmp:sub(63, 65)):toBe("\x00\x00\xFF")

            -- Green in BGR: B=0, G=255, R=0
            expect(bmp:sub(66, 68)):toBe("\x00\xFF\x00")
        end)

        test("handles 3x3 image correctly", function ()
            -- Create a simple 3x3 image with all black pixels
            local pixels = {}
            for i = 1, 9 do
                pixels[i] = 0x00000000
            end
            local image = mock.createImage(3, 3, pixels)
            local bmp = tostring(bitmap.create(image))

            -- 3 pixels per row = 9 bytes, needs 3 bytes padding to reach 12
            -- Total pixel data = (9 + 3) * 3 rows = 36 bytes
            expect(#bmp):toBe(90) -- 54 + 36
        end)

        test("throws error for non-RGB image", function ()
            local image = {
                width = 1,
                height = 1,
                colorMode = mock.ColorMode.GRAY,
                getPixel = function ()
                    return 0
                end,
            }

            local success, err = pcall(function ()
                bitmap.create(image)
            end)

            expect(success):toBe(false)
            expect(err:find("RGB")):toBeTruthy()
        end)

        test("creates complete valid 2x2 BMP", function ()
            -- Create a simple 2x2 test pattern
            local pixels = {
                0x000000FF, -- Red
                0x0000FF00, -- Green
                0x00FF0000, -- Blue
                0x0000FFFF, -- Yellow
            }
            local image = mock.createImage(2, 2, pixels)
            local bmp = tostring(bitmap.create(image))

            -- Verify it's a complete BMP file
            expect(bmp:sub(1, 2)):toBe("BM")
            expect(#bmp):toBe(70) -- 54 + (6 bytes pixels + 2 padding) * 2 rows
        end)

        test("BitmapFile has correct structure", function ()
            local pixels = { 0x00000000 }
            local image = mock.createImage(1, 1, pixels)
            local bmpFile = bitmap.create(image)

            -- Check that BitmapFile has the expected fields
            expect(type(bmpFile.fileHeader)):toBe("string")
            expect(type(bmpFile.bitmapInfoHeader)):toBe("string")
            expect(type(bmpFile.pixelData)):toBe("string")

            -- File header should be 14 bytes
            expect(#bmpFile.fileHeader):toBe(14)

            -- Bitmap info header should be 40 bytes
            expect(#bmpFile.bitmapInfoHeader):toBe(40)

            -- Pixel data should be 4 bytes (3 + 1 padding)
            expect(#bmpFile.pixelData):toBe(4)
        end)

        test("tostring method works", function ()
            local pixels = { 0x00000000 }
            local image = mock.createImage(1, 1, pixels)
            local bmpFile = bitmap.create(image)

            -- Test explicit tostring method
            local str1 = bmpFile:tostring()
            expect(str1:sub(1, 2)):toBe("BM")

            -- Test implicit __tostring metamethod
            local str2 = tostring(bmpFile)
            expect(str2:sub(1, 2)):toBe("BM")

            -- Both should produce the same result
            expect(str1):toBe(str2)
        end)
    end)
end)
