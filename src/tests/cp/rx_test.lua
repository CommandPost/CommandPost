local test                      = require("cp.test")
local rx                        = require("cp.rx")
local rxTest                    = require("cp.rx.test")

local Observable, Subject       = rx.Observable, rx.Subject
local sub                       = rxTest.subscribe

return test.suite("cp.rx")
:with {
    require "cp.rx.Observable_test",
    require "cp.rx.Subject_test",

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
}