-- local log		= require("hs.logger").new("t_named")
-- local inspect	= require("hs.inspect")

local require = require

local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"
local named                 = require "named"

local describe, it          = spec.describe, spec.it

return describe "named" {
    it "is constructed"
    :doing(function()
        local o = named(0x01, "Foobar")

        expect(type(o)):is("table")
        expect(named.is(o)):is(true)
        expect(o:name()):is "Foobar"
    end),

    it "is enabled"
    :doing(function()
        local o = named(0x02, "Foobar")

        expect(o:enabled()):is(true)
        expect(o:enabled(false)):is(false)
        expect(o:enabled()):is(false)
    end),

    it "is active"
    :doing(function()
        local o = named(0x03, "Foo")

        expect(o:active()):is(true)
        expect(o:enabled()):is(true)
        o.enabled:toggle()

        expect(o:active()):is(false)

        local bar = named(0x04, "Bar", o)
        expect(bar:enabled()):is(true)
        expect(bar:active()):is(false)

        o.enabled:toggle()
        expect(bar:active()):is(true)
    end),

    it "has 3-character name"
    :doing(function()
        local o = named(0x05, "Foobar")

        o:name3 "Foo"

        expect(o:name3()):is("Foo")
    end)
}
