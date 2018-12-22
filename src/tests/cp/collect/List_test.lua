local test          = require("cp.test")
local List          = require("cp.collect.List")

return test.suite("cp.collect.List"):with {
    test("of", function()
        -- the `new` method directly
        local l = List.of()
        ok(eq(#l, 0))

        -- alternate method, with default items
        l = List(1, 2, 3)
        ok(eq(#l, 3))
        ok(eq(l[1], 1))
        ok(eq(l[2], 2))
        ok(eq(l[3], 3))
    end),

    test("sized", function()
        local l = List.sized(10)
        ok(eq(#l, 10))

        local max
        for k,v in ipairs(l) do
            max = k
            ok(eq(v, nil))
        end
        ok(eq(max, 10))
    end),

    test("sized default", function()
        local l = List.sized(10, "foo")
        ok(eq(#l, 10))

        local max
        for k,v in ipairs(l) do
            max = k
            ok(eq(v, "foo"))
        end
        ok(eq(max, 10))
    end),

    test("=", function()
        local l = List()

        l[1] = "one"
        ok(eq(#l, 1))
        ok(eq(l[1], "one"))

        l[5] = "five"
        ok(eq(#l, 5))
        ok(eq(l[5], "five"))
    end),

    test("size", function()
        local l = List()

        ok(eq(#l, 0))

        l:size(4)
        ok(eq(#l, 4))

        l = List(1,2,3)
        ok(eq(#l, 3))

        l:size(1)
        ok(eq(#l, 1))
        ok(eq(l[1], 1))
        ok(eq(l[2], nil))
        ok(eq(l[3], nil))

    end),

    test("trim", function()
        local l = List(1,2,3,nil,nil,nil)

        ok(eq(#l, 6))

        l:trim(5)
        ok(eq(#l, 5))

        l:trim()
        ok(eq(#l, 3))

        l:trim(1)
        ok(eq(#l, 3))
    end),
}