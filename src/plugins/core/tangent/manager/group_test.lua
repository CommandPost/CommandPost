-- local log		= require("hs.logger").new("t_binding")
-- local inspect	= require("hs.inspect")

local test          = require("cp.test")

local group         = require("group")

return test.suite("group"):with {
    test("new", function()
        local o = group.new("Foo")

        ok(o ~= nil)
        ok(eq(o.name, "Foo"))
    end),

    test("parameter", function()
        local o = group.new("Foo")
        o:parameter(0x01):name("Bar")

        ok(eq(o.name, "Foo"))

        ok(eq(tostring(o:xml()), [[<Group name="Foo"><Parameter id="0x00000001"><Name>Bar</Name></Parameter></Group>]]))
    end),

    test("group", function()
        local o = group.new("Foo")
        o:group("Bar")

        ok(eq(o.name, "Foo"))

        ok(eq(tostring(o:xml()), [[<Group name="Foo"><Group name="Bar"></Group></Group>]]))
    end),

    test("enabled", function()
        local o = group.new("Foo")

        ok(eq(o:enabled(), true))
        ok(eq(o:enabled(false), false))
        ok(eq(o:enabled(), false))
    end),

    test("active", function()
        local o = group.new("Foo")

        ok(eq(o:enabled(), true))
        ok(eq(o:active(), true))
        o.enabled:toggle()

        ok(eq(o:active(), false))

        local bar = o:group("Bar")
        ok(eq(bar:enabled(), true))
        ok(eq(bar:active(), false))

        o.enabled:toggle()
        ok(eq(bar:active(), true))
    end)
}