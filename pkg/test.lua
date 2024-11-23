local describe = require("lib.test").describe

describe("pkg", function()
    describe("string", function()
        require("pkg.string.split_test")
    end)
end)
