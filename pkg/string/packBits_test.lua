local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local packBits = require("pkg.string.packBits").packBits

describe("packBits", function()
    test("empty", function()
        expect(packBits("")):toBe("")
    end)

    describe("same characters", function()
        test("3 chars", function()
            expect(packBits("\x01\x01\x01")):toBe("\xfe\x01")
        end)

        test("128 chars", function()
            expect(packBits(("\x01"):rep(128))):toBe("\x81\x01")
        end)

        test("129 chars", function()
            expect(packBits(("\x01"):rep(129))):toBe("\x81\x01\x00\x01")
        end)

        test("130 chars", function()
            expect(packBits(("\x01"):rep(130))):toBe("\x81\x01\xff\x01")
        end)
    end)

    describe("different characters for each", function()
        test("3 chars", function()
            expect(packBits("\x01\x02\x03")):toBe("\x02\x01\x02\x03")
        end)

        test("128 chars", function()
            local tbl = {}
            for i = 0, 0x7f do
                tbl[i + 1] = ("B"):pack(i)
            end
            local input = table.concat(tbl)
            local expected = "\x7f" .. input

            expect(packBits(input)):toBe(expected)
        end)

        test("129 chars", function()
            local tbl = {}
            for i = 0, 0x7f do
                tbl[i + 1] = ("B"):pack(i)
            end
            local input = table.concat(tbl) .. "\x80"
            local expected = "\x7f" .. table.concat(tbl) .. "\x00\x80"

            expect(packBits(input)):toBe(expected)
        end)
    end)

    test("3 different chars, 3 same chars then 3 different chars", function()
        expect(packBits("\x01\x02\x03\xff\xff\xff\x01\x02\x03")):toBe("\x02\x01\x02\x03\xfe\xff\x02\x01\x02\x03")
    end)

    test("3 same chars, 3 different chars then 3 same chars", function()
        expect(packBits("\xff\xff\xff\x01\x02\x03\xff\xff\xff")):toBe("\xfe\xff\x02\x01\x02\x03\xfe\xff")
    end)

    test("128 same chars then 3 different chars", function()
        expect(packBits(("\xff"):rep(128) .. "\x01\x02\x03")):toBe("\x81\xff\x02\x01\x02\x03")
    end)

    test("128 different chars then 3 same chars", function()
        local tbl = {}
        for i = 0, 0x7f do
            tbl[i + 1] = ("B"):pack(i)
        end
        local input = table.concat(tbl) .. "\xff\xff\xff"

        local expected = "\x7f" .. table.concat(tbl) .. "\xfe\xff"

        expect(packBits(input)):toBe(expected)
    end)
end)
