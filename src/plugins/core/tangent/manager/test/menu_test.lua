-- local log		= require("hs.logger").new("t_html")
-- local inspect	= require("hs.inspect")

local require = require
local test = require("cp.test")

local menu = require("menu")

return test.suite("menu"):with {
    test("new", function()
        local o = menu(0x01)

        ok(o ~= nil)
        ok(eq(o.id, 0x01))
    end),

    test("names", function()
        local o = menu(0x02)

        ok(eq(o:name("Foobar"), o))
        ok(eq(o:name(), "Foobar"))

        ok(eq(o:name3("Foobar"), o))
        ok(eq(o:name3(), "Foo"))

        ok(eq(o:name9(), nil))

        ok(o:xml(o), [[<Menu id="0x00000001"><Name>Foobar</Name><Name3>Foo</Name3></Menu>]])
    end),

    test("next", function()
        local o = menu(0x03)
        local next = false

        ok(eq(o:onNext(function() next = true end), o))
        ok(eq(o:next(), nil))
        ok(eq(next, true))
    end),

    test("prev", function()
        local o = menu(0x03)
        local prev = false

        ok(eq(o:onPrev(function() prev = true end), o))
        ok(eq(o:prev(), nil))
        ok(eq(prev, true))
    end),

    test("get", function()
        local o = menu(0x03)

        ok(eq(o:onGet(function() return "success" end), o))
        ok(eq(o:get(), "success"))
    end),
}
