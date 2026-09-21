local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test

-- Set up mocks
local mock = require("pkg.asepriteUtil.mock")
_G.ColorMode = mock.ColorMode
_G.app = mock.app
_G.Image = mock.Image
_G.Size = mock.Size
_G.Rectangle = mock.Rectangle

local image = require("pkg.asepriteUtil.image")

---Creates an image whose pixel values are 1-based sequential indices
---@param width integer
---@param height integer
---@return table
local function sequentialImage (width, height)
    local pixelData = {}
    for i = 1, width * height do
        pixelData[i] = i
    end
    return mock.createImage(width, height, pixelData)
end

describe("image", function ()
    describe("scaleInto", function ()
        test("copies the source as-is when the bounds match the source size", function ()
            local source = sequentialImage(2, 2)
            local result = image.scaleInto(source, Size(2, 2), Rectangle(0, 0, 2, 2))

            expect(result.width):toBe(2)
            expect(result.height):toBe(2)
            for y = 0, 1 do
                for x = 0, 1 do
                    expect(result:getPixel(x, y)):toBe(source:getPixel(x, y))
                end
            end
        end)

        test("scales by an integer factor and leaves the padding transparent", function ()
            -- 2x2 source scaled 2x into a 3x3 image: 1px padding on the right and bottom
            local source = sequentialImage(2, 2)
            local result = image.scaleInto(source, Size(3, 3), Rectangle(0, 0, 4, 4))

            expect(result.width):toBe(3)
            expect(result.height):toBe(3)
            -- Top-left 2x2 block comes from the source pixel (0, 0)
            expect(result:getPixel(0, 0)):toBe(source:getPixel(0, 0))
            expect(result:getPixel(1, 0)):toBe(source:getPixel(0, 0))
            expect(result:getPixel(0, 1)):toBe(source:getPixel(0, 0))
            expect(result:getPixel(1, 1)):toBe(source:getPixel(0, 0))
            -- The third row/column is inside the bounds, so it is the source pixel (1, *)
            expect(result:getPixel(2, 0)):toBe(source:getPixel(1, 0))
            expect(result:getPixel(0, 2)):toBe(source:getPixel(0, 1))
            expect(result:getPixel(2, 2)):toBe(source:getPixel(1, 1))
        end)

        test("pads a non-square source to a square image", function ()
            -- 2x1 source drawn at the top-left of a 2x2 image
            local source = sequentialImage(2, 1)
            local result = image.scaleInto(source, Size(2, 2), Rectangle(0, 0, 2, 1))

            expect(result:getPixel(0, 0)):toBe(source:getPixel(0, 0))
            expect(result:getPixel(1, 0)):toBe(source:getPixel(1, 0))
            -- Bottom row is padding
            expect(result:getPixel(0, 1)):toBe(0)
            expect(result:getPixel(1, 1)):toBe(0)
        end)

        test("draws at the given bounds origin", function ()
            local source = sequentialImage(1, 1)
            local result = image.scaleInto(source, Size(2, 2), Rectangle(1, 1, 1, 1))

            expect(result:getPixel(0, 0)):toBe(0)
            expect(result:getPixel(1, 1)):toBe(source:getPixel(0, 0))
        end)
    end)
end)
