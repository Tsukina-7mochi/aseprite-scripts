local describe = require("lib.test").describe
local expect = require("lib.test").expect
local test = require("lib.test").test
local isValid = require("pkg.type.validate").isValid

describe("validate", function()
    test("validate nil: success", function()
        local validator = { type = "nil" }
        local value = nil
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate nil: fail", function()
        local validator = { type = "nil" }
        local value = 0
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate number: success", function()
        local validator = { type = "number" }
        local value = 0
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate number: fail", function()
        local validator = { type = "number" }
        local value = "a"
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate integer: success", function()
        local validator = { type = "integer" }
        local value = 0
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate integer: fail", function()
        local validator = { type = "integer" }
        local value = 0.1
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate string: success", function()
        local validator = { type = "string" }
        local value = "a"
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate string: fail", function()
        local validator = { type = "string" }
        local value = 0
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate boolean: success", function()
        local validator = { type = "boolean" }
        local value = true
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate boolean: fail", function()
        local validator = { type = "boolean" }
        local value = 0
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate number value: success", function()
        local validator = { type = "value", value = 0 }
        local value = 0
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate number value: fail", function()
        local validator = { type = "value", value = 0 }
        local value = 1
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate string value: success", function()
        local validator = { type = "value", value = "a" }
        local value = "a"
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate string value: fail", function()
        local validator = { type = "value", value = "a" }
        local value = "b"
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate empty table: success", function()
        local validator = { type = "table", values = {} }
        local value = {}
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate nonempty table: success", function()
        local validator = {
            type = "table",
            values = {
                a = { type = "number" },
                b = { type = "string" },
                c = { type = "value", value = true },
                d = { type = "table", values = {} },
            }
        }
        local value = {
            a = 1,
            b = "a",
            c = true,
            d = {},
        }

        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate nonempty table: fail", function()
        local validator = {
            type = "table",
            values = {
                a = { type = "number" },
                b = { type = "string" },
                c = { type = "value", value = true },
                d = { type = "table", values = {} },
            }
        }
        local value = {
            a = "a",
            b = 1,
            c = false,
            d = {},
        }
        expect(isValid(value, validator)):toBe(false)
    end)

    test("validate array: success", function()
        local validator = { type = "array", values = { type = "number" } }
        local value = { 1, 2, 3 }
        expect(isValid(value, validator)):toBe(true)
    end)

    test("validate array: fail", function()
        local validator = { type = "array", values = { type = "number" } }
        local value = { 1, 2, "a" }
        expect(isValid(value, validator)):toBe(false)
    end)
end)
