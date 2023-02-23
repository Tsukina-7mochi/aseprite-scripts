local N = 100000

local function ex1(length)
    print("items: " .. length)

    local startTime = os.clock()
    for _ = 1, N do
        local tbl = {}
        for i = 1, length do
            tbl[i] = "A"
        end
        table.concat(tbl)
    end
    local endTime = os.clock()

    print("  table.concat: " .. (endTime - startTime))

    startTime = os.clock()
    for _ = 1, N do
        local str = ""
        for i = 1, length do
            str = str .. "A"
        end
    end
    endTime = os.clock()

    print("  string concatenate: " .. (endTime - startTime))
end

local function ex2()
    print("items: 10")

    local startTime = os.clock()
    local a = table.concat({ "A", "A", "A", "A", "A", "A", "A", "A", "A", "A"})
    local endTime = os.clock()

    print("  table.concat: " .. (endTime - startTime))

    local startTime = os.clock()
    local b = "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
    local endTime = os.clock()

    print("  string concatenate: " .. (endTime - startTime))

    print("items: 100")

    local startTime = os.clock()
    local a = table.concat({
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
        "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
    })
    local endTime = os.clock()

    print("  table.concat: " .. (endTime - startTime))

    local startTime = os.clock()
    local b = "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
        .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A" .. "A"
    local endTime = os.clock()

    print("  string concatenate: " .. (endTime - startTime))
end

print("== ex1 ==")
ex1(10)
ex1(100)
ex1(1000)

print("== ex2 ==")
ex2()
