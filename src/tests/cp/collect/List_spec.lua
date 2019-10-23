local spec          = require "cp.spec"
local expect        = require "cp.spec.expect"
local describe, it  = spec.describe, spec.it

local List          = require("cp.collect.List")

return describe "cp.collect.List" {
    it "can be constructed with a variable set of arguments"
    :doing(function()
        -- the `new` method directly
        local l = List.of()
        expect(#l):is(0)

        -- alternate method, with default items
        l = List(1, 2, 3)
        expect(#l):is(3)
        expect(l[1]):is(1)
        expect(l[2]):is(2)
        expect(l[3]):is(3)
    end),

    it "can have a preset size"
    :doing(function()
        local l = List.sized(10)
        expect(#l):is(10)

        local max
        for k,v in ipairs(l) do
            max = k
            expect(v):is(nil)
        end
        expect(max):is(10)
    end),

    it "can have a preset size with default values"
    :doing(function()
        local l = List.sized(10, "foo")
        expect(#l):is(10)

        local max
        for k,v in ipairs(l) do
            max = k
            expect(v):is("foo")
        end
        expect(max):is(10)
    end),

    it "can have values assigned by index"
    :doing(function()
        local l = List()

        l[1] = "one"
        expect(#l):is(1)
        expect(l[1]):is("one")

        l[5] = "five"
        expect(#l):is(5)
        expect(l[5]):is("five")
    end),

    it "can have the size set after construction"
    :doing(function()
        local l = List()

        expect(#l):is(0)

        l:size(4)
        expect(#l):is(4)

        l = List(1,2,3)
        expect(#l):is(3)

        l:size(1)
        expect(#l):is(1)
        expect(l[1]):is(1)
        expect(l[2]):is(nil)
        expect(l[3]):is(nil)

    end),

    it "can be trimmed to a specific size"
    :doing(function()
        local l = List(1,2,3,nil,nil,nil)

        expect(#l):is(6)

        l:trim(5)
        expect(#l):is(5)

        l:trim()
        expect(#l):is(3)

        l:trim(1)
        expect(#l):is(3)
    end),
}