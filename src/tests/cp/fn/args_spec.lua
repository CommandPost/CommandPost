local require               = require
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"

local describe, context, it = spec.describe, spec.context, spec.it

local args              = require "cp.fn.args"

return describe "cp.fn.args" {
    context "only" {
        it "should return the specified argument"
        :doing(function()
            local first = args.only(1)
            local second = args.only(2)
            local third = args.only(3)

            expect({first(1, 2, 3)}):is({1})
            expect({second(1, 2, 3)}):is({2})
            expect({third(1, 2, 3)}):is({3})
        end),
    },

    context "from" {
        it "should return all arguments from the index onwards"
        :doing(function()
            local first = args.from(1)
            local second = args.from(2)
            local third = args.from(3)

            expect({first(1, 2, 3)}):is({1, 2, 3})
            expect({second(1, 2, 3)}):is({2, 3})
            expect({third(1, 2, 3)}):is({3})
        end),
    },

    context "pack" {
        it "returns arguments in a table, followed by true"
        :doing(function()
            expect({args.pack(1, 2, 3)}):is({{1, 2, 3}, true})
            expect({args.pack(1, 2, 3, 4)}):is({{1, 2, 3, 4}, true})
        end),

        it "returns no arguments in an empty table, followed by true"
        :doing(function()
            expect({args.pack()}):is({{}, true})
        end),

        it "returns a single table unchanged, followed by false"
        :doing(function()
            expect({args.pack({1, 2, 3})}):is({{1, 2, 3}, false})
        end),

        it "wraps a table followed by a second argument in a table, followed by true"
        :doing(function()
            expect({args.pack({1, 2, 3}, 4)}):is({{{1, 2, 3}, 4}, true})
        end),
    },

    context "unpack" {
        it "unpacks the argument table if packed is true"
        :doing(function()
            expect({args.unpack({1, 2, 3}, true)}):is({1, 2, 3})
        end),

        it "doesn't unpack the argument table if packed is false"
        :doing(function()
            expect({args.unpack({1, 2, 3}, false)}):is({{1, 2, 3}})
        end),
    },

    context "hasNone" {
        it "returns true if no arguments are passed in"
        :doing(function()
            expect(args.hasNone()):is(true)
        end),

        it "returns true if all arguments are nil"
        :doing(function()
            expect(args.hasNone(nil, nil, nil)):is(true)
        end),

        it "returns false if any argument is not nil"
        :doing(function()
            expect(args.hasNone(nil, nil, 1)):is(false)
            expect(args.hasNone(nil, 1, nil)):is(false)
            expect(args.hasNone(1, nil, nil)):is(false)
        end),

        it "returns false if multiple arguments are not nil"
        :doing(function()
            expect(args.hasNone(nil, 1, 2)):is(false)
            expect(args.hasNone(1, nil, 2)):is(false)
            expect(args.hasNone(1, 2, nil)):is(false)
        end),
    },

    context "hasAny" {
        it "returns true if any argument is not nil"
        :doing(function()
            expect(args.hasAny(nil, nil, 1)):is(true)
            expect(args.hasAny(nil, 1, nil)):is(true)
            expect(args.hasAny(1, nil, nil)):is(true)
        end),

        it "returns false if all arguments are nil"
        :doing(function()
            expect(args.hasAny(nil, nil, nil)):is(false)
        end),

        it "returns false if multiple arguments are not nil"
        :doing(function()
            expect(args.hasAny(nil, 1, 2)):is(true)
            expect(args.hasAny(1, nil, 2)):is(true)
            expect(args.hasAny(1, 2, nil)):is(true)
        end),

        it "returns true if no arguments are not nil"
        :doing(function()
            expect(args.hasAny(1, 2, 3)):is(true)
        end),

        it "returns false if no arguments are passed in"
        :doing(function()
            expect(args.hasAny()):is(false)
        end),
    },
}