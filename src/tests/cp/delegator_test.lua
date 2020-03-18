local test          = require "cp.test"
local class         = require "middleclass"
local delegator     = require "cp.delegator"
local prop          = require "cp.prop"
local lazy          = require "cp.lazy"

-- local log           = require "hs.logger" .new "lazy_test"

return test.suite("cp.delegator"):with {
    test("statics", function()
        local Alpha = class("Alpha"):include(delegator)

        ok(eq(type(Alpha.static.delegateTo), "function"))
    end),

    test("simple", function()
        local Alpha = class("Alpha"):include(delegator)

        Alpha:delegateTo("delegated")

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

        Alpha:delegateTo("beta")

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
        ok(eq(a.beta.alphaValue, "betaAlphaValue"))
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

        Alpha:delegateTo("beta")

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
        ok(eq(a:beta().alphaValue, "betaAlphaValue"))
        ok(eq(a:beta().betaValue, "betaValue"))
        ok(eq(a:beta():betaMethod(), "betaValue"))
        ok(eq(a.betaValue, "betaValue"))
        ok(eq(a:betaMethod(), "betaValue"))
    end),

    test("delegate prop", function()
        local Beta = class("Beta")
        function Beta:initialize()
            self.betaValue = "betaValue"
            self.alphaValue = "betaAlphaValue"
            self.betaProp = prop.TRUE():bind(self, "betaProp")
        end

        function Beta:betaMethod()
            return self.betaValue
        end

        local Alpha = class("Alpha"):include(delegator)

        Alpha:delegateTo("beta")

        function Alpha:initialize()
            self.beta = prop.THIS(Beta()):bind(self)
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

        ok(eq(a:beta().alphaValue, "betaAlphaValue"))
        ok(eq(a:beta().betaValue, "betaValue"))
        ok(eq(a:beta():betaMethod(), "betaValue"))
        ok(eq(a.betaValue, "betaValue"))
        ok(eq(a:betaMethod(), "betaValue"))

        ok(eq(a:beta():betaProp(), true))
        ok(eq(a:betaProp(), true))
    end),

    test("override", function()
        local Alpha = class("Alpha"):include(delegator)

        Alpha:delegateTo("delegate")

        function Alpha:initialize()
            self.value = "undelegated"

            self.delegate = {
                value = "delegated",
                getValue = function(this)
                    return this.value
                end,
            }
        end

        local a = Alpha()

        ok(eq(a.value, "undelegated"))
        ok(eq(a.delegate.value, "delegated"))
        ok(eq(a.delegate:getValue(), "delegated"))
        ok(eq(a:getValue(), "delegated"))
    end),

    test("subclass", function()
        local Alpha = class("Alpha"):include(delegator)

        Alpha:delegateTo("aDelegate")

        function Alpha:initialize()
            self.aDelegate = {
                value = "alpha",
            }
        end

        function Alpha.a()
            return "a"
        end

        function Alpha.b()
            return "b"
        end

        local Beta = Alpha:subclass("Beta")

        Beta:delegateTo("bDelegate")

        function Beta:initialize()
            Alpha.initialize(self)

            self.aDelegate.value = "changed alpha"

            self.bDelegate = {
                value = "beta"
            }
        end

        function Beta.b()
            return "bb"
        end

        local a = Alpha()
        local b = Beta()

        ok(eq(a.aDelegate.value, "alpha"))
        ok(eq(a.value, "alpha"))

        ok(eq(b.aDelegate.value, "changed alpha"))
        ok(eq(b.bDelegate.value, "beta"))
        ok(eq(b.value, "beta"))

        ok(eq(a:a(), "a"))
        ok(eq(a:b(), "b"))
        ok(eq(b:a(), "a"))
        ok(eq(b:b(), "bb"))
    end),

    test("lazy first", function()
        local LazyFirst = class("LazyFirst"):include(lazy):include(delegator)
        LazyFirst:delegateTo("delegate")

        function LazyFirst:initialize()
            self.delegate = {
                value = "delegated value"
            }
        end

        function LazyFirst.lazy.value.value()
            return "lazy value"
        end

        local lf = LazyFirst()

        ok(eq(lf.value, "lazy value"))
        ok(eq(lf.delegate.value, "delegated value"))
    end),

    test("lazy second", function()
        local LazySecond = class("LazySecond"):include(delegator):include(lazy)
        LazySecond:delegateTo("delegate")

        function LazySecond:initialize()
            self.delegate = {
                value = "delegated value"
            }
        end

        function LazySecond.lazy.value.value()
            return "lazy value"
        end

        local lf = LazySecond()

        ok(eq(lf.value, "delegated value"))
        ok(eq(lf.delegate.value, "delegated value"))
    end),

    test("delegated prop", function()
        local Alpha = class("Alpha"):include(delegator)
        Alpha:delegateTo("delegate")
    end),

    test("multiple delegates", function()
        local Alpha = class("Alpha"):include(delegator)
            :delegateTo("one", "two")

        function Alpha:initialize()
            self.one = {
                alpha = true
            }

            self.two = {
                alpha = false,
                beta = true,
            }
        end

        local a = Alpha()

        ok(eq(a.alpha, true))
        ok(eq(a.beta, true))

        ok(eq(a.one.alpha, true))
        ok(eq(a.two.alpha, false))
        ok(eq(a.two.beta, true))
    end),

    test("delegate to parent class", function()
        local Alpha = class("Alpha")
        Alpha.static.Beta = class("Beta"):include(delegator)
            :delegateTo("parent")

        function Alpha:initialize(value)
            self.value = value
            self.beta = Alpha.Beta(self)
        end

        function Alpha:alphaMethod()
            return self.value
        end

        function Alpha.Beta:initialize(parent)
            self.parent = parent
            self.value = parent.value .. " beta"
        end

        local a = Alpha("foo")

        ok(eq(a.value, "foo"))
        ok(eq(a.beta.value, "foo beta"))
        ok(eq(a.beta:alphaMethod(), "foo"))
    end),
}