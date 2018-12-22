-- test cases for `cp.time.flicks`
local test      = require("cp.test")
local flicks    = require("cp.time.flicks")

return test.suite("cp.time.flicks"):with {
    test("new", function()
        ok(eq(flicks.new(1).value, 1))
        ok(eq(flicks.new(1 * flicks.perSecond).value, flicks.perSecond))
    end),

    test("parse", function()
        ok(eq(flicks.parse("1:30:00", 25).value, 1 * flicks.perMinute + 30 * flicks.perSecond))
        ok(eq(flicks.parse("1:30;00", 25).value, 1 * flicks.perMinute + 30 * flicks.perSecond))
        ok(eq(flicks.parse("13000", 25).value, 1 * flicks.perMinute + 30 * flicks.perSecond))
        ok(eq(flicks.parse("9000", 25).value, 90 * flicks.perSecond))

        local check = spy(function() eq(flicks.parse("ABC")) end)
        check()
        ok(check.errors[1], "Invalid timecode value.")
    end),

    test("__call", function()
        ok(eq(flicks(1).value, 1))
        ok(eq(flicks(1 * flicks.perSecond).value, 1 * flicks.perSecond))
    end),

    test("toSeconds", function()
        ok(eq(flicks(1):toSeconds(), 1/flicks.perSecond))
    end),

    test("toTimecode", function()
        local f = flicks.parse("123456", 60)
        ok(eq(f:toTimecode(60), "00123456"))
        ok(eq(f:toTimecode(60, ":"), "00:12:34:56"))
        ok(eq(f:toTimecode(60, ";"), "00:12:34;56"))
    end),

    test("NTSC", function()
        local f = flicks.parse("123456", 59.94)
        ok(eq(f:toTimecode(59.94), "00123456"))
        ok(eq(f:toTimecode(29.97), "00123428"))
        ok(eq(f:toTimecode(30), "00123520"))
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