local test          = require "cp.test"
local class         = require "middleclass"
local lazy          = require "cp.lazy"
local prop          = require "cp.prop"

-- local log           = require "hs.logger" .new "lazy_test"

return test.suite("cp.lazy"):with {
    test("statics", function()
        local Alpha = class("Alpha"):include(lazy)

        ok(eq(type(Alpha.static.lazy), "table"))
        ok(eq(type(Alpha.lazy), "table"))
        ok(eq(Alpha.lazy, Alpha.static.lazy))
    end),

    test("value", function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.value.id()
            count = count + 1
            return count
        end

        local a = Alpha()
        local b = Alpha()

        ok(eq(a.id, 1))
        ok(eq(a.id, 1))
        ok(eq(b.id, 2))
        ok(eq(b.id, 2))
    end),

    test("method", function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.method.id()
            count = count + 1
            return count
        end

        local a = Alpha()
        local b = Alpha()

        ok(eq(a:id(), 1))
        ok(eq(a:id(), 1))
        ok(eq(b:id(), 2))
        ok(eq(b:id(), 2))
    end),

    test("prop", function()
        local Alpha = class("Alpha"):include(lazy)

        local count = 0
        function Alpha.lazy.prop.id()
            count = count + 1
            return prop.THIS(count)
        end

        local a = Alpha()
        local b = Alpha()

        ok(eq(a:id(), 1))
        ok(eq(a:id(), 1))
        ok(eq(b:id(), 2))
        ok(eq(b:id(), 2))

        ok(prop.is(a.id), true)
        ok(prop.is(b.id), true)

        ok(eq(a.id:owner(), a))
        ok(eq(b.id:owner(), b))

        ok(eq(a.id:label(), "id"))
        ok(eq(b.id:label(), "id"))
    end),

    test("override", function()
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

        ok(eq(a:a(), "a"))
        ok(eq(a:b(), "b"), "lazy methods should not override 'real' methods")
        ok(eq(a:c(), "cc"))
    end),

    test("subclass", function()
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

        ok(eq(a:id(), 1))
        ok(eq(a:id(), 1))
        ok(eq(b:id(), 2))
        ok(eq(b:id(), 2))

        ok(eq(a:a(), "a"))
        ok(eq(a:b(), "b"))
        ok(eq(b:a(), "a"))
        ok(eq(b:b(), "bb"))
    end),

    test("in initialize", function()
        local Alpha = class("Alpha"):include(lazy)

        function Alpha.lazy.value.id()
            return "a"
        end

        function Alpha:initialize(key)
            self.something = self.id .. key
        end

        local a = Alpha("x")

        ok(eq(a.something, "ax"))
    end),
}