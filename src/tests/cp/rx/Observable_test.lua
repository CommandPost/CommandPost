local test          = require("cp.test")
local rxTest        = require("cp.rx.test")

local rx            = require("cp.rx")
local Subject       = rx.Subject
local Reference     = rx.Reference
local Observable    = rx.Observable
local Observer      = rx.Observer

local sub           = rxTest.subscribe
local containsOnly  = rxTest.containsOnly
local notNil        = rxTest.notNil
local mockScheduler = rxTest.mockScheduler

local insert        = table.insert

return test.suite("cp.rx.Subject")
:with {
    test("is", function()
        ok(eq(Observable.is(nil), false))
        ok(eq(Observable.is({}), false))
        ok(eq(Observable.is(Observable.create()), true))
    end),

    test("create", function()
        local onSub = function() end
        local o = Observable.create(onSub)

        ok(eq(o._subscribe, onSub))
    end),

    test("subscribe Observer", function()
        local observer, ref
        local o = Observable.create(function(newObserver)
            observer = newObserver
            ref = Reference.create(function() end)
            return ref
        end)

        ok(eq(observer, nil))
        ok(eq(ref, nil))

        local newObserver = Observer.create()
        local result = o:subscribe(newObserver)

        ok(eq(newObserver, observer))
        ok(eq(result, ref))
    end),

    test("subscribe functions", function()
        local observer, ref
        local o = Observable.create(function(newObserver)
            observer = newObserver
            ref = Reference.create(function() end)
            return ref
        end)

        ok(eq(observer, nil))
        ok(eq(ref, nil))
        local result = o:subscribe(function() end)

        ok(eq(Observer.is(observer), true))
        ok(eq(result, ref))
    end),

    test("empty", function()
        local o = Observable.empty()

        local result = sub(o)

        ok(result:is({}, nil, true))
    end),

    test("never", function()
        local o = Observable.never()

        local result = sub(o)

        ok(result:is({}, nil, false))
    end),

    test("throw", function()
        local result

        -- simple
        result = sub(Observable.throw("foo"))
        ok(result:is({}, "foo", false))

        -- with formatting
        result = sub(Observable.throw("foo %s", "bar"))
        ok(result:is({}, "foo bar", false))
    end),

    test("of", function()
        local result = sub(Observable.of(1,2,3))

        ok(result:is({1,2,3}, nil, true))
    end),

    test("fromRange", function()
        local result

        result = sub(Observable.fromRange(5))
        ok(result:is({1,2,3,4,5}, nil, true))

        result = sub(Observable.fromRange(2, 5))
        ok(result:is({2,3,4,5}, nil, true))

        result = sub(Observable.fromRange(2, 5, 2))
        ok(result:is({2,4}, nil, true))
    end),

    test("fromTable", function()
        local result

        result = sub(Observable.fromTable({a = "alpha", b = "beta"}))
        ok(result:is(containsOnly({"alpha", "beta"}), nil, true))

        result = sub(Observable.fromTable({a = "alpha", b = "beta"}, pairs, true))
        ok(result:is(containsOnly({{"alpha", "a", n = 2}, {"beta", "b", n = 2}}), nil, true))

        result = sub(Observable.fromTable({"alpha", "beta"}, ipairs))
        ok(result:is({"alpha", "beta"}, nil, true))

        result = sub(Observable.fromTable({"alpha", "beta"}, ipairs, true))
        ok(result:is({{"alpha", 1, n = 2}, {"beta", 2, n = 2}}, nil, true))
    end),

    -- TODO: Tests for `fromCoroutine` and `fromFileByLine`

    test("defer", function()
        local result
        local called = 0

        local o = Observable.defer(function()
            called = called + 1
            return Observable.of(called)
        end)

        ok(eq(called, 0))

        result = sub(o)
        ok(result:is({1}, nil, true))
        ok(eq(called, 1))

        result = sub(o)
        ok(result:is({2}, nil, true))
        ok(eq(called, 2))
    end),

    test("replicate", function()
        local result

        result = sub(Observable.replicate(9, 5))
        ok(result:is({9,9,9,9,9}, nil, true))

        result = sub(Observable.replicate(9, 0))
        ok(result:is({}, nil, true))
    end),

    test("dump completed", function()
        local prints = {}

        -- performs a function with a `test` print function replacement
        local function testPrint(fn)
            local realPrint = _G.print
            _G.print = function(msg)
                insert(prints, msg)
            end
            local ok, result = xpcall(fn, debug.traceback)
            _G.print = realPrint
            if not ok then
                error(result)
            else
                return result
            end
        end

        local s = Subject.create()

        s:dump("foo")

        ok(eq(prints, {}))
        ok(eq(#s.observers, 1))

        testPrint(function()
            s:onNext(1)
        end)

        ok(eq(prints, {"foo onNext: 1"}))
        ok(eq(#s.observers, 1))

        testPrint(function()
            s:onNext(2)
        end)

        ok(eq(prints, {"foo onNext: 1", "foo onNext: 2"}))
        ok(eq(#s.observers, 1))

        testPrint(function()
            s:onCompleted()
        end)

        ok(eq(prints, {"foo onNext: 1", "foo onNext: 2", "foo onCompleted"}))
        ok(eq(#s.observers, 0))
    end),

    test("dump error", function()
        local prints = {}

        -- performs a function with a `test` print function replacement
        local function testPrint(fn)
            local realPrint = _G.print
            _G.print = function(msg)
                insert(prints, msg)
            end
            local ok, result = xpcall(fn, debug.traceback)
            _G.print = realPrint
            if not ok then
                error(result)
            else
                return result
            end
        end

        local s = Subject.create()

        s:dump("foo")

        ok(eq(prints, {}))
        ok(eq(#s.observers, 1))

        testPrint(function()
            s:onNext(1)
        end)

        ok(eq(prints, {"foo onNext: 1"}))
        ok(eq(#s.observers, 1))

        testPrint(function()
            s:onError("error message")
        end)

        ok(eq(prints, {"foo onNext: 1", "foo onError: error message"}))
        ok(eq(#s.observers, 0))
    end),

    test("all", function()
        local s = Subject.create()

        local result = sub(s:all())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("all predicate", function()
        local s = Subject.create()

        -- all results will result in `false`
        local result = sub(s:all(function() return false end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({false}, nil, true))
        ok(eq(#s.observers, 0, "`all` did not unsubscribe on completion"))

        s:onCompleted()
        ok(result:is({false}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("all error", function()
        local s = Subject.create()

        -- all results will result in `false`
        local result = sub(s:all(function() error("fail") end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0, "`all` did not unsubscribe on error"))

        s:onCompleted()
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("firstEmitting a b", function()
        local a, b = Subject.create(), Subject.create()

        local result = sub(Observable.firstEmitting(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext("a")

        ok(result:is({"a"}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        b:onNext("b")
        ok(result:is({"a"}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        b:onCompleted()
        ok(result:is({"a"}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onCompleted()
        ok(result:is({"a"}, nil, true))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("firstEmitting b a", function()
        local a, b = Subject.create(), Subject.create()

        local result = sub(Observable.firstEmitting(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b")

        ok(result:is({"b"}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        a:onNext("a")
        ok(result:is({"b"}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        a:onCompleted()
        ok(result:is({"b"}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onCompleted()
        ok(result:is({"b"}, nil, true))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("firstEmitting cancel", function()
        local a, b = Subject.create(), Subject.create()

        local result = sub(Observable.firstEmitting(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        result.reference:cancel()
        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        a:onNext("a")
        b:onNext("b")
        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("average", function()
        local s = Subject.create()

        local result = sub(s:average())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        s:onNext(2)
        s:onNext(3)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()

        ok(result:is({2}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("average cancelled", function()
        local s = Subject.create()

        local result = sub(s:average())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        result.reference:cancel()

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        s:onNext(3)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))

        s:onCompleted()

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("buffer", function()
        local s = Subject.create()

        local result = sub(s:buffer(3))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1, 2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3, 4)
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(5, 6, 7)
        ok(result:is({{1,2,3,n=3}, {4,5,6, n=3}}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({{1,2,3,n=3}, {4,5,6, n=3}, 7}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("buffer cancel", function()
        local s = Subject.create()

        local result = sub(s:buffer(3))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1, 2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3, 4)
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(5, 6, 7)
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 0))

        s:onCompleted()
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("catch", function()
        local a, b = Subject.create(), Subject.create()

        local result = sub(a:catch(b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onError("foo")
        ok(result:is({1}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onNext(2)
        ok(result:is({1, 2}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onCompleted()
        ok(result:is({1, 2}, nil, true))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("catch cancel", function()
        local a, b = Subject.create(), Subject.create()

        local result = sub(a:catch(b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onError("foo")
        ok(result:is({1}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onNext(2)
        ok(result:is({1, 2}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        result.reference:cancel()
        ok(result:is({1, 2}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        b:onNext(3)
        b:onCompleted()
        ok(result:is({1, 2}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    -- TODO: Test `combineLatest`

    test("compact", function()
        local s = Subject.create()

        local result = sub(s:compact())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        s:onNext(nil)
        s:onNext(3)

        ok(result:is({1, 3}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(nil)
        s:onCompleted()
        ok(result:is({1, 3}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("compact canceled", function()
        local s = Subject.create()

        local result = sub(s:compact())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        s:onNext(nil)
        s:onNext(3)

        ok(result:is({1, 3}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({1, 3}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(4)
        s:onCompleted()
        ok(result:is({1, 3}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("concat", function()
        local a, b, c = Subject.create(), Subject.create(), Subject.create()

        local result = sub(a:concat(b, c))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        a:onNext(10)
        b:onNext(20)
        c:onNext(30)
        ok(result:is({10}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        a:onCompleted()
        ok(result:is({10}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))
        ok(eq(#c.observers, 0))

        b:onNext(21)
        c:onNext(31)
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))
        ok(eq(#c.observers, 0))

        b:onCompleted()
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 1))

        c:onNext(32)
        ok(result:is({10, 21, 32}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 1))

        c:onCompleted()
        ok(result:is({10, 21, 32}, nil, true))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))
    end),

    test("concat error", function()
        local a, b, c = Subject.create(), Subject.create(), Subject.create()

        local result = sub(a:concat(b, c))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        a:onNext(10)
        b:onNext(20)
        c:onNext(30)
        ok(result:is({10}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        a:onCompleted()
        ok(result:is({10}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))
        ok(eq(#c.observers, 0))

        b:onNext(21)
        c:onNext(31)
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))
        ok(eq(#c.observers, 0))

        b:onError("foo")
        ok(result:is({10, 21}, "foo", false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        c:onNext(32)
        ok(result:is({10, 21}, "foo", false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        c:onCompleted()
        ok(result:is({10, 21}, "foo", false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))
    end),


    test("concat cancel", function()
        local a, b, c = Subject.create(), Subject.create(), Subject.create()

        local result = sub(a:concat(b, c))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        a:onNext(10)
        b:onNext(20)
        c:onNext(30)
        ok(result:is({10}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        a:onCompleted()
        ok(result:is({10}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))
        ok(eq(#c.observers, 0))

        b:onNext(21)
        c:onNext(31)
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))
        ok(eq(#c.observers, 0))

        result.reference:cancel()
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        b:onNext(22)
        c:onNext(32)
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        c:onNext(33)
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))

        c:onCompleted()
        ok(result:is({10, 21}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
        ok(eq(#c.observers, 0))
    end),

    test("contains true", function()
        local s = Subject.create()

        local result = sub(s:contains(1))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(0)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("contains false", function()
        local s = Subject.create()

        local result = sub(s:contains(1))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(0)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({false}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("contains nil", function()
        local s = Subject.create()

        local result = sub(s:contains(nil))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(0)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(nil)
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("count", function()
        local s = Subject.create()

        local result = sub(s:count())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(nil)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({2}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("count predicate", function()
        local s = Subject.create()

        local result = sub(s:count(
            function(value) return value ~= nil end
        ))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(nil)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("count cancelled", function()
        local s = Subject.create()

        local result = sub(s:count())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))

        s:onCompleted()
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    -- TODO: Test `debounce`

    test("defaultIfEmpty", function()
        local s = Subject.create()

        local result = sub(s:defaultIfEmpty(1, 2))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({{1,2,n=2}}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("defaultIfEmpty not empty", function()
        local s = Subject.create()

        local result = sub(s:defaultIfEmpty(1, 2))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(0)
        ok(result:is({0}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({0}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("delay", function()
        local s = Subject.create()
        local scheduler = mockScheduler(1)

        local result = sub(s:delay(1, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 0))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 1))

        scheduler:next()
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 1))

        s:onNext(2)
        s:onNext(3)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 3))

        scheduler:next()
        ok(result:is({1, 2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 3))

        scheduler:next()
        ok(result:is({1, 2, 3}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 3))

        s:onCompleted()
        ok(result:is({1, 2, 3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 4))

        scheduler:next()
        ok(result:is({1, 2, 3}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 4))
    end),

    test("delay error", function()
        local s = Subject.create()
        local scheduler = mockScheduler(1)

        local result = sub(s:delay(1, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 0))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 1))

        scheduler:next()
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 1))

        s:onError("foo")
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 2))

        scheduler:next()
        ok(result:is({1}, "foo", false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 2))
    end),

    test("delay cancelled", function()
        local s = Subject.create()
        local scheduler = mockScheduler(2)

        local result = sub(s:delay(2, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 0))

        s:onNext(1)
        s:onNext(2)
        s:onCompleted()

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 3))

        scheduler:next()

        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 3))

        result.reference:cancel()

        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 3))
        ok(eq(scheduler[2], rxTest.CANCELLED))
        ok(eq(scheduler[3], rxTest.CANCELLED))
    end),

    -- TODO: test `distinct`
    -- TODO: test `distinctUntilChanged`
    -- TODO: test `elementAt`

    test("filter", function()
        local s = Subject.create()

        local result = sub(s:filter(function(value)
            return value % 2 == 0
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        s:onNext(4)
        s:onNext(5)
        ok(result:is({2,4}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({2,4}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("filter predicate error", function()
        local s = Subject.create()

        local result = sub(s:filter(function(_)
            error("foo")
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("filter cancelled", function()
        local s = Subject.create()

        local result = sub(s:filter(function(value)
            return value % 2 == 0
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(3)
        s:onCompleted()
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 0))
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
    end),

    test("switchIfEmpty cancelled", function()
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

        result.reference:cancel()
        ok(result:is({"default"}, nil, false))
        -- all subscribers gone
        ok(eq(#original.observers, 0))
        ok(eq(#alt.observers, 0))

        -- complete alt
        alt:onCompleted()
        -- never completes
        ok(result:is({"default"}, nil, false))
        -- all subscribers gone
        ok(eq(#original.observers, 0))
        ok(eq(#alt.observers, 0))
    end),

    test("finalize completed", function()
        local s = Subject.create()
        local handled = 0

        local result = sub(s:finalize(function()
            handled = handled + 1
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(handled, 0))

        s:onCompleted()
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(handled, 1))
    end),

    test("finalize error", function()
        local s = Subject.create()
        local handled = 0

        local result = sub(s:finalize(function()
            handled = handled + 1
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(handled, 0))

        s:onError("foo")
        ok(result:is({1}, "foo", false))
        ok(eq(#s.observers, 0))
        ok(eq(handled, 1))
    end),

    test("finalize handler error", function()
        local s = Subject.create()

        local result = sub(s:finalize(function()
            error("foo")
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({1}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("find", function()
        local s = Subject.create()

        local result = sub(s:find(function(x) return x == true end))

        -- initially...
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        -- send `false`
        s:onNext(false)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        -- send `true`
        s:onNext(true)
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))

        -- send again, gets ignored
        s:onNext(true)
        ok(result:is({true}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("first", function()
        local s = Subject.create()

        local result = sub(s:first())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        s:onCompleted()
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("first empty", function()
        local s = Subject.create()

        local result = sub(s:first())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("next", function()
        local s = Subject.create()

        local result = sub(s:next())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        s:onCompleted()
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("next empty", function()
        local s = Subject.create()

        local result = sub(s:next())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({}, nil, true))
        ok(eq(#s.observers, 0))
    end),

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
        ok(eq(#ifSubject.observers, 1))
        ok(eq(#whenSubject.observers, 0))

        -- send the if
        ifSubject:onNext(true)
        ok(eq(#ifSubject.observers, 1))
        ok(eq(#whenSubject.observers, 1))

        ifSubject:onCompleted()
        ok(result:is({}, nil, false))
        ok(eq(ifValue, true))
        ok(eq(#ifSubject.observers, 0))
        ok(eq(#whenSubject.observers, 1))

        -- send the when
        whenSubject:onNext(true)
        ok(result:is({true}, nil, false))
        ok(eq(ifValue, true))
        ok(eq(#ifSubject.observers, 0))
        ok(eq(#whenSubject.observers, 1))

        -- complete the when
        whenSubject:onCompleted()
        ok(result:is({true}, nil, true))
        ok(eq(ifValue, true))
        ok(eq(#ifSubject.observers, 0))
        ok(eq(#whenSubject.observers, 0))
    end),

    test("flatMapLatest", function()
        local s = Subject.create()
        local inner = {}

        local result = sub(s:flatMapLatest(function(_)
            local o = Subject.create()
            insert(inner, o)
            return o
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#inner, 0))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#inner, 1))
        ok(eq(#inner[1].observers, 1))

        inner[1]:onNext(10)
        ok(result:is({10}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#inner, 1))
        ok(eq(#inner[1].observers, 1))

        s:onNext(2)
        ok(result:is({10}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#inner, 2))
        ok(eq(#inner[1].observers, 0))
        ok(eq(#inner[2].observers, 1))

        inner[1]:onNext(11)
        inner[1]:onCompleted()
        inner[2]:onNext(20)
        inner[2]:onNext(21)
        inner[2]:onCompleted()
        ok(result:is({10, 20, 21}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#inner, 2))
        ok(eq(#inner[1].observers, 0))
        ok(eq(#inner[2].observers, 0))

        s:onCompleted()
        ok(result:is({10, 20, 21}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#inner, 2))
        ok(eq(#inner[1].observers, 0))
        ok(eq(#inner[2].observers, 0))
    end),


    test("flatten", function()
        -- simulates having the outer Observer completing after the inner observers.
        local o = Subject.create()
        local a = Subject.create()
        local b = Subject.create()

        local result = sub(o:flatten())

        ok(result:is({}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        o:onNext(a)
        ok(result:is({}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onNext(10)
        ok(result:is({10}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        o:onNext(b)
        ok(result:is({10}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext(20)
        ok(result:is({10,20}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext(11)
        ok(result:is({10,20,11}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onCompleted()
        ok(result:is({10,20,11}, nil, false))
        ok(eq(#o.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        o:onCompleted()
        ok(result:is({10,20,11}, nil, false))
        ok(eq(#o.observers, 0))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onNext(21)
        ok(result:is({10,20,11,21}, nil, false))
        ok(eq(#o.observers, 0))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onCompleted()
        ok(result:is({10,20,11,21}, nil, true))
        ok(eq(#o.observers, 0))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("ignoreElements", function()
        local s = Subject.create()

        local result = sub(s:ignoreElements())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("last", function()
        local s = Subject.create()

        local result = sub(s:last())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({2}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("map", function()
        local s = Subject.create()

        local result = sub(s:map(function(value)
            return value * 10
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({10}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({10,20}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({10,20}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("merge", function()
        local s = Subject.create()
        local a = Subject.create()
        local b = Subject.create()

        local result = sub(s:merge(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b")
        a:onNext("a")
        s:onNext("s")
        ok(result:is({"b", "a", "s"}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onCompleted()
        a:onNext("a1")
        s:onCompleted()
        ok(result:is({"b", "a", "s", "a1"}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onCompleted()
        ok(result:is({"b", "a", "s", "a1"}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("min", function()
        local s = Subject.create()

        local result = sub(s:min())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        s:onNext(1)
        s:onNext(3)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("min error", function()
        local s = Subject.create()

        local result = sub(s:min())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        s:onNext("a")

        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("reduce", function()
        local s = Subject.create()

        local result = sub(s:reduce(function(last, value)
            return last + value
        end), 0)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({3}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("reduce error", function()
        local s = Subject.create()

        local result = sub(s:reduce(function(last, value)
            return last + value
        end), 0)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext("a")
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("reduce cancelled", function()
        local s = Subject.create()

        local result = sub(s:reduce(function(last, value)
            return last + value
        end), 0)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("pack", function()
        local s = Subject.create()

        local result = sub(s:pack())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1,2,3)
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(4,5,6)
        ok(result:is({{1,2,3,n=3},{4,5,6,n=3}}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({{1,2,3,n=3},{4,5,6,n=3}}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("partition", function()
        local s = Subject.create()

        local a, b = s:partition()

        local resultA, resultB = sub(a), sub(b)

        ok(resultA:is({}, nil, false))
        ok(resultB:is({}, nil, false))
        ok(eq(#s.observers, 2))

        s:onNext(true)
        ok(resultA:is({true}, nil, false))
        ok(resultB:is({}, nil, false))
        ok(eq(#s.observers, 2))

        s:onNext(false)
        ok(resultA:is({true}, nil, false))
        ok(resultB:is({false}, nil, false))
        ok(eq(#s.observers, 2))

        s:onCompleted()
        ok(resultA:is({true}, nil, true))
        ok(resultB:is({false}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("reject", function()
        local s = Subject.create()

        local result = sub(s:reject(function(value)
            return value % 2 ~= 0
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        s:onNext(4)
        s:onNext(5)
        ok(result:is({2,4}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({2,4}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("reject predicate error", function()
        local s = Subject.create()

        local result = sub(s:reject(function(_)
            error("foo")
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))

        s:onNext(2)
        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("reject cancelled", function()
        local s = Subject.create()

        local result = sub(s:reject(function(value)
            return value % 2 ~= 0
        end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(3)
        s:onCompleted()
        ok(result:is({2}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("pluck", function()
        local s = Subject.create()

        local result = sub(s:pluck("foo"))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext({foo = "bar"})
        ok(result:is({"bar"}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({"bar"}, nil, true))
        ok(eq(#s.observers, 0))

    end),

    test("pluck recursive", function()
        local s = Subject.create()

        local result = sub(s:pluck("foo", "yada"))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext({foo = {yada = "bar"}})
        ok(result:is({"bar"}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({"bar"}, nil, true))
        ok(eq(#s.observers, 0))

    end),

    test("retry completed", function()
        local observers = {}
        local cancels = 0
        local o = Observable.create(function(observer)
            insert(observers, observer)
            return Reference.create(function()
                cancels = cancels + 1
            end)
        end)

        local result = sub(o:retry(2))

        ok(result:is({}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 0))

        observers[1]:onNext(1)
        observers[1]:onError("one")

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 1))

        observers[2]:onNext(2)
        observers[2]:onError("two")
        ok(result:is({1,2}, nil, false))
        ok(eq(#observers, 3))
        ok(eq(cancels, 2))

        observers[3]:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(eq(#observers, 3))
        ok(eq(cancels, 3))
    end),

    test("retry error", function()
        local observers = {}
        local cancels = 0
        local o = Observable.create(function(observer)
            insert(observers, observer)
            return Reference.create(function()
                cancels = cancels + 1
            end)
        end)

        local result = sub(o:retry(2))

        ok(result:is({}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 0))

        observers[1]:onNext(1)
        observers[1]:onError("one")

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 1))

        observers[2]:onNext(2)
        observers[2]:onError("two")
        ok(result:is({1,2}, nil, false))
        ok(eq(#observers, 3))
        ok(eq(cancels, 2))

        observers[3]:onError("three")
        ok(result:is({1,2}, "three", false))
        ok(eq(#observers, 3))
        ok(eq(cancels, 3))
    end),

    test("retry cancelled", function()
        local observers = {}
        local cancels = 0
        local o = Observable.create(function(observer)
            insert(observers, observer)
            return Reference.create(function()
                cancels = cancels + 1
            end)
        end)

        local result = sub(o:retry(2))

        ok(result:is({}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 0))

        observers[1]:onNext(1)
        observers[1]:onError("one")

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 1))

        result.reference:cancel()
        ok(result:is({1}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 2))
    end),


    test("retryWithDelay completed", function()
        local observers = {}
        local cancels = 0
        local o = Observable.create(function(observer)
            insert(observers, observer)
            return Reference.create(function()
                cancels = cancels + 1
            end)
        end)
        local scheduler = mockScheduler(5)
        local result = sub(o:retryWithDelay(2, 5, scheduler))

        -- initially, 1 observer
        ok(result:is({}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 0))
        ok(eq(#scheduler, 0))

        -- send a value and then an error
        observers[1]:onNext(1)
        observers[1]:onError("one")

        -- now, 1 value, original observer canceled, new action added to scheduler
        ok(result:is({1}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 1))
        ok(eq(#scheduler, 1))

        -- run the item on the scheduler
        scheduler:next()

        -- now, another observer added
        ok(result:is({1}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 1))
        ok(eq(#scheduler, 1))

        -- send another value and another error
        observers[2]:onNext(2)
        observers[2]:onError("two")

        -- the 2nd observer is cancelled, added another scheduler action
        ok(result:is({1,2}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 2))
        ok(eq(#scheduler, 2))

        -- trigger the next action
        scheduler:next()

        -- 3rd observer added
        ok(result:is({1,2}, nil, false))
        ok(eq(#observers, 3))
        ok(eq(cancels, 2))
        ok(eq(#scheduler, 2))

        -- complete the 3rd observer
        observers[3]:onCompleted()

        -- 3rd observer is cancelled, no additional actions scheduled.
        ok(result:is({1,2}, nil, true))
        ok(eq(#observers, 3))
        ok(eq(cancels, 3))
        ok(eq(#scheduler, 2))
    end),

    test("retryWithDelay error", function()
        local observers = {}
        local cancels = 0
        local o = Observable.create(function(observer)
            insert(observers, observer)
            return Reference.create(function()
                cancels = cancels + 1
            end)
        end)
        local scheduler = mockScheduler(8)

        local result = sub(o:retryWithDelay(2, 8, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 0))
        ok(eq(#scheduler, 0))

        observers[1]:onNext(1)
        observers[1]:onError("one")

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 1))
        ok(eq(#scheduler, 1))

        scheduler:next()

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 1))
        ok(eq(#scheduler, 1))

        observers[2]:onNext(2)
        observers[2]:onError("two")

        ok(result:is({1,2}, nil, false))
        ok(eq(#observers, 2))
        ok(eq(cancels, 2))
        ok(eq(#scheduler, 2))

        scheduler:next()

        ok(result:is({1,2}, nil, false))
        ok(eq(#observers, 3))
        ok(eq(cancels, 2))
        ok(eq(#scheduler, 2))

        observers[3]:onError("three")

        ok(result:is({1,2}, "three", false))
        ok(eq(#observers, 3))
        ok(eq(cancels, 3))
        ok(eq(#scheduler, 2))
    end),

    test("retryWithDelay cancelled", function()
        local observers = {}
        local cancels = 0
        local o = Observable.create(function(observer)
            insert(observers, observer)
            return Reference.create(function()
                cancels = cancels + 1
            end)
        end)
        local scheduler = mockScheduler(3)

        local result = sub(o:retryWithDelay(2, 3, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 0))
        ok(eq(#scheduler, 0))

        observers[1]:onNext(1)
        observers[1]:onError("one")

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 1))
        ok(eq(#scheduler, 1))

        result.reference:cancel()

        ok(result:is({1}, nil, false))
        ok(eq(#observers, 1))
        ok(eq(cancels, 1))
        ok(eq(#scheduler, 1))
        ok(eq(scheduler[1], rxTest.CANCELLED))
    end),

    test("sample", function()
        local s = Subject.create()
        local a = Subject.create()

        local result = sub(s:sample(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- no change, since no 'latest' from `s`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(1)

        -- no change, since no signal from `a`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- emit the latest
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(2)
        s:onNext(3)
        a:onNext("foobar")

        -- emit the latest
        ok(result:is({1,3}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onCompleted()

        -- emit the latest
        ok(result:is({1,3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 1))

        a:onNext(true)
        ok(result:is({1,3,3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 1))

        a:onCompleted()
        ok(result:is({1,3,3}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

    end),

    test("sample source error", function()
        local s = Subject.create()
        local a = Subject.create()

        local result = sub(s:sample(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- no change, since no 'latest' from `s`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(1)

        -- no change, since no signal from `a`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- emit the latest
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(2)
        s:onError("foobar")

        -- error immediately
        ok(result:is({1}, "foobar", false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        a:onNext("foobar")

        -- no more emissions
        ok(result:is({1}, "foobar", false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
    end),

    test("sample sampler error", function()
        local s = Subject.create()
        local a = Subject.create()

        local result = sub(s:sample(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- no change, since no 'latest' from `s`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(1)

        -- no change, since no signal from `a`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- emit the latest
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(2)
        a:onError("foobar")

        -- error immediately
        ok(result:is({1}, "foobar", false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        s:onNext(3)

        -- no more emissions
        ok(result:is({1}, "foobar", false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
    end),


    test("sample cancelled", function()
        local s = Subject.create()
        local a = Subject.create()

        local result = sub(s:sample(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- no change, since no 'latest' from `s`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(1)

        -- no change, since no signal from `a`.
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)

        -- emit the latest
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(2)
        result.reference:cancel()

        -- error immediately
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        s:onNext(3)
        a:onNext(true)

        -- no more emissions
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
    end),

    test("scan", function()
        local s = Subject.create()
        local accumulator, inputs

        local result = sub(s:scan(function(acc, value)
            accumulator = acc
            inputs = value
            return acc * value
        end, 1))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(accumulator, nil))
        ok(eq(inputs, nil))

        s:onNext(10)

        ok(result:is({10}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(accumulator, 1))
        ok(eq(inputs, 10))

        s:onNext(20)
        ok(result:is({10,200}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(accumulator, 10))
        ok(eq(inputs, 20))

        s:onCompleted()
        ok(result:is({10,200}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(accumulator, 10))
        ok(eq(inputs, 20))
    end),

    test("scan error", function()
        local s = Subject.create()
        local accumulator, inputs

        local result = sub(s:scan(function(acc, value)
            accumulator = acc
            inputs = value
            return acc * value
        end, 1))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(accumulator, nil))
        ok(eq(inputs, nil))

        s:onNext(10)

        ok(result:is({10}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(accumulator, 1))
        ok(eq(inputs, 10))

        s:onError("foo")
        ok(result:is({10}, "foo", false))
        ok(eq(#s.observers, 0))
        ok(eq(accumulator, 1))
        ok(eq(inputs, 10))
    end),

    test("scan accumulator error", function()
        local s = Subject.create()
        local result = sub(s:scan(function(_, _)
            error("foo")
        end, 1))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(10)

        ok(result:is({}, notNil(), false))
        ok(eq(#s.observers, 0))
    end),

    test("skip", function()
        local s = Subject.create()
        local result = sub(s:skip(2))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(4)
        ok(result:is({3,4}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({3,4}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("skip cancelled", function()
        local s = Subject.create()
        local result = sub(s:skip(2))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(4)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 0))

        s:onCompleted()
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("skipLast", function()
        local s = Subject.create()
        local result = sub(s:skipLast(2))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(4)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("skipUntil", function()
        local s = Subject.create()
        local a = Subject.create()
        local result = sub(s:skipUntil(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        a:onNext(true)

        s:onNext(3)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(4)
        ok(result:is({3,4}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({3,4}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("skipUntil cancelled", function()
        local s = Subject.create()
        local a = Subject.create()
        local result = sub(s:skipUntil(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        a:onNext(true)

        s:onNext(3)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 1))

        result.reference:cancel()
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 0))

        s:onNext(4)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 0))

        s:onCompleted()
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 0))
    end),

    test("skipWhile", function()
        local s = Subject.create()
        local result = sub(s:skipWhile(function(value) return value < 3 end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        ok(result:is({3}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(4)
        ok(result:is({3,4}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({3,4}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("startWith", function()
        local s = Subject.create()
        local result = sub(s:startWith(1))

        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        s:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))

    end),

    test("sum", function()
        local s = Subject.create()
        local result = sub(s:sum())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        s:onNext(3)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({6}, nil, true))
        ok(eq(#s.observers, 0))

    end),

    test("switch", function()
        local s = Subject.create()
        local a, b = Subject.create(), Subject.create()
        local result = sub(s:switch())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        s:onNext(a)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        a:onNext(10)
        a:onNext(11)
        ok(result:is({10,11}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 0))

        s:onNext(b)
        ok(result:is({10,11}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        a:onNext(12)
        b:onNext(20)

        ok(result:is({10,11,20}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onCompleted()
        ok(result:is({10,11,20}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        s:onCompleted()
        ok(result:is({10,11,20}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("take", function()
        local s = Subject.create()

        local result = sub(s:take(1))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))

        s:onNext(2)

        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
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
        ok(eq(#s.observers, 1))

        -- take the first value and complete
        s:onNext(1)
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))

        -- ignore subsequent values
        s:onNext(2)
        ok(result:is({1}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("takeLast", function()
        local s = Subject.create()
        local result = sub(s:takeLast(2))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(4)
        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({3,4}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("takeUntil", function()
        local s = Subject.create()
        local a = Subject.create()
        local result = sub(s:takeUntil(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(1)

        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        a:onNext(true)
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        s:onNext(3)
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        s:onNext(4)
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        s:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
    end),

    test("takeUntil cancelled", function()
        local s = Subject.create()
        local a = Subject.create()
        local result = sub(s:takeUntil(a))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        s:onNext(1)

        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))

        result.reference:cancel()
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))

        s:onNext(2)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
    end),

    test("takeWhile", function()
        local s = Subject.create()
        local result = sub(s:takeWhile(function(value) return value < 3 end))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)

        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(3)
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))

        s:onNext(4)
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))

        s:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("tap", function()
        local s = Subject.create()
        local nexts = {}
        local message = nil
        local completed = false

        local result = sub(s:tap(
            function(value)
                insert(nexts, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                completed = true
            end
        ))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1)
        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(nexts, {1,2}))
        ok(eq(message, nil))
        ok(eq(completed, false))

        s:onCompleted()
        ok(result:is({1,2}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(nexts, {1,2}))
        ok(eq(message, nil))
        ok(eq(completed, true))
    end),

    test("timeout message", function()
        local s = Subject.create()
        local scheduler = mockScheduler(6)
        local result = sub(s:timeout(6, "Timeout", scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 2))
        ok(eq(scheduler[1], rxTest.CANCELLED))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 3))
        ok(eq(scheduler[2], rxTest.CANCELLED))

        scheduler[3]()
        ok(result:is({1,2}, "Timeout", false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 3))
    end),

    test("timeout switch", function()
        local s = Subject.create()
        local alt = Subject.create()
        local scheduler = mockScheduler(6)
        local result = sub(s:timeout(6, alt, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 2))
        ok(eq(scheduler[1], rxTest.CANCELLED))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 3))
        ok(eq(scheduler[2], rxTest.CANCELLED))

        scheduler[3]()
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 1))
        ok(eq(#scheduler, 3))

        alt:onNext(3)
        ok(result:is({1,2,3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 1))
        ok(eq(#scheduler, 3))

        alt:onCompleted()
        ok(result:is({1,2,3}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 3))

    end),

    test("timeout message cancelled", function()
        local s = Subject.create()
        local scheduler = mockScheduler(6)
        local result = sub(s:timeout(6, "Timeout", scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 2))
        ok(eq(scheduler[1], rxTest.CANCELLED))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#scheduler, 3))
        ok(eq(scheduler[2], rxTest.CANCELLED))

        result.reference:cancel()
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#scheduler, 3))
        ok(eq(scheduler[3], rxTest.CANCELLED))
    end),

    test("timeout switch", function()
        local s = Subject.create()
        local alt = Subject.create()
        local scheduler = mockScheduler(6)
        local result = sub(s:timeout(6, alt, scheduler))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 1))

        s:onNext(1)
        ok(result:is({1}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 2))
        ok(eq(scheduler[1], rxTest.CANCELLED))

        s:onNext(2)
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 3))
        ok(eq(scheduler[2], rxTest.CANCELLED))

        scheduler[3]()
        ok(result:is({1,2}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 1))
        ok(eq(#scheduler, 3))

        alt:onNext(3)
        ok(result:is({1,2,3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 1))
        ok(eq(#scheduler, 3))

        result.reference:cancel()
        ok(result:is({1,2,3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 3))

        alt:onNext(4)
        alt:onCompleted()
        ok(result:is({1,2,3}, nil, false))
        ok(eq(#s.observers, 0))
        ok(eq(#alt.observers, 0))
        ok(eq(#scheduler, 3))
    end),

    test("unpack", function()
        local s = Subject.create()
        local result = sub(s:unpack())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext({1,2,3})
        ok(result:is({{1,2,3,n=3}}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({{1,2,3,n=3}}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("unwrap", function()
        local s = Subject.create()
        local result = sub(s:unwrap())

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(1,2,3)
        ok(result:is({1,2,3}, nil, false))
        ok(eq(#s.observers, 1))

        s:onNext(nil, 5)
        ok(result:is({1,2,3,nil,5,n=5}, nil, false))
        ok(eq(#s.observers, 1))

        s:onCompleted()
        ok(result:is({1,2,3,nil,5,n=5}, nil, true))
        ok(eq(#s.observers, 0))
    end),

    test("with", function()
        local s = Subject.create()
        local a, b = Subject.create(), Subject.create()
        local result = sub(s:with(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        s:onNext(10)
        ok(result:is({{10,n=3}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext(20)
        ok(result:is({{10,n=3}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext(30)
        ok(result:is({{10,n=3}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        s:onNext(11)
        ok(result:is({{10,n=3},{11,20,30,n=3}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onCompleted()
        ok(result:is({{10,n=3},{11,20,30,n=3}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onNext(31)
        ok(result:is({{10,n=3},{11,20,30,n=3}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        s:onNext(12)
        ok(result:is({{10,n=3},{11,20,30,n=3},{12,20,31}}, nil, false))
        ok(eq(#s.observers, 1))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 1))

        b:onNext(32)

        s:onCompleted()
        ok(result:is({{10,n=3},{11,20,30,n=3},{12,20,31}}, nil, true))
        ok(eq(#s.observers, 0))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("zip", function()
        local a = Subject.create()
        local b = Subject.create()

        local result = sub(Observable.zip(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext("a1")

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b1")
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b2")
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b3")
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext("a2")
        ok(result:is({{"a1", "b1",n=2},{"a2", "b2",n=2}}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onCompleted()
        ok(result:is({{"a1", "b1",n=2},{"a2", "b2",n=2}}, nil, true))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        b:onNext("b3")
        b:onCompleted()
        ok(result:is({{"a1", "b1",n=2},{"a2", "b2",n=2}}, nil, true))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("zip error", function()
        local a = Subject.create()
        local b = Subject.create()

        local result = sub(Observable.zip(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext("a1")

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b1")
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onError("foo")
        ok(result:is({{"a1", "b1",n=2}}, "foo", false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        b:onNext("b2")
        b:onCompleted()
        ok(result:is({{"a1", "b1",n=2}}, "foo", false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
    end),

    test("zip cancelled", function()
        local a = Subject.create()
        local b = Subject.create()

        local result = sub(Observable.zip(a, b))

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        a:onNext("a1")

        ok(result:is({}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        b:onNext("b1")
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 1))
        ok(eq(#b.observers, 1))

        result.reference:cancel()
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))

        a:onNext("a2")
        b:onNext("b2")
        b:onCompleted()
        ok(result:is({{"a1", "b1",n=2}}, nil, false))
        ok(eq(#a.observers, 0))
        ok(eq(#b.observers, 0))
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

    test("zip immediate completed", function()
        local a = Subject.create()
        local result = sub(Observable.zip(a, Observable.empty()))

        ok(result:is({}, nil, true))
        ok(eq(#a.observers, 0))
    end)
}
