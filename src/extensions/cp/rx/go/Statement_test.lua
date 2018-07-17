-- local log           = require("hs.logger").new("rxgotils")

local test          = require("cp.test")

local rx            = require("cp.rx")
local Statement     = require("cp.rx.go.Statement")

local Observable    = rx.Observable
local toObservable, toObservables = Statement.toObservable, Statement.toObservables

local insert = table.insert

return test.suite("cp.rx.go.Statement"):with {
    test("toObservable", function()
        local o, result
        ok(Observable.is(toObservable(1)))
        o = toObservable(function(one) return one * 2 end, {4})
        o:subscribe(function(x) result = x end)
        ok(Observable.is(o))
        ok(eq(result, 8))

        -- more complex example
        o = toObservable(function() return 1, function() return 2 end, Observable.of(3) end)
        o:subscribe(function(x, y, z)
            ok(eq(x, 1))
            ok(eq(y, 2))
            ok(eq(z, 3))
        end)
    end),

    test("toObservables", function()
        local args = {1, 2, 3}
        local results = {}
        local o = toObservables({1, 2, 3})
        ok(eq(#o, 3))

        for _,v in ipairs(o) do
            v:subscribe(function(x) insert(results, x) end)
        end

        ok(eq(args, results))
    end),

    test("Statement.is", function()
        local Test = Statement.named("Test"):onObservable(function() return Observable.empty() end):define()

        ok(Statement.Definition.is(Test), "Test is not a Statement")
        ok(Statement.is(Test()), "Test.mt is not a Statement")
    end),

    test("Statement Call", function()
        local result = nil
        local Test = Statement.named("Test")
        :onInit(function(context, value)
            context.value = value
        end)
        :onObservable(function(context)
            return Observable.of(context.value)
        end):define()

        local statement = Test("one")
        statement(function(value) result = value end)

        ok(eq(result, "one"))
    end),
}