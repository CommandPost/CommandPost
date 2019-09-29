local interpolate = require "cp.interpolate"

local spec = require "cp.spec"
local expect = require "cp.spec.expect"

local describe, it = spec.describe, spec.it

return describe "cp.interpolate" {
    it "does nothing without tokens"
    :doing(function()
        expect(interpolate("foobar")):is("foobar")
    end),

    it "replaces a single token"
    :doing(function()
        expect(interpolate("Hello ${world}", { world = "Earth" })):is("Hello Earth")
    end),

    it "replaces a formatted token"
    :doing(function()
        expect(interpolate("Hello ${world:04d}", { world = 512 })):is("Hello 0512")
    end),

}