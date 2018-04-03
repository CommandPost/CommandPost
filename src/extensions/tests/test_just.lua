local test		= require("cp.test")
-- local log		= require("hs.logger").new("testjust")

local just		= require("cp.just")

return test.suite("cp.just"):with(
    test("Just Until Once", function()
        local count = 0
        local result = just.doUntil(function() count = count + 1; return true end)

        ok(eq(count, 1))
        ok(eq(result, true))
    end),

    test("Just While Once", function()
        local count = 0
        local result = just.doWhile(function() count = count + 1; return false end)

        ok(eq(count, 1))
        ok(eq(result, false))
    end),

    test("Just Until Default Timeout", function()
        local count = 0
        local result = just.doUntil(function() count = count + 1; return false end)

        ok(eq(result, false))
    end),

    test("Just While Default Timeout", function()
        local count = 0
        local result = just.doWhile(function() count = count + 1; return true end)

        ok(eq(result, true))
    end),

    test("Just Until 5 times", function()
        local count = 0
        local result = just.doUntil(function() count = count + 1; return false end, 0.5, 0.1)

        ok(eq(count, 5))
        ok(eq(result, false))
    end),

    test("Just While 5 times", function()
        local count = 0
        local result = just.doWhile(function() count = count + 1; return true end, 0.5, 0.1)

        ok(eq(count, 5))
        ok(eq(result, true))
    end)
)