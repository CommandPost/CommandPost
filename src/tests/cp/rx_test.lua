local test          = require("cp.test")
local rx            = require("cp.rx")

local Observable, Subject = rx.Observable, rx.Subject

return test.suite("cp.rx"):with {
    test("flatMap", function()
        local ifSubject = Subject.create()
        local whenSubject = Subject.create()
        local ifValue = nil
        local result = nil
        local results = 0
        local completed = false

        ifSubject:flatMap(function(value)
            ifValue = value
            return whenSubject
        end):subscribe(
            function(value)
                result = value
                results = results + 1
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        -- initially
        ok(eq(ifValue, nil))
        ok(eq(result, nil))
        ok(eq(results, 0))
        ok(eq(completed, false))

        -- send the if
        ifSubject:onNext(true)
        ifSubject:onCompleted()
        ok(eq(ifValue, true))
        ok(eq(result, nil))
        ok(eq(results, 0))
        ok(eq(completed, false))

        -- send the when
        whenSubject:onNext(true)
        ok(eq(ifValue, true))
        ok(eq(result, true))
        ok(eq(results, 1))
        ok(eq(completed, false))

        -- complete the when
        whenSubject:onCompleted()
        ok(eq(ifValue, true))
        ok(eq(result, true))
        ok(eq(results, 1))
        ok(eq(completed, true))
    end),

    test("find", function()
        local aSubject = Subject.create()
        local results = 0
        local completed = false

        aSubject:find(function(x) return x == true end)
        :subscribe(
            function(value)
                ok(eq(value, true))
                results = results + 1
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        -- initially...
        ok(eq(results, 0))
        ok(eq(completed, false))

        -- send `false`
        aSubject:onNext(false)
        ok(eq(results, 0))
        ok(eq(completed, false))

        -- send `true`
        aSubject:onNext(true)
        ok(eq(results, 1))
        ok(eq(completed, true))

        -- send again, gets ignored
        aSubject:onNext(true)
        ok(eq(results, 1))
        ok(eq(completed, true))
    end),

    test("zip flatMap", function()
        local outerSubject = Subject.create()
        local innerSubject = Subject.create()
        local flatValue = nil

        local result = nil
        local completed = false

        Observable.zip(outerSubject)
        :first()
        :flatMap(function(value)
            flatValue = value
            return Observable.zip(innerSubject)
        end)
        :subscribe(
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

        -- initially...
        ok(eq(flatValue, nil))
        ok(eq(result, nil))
        ok(eq(completed, false))

        -- send true, passes:
        outerSubject:onNext(true)
        ok(eq(flatValue, true))
        ok(eq(result, nil))
        ok(eq(completed, false))

        -- send "success" internally
        innerSubject:onNext("success")
        ok(eq(flatValue, true))
        ok(eq(result, "success"))
        ok(eq(completed, false))

        -- send internal completed
        innerSubject:onCompleted()
        ok(eq(completed, true))
    end),

    test("flatten sync", function()
        -- simulates having the outer Observer completing after the inner observers.
        local outerSubject = Subject.create()
        local innerSubject = Subject.create()
        local results, completed = 0, false

        outerSubject:flatten()
        :subscribe(
            function(_)
                results = results + 1
            end,
            function(message)
                ok(eq(false, message))
            end,
            function()
                completed = true
            end
        )

        -- initially...
        ok(eq(results, 0))
        ok(eq(completed, false))

        -- send the inner subject...
        outerSubject:onNext(innerSubject)
        ok(eq(results, 0))
        ok(eq(completed, false))

        innerSubject:onNext(1)
        ok(eq(results, 1))
        ok(eq(completed, false))

        -- send another to the inner
        innerSubject:onNext(2)
        ok(eq(results, 2))
        ok(eq(completed, false))

        -- complete the inner
        innerSubject:onCompleted()
        ok(eq(results, 2))
        ok(eq(completed, false))

        -- ignore further values.
        innerSubject:onNext(3)
        ok(eq(results, 2))
        ok(eq(completed, false))

        -- complete the outer but not the inner
        outerSubject:onCompleted()
        ok(eq(results, 2))
        ok(eq(completed, true))
    end),

    test("flatten async", function()
        -- simulates having the outer Observer completing before the inner observers.
        local outerSubject = Subject.create()
        local innerSubject = Subject.create()
        local results, completed = 0, false

        outerSubject:flatten()
        :subscribe(
            function(_)
                results = results + 1
            end,
            function(message)
                ok(eq(false, message))
            end,
            function()
                completed = true
            end
        )

        -- initially...
        ok(eq(results, 0))
        ok(eq(completed, false))

        -- send the inner subject...
        outerSubject:onNext(innerSubject)
        ok(eq(results, 0))
        ok(eq(completed, false))

        innerSubject:onNext(1)
        ok(eq(results, 1))
        ok(eq(completed, false))

        -- complete the outer but not the inner
        outerSubject:onCompleted()
        ok(eq(results, 1))
        ok(eq(completed, false))

        -- send another to the inner
        innerSubject:onNext(2)
        ok(eq(results, 2))
        ok(eq(completed, false))

        -- complete the inner
        innerSubject:onCompleted()
        ok(eq(results, 2))
        ok(eq(completed, true))

        -- ignore further values.
        innerSubject:onNext(3)
        ok(eq(results, 2))
        ok(eq(completed, true))
    end),
}