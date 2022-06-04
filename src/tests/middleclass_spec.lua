-- local log		= require("hs.logger").new("t_middleclass")
-- local inspect	= require("hs.inspect")

local require = require

local spec      = require "cp.spec"
local expect    = require "cp.spec.expect"

local describe, context, it          = spec.describe, spec.context, spec.it

local class     = require "middleclass"

local MyClass = class("MyClass")
local MySubclass = MyClass:subclass("MySubclass")

return describe "middleclass" {

    context "class" {
        it "has a name property on the class"
        :doing(function()
            local Alpha = class("Alpha")

            expect(Alpha.name):is("Alpha")
        end),

        context "isClassFor" {
            it "returns true if the value is a MyClass"
            :doing(function()
                local myInstance = MyClass()
                expect(MyClass:isClassFor(myInstance)):is(true)
                expect(MySubclass:isClassFor(myInstance)):is(false)
            end),
    
            it "returns false if the value is a subclass"
            :doing(function()
                local myInstance = MySubclass()
    
                expect(MyClass:isClassFor(myInstance)):is(false)
                expect(MySubclass:isClassFor(myInstance)):is(true)
            end),
    
            it "returns false if the value is not an instance of the class"
            :doing(function()
                expect(MyClass:isClassFor("foo")):is(false)
            end),
        },
    
        context "isSuperclassFor" {
            it "returns true if the value is a subclass of MyClass"
            :doing(function()
                local myInstance = MySubclass()
                expect(MyClass:isSuperclassFor(myInstance)):is(true)
                expect(MySubclass:isSuperclassFor(myInstance)):is(true)
            end),
    
            it "returns false if the value is not a subclass of MyClass"
            :doing(function()
                local myInstance = MyClass()
                expect(MyClass:isSuperclassFor(myInstance)):is(true)
                expect(MySubclass:isSuperclassFor(myInstance)):is(false)
            end),
    
            it "returns false if the value is not an instance of the class"
            :doing(function()
                expect(MyClass:isSuperclassFor("foo")):is(false)
            end),
        },
    
        context "isSuperclassOf" {
            it "returns true if the value is a subclass of MyClass"
            :doing(function()
                expect(MyClass:isSuperclassOf(MyClass)):is(true)
                expect(MyClass:isSuperclassOf(MySubclass)):is(true)
                expect(MySubclass:isSuperclassOf(MySubclass)):is(true)
            end),
    
            it "returns false if the value is not a subclass of MyClass"
            :doing(function()
                expect(MySubclass:isSuperclassOf(MyClass)):is(false)
            end),
    
            it "returns false if the value is not an instance of the class"
            :doing(function()
                expect(MyClass:isSuperclassOf("foo")):is(false)
            end),
        },
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

            expect(a:isInstanceOf(Alpha)):is(true)
            expect(b:isInstanceOf(Alpha)):is(true)
            expect(a:isInstanceOf(Beta)):is(false)
            expect(b:isInstanceOf(Beta)):is(true)
        end)

    },
}
