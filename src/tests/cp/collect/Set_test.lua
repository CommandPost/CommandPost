local test          = require("cp.test")
local Set          = require("cp.collect.Set")

return test.suite("cp.collect.Set"):with {
    test("new", function()
        -- the `new` method directly
        local s = Set.new()
        ok(eq(s:size(), 0))

        -- alternate method, with default items
        s = Set(1, 2, 3)
        ok(eq(s:size(), 3))
        ok(eq(s:has(1), true))
        ok(eq(s:has(2), true))
        ok(eq(s:has(3), true))
        ok(eq(s:has(4), false))

        ok(eq(s[1], true))
        ok(eq(s[2], true))
        ok(eq(s[3], true))
        ok(eq(s[4], nil))
    end),

    test("new duplicates", function()
        local s = Set(1,2,2,3,1,2,3)

        ok(eq(s:size(), 3))
        ok(eq(s[1], true))
        ok(eq(s[2], true))
        ok(eq(s[3], true))
        ok(eq(s[4], nil))
    end),

    test("union", function()
        local a = Set(1, 2)
        local b = Set(2, 3)

        local u = Set.union(a, b)
        ok(eq(u:size(), 3))
        ok(eq(u, Set(1, 2, 3)))
    end),

    test("intersection", function()
        local a = Set.new(1, 2)
        local b = Set.new(2, 3)
        ok(eq(a:size(), 2))
        ok(eq(b:size(), 2))

        local u = Set.intersection(a, b)
        ok(eq(u:size(), 1))
        ok(eq(u, Set(2)))
    end),

    test("==", function()
        local a = Set(1, 2)
        local b = Set(2, 1)

        ok(a == b)
    end),

    test("tostring", function()
        ok(tostring(Set(1, 2, 3), "cp.collect.Set: {1, 2, 3}"))
    end),

    test("difference", function()
        ok(eq(Set.difference(Set(1, 2, 3), Set(1, 2)), Set(3)))
    end),

    test("complement", function()
        local a = Set(1,2,3)
        local _a = Set.complement(a)

        ok(eq(a, _a, false))
        ok(eq(_a:isComplement(), true))
        ok(eq(_a:size(), -3))
        ok(eq(_a:has(1), false))
        ok(eq(_a:has(3), false))
        ok(eq(_a:has(4), true))
        ok(eq(_a:has(123456789), true))
        ok(eq(_a:has("foo"), true))

        _a = -Set(1,2,3)

        ok(eq(_a:isComplement(), true))
        ok(eq(_a:size(), -3))
        ok(eq(_a:has(1), false))
        ok(eq(_a:has(3), false))
        ok(eq(_a:has(4), true))
        ok(eq(_a:has(123456789), true))
        ok(eq(_a:has("foo"), true))
    end),

    test("complement of a complement", function()
        -- complement of a complement
        local _a = -(-Set(1,2,3))

        ok(eq(_a, Set(1,2,3)))

        ok(eq(_a:isComplement(), false))

        ok(eq(_a:size(), 3))
        ok(eq(_a:has(1), true))
        ok(eq(_a:has(3), true))
        ok(eq(_a:has(4), false))
        ok(eq(_a:has(123456789), false))
        ok(eq(_a:has("foo"), false))
    end),

    test("everything", function()
        local a = Set.everything

        ok(eq(a:isComplement(), true))
        ok(eq(a:size(), nil))

        ok(eq(a:has(0), true))
        ok(eq(a:has(nil), true))
        ok(eq(a:has("foo"), true))
    end),

    test("nothing", function()
        local a = Set.nothing

        ok(eq(a:isComplement(), false))
        ok(eq(a:size(), 0))

        ok(eq(a:has(0), false))
        ok(eq(a:has(nil), false))
        ok(eq(a:has("foo"), false))
    end),

    test("set | set", function()
        ok(eq(Set(1,2) | Set(2,3), Set(1,2,3)))
    end),

    test("set | complement", function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a | b

        ok(eq(c, -Set(4,5)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -2))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), true))
        ok(eq(c:has(2), true))
        ok(eq(c:has(3), true))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),

    test("complement | complement", function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a | b

        ok(eq(c, -Set(3)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -1))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), true))
        ok(eq(c:has(2), true))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), true))
        ok(eq(c:has(5), true))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),

    test("complement | set", function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a | b

        ok(eq(c, -Set(1,2)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -2))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), true))
        ok(eq(c:has(4), true))
        ok(eq(c:has(5), true))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),

    test("set & set", function()
        ok(eq(Set(1,2) & Set(2,3), Set(2)))
    end),

    test("set & complement", function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a & b

        ok(eq(c, Set(1,2)))

        ok(eq(c:isComplement(), false))
        ok(eq(c:size(), 2))
        ok(eq(c:has(0), false))
        ok(eq(c:has(1), true))
        ok(eq(c:has(2), true))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), false))
        ok(eq(c:has("foo"), false))
    end),

    test("complement & complement", function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a & b

        ok(eq(c, -Set(1,2,3,4,5)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -5))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),

    test("complement & set", function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a & b

        ok(eq(c, Set(4,5)))

        ok(eq(c:isComplement(), false))
        ok(eq(c:size(), 2))
        ok(eq(c:has(0), false))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), true))
        ok(eq(c:has(5), true))
        ok(eq(c:has(6), false))
        ok(eq(c:has("foo"), false))
    end),

    test("set - set", function()
        ok(eq(Set(1,2,3) - Set(1,2), Set(3)))
        ok(eq(Set(1,2,3) - Set(2,3,4), Set(1)))
        ok(eq(Set() - Set(1,2,3), Set()))
    end),


    test("set - complement", function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a - b

        ok(eq(c, Set(3)))

        ok(eq(c:isComplement(), false))
        ok(eq(c:size(), 1))
        ok(eq(c:has(0), false))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), true))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), false))
        ok(eq(c:has("foo"), false))
    end),

    test("complement - complement", function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a - b

        ok(eq(c, Set(4,5)))

        ok(eq(c:isComplement(), false))
        ok(eq(c:has(0), false))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), true))
        ok(eq(c:has(5), true))
        ok(eq(c:has(6), false))
        ok(eq(c:has("foo"), false))
    end),

    test("complement - set", function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a - b

        ok(eq(c, -Set(1,2,3,4,5)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -5))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),

    test("set ~ set", function()
        ok(eq(Set(1,2,3) ~ Set(3,4,5), Set(1,2,4,5)))
    end),

    test("set ~ complement", function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a ~ b

        ok(eq(c, -Set(1,2,4,5)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -4))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), true))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),

    test("complement ~ complement", function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a ~ b

        ok(eq(c, Set(1,2,4,5)))

        ok(eq(c:isComplement(), false))
        ok(eq(c:size(), 4))
        ok(eq(c:has(0), false))
        ok(eq(c:has(1), true))
        ok(eq(c:has(2), true))
        ok(eq(c:has(3), false))
        ok(eq(c:has(4), true))
        ok(eq(c:has(5), true))
        ok(eq(c:has(6), false))
        ok(eq(c:has("foo"), false))
    end),

    test("complement ~ set", function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a ~ b

        ok(eq(c, -Set(1,2,4,5)))

        ok(eq(c:isComplement(), true))
        ok(eq(c:size(), -4))
        ok(eq(c:has(0), true))
        ok(eq(c:has(1), false))
        ok(eq(c:has(2), false))
        ok(eq(c:has(3), true))
        ok(eq(c:has(4), false))
        ok(eq(c:has(5), false))
        ok(eq(c:has(6), true))
        ok(eq(c:has("foo"), true))
    end),
}