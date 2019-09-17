local test          = require "cp.test"
local class         = require "middleclass"
local delegator      = require "cp.delegator"
local prop          = require "cp.prop"

-- local log           = require "hs.logger" .new "lazy_test"

return test.suite("cp.delegator"):with {
    test("statics", function()
        local Alpha = class("Alpha"):include(delegator)

        ok(eq(type(Alpha.static.delegateTo), "function"))
        ok(eq(type(Alpha.delegates), "table"))
        ok(eq(Alpha.lazy, Alpha.static.lazy))
    end),

    test("simple", function()
        local Alpha = class("Alpha"):include(delegator)

        Alpha.delegateTo("delegated")

        function Alpha:initialize()
            self.delegated = {
                delegatedValue = "delegatedValue"
            }
            self.alphaValue = "alphaValue"
        end

        local a = Alpha()

        ok(eq(a.alphaValue, "alphaValue"))
        ok(eq(a.delegatedValue, "delegatedValue"))
        ok(eq(a.delegated.delegatedValue, "delegatedValue"))
    end),

    test("delegate value", function()
        local Beta = class("Beta")
        function Beta:initialize()
            self.betaValue = "betaValue"
            self.alphaValue = "betaAlphaValue"
        end

        function Beta:betaMethod()
            return self.betaValue
        end

        local Alpha = class("Alpha"):include(delegator)

        Alpha.delegateTo("beta")

        function Alpha:initialize()
            self.beta = Beta()
            self.alphaValue = "alphaValue"
        end

        function Alpha:alphaMethod()
            return self.alphaValue
        end

        local a = Alpha()

        ok(eq(a.alphaValue, "alphaValue"))
        ok(eq(a:alphaMethod(), "alphaValue"))
        ok(eq(a.beta.alphaValue, "alphaBetaValue"))
        ok(eq(a.beta.betaValue, "betaValue"))
        ok(eq(a.beta:betaMethod(), "betaValue"))
        ok(eq(a.betaValue, "betaValue"))
        ok(eq(a:betaMethod(), "betaValue"))
    end),

    test("delegate method", function()
        local Beta = class("Beta")
        function Beta:initialize()
            self.betaValue = "betaValue"
            self.alphaValue = "betaAlphaValue"
        end

        function Beta:betaMethod()
            return self.betaValue
        end

        local Alpha = class("Alpha"):include(delegator)

        Alpha.delegateTo("beta")

        function Alpha:initialize()
            self._beta = Beta()
            self.alphaValue = "alphaValue"
        end

        function Alpha:beta()
            return self._beta
        end

        function Alpha:alphaMethod()
            return self.alphaValue
        end

        local a = Alpha()

        ok(eq(a.alphaValue, "alphaValue"))
        ok(eq(a:alphaMethod(), "alphaValue"))
        ok(eq(a.beta.alphaValue, "alphaBetaValue"))
        ok(eq(a.beta.betaValue, "betaValue"))
        ok(eq(a.beta:betaMethod(), "betaValue"))
        ok(eq(a.betaValue, "betaValue"))
        ok(eq(a:betaMethod(), "betaValue"))
    end),

    test("delegate prop", function()
        local Beta = class("Beta")
        function Beta:initialize()
            self.betaValue = "betaValue"
            self.alphaValue = "betaAlphaValue"
        end

        function Beta:betaMethod()
            return self.betaValue
        end

        local Alpha = class("Alpha"):include(delegator)

        Alpha.delegateTo("beta")

        function Alpha:initialize()
            self.beta = prop.THIS(Beta())
            self.alphaValue = "alphaValue"
        end

        function Alpha:beta()
            return self._beta
        end

        function Alpha:alphaMethod()
            return self.alphaValue
        end

        local a = Alpha()

        -- delegate methods should not override parent methods.
        ok(eq(a.alphaValue, "alphaValue"))
        ok(eq(a:alphaMethod(), "alphaValue"))

        ok(eq(a.beta.alphaValue, "alphaBetaValue"))
        ok(eq(a.beta.betaValue, "betaValue"))
        ok(eq(a.beta:betaMethod(), "betaValue"))
        ok(eq(a.betaValue, "betaValue"))
        ok(eq(a:betaMethod(), "betaValue"))
    end),

    test("subclass", function()
        local Alpha = class("Alpha"):include(delegator)

        function Alpha:initialize()
            self.delegated = {
                delegatedValue = "delegatedValue",
                betaValue = "delegatedBeta"
            }
        end

        local Beta = Alpha:subclass("Beta")

        function Beta.lazy.method.b()
            return "bb"
        end

        local a = Alpha()
        local b = Beta()

        ok(eq(a:id(), 1))
        ok(eq(a:id(), 1))
        ok(eq(b:id(), 2))
        ok(eq(b:id(), 2))

        ok(eq(a:a(), "a"))
        ok(eq(a:b(), "b"))
        ok(eq(b:a(), "a"))
        ok(eq(b:b(), "bb"))
    end),
}