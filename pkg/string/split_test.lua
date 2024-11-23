local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local split = require("pkg.string.split").split

describe("split", function()
    test("split by comma", function()
        expect(split("a,b,c", ",")):toEqual({ "a", "b", "c" })
    end)

    test("split by dot and comma", function()
        expect(split("a.b,c", ".,")):toEqual({ "a", "b", "c" })
    end)

    test("split by space", function()
        expect(split("a b\nc\td", "%s")):toEqual({ "a", "b", "c", "d" })
    end)
end)
