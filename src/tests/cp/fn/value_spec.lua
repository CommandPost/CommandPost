-- Test script for `cp.fn.value`

local require               = require
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"

local describe, context, it = spec.describe, spec.context, spec.it

local value                 = require "cp.fn.value"

return describe "cp.fn.value" {
    context "default" {
        it "can take a list of default values and use the provided values if required"
        :doing(function()
            local default = value.default(1, 2, 3)

            expect({default(5, nil, 6)}):is({5, 2, 6})
            expect({default(5, nil, 6, 7)}):is({5, 2, 6, 7})
            expect({default(5)}):is({5, 2, 3})
        end)
    },

    context "filter" {
        it "returns a value if it matches the predicate"
        :doing(function()
            local filter = value.filter(function(v) return v == 1 end)

            expect(filter(1)):is(1)
            expect(filter(2)):is(nil)
        end)
    },

    context "map" {
        it "transforms the value if it is not nil"
        :doing(function()
            local map = value.map(function(v) return v + 1 end)

            expect(map(1)):is(2)
        end),

        it "ignores the transform function if the value is nil"
        :doing(function()
            local map = value.map(function(v) return v + 1 end)

            expect(map(nil)):is(nil)
        end),
    },

    context "matches" {
        it "returns true if the value matches the predicate"
        :doing(function()
            local matches = value.matches(function(v) return v == 1 end)

            expect(matches(1)):is(true)
            expect(matches(2)):is(false)
        end)
    },

    context "is" {
        it "returns true if the provided value matches the required value"
        :doing(function()
            local is = value.is(1)

            expect(is(1)):is(true)
            expect(is(2)):is(false)
        end),

        it "returns true if the provided value matches the result of the required function"
        :doing(function()
            local is = value.is(function() return 1 end)

            expect(is(1)):is(true)
            expect(is(2)):is(false)
        end),
    },
}
