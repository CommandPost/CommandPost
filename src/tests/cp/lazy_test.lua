local test          = require "cp.test"
local lazy          = require "cp.lazy"

-- local log           = require "hs.logger" .new "lazy_test"

return test.suite("cp.lazy"):with {
    test("getFactory", function()
        local alphaMt = {}
        alphaMt.__index = alphaMt
        local alphaFactory = {}
        lazy._setFactory(alphaMt, alphaFactory)

        local a = setmetatable({}, alphaMt)

        ok(eq(lazy._getFactory(a), alphaFactory))

        local aFactory = setmetatable({}, {__index = alphaFactory})
        lazy._setFactory(a, aFactory)

        ok(eq(lazy._getFactory(a), aFactory))
    end),

    test("fn", function()
        local count = 0
        local o = lazy.fn({
            a = "a",
        }) {
            id = function() count = count+1; return count end,
            a = function() return "b" end,
        }

        ok(eq(o:id(), 1)) -- initially 1
        ok(eq(o:id(), 1)) -- still 1

        ok(eq(o.a, "a")) -- doesn't override existing values
    end),

    test("value", function()
        local count = 0
        local o = lazy.value({
            a = "a",
        }) {
            id = function() count = count+1; return count end,
            a = function() return "b" end,
        }

        ok(eq(o.id, 1)) -- initially 1
        ok(eq(o.id, 1)) -- still 1

        ok(eq(o.a, "a")) -- doesn't override existing values.
    end),

    test("subtype", function()
        local alpha = {
            first = function() return 1 end,
            __tostring = function(self)
                return "alpha: " .. self.name
            end
        }

        local beta = {
            second = function() return 2 end,
            __tostring = function(self)
                return "beta: " .. self.name
            end
        }
        -- beta extends alpha
        setmetatable(beta, {__index = alpha})

        local count = 0
        lazy.fn(alpha) {
            id = function()
                count = count+1;
                return count
            end,
        }
        lazy.fn(beta) {
            fromB = function() return true end,
        }

        local a = setmetatable({
            name = "a",
        }, {__index = alpha})

        local b = setmetatable({
            name = "b",
            two = function() return 2 end,
        }, {__index = beta})

        ok(eq(a:id(), 1))
        ok(eq(a:id(), 1))
        ok(eq(b:id(), 2))
        ok(eq(b:id(), 2))
        ok(eq(a:first(), 1))
        ok(eq(b:first(), 1))
        ok(eq(b:second(), 2))
        ok(eq(b:fromB(), true))
    end),
}