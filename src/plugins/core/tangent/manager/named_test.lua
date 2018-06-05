-- local log		= require("hs.logger").new("t_named")
-- local inspect	= require("hs.inspect")

local test = require("cp.test")

local named = require("named")

return test.suite("named"):with(
    test("call", function()
        local o = named()

        ok(eq(o:name(), nil))
    end),

    test("name", function()
        local o = named({})

        ok(eq(tostring(named.xml(o)), ""))

        ok(eq(o:name("Foobar"), o))
        ok(eq(o:name(), "Foobar"))

        ok(eq(o:name3("Foobar"), o))
        ok(eq(o:name3(), "Foo"))

        ok(eq(o:name9(), nil))

        ok(eq(tostring(named.xml(o)), "<Name>Foobar</Name><Name3>Foo</Name3>"))
    end)
)