local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test

-- Set up mocks
local mock = require("pkg.asepriteUtil.mock")
_G.ColorMode = mock.ColorMode
_G.app = mock.app

local bitmap = require("pkg.bitmap").bitmap

describe("bitmap", function ()
    describe("bitmap constructor", function ()
        test("creates valid BMP file header", function ()
            local pixels = {
                mock.app.pixelColor.rgba(255, 0, 0), -- Red
            }
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap(image))

            -- Check BMP signature
            expect(bmp:sub(1, 2)):toBe("BM")

            -- File size: 54 (headers) + 4 (1 pixel * 3 bytes + 1 padding) = 58
            local fileSize = string.unpack("<I4", bmp:sub(3, 6))
            expect(fileSize):toBe(58)

            -- Data offset should be 54
            local dataOffset = string.unpack("<I4", bmp:sub(11, 14))
            expect(dataOffset):toBe(54)
        end)

        test("creates valid bitmap info header", function ()
            local pixels = { mock.app.pixelColor.rgba(0, 0, 0) }
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap(image))

            -- Info header starts at byte 15
            local headerSize = string.unpack("<I4", bmp:sub(15, 18))
            expect(headerSize):toBe(40)

            local width = string.unpack("<i4", bmp:sub(19, 22))
            expect(width):toBe(1)

            local height = string.unpack("<i4", bmp:sub(23, 26))
            expect(height):toBe(1)

            local planes = string.unpack("<I2", bmp:sub(27, 28))
            expect(planes):toBe(1)

            local bitsPerPixel = string.unpack("<I2", bmp:sub(29, 30))
            expect(bitsPerPixel):toBe(24)
        end)

        test("encodes pixels in BGR order", function ()
            -- Create a 1x1 image with red pixel (R=255, G=0, B=0)
            local pixels = {
                mock.app.pixelColor.rgba(255, 0, 0),
            }
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap(image))

            -- Pixel data starts at byte 55 (after 54-byte header)
            -- BGR order: B=0, G=0, R=255
            expect(bmp:sub(55, 55)):toBe("\x00") -- Blue
            expect(bmp:sub(56, 56)):toBe("\x00") -- Green
            expect(bmp:sub(57, 57)):toBe("\xFF") -- Red
        end)

        test("adds correct row padding for width=1", function ()
            local pixels = { mock.app.pixelColor.rgba(0, 0, 0) }
            local image = mock.createImage(1, 1, pixels)
            local bmp = tostring(bitmap(image))

            -- 1 pixel = 3 bytes, needs 1 byte padding to reach 4
            -- Pixel data: 3 bytes + 1 padding = 4 bytes total
            expect(#bmp):toBe(54 + 4)
            expect(bmp:sub(58, 58)):toBe("\x00") -- Padding byte
        end)

        test("adds correct row padding for width=2", function ()
            local pixels = {
                mock.app.pixelColor.rgba(0, 0, 0),
                mock.app.pixelColor.rgba(0, 0, 0),
            }
            local image = mock.createImage(2, 1, pixels)
            local bmp = tostring(bitmap(image))

            -- 2 pixels = 6 bytes, needs 2 bytes padding to reach 8
            expect(#bmp):toBe(54 + 8)
        end)

        test("adds no padding for width=4", function ()
            local pixels = {
                mock.app.pixelColor.rgba(0, 0, 0),
                mock.app.pixelColor.rgba(0, 0, 0),
                mock.app.pixelColor.rgba(0, 0, 0),
                mock.app.pixelColor.rgba(0, 0, 0),
            }
            local image = mock.createImage(4, 1, pixels)
            local bmp = tostring(bitmap(image))

            -- 4 pixels = 12 bytes, already aligned to 4, no padding needed
            expect(#bmp):toBe(54 + 12)
        end)

        test("stores rows bottom-to-top", function ()
            -- Create a 2x2 image:
            -- Top row (y=0):    Red(255,0,0)    Green(0,255,0)
            -- Bottom row (y=1): Blue(0,0,255)   White(255,255,255)
            local pixels = {
                mock.app.pixelColor.rgba(255, 0, 0), -- Top-left: Red
                mock.app.pixelColor.rgba(0, 255, 0), -- Top-right: Green
                mock.app.pixelColor.rgba(0, 0, 255), -- Bottom-left: Blue
                mock.app.pixelColor.rgba(255, 255, 255), -- Bottom-right: White
            }
            local image = mock.createImage(2, 2, pixels)
            local bmp = tostring(bitmap(image))

            -- Pixel data starts at byte 55
            -- First row in BMP should be bottom row (y=1): Blue, White
            -- Blue in BGR: B=255, G=0, R=0
            expect(bmp:sub(55, 55)):toBe("\xFF") -- Blue.B
            expect(bmp:sub(56, 56)):toBe("\x00") -- Blue.G
            expect(bmp:sub(57, 57)):toBe("\x00") -- Blue.R

            -- White in BGR: B=255, G=255, R=255
            expect(bmp:sub(58, 58)):toBe("\xFF") -- White.B
            expect(bmp:sub(59, 59)):toBe("\xFF") -- White.G
            expect(bmp:sub(60, 60)):toBe("\xFF") -- White.R

            -- 2 pixels = 6 bytes, need 2 bytes padding
            -- Second row in BMP should be top row (y=0): Red, Green
            -- Red in BGR: B=0, G=0, R=255
            expect(bmp:sub(63, 63)):toBe("\x00") -- Red.B
            expect(bmp:sub(64, 64)):toBe("\x00") -- Red.G
            expect(bmp:sub(65, 65)):toBe("\xFF") -- Red.R

            -- Green in BGR: B=0, G=255, R=0
            expect(bmp:sub(66, 66)):toBe("\x00") -- Green.B
            expect(bmp:sub(67, 67)):toBe("\xFF") -- Green.G
            expect(bmp:sub(68, 68)):toBe("\x00") -- Green.R
        end)

        test("handles 3x3 image correctly", function ()
            -- Create a simple 3x3 image with all black pixels
            local pixels = {}
            for i = 1, 9 do
                pixels[i] = mock.app.pixelColor.rgba(0, 0, 0)
            end
            local image = mock.createImage(3, 3, pixels)
            local bmp = tostring(bitmap(image))

            -- 3 pixels per row = 9 bytes, needs 3 bytes padding to reach 12
            -- Total pixel data = (9 + 3) * 3 rows = 36 bytes
            expect(#bmp):toBe(54 + 36)
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
                bitmap(image)
            end)

            expect(success):toBe(false)
            expect(err:find("RGB")):toBeTruthy()
        end)

        test("creates complete valid 2x2 BMP", function ()
            -- Create a simple 2x2 test pattern
            local pixels = {
                mock.app.pixelColor.rgba(255, 0, 0), -- Red
                mock.app.pixelColor.rgba(0, 255, 0), -- Green
                mock.app.pixelColor.rgba(0, 0, 255), -- Blue
                mock.app.pixelColor.rgba(255, 255, 0), -- Yellow
            }
            local image = mock.createImage(2, 2, pixels)
            local bmp = tostring(bitmap(image))

            -- Verify it's a complete BMP file
            expect(bmp:sub(1, 2)):toBe("BM")
            expect(#bmp):toBe(54 + 16) -- Header + (6 bytes pixels + 2 padding) * 2 rows
        end)

        test("tostring method works", function ()
            local pixels = { mock.app.pixelColor.rgba(0, 0, 0) }
            local image = mock.createImage(1, 1, pixels)
            local bmp = bitmap(image)

            -- Test explicit tostring method
            local str1 = bmp:tostring()
            expect(str1:sub(1, 2)):toBe("BM")

            -- Test implicit __tostring metamethod
            local str2 = tostring(bmp)
            expect(str2:sub(1, 2)):toBe("BM")

            -- Both should produce the same result
            expect(str1):toBe(str2)
        end)
    end)
end)
