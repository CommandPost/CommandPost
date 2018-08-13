local test          = require("cp.test")
local rxTest        = require("cp.rx.test")

local Subject       = require("cp.rx").Subject
local sub           = rxTest.subscribe

return test.suite("cp.rx.Subject")
:with {
    test("simple", function()
        local s = Subject.create()

        local result = sub(s)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext("foo")
        ok(result:is({"foo"}, nil, false))

        s:onCompleted()
        ok(result:is({"foo"}, nil, true))
        ok(eq(#s.observers, 0))
   end),

   test("error", function()
        local s = Subject.create()

        local result = sub(s)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext("foo")
        ok(result:is({"foo"}, nil, false))

        s:onError("bar")
        ok(result:is({"foo"}, "bar", false))
        ok(eq(#s.observers, 0))
    end),
}
