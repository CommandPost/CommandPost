local test          = require("cp.test")
local Set          = require("cp.collect.Set")

return test.suite("cp.collect.Set"):with {
    test("new", function()
        -- the `new` method directly
        local s = Set.new()
        ok(eq(#s, 0))

        -- alternate method, with default items
        s = Set(1, 2, 3)
        ok(eq(#s, 3))
        ok(eq(s:has(1), true))
        ok(eq(s:has(2), true))
        ok(eq(s:has(3), true))
        ok(eq(s:has(4), false))

        ok(eq(s[1], true))
        ok(eq(s[2], true))
        ok(eq(s[3], true))
        ok(eq(s[4], nil))
    end),

    test("union", function()
        local a = Set(1, 2)
        local b = Set(2, 3)

        local u = Set.union(a, b)
        ok(eq(#u, 3))
        ok(eq(u, Set(1, 2, 3)))
    end),

    test("intersection", function()
        local a = Set.new(1, 2)
        local b = Set.new(2, 3)
        ok(eq(#a, 2))
        ok(eq(#b, 2))

        local u = Set.intersection(a, b)
        ok(eq(#u, 1))
        ok(eq(u, Set(2)))
    end),
}