-- local log		= require("hs.logger").new("t_group")
-- local inspect	= require("hs.inspect")

local require = require

local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"
local group                 = require "group"

local describe, it          = spec.describe, spec.it

return describe "group" {
    it "is constructed"
    :doing(function()
        local o = group "Foo"

        expect(o):isNot(nil)
        expect(o:name()):is "Foo"
    end),

    it "is constructed with no name"
    :doing(function(this)
        this:expectAbort("Group names cannot be empty")
        group:new()
    end),

    it "has a parameter"
    :doing(function()
        local o = group "Foo"
        expect(tostring(o:xml())):is [[<Group name="Foo"></Group>]]

        o:parameter(0x01):name "Bar"

        expect(o:name()):is "Foo"
        expect(tostring(o:xml())):is [[<Group name="Foo"><Parameter id="0x00000001"><Name>Bar</Name></Parameter></Group>]]
    end),

    it "has a group"
    :doing(function()
        local o = group("Foo")
        o:group "Bar"

        expect(o:name()):is "Foo"

        expect(tostring(o:xml())):is [[<Group name="Foo"><Group name="Bar"></Group></Group>]]
    end),

    it "is enabled"
    :doing(function()
        local o = group "Foo"

        expect(o:enabled()):is(true)
        expect(o:enabled(false)):is(false)
        expect(o:enabled()):is(false)
    end),

    it "is active"
    :doing(function()
        local o = group "Foo"

        expect(o:enabled()):is(true)
        expect(o:active()):is(true)
        o.enabled:toggle()

        expect(o:active()):is(false)

        local bar = o:group "Bar"
        expect(bar:enabled()):is(true)
        expect(bar:active()):is(false)

        o.enabled:toggle()
        expect(bar:active()):is(true)
    end)
}
