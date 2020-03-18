local require = require

local spec      = require "cp.spec"
local expect    = require "cp.spec.expect"

local describe, it  = spec.describe, spec.it

local class         = require "middleclass"
local lazy          = require "cp.lazy"
local prop          = require "cp.prop"

-- local log           = require "hs.logger" .new "s_lazy"
-- local inspect       = require "hs.inspect"

return describe "cp.lazy" {
    it "will has a static `lazy` table"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        expect(type(Alpha.static.lazy)):is("table")
        expect(type(Alpha.lazy)):is("table")
        expect(Alpha.lazy):is(Alpha.static.lazy)
    end),

    it "can have lazy values"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.value.id()
            count = count + 1
            return count
        end

        local a = Alpha()
        local b = Alpha()

        expect(a.id):is(1)
        expect(count):is(1)
        expect(a.id):is(1)
        expect(count):is(1)

        expect(b.id):is(2)
        expect(count):is(2)
        expect(b.id):is(2)
        expect(count):is(2)
    end),

    it "can have lazy methods"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.method.id()
            count = count + 1
            return count
        end

        local a = Alpha()
        local b = Alpha()

        expect(a:id()):is(1)
        expect(count):is(1)
        expect(a:id()):is(1)
        expect(count):is(1)

        expect(b:id()):is(2)
        expect(count):is(2)
        expect(b:id()):is(2)
        expect(count):is(2)
    end),

    it " can have lazy props"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.prop.id()
            count = count + 1
            return prop.THIS(count)
        end

        local a = Alpha()
        local b = Alpha()

        expect(a:id()):is(1)
        expect(a:id()):is(1)
        expect(b:id()):is(2)
        expect(b:id()):is(2)

        expect(prop.is(a.id)):is(true)
        expect(prop.is(b.id)):is(true)

        expect(a.id:owner()):is(a)
        expect(b.id:owner()):is(b)

        expect(a.id:label()):is("id")
        expect(b.id:label()):is("id")
    end),

    it "will not override a defined method"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        function Alpha.a()
            return "a"
        end

        function Alpha.b()
            return "b"
        end

        function Alpha.lazy.method.b()
            return "bb"
        end

        function Alpha.lazy.method.c()
            return "cc"
        end

        local a = Alpha()

        expect(a:a()):is("a")
        expect.given("lazy methods should not override 'real' methods"):that(a:b()):is("b")
        expect(a:c()):is("cc")
    end),

    it "will pass on lazy properties to subclasses"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.method.id()
            count = count + 1
            return count
        end

        function Alpha.lazy.method.a()
            return "a"
        end

        function Alpha.lazy.method.b()
            return "b"
        end

        local Beta = Alpha:subclass("Beta")

        function Beta.lazy.method.b()
            return "bb"
        end

        local a = Alpha()
        local b = Beta()

        expect(a:id()):is(1)
        expect(a:id()):is(1)
        expect(b:id()):is(2)
        expect(b:id()):is(2)

        expect(a:a()):is("a")
        expect(a:b()):is("b")
        expect(b:a()):is("a")
        expect(b:b()):is("bb")
    end),

    it "is available in initialize"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        function Alpha.lazy.value.id()
            return "a"
        end

        function Alpha:initialize(key)
            self.something = self.id .. key
        end

        local a = Alpha("x")

        expect(a.something):is("ax")
    end),

    it "works if __index is defined on the class directly"
    :doing(function()
        local Alpha = class("Alpha"):include(lazy)

        function Alpha.lazy.value.id()
            return "a"
        end

        function Alpha.__index(_, key)
            if key == "beta" then
                return "b"
            end
        end

        local a = Alpha()

        expect(a.id):is("a")
        expect(a.beta):is("b")
    end),
}