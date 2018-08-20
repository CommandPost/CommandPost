local test          = require("cp.test")
local rxTest        = require("cp.rx.test")

local AsyncSubject  = require("cp.rx").AsyncSubject
local sub           = rxTest.subscribe

local insert        = table.insert

return test.suite("cp.rx.Subject")
:with {
    test("simple", function()
        local s = AsyncSubject.create()

        local result = sub(s)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        s:onNext(2)
        ok(result:is({}, nil, false))

        s:onCompleted()
        ok(result:is({2}, nil, true))
        ok(eq(#s.observers, 0))
   end),

   test("error", function()
        local s = AsyncSubject.create()

        local result = sub(s)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))

        s:onError("bar")
        ok(result:is({}, "bar", false))
        ok(eq(#s.observers, 0))
    end),

    test("multiple subscribers", function()
        local s = AsyncSubject.create()

        local result1, result2 = sub(s), sub(s)

        ok(result1:is({}, nil, false))
        ok(result2:is({}, nil, false))
        ok(eq(#s.observers, 2))

        s:onNext(1)
        ok(result1:is({}, nil, false))
        ok(result2:is({}, nil, false))
        ok(eq(#s.observers, 2))

        result2.reference:cancel()
        ok(result1:is({}, nil, false))
        ok(result2:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result1:is({}, nil, false))
        ok(result2:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result1:is({2}, nil, true))
        ok(result2:is({}, nil, false))
        ok(eq(#s.observers, 0))

    end),

    test("recursive next", function()
        local s = AsyncSubject.create()
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

        ok(eq(nexts, {}))
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
