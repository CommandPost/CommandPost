local test          = require("cp.test")

local Require       = require("cp.rx.go.Require")
local Subject       = require("cp.rx").Subject

local insert        = table.insert

return test.suite("cp.rx.go.Require"):with {
    test("Require completed", function()
        local s = Subject.create()

        local results = {}
        local message = nil
        local completed = false

        Require(s)
        :OrThrow("Failed")
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

        s:onNext(true)
        s:onCompleted()

        ok(eq(results, {true}))
        ok(eq(message, nil))
        ok(eq(completed, true))
    end),

    test("Require failed", function()
        local s = Subject.create()

        local results = {}
        local message = nil
        local completed = false

        Require(s)
        :OrThrow("Failed")
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

        s:onNext(false)

        ok(eq(results, {}))
        ok(eq(message, "Failed"))
        ok(eq(completed, false))
    end),

}