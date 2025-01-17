local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local assertType = require("pkg.type.isType")

local isInteger = assertType.isInteger

describe("isType", function()
    describe("isInteger", function()
        test("0", function()
            expect(isInteger(0)):toEqual(true)
        end)

        test("-1", function()
            expect(isInteger(-1)):toEqual(true)
        end)

        test("0.1", function()
            expect(isInteger(0.1)):toEqual(false)
        end)

        test("0.0", function()
            expect(isInteger(0.0)):toEqual(false)
        end)

        test("string", function()
            expect(isInteger("a")):toEqual(false)
        end)

        test("boolean", function()
            expect(isInteger(true)):toEqual(false)
        end)

        test("nil", function()
            expect(isInteger(nil)):toEqual(false)
        end)

        test("function", function()
            expect(isInteger(function() end)):toEqual(false)
        end)
    end)
end)
