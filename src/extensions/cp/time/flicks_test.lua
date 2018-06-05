-- test cases for `cp.time.flicks`
local test      = require("cp.test")
local flicks    = require("cp.time.flicks")

return test.suite("cp.time.flicks"):with {
    test("new", function()
        ok(eq(flicks.new(1).value, 1))
        ok(eq(flicks.new(1, flicks.perSecond).value, flicks.perSecond))
    end),

    test("__call", function()
        ok(eq(flicks.new(1).value, flicks(1).value))
    end),

    test("toSeconds", function()
        ok(eq(flicks(1):toSeconds(), 1/flicks.perSecond))
    end),

    test("==", function()
        ok(eq(flicks(1), flicks(1)))
        ok(neq(flicks(1), 1))
    end),

    test("+", function()
        local a, b = flicks(1), flicks(2)
        ok(eq(a + b, flicks(3)))
    end),

    test("-", function()
        local a, b = flicks(1), flicks(2)
        ok(eq(a - b, flicks(-1)))
    end),

    test("*", function()
        local a = flicks(2)
        ok(eq(a * 2, flicks(4)))
        ok(eq(a * 0.5, flicks(1)))
        ok(eq(2 * a, flicks(4)))
        ok(eq(0.5 * a, flicks(1)))
    end),

    test("/", function()
        local a = flicks(2)
        ok(eq(a / 2, flicks(1)))
        ok(eq(a / 0.5, flicks(4)))
        ok(eq(1 / a, flicks(0)))
    end),

    test("//", function()
        local a = flicks(10)
        ok(eq(a // 5, flicks(2)))
        ok(eq(a // 3, flicks(3)))
        ok(eq(1 // a, flicks(0)))
    end),

    test("%", function()
        local a = flicks(10)
        ok(eq(a % 5, flicks(0)))
        ok(eq(a % 3, flicks(1)))
        ok(eq(1 % a, flicks(1)))
    end),
}