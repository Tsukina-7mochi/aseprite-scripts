local describe = require("lib.test").describe

describe("pkg", function()
    describe("string", function()
        require("pkg.string.split_test")
        require("pkg.string.packBits_test")
        require("pkg.string.pack_test")
    end)
end)
