-- local log           = require("hs.logger").new("rxgotils")
local inspect       = require("hs.inspect")

local test          = require("cp.test")

local rx            = require("cp.rx")
local Statement     = require("cp.rx.go.Statement")
local Given         = require("cp.rx.go.Given")

local Observable    = rx.Observable

local insert = table.insert

return test.suite("cp.rx.go.Given"):with {

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
        ok(Statement.Modifier.Definition.is(Given.Then))

        local result = Given(1):Then(function(one)
            ok(eq(one, 1))
            return "One"
        end)

        result:Now(function(value)
            ok(eq(value, "One"))
        end)

        ok(Statement.Modifier.is(result), "Given:Then is not a Statement.Modifier")
    end),

    test("Given.Then.Then", function()
        ok(Statement.Modifier.Definition.is(Given.Then.Then), inspect(Given.Then.Then))

        local results = {}
        local message = nil
        local completed = false

        local result = Given(1)
        :Then(function(one)
            ok(eq(one, 1))
            return "Two"
        end)
        :Then(function(two)
            ok(eq(two, "Two"))
            return 3
        end)

        ok(Statement.Modifier.is(result))

        result:Now(
            function(value)
                insert(results, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {3}))
        ok(eq(message, nil))
        ok(eq(completed, true))
    end),

    test("Given.Then Error", function()
        local results = {}
        local message = nil
        local completed = false

        Given(true)
        :Then(function()
            error "message"
        end)
        :Now(
            function(value)
                insert(results, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {}))
        ok(neq(message, nil))
        ok(eq(completed, false))
    end),
}