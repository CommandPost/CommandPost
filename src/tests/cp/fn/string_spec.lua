local require               = require
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"

local describe, context, it = spec.describe, spec.context, spec.it

local fnstring              = require "cp.fn.string"

return describe "cp.fn.string" {
    context "match" {
        it "should return true if the pattern matches and doesn't have groups"
        :doing(function()
            local hello = fnstring.match("hello")

            expect(hello("hello")):is("hello")
            expect(hello("goodbye")):is(nil)
        end),

        it "should return each group as a string if the pattern matches and has groups"
        :doing(function()
            local helloX = fnstring.match("(%w+) (%w+)")

            expect(helloX("hello world")):is("hello", "world")
            expect(helloX("goodbye world")):is("goodbye", "world")

            local hello, location = helloX("hello world")
            expect(hello):is("hello")
            expect(location):is("world")
        end),
    }
}