local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it
local expect        = require "cp.spec.expect"

local class         = require "middleclass"
local delegator     = require "cp.delegator"
local prop          = require "cp.prop"
local lazy          = require "cp.lazy"

-- local log           = require "hs.logger" .new "lazy_test"

return describe "cp.delegator" {
    it "configures the class"
    :doing(function()
        local Alpha = class("Alpha"):include(delegator)

        expect(type(Alpha.static.delegateTo)):is("function")
    end),

    it "delegates table values"
    :doing(function()
        local Alpha = class("Alpha"):include(delegator)

        Alpha:delegateTo("delegated")

        function Alpha:initialize()
            self.delegated = {
                delegatedValue = "delegatedValue"
            }
            self.alphaValue = "alphaValue"
        end

        local a = Alpha()

        expect(a.alphaValue):is("alphaValue")
        expect(a.delegatedValue):is("delegatedValue")
        expect(a.delegated.delegatedValue):is("delegatedValue")
    end),

    it "delegates to classes"
    :doing(function()
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

        expect(a.alphaValue):is("alphaValue")
        expect(a:alphaMethod()):is("alphaValue")
        expect(a.beta.alphaValue):is("betaAlphaValue")
        expect(a.beta.betaValue):is("betaValue")
        expect(a.beta:betaMethod()):is("betaValue")
        expect(a.betaValue):is("betaValue")
        expect(a:betaMethod()):is("betaValue")
    end),

    it "delegates methods"
    :doing(function()
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

        expect(a.alphaValue):is("alphaValue")
        expect(a:alphaMethod()):is("alphaValue")
        expect(a:beta().alphaValue):is("betaAlphaValue")
        expect(a:beta().betaValue):is("betaValue")
        expect(a:beta():betaMethod()):is("betaValue")
        expect(a.betaValue):is("betaValue")
        expect(a:betaMethod()):is("betaValue")
    end),

    it "delegates cp.prop"
    :doing(function()
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
        expect(a.alphaValue):is("alphaValue")
        expect(a:alphaMethod()):is("alphaValue")

        expect(a:beta().alphaValue):is("betaAlphaValue")
        expect(a:beta().betaValue):is("betaValue")
        expect(a:beta():betaMethod()):is("betaValue")
        expect(a.betaValue):is("betaValue")
        expect(a:betaMethod()):is("betaValue")

        expect(a:beta():betaProp()):is(true)
        expect(a:betaProp()):is(true)
    end),

    it "executes delegated methods relative to the delegate"
    :doing(function()
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

        expect(a.value):is("undelegated")
        expect(a.delegate.value):is("delegated")
        expect(a.delegate:getValue()):is("delegated")
        expect(a:getValue()):is("delegated")
    end),

    it "inherits delegations from superclasses"
    :doing(function()
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

        expect(a.aDelegate.value):is("alpha")
        expect(a.value):is("alpha")

        expect(b.aDelegate.value):is("changed alpha")
        expect(b.bDelegate.value):is("beta")
        expect(b.value):is("beta")

        expect(a:a()):is("a")
        expect(a:b()):is("b")
        expect(b:a()):is("a")
        expect(b:b()):is("bb")
    end),

    it "prioritises lazy values if lazy is included first"
    :doing(function()
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

        expect(lf.value):is("lazy value")
        expect(lf.delegate.value):is("delegated value")
    end),

    it "prioritises delegated values if lazy is included second"
    :doing(function()
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

        expect(lf.value):is("delegated value")
        expect(lf.delegate.value):is("delegated value")
    end),

    it "delegates to multiple targets in left-to-right order"
    :doing(function()
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

        expect(a.alpha):is(true)
        expect(a.beta):is(true)

        expect(a.one.alpha):is(true)
        expect(a.two.alpha):is(false)
        expect(a.two.beta):is(true)
    end),

    it "delegates to parent class"
    :doing(function()
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

        expect(a.value):is("foo")
        expect(a.beta.value):is("foo beta")
        expect(a.beta:alphaMethod()):is("foo")
    end),
}