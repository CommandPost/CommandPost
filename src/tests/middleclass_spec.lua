-- local log		= require("hs.logger").new("t_middleclass")
-- local inspect	= require("hs.inspect")

local require = require

local spec      = require "cp.spec"
local expect    = require "cp.spec.expect"

local describe, context, it          = spec.describe, spec.context, spec.it

local class     = require "middleclass"

return describe "middleclass" {

    context "class" {
        it "has a name property on the class"
        :doing(function()
            local Alpha = class("Alpha")

            expect(Alpha.name):is("Alpha")
        end),
    },

    context "instance" {

        it "has a name property on the instance"
        :doing(function()
            local Alpha = class("Alpha")

            function Alpha:initialize(name)
                self.name = name
            end

            expect(Alpha.name):is("Alpha")

            local a1 = Alpha("one")
            expect(a1.name):is("one")
            expect(Alpha.name):is("Alpha")
        end),

        it "has a name method on the instance"
        :doing(function()
            local Alpha = class("Alpha")

            function Alpha:initialize(name)
                self._name = name
            end

            function Alpha:name()
                return self._name
            end

            expect(Alpha.name):is("Alpha")

            local a1 = Alpha("one")
            expect(a1:name()):is("one")
            expect(Alpha.name):is("Alpha")
        end),

        it "can test if a value is an instance of a class"
        :doing(function()
            local Alpha = class "Alpha"
            local Beta = Alpha:subclass "Beta"

            local a = Alpha()
            local b = Beta()

            expect(Alpha:isClassFor(a)):is(true)
            expect(Alpha:isClassFor(b)):is(true)
            expect(Beta:isClassFor(a)):is(false)
            expect(Beta:isClassFor(b)):is(true)

            expect(Alpha:isClassFor(nil)):is(false)
            expect(Alpha:isClassFor(123)):is(false)
            expect(Alpha:isClassFor("Alpha")):is(false)
            expect(Alpha:isClassFor(true)):is(false)
        end)

    },
}
