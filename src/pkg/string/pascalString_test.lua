local test = require("lib.test").test
local describe = require("lib.test").describe
local expect = require("lib.test").expect
local toPascalString = require("pkg.string.pascalString")

describe("pascalString", function()
    describe("no align", function()
        test("empty", function()
            expect(toPascalString("")):toBe("\x00")
        end)

        test("non-empty", function()
            expect(toPascalString("abc")):toBe("\x03abc")
        end)
    end)

    describe("2-align", function()
        test("empty", function()
            expect(toPascalString("", 2)):toBe("\x00\x00")
        end)

        test("odd length", function()
            expect(toPascalString("abc", 2)):toBe("\x03abc")
        end)

        test("even length", function()
            expect(toPascalString("abcd", 2)):toBe("\x04abcd\x00")
        end)
    end)

    describe("4-align", function()
        test("empty", function()
            expect(toPascalString("", 4)):toBe("\x00\x00\x00\x00")
        end)

        test("length mod 4 = 1", function()
            expect(toPascalString("a", 4)):toBe("\x01a\x00\x00")
        end)

        test("length mod 4 = 2", function()
            expect(toPascalString("ab", 4)):toBe("\x02ab\x00")
        end)

        test("length mod 4 = 3", function()
            expect(toPascalString("abc", 4)):toBe("\x03abc")
        end)

        test("length mod 4 = 0", function()
            expect(toPascalString("abcd", 4)):toBe("\x04abcd\x00\x00\x00")
        end)
    end)

    test("over max length", function()
        expect(toPascalString("abcdefg", 4, 4)):toBe("\x03abc")
    end)
end)
