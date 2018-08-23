local test          = require("cp.test")
local rxTest        = require("cp.rx.test")

local ReplaySubject = require("cp.rx").ReplaySubject
local sub           = rxTest.subscribe

return test.suite("cp.rx.ReplaySubject")
:with {
    test("simple", function()
        local s = ReplaySubject.create(2)

        local result = sub(s)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#s.buffer, 0))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#s.buffer, 1))

        local result2 = sub(s)
        ok(result:is({1}, nil, false))
        ok(result2:is({1}, nil, false))
        ok(eq(#s.observers, 2))
        ok(eq(#s.buffer, 1))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(result2:is({1,2}, nil, false))
        ok(eq(#s.observers, 2))
        ok(eq(#s.buffer, 2))

        s:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(result2:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#s.buffer, 2))

        local result3 = sub(s)
        ok(result3:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#s.buffer, 2))
   end),

   test("error", function()
        local s = ReplaySubject.create()

        local result = sub(s)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))

        s:onError("bar")
        ok(result:is({1}, "bar", false))
        ok(eq(#s.observers, 0))

        ok(sub(s):is({1}, "bar", false))
    end),
}
