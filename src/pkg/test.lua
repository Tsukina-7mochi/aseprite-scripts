local describe = require("lib.test").describe

describe("pkg", function()
    describe("string", function()
        require("pkg.string.split_test")
        require("pkg.string.packBits_test")
        require("pkg.string.pack_test")
        require("pkg.string.pascalString_test")
    end)

    describe("type", function()
        require("pkg.type.isType_test")
        require("pkg.type.validate_test")
    end)

    describe("riff", function()
        require("pkg.riff.riff_test")
    end)
end)
