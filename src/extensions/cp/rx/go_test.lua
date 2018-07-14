-- local log           = require("hs.logger").new("rxgotils")
local inspect       = require("hs.inspect")

local test          = require("cp.test")

local prop          = require("cp.prop")
local rx            = require("cp.rx")
local rxgo          = require("cp.rx.go")

local Observable, Subject = rx.Observable, rx.Subject
local append, is, toObservable, toObservables = rxgo.append, rxgo.is, rxgo.toObservable, rxgo.toObservables
local Statement, SubStatement = rxgo.Statement, rxgo.SubStatement
local Given, If, WaitUntil, Throw = rxgo.Given, rxgo.If, rxgo.WaitUntil, rxgo.Throw
--local First = rxgo.First
local Last = rxgo.Last

local insert = table.insert

-- local function debug(label)
--     return function(value)
--         print(label .. " NEXT: ", value)
--     end,
--     function(message)
--         print(label .. " ERROR: ", message)
--     end,
--     function()
--         print(label .. " COMPLETED")
--     end
-- end

return test.suite("cp.rx.go"):with {
    test("append", function()
        local values = {}
        ok(eq(append(values, 1, 2, 3), {1, 2, 3}))
        ok(eq(values, {1, 2, 3}))

        ok(eq(append(values, 4, 5), {1, 2, 3, 4, 5}))
        ok(eq(values, {1, 2, 3, 4, 5}))
    end),

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

        ok(SubStatement.is(result))

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
        local result, completed = nil, false

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
                result = value
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
        ok(eq(result, nil))
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

    test("WaitUntil", function()
        -- local scheduler = rx.CooperativeScheduler.create(0)

        local subject = Subject.create()
        local received = nil
        local completed = false

        local wait = WaitUntil(subject):Is("green")

        wait:Now(
            function(value)
                ok(eq(value, "green"))
                received = value
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(subject == wait:context().requirement)

        ok(eq(received, nil))

        subject:onNext("red")
        ok(eq(received, nil))
        ok(eq(completed, false))

        subject:onNext("green")
        ok(eq(received, "green"))
        ok(eq(completed, true))
    end),

    test("If WaitUntil", function()
        local ifSubject = Subject.create()
        local waitSubject = Subject.create()
        local received = nil
        local completed = false

        If(ifSubject):Then(function()
            return WaitUntil(waitSubject)
        end):Now(
            function(value)
                received = value
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(eq(received, nil))
        ok(eq(completed, false))

        -- resolve the 'if'
        ifSubject:onNext(true)
        ok(eq(received, nil))
        ok(eq(completed, false))

        -- 'wait until' should not resolve yet
        waitSubject:onNext(false)
        ok(eq(received, nil))
        ok(eq(completed, false))

        -- 'wait until' now resolves
        waitSubject:onNext(true)
        ok(eq(received, true))
        ok(eq(completed, true))
    end),

    test("Statement Call", function()
        local called = false

        local statement = Given(
            function()
                called = true
            end
        )

        ok(eq(called, false))

        statement()
        ok(eq(called, true))
    end),

    test("Throw", function()
        -- straight throw:
        local error = false

        Throw("Message %s", "Test"):Now(
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


    test("Given:Then:Throw", function()
        -- straight throw:
        local error = false

        Given(true)
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

    test("Last", function()
        local result = nil
        local error = false
        local completed = true

        Last(Observable.of(1, 2, 3)):
        Now(
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

        ok(eq(result, 3))
        ok(eq(error, false))
        ok(eq(completed, true))
    end)
}
