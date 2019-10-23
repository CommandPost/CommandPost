local spec          = require "cp.spec"
local expect        = require "cp.spec.expect"
local describe, it  = spec.describe, spec.it

local Set           = require("cp.collect.Set")

return describe "cp.collect.Set" {
    it "can be constructed from a vararg of items"
    :doing(function()
        -- the `new` method directly
        local s = Set.of()
        expect(s:size()):is(0)

        -- alternate method, with default items
        s = Set(1, 2, 3)
        expect(s:size()):is(3)
        expect(s:has(1)):is(true)
        expect(s:has(2)):is(true)
        expect(s:has(3)):is(true)
        expect(s:has(4)):is(false)

        expect(s[1]):is(true)
        expect(s[2]):is(true)
        expect(s[3]):is(true)
        expect(s[4]):is(nil)
    end),

    it "can be constructed from a table list"
    :doing(function()
        local s = Set.fromList({1,1,2,3})
        expect(s:size()):is(3)
        expect(s:has(1)):is(true)
        expect(s:has(2)):is(true)
        expect(s:has(3)):is(true)
        expect(s:has(4)):is(false)
    end),

    it "can be constructed from a table map"
    :doing(function()
        local s = Set.fromMap({[1] = true,[2] = true, [3] = false, [4] = "foobar"})
        expect(s:size()):is(2)
        expect(s:has(1)):is(true)
        expect(s:has(2)):is(true)
        expect(s:has(3)):is(false)
        expect(s:has(4)):is(false)
    end),

    it "ignores duplicates"
    :doing(function()
        local s = Set(1,2,2,3,1,2,3)

        expect(s:size()):is(3)
        expect(s[1]):is(true)
        expect(s[2]):is(true)
        expect(s[3]):is(true)
        expect(s[4]):is(nil)
    end),

    it "creates a union from two sets"
    :doing(function()
        local a = Set(1, 2)
        local b = Set(2, 3)

        local u = Set.union(a, b)
        expect(u:size()):is(3)
        expect(u):is(Set(1, 2, 3))
    end),

    it "creates an intersection from two sets"
    :doing(function()
        local a = Set.of(1, 2)
        local b = Set.of(2, 3)
        expect(a:size()):is(2)
        expect(b:size()):is(2)

        local u = Set.intersection(a, b)
        expect(u:size()):is(1)
        expect(u):is(Set(2))
    end),

    it "can be compared with `==` operator"
    :doing(function()
        local a = Set(1, 2)
        local b = Set(2, 1)

        expect(a == b):is(true)
    end),

    it "supports `tostring`"
    :doing(function()
        expect(tostring(Set(1, 2, 3))):is("cp.collect.Set: {1, 2, 3}")
    end),

    it "creates a new set from the difference of two sets"
    :doing(function()
        expect(Set.difference(Set(1, 2, 3), Set(1, 2))):is(Set(3))
    end),

    it "can create a complement of a set"
    :doing(function()
        local a = Set(1,2,3)
        local _a = Set.complement(a)

        expect(a == _a):is(false)

        expect(_a:isComplement()):is(true)
        expect(_a:size()):is(-3)
        expect(_a:has(1)):is(false)
        expect(_a:has(3)):is(false)
        expect(_a:has(4)):is(true)
        expect(_a:has(123456789)):is(true)
        expect(_a:has("foo")):is(true)

        _a = -Set(1,2,3)

        expect(_a:isComplement()):is(true)
        expect(_a:size()):is(-3)
        expect(_a:has(1)):is(false)
        expect(_a:has(3)):is(false)
        expect(_a:has(4)):is(true)
        expect(_a:has(123456789)):is(true)
        expect(_a:has("foo")):is(true)
    end),

    it "can create a complement of a complement"
    :doing(function()
        -- complement of a complement
        local a = Set(1,2,3)
        local _a = -(-a)

        expect(_a):is(a)

        expect(_a:isComplement()):is(false)

        expect(_a:size()):is(3)
        expect(_a:has(1)):is(true)
        expect(_a:has(3)):is(true)
        expect(_a:has(4)):is(false)
        expect(_a:has(123456789)):is(false)
        expect(_a:has("foo")):is(false)
    end),

    it "can represent everything"
    :doing(function()
        local a = Set.everything

        expect(a:isComplement()):is(true)
        expect(a:size()):is(nil)

        expect(a:has(0)):is(true)
        expect(a:has(nil)):is(true)
        expect(a:has("foo")):is(true)
    end),

    it "can represent nothing"
    :doing(function()
        local a = Set.nothing

        expect(a:isComplement()):is(false)
        expect(a:size()):is(0)

        expect(a:has(0)):is(false)
        expect(a:has(nil)):is(false)
        expect(a:has("foo")):is(false)
    end),

    it "creates a union with the `|` operator"
    :doing(function()
        expect(Set(1,2) | Set(2,3)):is(Set(1,2,3))
    end),

    it "creates a union of a set and a complement"
    :doing(function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a | b

        expect(c):is(-Set(4,5))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-2)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(true)
        expect(c:has(2)):is(true)
        expect(c:has(3)):is(true)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),

    it "creates a union of two complements"
    :doing(function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a | b

        expect(c):is(-Set(3))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-1)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(true)
        expect(c:has(2)):is(true)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(true)
        expect(c:has(5)):is(true)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),

    it "creates a union of a complement and a set"
    :doing(function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a | b

        expect(c):is(-Set(1,2))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-2)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(true)
        expect(c:has(4)):is(true)
        expect(c:has(5)):is(true)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),

    it "creates an intersect with the `&` operator"
    :doing(function()
        expect(Set(1,2) & Set(2,3)):is(Set(2))
    end),

    it "creates a set from an intersect of a set a complement"
    :doing(function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a & b

        expect(c):is(Set(1,2))

        expect(c:isComplement()):is(false)
        expect(c:size()):is(2)
        expect(c:has(0)):is(false)
        expect(c:has(1)):is(true)
        expect(c:has(2)):is(true)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(false)
        expect(c:has("foo")):is(false)
    end),

    it "creates a complement from an intersect of two complements"
    :doing(function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a & b

        expect(c):is(-Set(1,2,3,4,5))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-5)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),

    it "creates a set from an intersect of a complement and a set"
    :doing(function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a & b

        expect(c):is(Set(4,5))

        expect(c:isComplement()):is(false)
        expect(c:size()):is(2)
        expect(c:has(0)):is(false)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(true)
        expect(c:has(5)):is(true)
        expect(c:has(6)):is(false)
        expect(c:has("foo")):is(false)
    end),

    it "subtracts items in one set from another set with the `-` operator"
    :doing(function()
        expect(Set(1,2,3) - Set(1,2)):is(Set(3))
        expect(Set(1,2,3) - Set(2,3,4)):is(Set(1))
        expect(Set() - Set(1,2,3)):is(Set())
    end),


    it "subtracts items in a complement from a set with the `-` operator"
    :doing(function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a - b

        expect(c):is(Set(3))

        expect(c:isComplement()):is(false)
        expect(c:size()):is(1)
        expect(c:has(0)):is(false)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(true)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(false)
        expect(c:has("foo")):is(false)
    end),

    it "subtracts the items in one complement from another complement"
    :doing(function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a - b

        expect(c):is(Set(4,5))

        expect(c:isComplement()):is(false)
        expect(c:has(0)):is(false)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(true)
        expect(c:has(5)):is(true)
        expect(c:has(6)):is(false)
        expect(c:has("foo")):is(false)
    end),

    it "creates a complement when performing a symetric difference between a complement and a set"
    :doing(function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a - b

        expect(c):is(-Set(1,2,3,4,5))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-5)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),

    it "creates a set when performing a symetric difference of two sets"
    :doing(function()
        expect(Set(1,2,3) ~ Set(3,4,5)):is(Set(1,2,4,5))
    end),

    it "creates a complement when performing a symetric difference between a set and a complement"
    :doing(function()
        local a = Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a ~ b

        expect(c):is(-Set(1,2,4,5))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-4)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(true)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),

    it "creates a set when performing a symetric difference between a complement and a complement"
    :doing(function()
        local a = -Set(1,2,3)
        local b = -Set(3,4,5)
        local c = a ~ b

        expect(c):is(Set(1,2,4,5))

        expect(c:isComplement()):is(false)
        expect(c:size()):is(4)
        expect(c:has(0)):is(false)
        expect(c:has(1)):is(true)
        expect(c:has(2)):is(true)
        expect(c:has(3)):is(false)
        expect(c:has(4)):is(true)
        expect(c:has(5)):is(true)
        expect(c:has(6)):is(false)
        expect(c:has("foo")):is(false)
    end),

    it "creates a complement when performing a symetric difference between a complement and a set"
    :doing(function()
        local a = -Set(1,2,3)
        local b = Set(3,4,5)
        local c = a ~ b

        expect(c):is(-Set(1,2,4,5))

        expect(c:isComplement()):is(true)
        expect(c:size()):is(-4)
        expect(c:has(0)):is(true)
        expect(c:has(1)):is(false)
        expect(c:has(2)):is(false)
        expect(c:has(3)):is(true)
        expect(c:has(4)):is(false)
        expect(c:has(5)):is(false)
        expect(c:has(6)):is(true)
        expect(c:has("foo")):is(true)
    end),
}