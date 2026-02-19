local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local pack = require("pkg.string.pack")

describe("pack", function ()
    describe("u32BE", function ()
        test("0", function ()
            expect(pack.u32BE(0)):toBe("\x00\x00\x00\x00")
        end)

        test("0x12345678", function ()
            expect(pack.u32BE(0x12345678)):toBe("\x12\x34\x56\x78")
        end)
    end)

    describe("i32BE", function ()
        test("0", function ()
            expect(pack.i32BE(0)):toBe("\x00\x00\x00\x00")
        end)

        test("0x12345678", function ()
            expect(pack.i32BE(0x12345678)):toBe("\x12\x34\x56\x78")
        end)

        test("-2", function ()
            expect(pack.i32BE(-2)):toBe("\xff\xff\xff\xfe")
        end)
    end)

    describe("u16BE", function ()
        test("0", function ()
            expect(pack.u16BE(0)):toBe("\x00\x00")
        end)

        test("0x1234", function ()
            expect(pack.u16BE(0x1234)):toBe("\x12\x34")
        end)
    end)

    describe("u8", function ()
        test("0", function ()
            expect(pack.u8(0)):toBe("\x00")
        end)

        test("0xff", function ()
            expect(pack.u8(0xff)):toBe("\xff")
        end)
    end)

    describe("u32LE", function ()
        test("0", function ()
            expect(pack.u32LE(0)):toBe("\x00\x00\x00\x00")
        end)

        test("0x12345678", function ()
            expect(pack.u32LE(0x12345678)):toBe("\x78\x56\x34\x12")
        end)
    end)

    describe("i32LE", function ()
        test("0", function ()
            expect(pack.i32LE(0)):toBe("\x00\x00\x00\x00")
        end)

        test("0x12345678", function ()
            expect(pack.i32LE(0x12345678)):toBe("\x78\x56\x34\x12")
        end)

        test("-2", function ()
            expect(pack.i32LE(-2)):toBe("\xfe\xff\xff\xff")
        end)
    end)

    describe("u16LE", function ()
        test("0", function ()
            expect(pack.u16LE(0)):toBe("\x00\x00")
        end)

        test("0x1234", function ()
            expect(pack.u16LE(0x1234)):toBe("\x34\x12")
        end)
    end)
end)
