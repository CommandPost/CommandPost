-- local log		= require("hs.logger").new("t_html")
-- local inspect	= require("hs.inspect")

local test = require("cp.test")

local action = require("action")

return test.suite("action"):with {
    test("new", function()
        local o = action.new(0x01)

        ok(o ~= nil)
        ok(eq(o.id, 0x01))
    end),

	test("names", function()
        local o = action.new(0x01)

        ok(eq(o:name("Foobar"), o))
        ok(eq(o:name(), "Foobar"))

        ok(eq(o:name3("Foobar"), o))
        ok(eq(o:name3(), "Foo"))

        ok(eq(o:name9(), nil))

        ok(eq(tostring(o:xml()), [[<Action id="0x00000001"><Name>Foobar</Name><Name3>Foo</Name3></Action>]]))
    end),

    test("press", function()
        local pressed = false
        local o = action.new(0x01)
            :onPress(function() pressed = true end)

        ok(eq(pressed, false))

        o:press()
        ok(eq(pressed, true))
    end),

    test("release", function()
        local released = false
        local o = action.new(0x01)
            :onRelease(function() released = true end)

        ok(eq(released, false))

        o:release()
        ok(eq(released, true))
    end),
}