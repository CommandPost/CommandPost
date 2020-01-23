-- local log		= require("hs.logger").new("t_binding")
-- local inspect	= require("hs.inspect")

local require = require
local test          = require("cp.test")

local binding       = require("binding")
local parameter     = require("parameter")

return test.suite("binding"):with {
    test("new", function()
        local o = binding("Foo")

        ok(o ~= nil)
        ok(eq(o.name, "Foo"))
    end),

    test("member", function()
        local p1 = parameter(0x01)
        local p2 = parameter(0x02)

        local o = binding("Foo")
        o:member(p1)
        o:member(p2)

        ok(eq(o.name, "Foo"))
        ok(eq(o._members, {p1, p2}))

        ok(eq(tostring(o:xml()), [[<Binding name="Foo"><Member id="0x00000001"/><Member id="0x00000002"/></Binding>]]))
    end),

    test("members", function()
        local p1 = parameter(0x01)
        local p2 = parameter(0x02)

        local o = binding("Foo")
        o:members(p1, p2)

        ok(eq(o.name, "Foo"))
        ok(eq(o._members, {p1, p2}))

        ok(eq(tostring(o:xml()), [[<Binding name="Foo"><Member id="0x00000001"/><Member id="0x00000002"/></Binding>]]))
    end),
}
