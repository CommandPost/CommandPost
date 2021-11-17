-- test spec for `cp.fn`
local require               = require
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"

local describe, context, it = spec.describe, spec.context, spec.it

local pack                  = table.pack
local unpack                = table.unpack

local fn                    = require "cp.fn"

local private = fn._private

-- local log                  = require "hs.logger" .new "fn_spec"

local function incr(x) return x + 1 end
local function double(x) return x * 2 end
local function square(x) return x * x end
local function add(x, y) return x + y end
local function zero() return 0 end

-- clone(x) -> function(value) -> ...
-- Function
-- Returns a function that returns `x` copies of the value passed to it.
--
-- Parameters:
--  * x - The number of copies to return.
--
-- Returns:
--  * A function that returns `x` copies of the value passed to it.
local function clone(x)
    return function(value)
        local result = {}
        for i = 1, x+1 do
            result[i] = value
        end
        return unpack(result)
    end
end

local function concat(...)
    -- log.df("concat: args: %s", hs.inspect(pack(...)))
    return table.concat(pack(...))
end

local function filter(predicate, ...)
    local inputs = pack(...)
    local outputs = {}
    for i = 1, #inputs do
        if predicate(inputs[i]) then
            outputs[#outputs + 1] = inputs[i]
        end
    end
    return unpack(outputs)
end

return describe "cp.fn" {
    context "all" {
        it "returns ${result} if given ${first} and ${second}"
        :doing(function(this)
            local check = fn.all(fn.constant(this.first), fn.constant(this.second))
            expect(check()):is(this.result)
        end)
        :where {
            { "first",  "second",   "result"    },
            { true,     true,       true        },
            { true,     false,      false       },
            { false,    true,       false       },
            { false,    false,      false       },
        }
    },

    context "any" {
        it "returns ${result} if given ${first} and ${second}"
        :doing(function(this)
            local check = fn.any(fn.constant(this.first), fn.constant(this.second))
            expect(check()):is(this.result)
        end)
        :where {
            { "first",  "second",   "result"   },
            { true,     true,        true      },
            { true,     false,       true      },
            { false,    true,        true      },
            { false,    false,       false     },
        },
    },

    context "call" {
        it "should call a function with no arguments"
        :doing(function()
            local result = fn.call(zero)
            expect(result):is(0)
            expect(result):is(0)
        end),

        it "should call a function with one argument"
        :doing(function()
            local result = fn.call(incr, 1)
            expect(result):is(2)
            expect(result):is(2)
        end),
    },

    context "chain" {
        it "can chain two functions"
        :doing(function()
            local incrThenDouble = fn.chain(incr, double)

            expect(incrThenDouble(1)):is(4)
        end),

        it "can chain three functions"
        :doing(function()
            local incrThenDoubleThenSquare = fn.chain(incr, double, square)

            expect(incrThenDoubleThenSquare(1)):is(16)
        end),

        it "can chain a function with more than one input to a fuction with only one input"
        :doing(function()
            local addThenIncr = fn.chain(add, incr)

            expect(addThenIncr(1, 2)):is(4)
        end),

        it "can chain a single function and expect the result of that function"
        :doing(function()
            local incrChained = fn.chain(incr)

            expect(incrChained(1)):is(2)
        end),

        it "can chain no functions and return the input unchanged"
        :doing(function()
            local nothingChained = fn.chain()

            expect(nothingChained(1)):is(1)
        end),

        it "will chain a list of strings which are all filtered out to be concatenated into a nil value"
        :doing(function()
            local filteredConcat = fn.chain(filter, concat)

            expect(filteredConcat(function(value) return value > "z" end, "a", "b", "c")):is(nil)
        end),

        it "will not execute the second function when the first function returns nil"
        :doing(function()
            local calls = 0
            local function countCalls()
                calls = calls + 1
            end

            local filteredCount = fn.chain(filter, countCalls)

            expect(filteredCount(function(value) return value > "z" end, "a", "b", "c")):is(nil)
            expect(calls):is(0)
        end),

        it "chains with the same result with three functions as nesting the functions in multiple chains"
        :doing(function()
            local incrThenDoubleThenSquare = fn.chain(incr, double, square)
            local incrThenDoubleThenSquare2 = fn.chain(fn.chain(fn.chain(incr), double), square)

            expect(incrThenDoubleThenSquare(1)):is(16)
            expect(incrThenDoubleThenSquare2(1)):is(16)
        end),

        context "//>>" {
            it "calls a single function"
            :doing(function()

                local chained = fn.chain // incr
                expect(chained(2)):is(3)
            end),

            it "calls two functions when they both return a value"
            :doing(function()
                local calls = 0
                local function countCalls(...)
                    calls = calls + 1
                    return ...
                end
                local chained = fn.chain // countCalls >> countCalls

                expect(chained(true)):is(true)
                expect(calls):is(2)
            end),

            it "will not execute the second function when the first function returns nil"
            :doing(function()
                local calls = 0
                local function countCalls()
                    calls = calls + 1
                end
                local chained = fn.chain // countCalls >> countCalls

                expect(chained(true)):is(nil)
                expect(calls):is(1)
            end),

            it "will call three functions when they all return a value"
            :doing(function()
                local calls = 0
                local function countCalls(...)
                    calls = calls + 1
                    return ...
                end
                local chained = fn.chain // countCalls >> countCalls >> countCalls

                expect(chained(true)):is(true)
                expect(calls):is(3)
            end),
        },
    },

    context "compare" {
        it "should use natural sort order if not passed any comparators"
        :doing(function()
            local compare = fn.compare()

            expect(compare("a", "b")):is(true)
            expect(compare("b", "a")):is(false)
            expect(compare("a", "a")):is(false)
        end),

        it "should use the first comparator if passed one"
        :doing(function()
            local compare = fn.compare(function(a, b) return a > b end)

            expect(compare("a", "b")):is(false)
            expect(compare("b", "a")):is(true)
            expect(compare("a", "a")):is(false)
        end),

        it "should sort an unordered list of points by x first then by y if the x values are equal"
        :doing(function()
            local compare = fn.compare(function(a, b) return a.x < b.x end, function(a, b) return a.y < b.y end)

            local points = {
                { x = 1, y = 2 },
                { x = 2, y = 2 },
                { x = 2, y = 1 },
                { x = 1, y = 1 },
            }

            table.sort(points, compare)

            expect(points[1]):is({ x = 1, y = 1 })
            expect(points[2]):is({ x = 1, y = 2 })
            expect(points[3]):is({ x = 2, y = 1 })
            expect(points[4]):is({ x = 2, y = 2 })
            expect(points[5]):is(nil)
        end),
    },

    context "compose" {
        it "can compose two functions"
        :doing(function()
            local doubleThenIncr = fn.compose(incr, double)

            expect(doubleThenIncr(1)):is(3)
        end),

        it "can compose three functions"
        :doing(function()
            local squareThenDoubleThenIncr = fn.compose(incr, double, square)

            expect(squareThenDoubleThenIncr(1)):is(3)
            expect(squareThenDoubleThenIncr(2)):is(9)
        end),

        it "can compose a function with more than one input to a fuction with only one input"
        :doing(function()
            local addThenIncr = fn.compose(incr, add)

            expect(addThenIncr(1, 2)):is(4)
        end),

        it "can compose an array of three functions"
        :doing(function()
            local incrThenDoubleThenSquare = fn.compose({square, double, incr})

            expect(incrThenDoubleThenSquare(1)):is(16)
        end),
    },

    context "constant" {
        it "should return a function that always returns the same value"
        :doing(function()
            local constant = fn.constant(1)

            expect(constant()):is(1)
            expect(constant()):is(1)
        end),
    },

    context "curry" {
        it "can curry a function with one argument"
        :doing(function()
            local incrCurried = fn.curry(incr, 1)

            expect(incrCurried(1)):is(2)
        end),

        it "can curry a function with two arguments"
        :doing(function()
            local addCurried = fn.curry(add, 2)

            expect(addCurried(1)(2)):is(3)
        end),

        it "can concat 4 values"
        :doing(function()
            local concatCurried = fn.curry(concat, 4)

            expect(concatCurried("a")("b")("c")("d")):is("abcd")
        end),
    },

    context "flip" {
        it "can flip a curried function concatenating two strings"
        :doing(function()
            local concatFlipped = fn.flip(fn.curry(concat, 2))

            expect(concatFlipped("b")("a")):is("ab")
        end),

        it "can flip a curried function concatenating three strings"
        :doing(function()
            local concatFlipped = fn.flip(fn.curry(concat, 3))

            expect(concatFlipped("b")("a")("c")):is("abc")
        end),
    },

    context "fork" {
        it "can fork with a single function"
        :doing(function()
            local incrForked = fn.fork(incr)
            local a, b = incrForked(1)

            expect(a):is(2)
            expect(b):is(nil)
        end),

        it "can fork with two functions"
        :doing(function()
            local incrAndDouble = fn.fork(incr, double)
            local a, b, c = incrAndDouble(5)

            expect(a):is(6)
            expect(b):is(10)
            expect(c):is(nil)
        end),

        it "can fork with two functions in a table"
        :doing(function()
            local incrAndDouble = fn.fork({incr, double})
            local a, b = incrAndDouble(5)

            expect(a):is({6, 10})
            expect(b):is(nil)
        end),

        it "can fork with two functions that return multiple values each"
        :doing(function()
            local clone1and2 = fn.fork(clone(1), fn.pipe(double, clone(2)))
            local a1, a2, b1, b2, b3, x = clone1and2(5)

            expect(a1):is(5)
            expect(a2):is(5)
            expect(b1):is(10)
            expect(b2):is(10)
            expect(b3):is(10)
            expect(x):is(nil)
        end),
    },

    context "identity" {
        it "should return the input"
        :doing(function()
            local identity = fn.identity

            expect(identity(1)):is(1)
            expect(identity("a")):is("a")
            expect(identity(true)):is(true)
            expect(identity(nil)):is(nil)

            local one, two, three = identity(1, 2, 3)
            expect(one):is(1)
            expect(two):is(2)
            expect(three):is(3)
        end),
    },

    context "over" {
        it "can apply a incr to a table containing an integer"
        :doing(function()
            local a = {value = 1}
            local incrOver = fn.over(function(tx)
                return function(s)
                    return {value = tx(s.value)}
                end
            end, incr)

            expect(incrOver(a)):is({value = 2})
        end),
    },

    context "pipe" {
        it "can pipe two functions"
        :doing(function()
            local incrThenDouble = fn.pipe(incr, double)

            expect(incrThenDouble(1)):is(4)
        end),

        it "can pipe three functions"
        :doing(function()
            local incrThenDoubleThenSquare = fn.pipe(incr, double, square)

            expect(incrThenDoubleThenSquare(1)):is(16)
        end),

        it "can pipe a function with more than one input to a fuction with only one input"
        :doing(function()
            local addThenIncr = fn.pipe(add, incr)

            expect(addThenIncr(1, 2)):is(4)
        end),

        it "can pipe a single function and expect the result of that function"
        :doing(function()
            local incrPiped = fn.pipe(incr)

            expect(incrPiped(1)):is(2)
        end),

        it "can pipe no functions and return the input unchanged"
        :doing(function()
            local nothingPiped = fn.pipe()

            expect(nothingPiped(1)):is(1)
        end),

        it "can pipe a filtered list of strings to be concatenated into a single string"
        :doing(function()
            local filteredConcat = fn.pipe(filter, concat)

            expect(filteredConcat(function(value) return value > "a" end, "a", "b", "c")):is("bc")
        end),

        it "will pipe a list of strings which are all filtered out to be concatenated into an empty string"
        :doing(function()
            local filteredConcat = fn.pipe(filter, concat)

            expect(filteredConcat(function(value) return value > "z" end, "a", "b", "c")):is("")
        end),

        it "will execute the second function when the first function returns nil"
        :doing(function()
            local calls = 0
            local function countCalls()
                calls = calls + 1
            end

            local filteredCount = fn.pipe(filter, countCalls)

            expect(filteredCount(function(value) return value > "z" end, "a", "b", "c")):is(nil)
            expect(calls):is(1)
        end),
    },

    context "prefix" {
        it "returns a function prefixing 'foo'"
        :doing(function()
            local prefixFoo = fn.prefix(concat, "foo")

            expect(prefixFoo("bar")):is("foobar")
            expect(prefixFoo("baz")):is("foobaz")
        end),

        it "returns a function prefixing 'a' and 'b' to the value"
        :doing(function()
            local concatAB = fn.prefix(concat, "a", "b")

            expect(concatAB("c")):is("abc")
            expect(concatAB("d", "e")):is("abde")
        end),
    },

    context "reduce" {
        it "can reduce a list of values to a single value"
        :doing(function()
            local sum = fn.reduce(add, 0, 1, 2, 3, 4)

            expect(sum):is(10)
        end),
    },

    context "resolve" {
        it "can resolve a function with no arguments"
        :doing(function()
            local function noArgs()
                return "foo"
            end

            expect(fn.resolve(noArgs)):is("foo")
        end),

        it "can resolve a function with arguments"
        :doing(function()
            local function withArgs(a, b, c)
                return a .. b .. c
            end

            expect(fn.resolve(withArgs, "a", "b", "c")):is("abc")
        end),

        it "can resolve a non-function value"
        :doing(function()
            expect(fn.resolve("foo")):is("foo")
        end),
    },

    context "set" {
        it "can set a value in a table"
        :doing(function()
            local a = {value = 1}
            local setValue = fn.set(fn.table.mutate("value"), 2)

            expect(setValue(a)):is({value = 2})
        end),
    },

    context "uncurry" {
        it "can uncurry a curried function"
        :doing(function()
            local addCurried = fn.curry(add, 2)
            local addUncurried = fn.uncurry(addCurried, 2)

            expect(addUncurried(1, 2)):is(3)
        end),

        it "can partially uncurry a curried concat"
        :doing(function()
            local concat4Curried = fn.curry(concat, 4)
            local concat2Uncurried = fn.uncurry(concat4Curried, 2)

            expect(concat2Uncurried("a", "b")("c")("d")):is("abcd")
        end),
    },

    context "with" {
        it "returns a function that calls the given function with the given argument"
        :doing(function()
            local addWithTwo = fn.with(2, add)

            expect(addWithTwo(1)):is(3)
        end),
    },

    context "function composition" {
        it "can use with to double a string length"
        :doing(function()
            local doubleLen = fn.pipe(string.len, double)
            local concatDoubleLen = fn.pipe(concat, doubleLen)
            local concatDoubleLenString = fn.pipe(concatDoubleLen, tostring)

            expect(doubleLen("alpha")):is(10)
            expect(doubleLen("beta")):is(8)

            expect(concatDoubleLen("alpha", "beta")):is(18)
            expect(concatDoubleLen("alpha", "beta", "gamma")):is(28)

            expect(concatDoubleLenString("alpha", "beta")):is("18")
        end),
    },

    context "private" {

        context "_chain2" {
            it "calls the second function if the first function returns a value"
            :doing(function()
                local calls = 0
                local function countCalls(value)
                    calls = calls + 1
                    return value
                end

                local zeroCount = private._chain2(zero, countCalls)

                expect(zeroCount()):is(0)
                expect(calls):is(1)
            end),

            it "does not call the second function if the first function returns nil"
            :doing(function()
                local calls = 0
                local function countCalls(value)
                    calls = calls + 1
                    return value
                end

                local zeroCount = private._chain2(function() return nil end, countCalls)

                expect(zeroCount()):is(nil)
                expect(calls):is(0)
            end),
        },

        context "_chainN" {
            it "calls the last function if the first function returns a value"
            :doing(function()
                local calls = 0
                local function countCalls(value)
                    calls = calls + 1
                    return value
                end

                local zeroCount = private._chainN(zero, countCalls)

                expect(zeroCount()):is(0)
                expect(calls):is(1)
            end),

            it "does not call the last function if the first function returns nil"
            :doing(function()
                local calls = 0
                local function countCalls(value)
                    calls = calls + 1
                    return value
                end

                local chained = private._chainN(function() return nil end, countCalls)

                expect(chained()):is(nil)
                expect(calls):is(0)
            end),

            it "calls all three functions if all return a value"
            :doing(function()
                local calls = 0
                local function countCalls(value)
                    calls = calls + 1
                    return value
                end

                local chained = private._chainN(countCalls, countCalls, countCalls)

                expect(chained(1)):is(1)
                expect(calls):is(3)
            end),

            it "stops after the second function if it returns nil"
            :doing(function()
                local calls = 0
                local function countCalls(value)
                    calls = calls + 1
                    return value
                end

                local chained = private._chainN(
                    countCalls,
                    function()
                        calls = calls+1
                        return nil
                    end,
                    countCalls
                )

                expect(chained(1)):is(nil)
                expect(calls):is(2)
            end),
        },

        context("_callIfHasArgs") {
            it "calls the function if any argument is not nil"
            :doing(function()
                local calls = 0
                local function countCalls(...)
                    calls = calls + 1
                    return ...
                end

                local callIfHasArgs = private._callIfHasArgs

                expect({callIfHasArgs(countCalls, 1, nil, nil)}):is({1})
                expect(calls):is(1)
                expect({callIfHasArgs(countCalls, nil, true, nil)}):is({nil, true, nil})
                expect(calls):is(2)
            end),

            it "doesn't call the function if all argument values are nil"
            :doing(function()
                local calls = 0
                local function countCalls(...)
                    calls = calls + 1
                    return ...
                end

                local callIfHasArgs = private._callIfHasArgs

                expect({callIfHasArgs(countCalls, nil, nil, nil)}):is({})
                expect(calls):is(0)
            end),
        }
    }
}