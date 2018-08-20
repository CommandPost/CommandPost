local test          = require("cp.test")
local rxTest        = require("cp.rx.test")

local Subject       = require("cp.rx").Subject
local sub           = rxTest.subscribe

local insert        = table.insert

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

    test("multiple subscribers", function()
        local s = Subject.create()

        local result1, result2 = sub(s), sub(s)

        ok(result1:is({}, nil, false))
        ok(result2:is({}, nil, false))
        ok(eq(#s.observers, 2))

        s:onNext(1)
        s:onCompleted()
        ok(result1:is({1}, nil, true))
        ok(result2:is({1}, nil, true))
        ok(eq(#s.observers, 0))

    end),

    test("recursive next", function()
        local s = Subject.create()
        local nexts = {}
        local message = nil
        local completed = false

        s:subscribe(
            function(value)
                insert(nexts, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                -- this should get ignored...
                s:onNext(100)
                completed = true
            end
        )

        ok(eq(nexts, {}))
        ok(eq(message, nil))
        ok(eq(completed, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(eq(nexts, {1}))
        ok(eq(message, nil))
        ok(eq(completed, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()

        ok(eq(nexts, {1}))
        ok(eq(message, nil))
        ok(eq(completed, true))
        ok(eq(#s.observers, 0))
    end),
}
