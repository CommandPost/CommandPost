local test                      = require("cp.test")
local rx                        = require("cp.rx")
local rxTest                    = require("cp.rx.test")

local Observable, Subject       = rx.Observable, rx.Subject
local sub                       = rxTest.subscribe

return test.suite("cp.rx")
:with {
    require "cp.rx.Subject_test",

    test("flatMap", function()
        local ifSubject = Subject.create()
        local whenSubject = Subject.create()
        local ifValue = nil

        local result = sub(ifSubject:flatMap(function(value)
            ifValue = value
            return whenSubject
        end))

        -- initially
        ok(result:is({}, nil, false))
        ok(eq(ifValue, nil))

        -- send the if
        ifSubject:onNext(true)
        ifSubject:onCompleted()
        ok(result:is({}, nil, false))
        ok(eq(ifValue, true))

        -- send the when
        whenSubject:onNext(true)
        ok(result:is({true}, nil, false))
        ok(eq(ifValue, true))

        -- complete the when
        whenSubject:onCompleted()
        ok(result:is({true}, nil, true))
        ok(eq(ifValue, true))
    end),

    test("find", function()
        local aSubject = Subject.create()

        local result = sub(aSubject:find(function(x) return x == true end))

        -- initially...
        ok(result:is({}, nil, false))

        -- send `false`
        aSubject:onNext(false)
        ok(result:is({}, nil, false))

        -- send `true`
        aSubject:onNext(true)
        ok(result:is({true}, nil, true))

        -- send again, gets ignored
        aSubject:onNext(true)
        ok(result:is({true}, nil, true))
    end),

    test("zip flatMap", function()
        local outerSubject = Subject.create()
        local innerSubject = Subject.create()
        local flatValue = nil

        local result = sub(Observable.zip(outerSubject)
        :first()
        :flatMap(function(value)
            flatValue = value
            return Observable.zip(innerSubject)
        end))

        -- initially...
        ok(result:is({}, nil, false))
        ok(eq(flatValue, nil))

        -- send true, passes:
        outerSubject:onNext(true)
        ok(result:is({}, nil, false))
        ok(eq(flatValue, true))

        -- send "success" internally
        innerSubject:onNext("success")
        ok(result:is({"success"}, nil, false))
        ok(eq(flatValue, true))

        -- send internal completed
        innerSubject:onCompleted()
        ok(result:is({"success"}, nil, true))
    end),

    test("flatten sync", function()
        -- simulates having the outer Observer completing after the inner observers.
        local outerSubject = Subject.create()
        local innerSubject = Subject.create()

        local result = sub(outerSubject:flatten())

        -- initially...
        ok(result:is({}, nil, false))

        -- send the inner subject...
        outerSubject:onNext(innerSubject)
        ok(result:is({}, nil, false))

        innerSubject:onNext(1)
        ok(result:is({1}, nil, false))

        -- send another to the inner
        innerSubject:onNext(2)
        ok(result:is({1,2}, nil, false))

        -- complete the inner
        innerSubject:onCompleted()
        ok(result:is({1,2}, nil, false))

        -- ignore further values.
        innerSubject:onNext(3)
        ok(result:is({1,2}, nil, false))

        -- complete the outer but not the inner
        outerSubject:onCompleted()
        ok(result:is({1,2}, nil, true))
    end),

    test("flatten async", function()
        -- simulates having the outer Observer completing before the inner observers.
        local outerSubject = Subject.create()
        local innerSubject = Subject.create()

        local result = sub(outerSubject:flatten())

        -- initially...
        ok(result:is({}, nil, false))

        -- send the inner subject...
        outerSubject:onNext(innerSubject)
        ok(result:is({}, nil, false))

        innerSubject:onNext(1)
        ok(result:is({1}, nil, false))

        -- complete the outer but not the inner
        outerSubject:onCompleted()
        ok(result:is({1}, nil, false))

        -- send another to the inner
        innerSubject:onNext(2)
        ok(result:is({1,2}, nil, false))

        -- complete the inner
        innerSubject:onCompleted()
        ok(result:is({1,2}, nil, true))

        -- ignore further values.
        innerSubject:onNext(3)
        ok(result:is({1,2}, nil, true))
    end),

    test("take", function()
        local s = Subject.create()

        local result = sub(s:take(1))

        ok(result:is({}, nil, false))

        s:onNext(1)

        ok(result:is({1}, nil, true))

        s:onNext(2)

        ok(result:is({1}, nil, true))
    end),

    test("take recursive", function()
        local s = Subject.create()

        local result = sub(s:take(1):tap(
            function(value)
                s:onNext(value * 10)
            end
        ))

        -- initially, nothing
        ok(result:is({}, nil, false))

        -- take the first value and complete
        s:onNext(1)
        ok(result:is({1}, nil, true))

        -- ignore subsequent values
        s:onNext(2)
        ok(result:is({1}, nil, true))
    end),

    test("switchIfEmpty", function()
        local original = Subject.create()
        local alt = Subject.create()

        local result = sub(original:switchIfEmpty(alt))

        -- initially, defaults.
        ok(result:is({}, nil, false))
        -- original has one sub, alt none
        ok(eq(#original.observers, 1))
        ok(eq(#alt.observers, 0))

        -- the original completes
        original:onCompleted()
        -- still no results
        ok(result:is({}, nil, false))
        -- original has no subscribers, alt now has one
        ok(eq(#original.observers, 0))
        ok(eq(#alt.observers, 1))

        -- send a value to alt
        alt:onNext("default")
        -- receive it
        ok(result:is({"default"}, nil, false))

        -- complete alt
        alt:onCompleted()
        -- receive completion
        ok(result:is({"default"}, nil, true))
        -- all subscribers gone
        ok(eq(#original.observers, 0))
        ok(eq(#alt.observers, 0))
    end)
}