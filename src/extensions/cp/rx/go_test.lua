-- local log       = require("hs.logger").new("rxutils")
local inspect   = require("hs.inspect")

local test      = require("cp.test")

local rx = require("cp.rx")
local rxu = require("cp.rx.go")

local Observable = rx.Observable
local is, toObservable, toObservables = rxu.is, rxu.toObservable, rxu.toObservables
local Statement, SubStatement = rxu.Statement, rxu.SubStatement
local Given = rxu.Given

local insert = table.insert

return test.suite("cp.rx.go"):with {
    test("is", function()
        local thing = {}
        thing.mt = {}

        local a = setmetatable({}, thing.mt)

        ok(is(a, thing), "a is not a thing")
        ok(is(a, thing.mt), "a is not a thing.mt")

        local subthing = {}
        subthing.mt = setmetatable({}, thing.mt)

        local b = setmetatable({}, subthing.mt)

        ok(is(b, subthing), "b is not a subthing")
        ok(is(b, subthing.mt), "b is not a subthing.mt")
        ok(is(b, thing), "b is not a thing")
        ok(is(b, thing.mt), "b is not a thing.mt")
    end),

    test("toObservable", function()
        local o, result
        ok(Observable.is(toObservable(1)))
        o = toObservable(function(one) return one * 2 end, {4})
        o:subscribe(function(x) result = x end)
        ok(Observable.is(o))
        ok(eq(result, 8))
    end),

    test("toObservables", function()
        local args = {1, 2, 3}
        local results = {}
        local o = toObservables({1, 2, 3})

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

    test("Given", function()
        ok(Statement.Definition.is(Given), "Given is not a Statement Definition")

        local result = Given(
            Observable.of(1),
            2,
            function() return "Hello" end
        )

        ok(Given.is(result), "result is not a Given")
        ok(Statement.is(result), "result is not a Statement")

        result:Now(function(one, two, three)
            ok(eq(one, 1))
            ok(eq(two, 2))
            ok(eq(three, "Hello"))
        end)
    end),

    test("Given.Then", function()
        ok(SubStatement.Definition.is(Given.Then))

        local result = Given(1):Then(function(one)
            ok(eq(one, 1))
            return "One"
        end)

        result:Now(function(value)
            ok(eq(value, "One"))
        end)

        ok(SubStatement.is(result), "Given:Then is not a SubStatement")
    end),

    test("Given.Then.Then", function()
        ok(SubStatement.Definition.is(Given.Then.Then), inspect(Given.Then.Then))

        local result = Given(1)
        :Then(function(one)
            ok(eq(one, 1))
            return "Two"
        end)
        :Then(function(two)
            ok(eq(two, "Two"))
            return 3
        end)

        ok(SubStatement.is(result))

        result:Now(function(value)
            ok(eq(value, 3))
        end)
    end)
}