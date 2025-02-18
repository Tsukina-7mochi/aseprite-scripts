local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local riff = require("pkg.riff")

describe("riff", function()
    test("empty", function()
        local chunk = riff.chunk("ABCD", "")
        expect(chunk:tostring()):toBe("ABCD\x00\x00\x00\x00")
    end)

    test("1-byte payload", function()
        local chunk = riff.chunk("ABCD", "a")
        expect(chunk:tostring()):toBe("ABCD\x01\x00\x00\x00a\x00")
    end)

    test("2-byte payload", function()
        local chunk = riff.chunk("ABCD", "ab")
        expect(chunk:tostring()):toBe("ABCD\x02\x00\x00\x00ab")
    end)

    test("string array payload", function()
        local chunk = riff.chunk("ABCD", { "a", "b" })
        expect(chunk:tostring()):toBe("ABCD\x02\x00\x00\x00ab")
    end)

    test("nested payload", function()
        local chunk1 = riff.chunk("ABCD", "a")
        local chunk2 = riff.chunk("EFGH", { chunk1, "b" })
        expect(chunk2:tostring()):toBe("EFGH\x0B\x00\x00\x00ABCD\x01\x00\x00\x00a\x00b\x00")
    end)
end)
