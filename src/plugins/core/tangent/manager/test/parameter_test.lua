-- local log		= require("hs.logger").new("t_html")
-- local inspect	= require("hs.inspect")

local require = require
local test = require("cp.test")

local parameter = require("parameter")

return test.suite("action"):with {
    test("new", function()
        local o = parameter(0x01, "Foobar")

        ok(o ~= nil)
        ok(eq(o:name(), "Foobar"))
    end),

    test("names", function()
        local o = parameter(0x01)

        ok(eq(o:name("Foobar"), o))
        ok(eq(o:name(), "Foobar"))

        ok(eq(o:name3("Foobar"), o))
        ok(eq(o:name3(), "Foo"))

        ok(eq(o:name9(), nil))

        ok(o:xml(o), [[<Parameter id="0x00000001"><Name>Foobar</Name><Name3>Foo</Name3></Parameter>]])
    end),

    test("properties", function()
        local o = parameter(0x02)

        ok(eq(o:minValue(1), o))
        ok(eq(o:minValue(), 1))

        ok(eq(o:maxValue(100), o))
        ok(eq(o:maxValue(), 100))

        ok(eq(o:stepSize(10), o))
        ok(eq(o:stepSize(), 10))
    end),

    test("get", function()
        local o = parameter(0x03)

        ok(eq(o:get(), nil))

        ok(eq(o:onGet(function() return 1 end), o))
        ok(eq(o:get(), 1))
    end),

    test("change", function()
        local o = parameter(0x43)

        ok(eq(o:change(), nil))

        local value = 0
        ok(eq(o:onGet(function() return value end), o))
        ok(eq(o:onChange(function(increment) value = value + increment end), o))

        ok(eq(o:change(1), 1))
        ok(eq(o:change(5), 6))
        ok(eq(o:change(-1), 5))
    end),

    test("reset", function()
        local o = parameter(0x05)

        local isReset = false
        ok(eq(o:reset(), nil))

        ok(eq(o:onReset(function() isReset = true end), o))
        ok(eq(o:reset(), nil))
        ok(eq(isReset, true))
    end),
}
