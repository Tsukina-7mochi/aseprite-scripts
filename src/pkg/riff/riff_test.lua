local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local riff = require("pkg.riff")

describe("riff", function ()
    test("empty", function ()
        local chunk = riff.chunk("ABCD", "")
        expect(tostring(chunk)):toBe("ABCD\x00\x00\x00\x00")
    end)

    test("1-byte payload", function ()
        local chunk = riff.chunk("ABCD", "a")
        expect(tostring(chunk)):toBe("ABCD\x01\x00\x00\x00a\x00")
    end)

    test("2-byte payload", function ()
        local chunk = riff.chunk("ABCD", "ab")
        expect(tostring(chunk)):toBe("ABCD\x02\x00\x00\x00ab")
    end)

    test("RIFF chunk: string", function ()
        local chunk = riff.riffChunk("wave", riff.chunk("ABCD", ""))
        expect(tostring(chunk)):toBe("RIFF\x0C\x00\x00\x00waveABCD\x00\x00\x00\x00")
    end)

    test("RIFF chunk: table", function ()
        local chunk = riff.riffChunk("wave", {
            riff.chunk("ABCD", ""),
            riff.chunk("EFGH", ""),
        })
        expect(tostring(chunk)):toBe("RIFF\x14\x00\x00\x00waveABCD\x00\x00\x00\x00EFGH\x00\x00\x00\x00")
    end)

    test("LIST chunk: empty", function ()
        local chunk = riff.listChunk("frms", {})
        expect(tostring(chunk)):toBe("LIST\x04\x00\x00\x00frms")
    end)

    test("LIST chunk: one item", function ()
        local chunk = riff.listChunk("frms", { riff.chunk("ABCD", "") })
        expect(tostring(chunk)):toBe("LIST\x0C\x00\x00\x00frmsABCD\x00\x00\x00\x00")
    end)

    test("LIST chunk: items", function ()
        local chunk = riff.listChunk("frms", {
            riff.chunk("ABCD", ""),
            riff.chunk("EFGH", ""),
        })
        expect(tostring(chunk)):toBe("LIST\x14\x00\x00\x00frmsABCD\x00\x00\x00\x00EFGH\x00\x00\x00\x00")
    end)
end)
