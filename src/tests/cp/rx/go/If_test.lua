local test          = require("cp.test")

local prop          = require("cp.prop")
local rx            = require("cp.rx")
local Statement     = require("cp.rx.go.Statement")
local If            = require("cp.rx.go.If")
local Given         = require("cp.rx.go.Given")
local Throw         = require("cp.rx.go.Throw")

local Subject       = rx.Subject
local insert        = table.insert

return test.suite("cp.rx.go.If"):with {
    test("If", function()
        ok(Statement.Definition.is(If))

        local thenCalled, otherwiseCalled = false, false
        local result, completed = nil, false
        If(true):Then(function(value)
            ok(eq(value, true))
            thenCalled = true
            return true
        end):Now(
            function(value)
                result = value
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(eq(thenCalled, true))
        ok(eq(otherwiseCalled, false))
        ok(eq(result, true))
        ok(eq(completed, true))
    end),

    test("If Complex", function()
        local thenCalled, otherwiseCalled = false, false
        local result, completed = {}, false

        If("a"):Is("b")
        :Then(function(_)
            ok(false, "This should not be executed")
            thenCalled = true
        end)
        :Otherwise(function(value)
            ok(value, "a")
            otherwiseCalled = true
        end)
        :Now(
            function(value)
                insert(result, value)
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(eq(thenCalled, false))
        ok(eq(otherwiseCalled, true))
        ok(eq(result, {nil}))
        ok(eq(completed, true))

        local aProp = prop.TRUE()
        If(aProp):Then(function(value)
            ok(eq(value, true))
        end)
    end),

    test("If:Then:Then:Otherwise", function()
        local ifSubject = Subject.create()
        local thenSubject = Subject.create()
        local then1 = nil
        local then2 = nil
        local results = {}
        local completed = false

        If(ifSubject):Then(function(value)
            then1 = value
            return thenSubject
        end)
        :Then(function(value)
            then2 = value
            return "done"
        end)
        :Otherwise("otherwise")
        :Now(
            function(value)
                insert(results, value)
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        -- before sending anything...
        ok(eq(then1, nil))
        ok(eq(then2, nil))
        ok(eq(results, {}))
        ok(eq(completed, false))

        -- send the first value
        ifSubject:onNext("first")
        ok(eq(then1, "first"))
        ok(eq(then2, nil))
        ok(eq(results, {}))
        ok(eq(completed, false))

        -- subsequent values are ignored.
        ifSubject:onNext("second")
        ok(eq(then1, "first"))
        ok(eq(then2, nil))
        ok(eq(results, {}))
        ok(eq(completed, false))

        -- send the first 'then' value to the second 'then'
        -- then send "done" to the end
        thenSubject:onNext("then")
        ok(eq(then1, "first"))
        ok(eq(then2, "then"))
        ok(eq(results, {"done"}))
        ok(eq(completed, false))

        -- only completes once the `thenSubject` completes
        thenSubject:onCompleted()
        ok(eq(completed, true))
    end),

    test("If:Then:Then:Error", function()
        local ifSubject = Subject.create()
        local thenSubject = Subject.create()
        local then1 = nil
        local then2 = nil
        local results = {}
        local message = nil
        local completed = false

        If(ifSubject)
        :Then(function(value)
            then1 = value
            return thenSubject
        end)
        :Then(function(value)
            then2 = value
            return "done"
        end)
        :Otherwise("otherwise")
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

        -- before sending anything...
        ok(eq(then1, nil))
        ok(eq(then2, nil))
        ok(eq(results, {}))
        ok(eq(completed, false))

        -- send the first value
        ifSubject:onNext("first")
        ok(eq(then1, "first"))
        ok(eq(then2, nil))
        ok(eq(results, {}))
        ok(eq(message, nil))
        ok(eq(completed, false))

        -- send the first 'then' value to the second 'then'
        -- then send "done" to the end
        thenSubject:onError("error")
        ok(eq(then1, "first"))
        ok(eq(then2, nil))
        ok(eq(results, {}))
        ok(eq(message, "error"))
        ok(eq(completed, false))

        -- completion is ignored after an error
        thenSubject:onCompleted()
        ok(eq(completed, false))
    end),


    test("If:Then:Throw", function()
        -- straight throw:
        local error = false

        If(true)
        :Then(Throw("Message %s", "Test"))
        :Now(
            function(_)
                ok(false, "Should not be called.")
            end,
            function(message)
                ok(message, "Message Test")
                error = true
            end,
            function()
                ok(false, "Completed should not be called.")
            end
        )

        ok(eq(error, true))
    end),

    test("If:Then:Given:Then:Throw", function()
        -- straight throw:
        local error = false

        If(true)
        :Then(function()
            return Given(true):Then(function()
                return Throw("Message %s", "Test")
            end)
        end)
        :Otherwise(Throw("Otherwise"))
        :Now(
            function(_)
                ok(false, "Should not be called.")
            end,
            function(message)
                ok(message, "Message Test")
                error = true
            end,
            function()
                ok(false, "Completed should not be called.")
            end
        )

        ok(eq(error, true))
    end),

    test("If:Then:Then", function()
        local ifProp = prop.FALSE()
        local results = {}
        local message = nil
        local completed = true

        If(ifProp):Is(false):Then(function() end)
        :Then(Given(true))
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

        ok(eq(results, {true}))
        ok(eq(message, nil))
        ok(eq(completed, true))
    end),
}