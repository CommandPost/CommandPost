-- test spec for `cp.fn.table`
local require               = require
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"

local describe, context, it = spec.describe, spec.context, spec.it

-- local log                   = require "hs.logger" .new "table_spec"

local fntable               = require "cp.fn.table"

local function incr(x) return x + 1 end
local function double(x) return x * 2 end

return describe "cp.fn.table" {
    context "call" {
        it "should call a named property on a table, passing on the result"
        :doing(function()
            local t = {
                x = 1
            }
            function t:add(y)
                self.x = self.x + y
            end

            local callAdd2 = fntable.call("add", 2)

            -- calling doesn't return anything
            expect(callAdd2(t)):is(nil)
            -- but the table is updated
            expect(t.x):is(3)
        end)
    },

    context "copy" {
        it "should copy the table"
        :doing(function()
            local t = {1, 2, 3}
            local result = fntable.copy(t)
            expect(result):is(t)
        end),

        it "should not modify the original when modifying the copy"
        :doing(function()
            local t = {1, 2, 3}
            local result = fntable.copy(t)
            result[1] = 10
            expect(t[1]):is(1)
        end),
    },

    context "filter" {
        it "can filter vowels from a list of characters"
        :doing(function()
            local vowels = fntable.filter(function(value) return value:match("[aeiou]") end)

            local result = vowels({"o", "r", "a", "n", "g", "e"})
            -- sort because the order of the array is not guaranteed
            table.sort(result)

            expect(result):is({"a", "e", "o"})
        end),
    },

    context "first" {
        it "can retrieve the first value from a table"
        :doing(function()
            expect(fntable.first({1, 2, 3})):is(1)
        end),

        it "returns the only item from a single-item table"
        :doing(function()
            expect(fntable.first({1})):is(1)
        end),

        it "returns nil from an empty table"
        :doing(function()
            expect(fntable.first({})):is(nil)
        end),
    },

    context "get" {
        it "can get a value from a table"
        :doing(function()
            local a = {value = 1}

            local value = fntable.get("value")

            expect(value(a)):is(1)
        end),

        it "returns nil if the value doesn't exist in the table"
        :doing(function()
            local a = {value = 1}

            local value2 = fntable.get("value2")

            expect(value2(a)):is(nil)
        end),

        it "returns index values from a table"
        :doing(function()
            local a = {1, 2, 3}

            local value1 = fntable.get(1)
            local value2 = fntable.get(2)
            local value3 = fntable.get(3)
            local value4 = fntable.get(4)

            expect(value1(a)):is(1)
            expect(value2(a)):is(2)
            expect(value3(a)):is(3)
            expect(value4(a)):is(nil)
        end),
    },

    context "ifilter" {
        it "can filter vowels from a list of characters"
        :doing(function()
            local vowels = fntable.ifilter(function(value) return value:match("[aeiou]") end)

            local result = vowels({"o", "r", "a", "n", "g", "e"})

            expect(result):is({"o", "a", "e"})
        end),
    },

    context "imap" {
        it "can map a function over an ordered table"
        :doing(function()
            expect(fntable.imap(double, {1, 2, 3})):is({2, 4, 6})
        end),

        it "can map a function over a list of values"
        :doing(function()
            local a, b, c, d = fntable.imap(double, 1, 2, 3)
            expect(a):is(2)
            expect(b):is(4)
            expect(c):is(6)
            expect(d):is(nil)
        end),

        it "maps over ordered values and ignores key values in a table"
        :doing(function()
            local result = fntable.imap(double, {1, 2, 3, a = 1, b = 2, c = 3})
            expect(result):is({2, 4, 6})
        end),
    },

    context "last" {
        it "can retrieve the last value from a table"
        :doing(function()
            expect(fntable.last({1, 2, 3})):is(3)
        end),

        it "returns the only value from a single-item table"
        :doing(function()
            expect(fntable.last({1})):is(1)
        end),

        it "returns nil from an empty table"
        :doing(function()
            expect(fntable.last({})):is(nil)
        end),
    },

    context "map" {
        it "can map over an unordered table"
        :doing(function()
            local result = fntable.map(double, {1, 2, 3})
            table.sort(result)
            expect(result):is({2, 4, 6})
        end),

        it "can map over a table with key values"
        :doing(function()
            local result = fntable.map(double, {a = 1, b = 2, c = 3})
            table.sort(result)
            expect(result):is({a = 2, b = 4, c = 6})
        end),
    },

    context "mutate" {
        it "can increment a number value in a table"
        :doing(function()
            local table = {value = 1}
            local incrValue = fntable.mutate("value")(incr)

            local mutated = incrValue(table)

            expect(mutated):is({value = 2})
        end),
    },

    context "set" {
        it "can set a value in a table"
        :doing(function()
            local table = {}
            local value100 = fntable.set("value", 100)

            local mutated = value100(table)

            expect(mutated):is({value = 100})
        end),
    },

    context "sort" {
        it "can sort an unsorted table of strings"
        :doing(function()
            local t = {"c", "a", "b"}
            local naturalSort = fntable.sort()

            expect(naturalSort(t)):is({"a", "b", "c"})
        end),

        it "can sort an unsorted table of strings with an reverse comparator function"
        :doing(function()
            local t = {"c", "a", "b"}
            local reverseSort = fntable.sort(function(a, b) return a > b end)

            expect(reverseSort(t)):is({"c", "b", "a"})
        end),

        it "can sort an unsorted table of points with a comparator that sorts by x and another that sorts by y"
        :doing(function()
            local t = {
                {x = 1, y = 2},
                {x = 2, y = 2},
                {x = 3, y = 4},
                {x = 2, y = 1},
            }
            local compareX = function(a, b)
                return a.x < b.x
            end
            local compareY = function(a, b)
                return a.y < b.y
            end
            local sortByXorY = fntable.sort(compareX, compareY)

            expect(sortByXorY(t)):is({
                {x = 1, y = 2},
                {x = 2, y = 1},
                {x = 2, y = 2},
                {x = 3, y = 4},
            })
        end),

        it "should not modify the original unordered list after sorting"
        :doing(function()
            local t = {"c", "a", "b"}
            local naturalSort = fntable.sort()

            expect(naturalSort(t)):is({"a", "b", "c"})
            expect(t):is({"c", "a", "b"})
        end),
    },

    context "split" {
        it "can split an array of random numbers whenever a number is 0"
        :doing(function()
            local t = {1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9}
            local splitter = fntable.split(function(value) return value == 0 end)
            local segments, splits = splitter(t)

            expect(segments):is({
                {1, 2, 3},
                {4, 5, 6},
                {7, 8, 9},
            })
            expect(splits):is({0, 0})
        end),

        it "returns a table with empty tables when the array only contains predicate matches"
        :doing(function()
            local t = {0, 0, 0}
            local splitter = fntable.split(function(value) return value == 0 end)
            local segments, splits = splitter(t)

            expect(segments):is({{}, {}, {}, {}})
            expect(splits):is({0, 0, 0})
        end),
    },

    context "zip" {
        it "zips two arrays into a single array with all values"
        :doing(function()
            local a = {1, 2, 3}
            local b = {4, 5, 6}

            local zipped = fntable.zip(a, b)

            expect(zipped[1]):is({1,4})
            expect(zipped[2]):is({2,5})
            expect(zipped[3]):is({3,6})
        end),

        it "zips three arrays into a single array with all values"
        :doing(function()
            local a = {1, 2, 3}
            local b = {4, 5, 6}
            local c = {7, 8, 9}

            local zipped = fntable.zip(a, b, c)

            expect(zipped[1]):is({1,4,7})
            expect(zipped[2]):is({2,5,8})
            expect(zipped[3]):is({3,6,9})
        end),

        it "zips a list of three arrays into a single array with all values"
        :doing(function()
            local a = {1, 2, 3}
            local b = {4, 5, 6}
            local c = {7, 8, 9}

            local zipped = fntable.zip({a, b, c})

            expect(zipped[1]):is({1,4,7})
            expect(zipped[2]):is({2,5,8})
            expect(zipped[3]):is({3,6,9})
        end),

        it "zips an array of numbers with the names of each number"
        :doing(function()
            local numbers = {1, 2, 3}
            local names = {"one", "two", "three"}

            local zipped = fntable.zip(numbers, names)

            expect(zipped[1]):is({1,"one"})
            expect(zipped[2]):is({2,"two"})
            expect(zipped[3]):is({3,"three"})
        end),

        it "zips two arrays with different lengths with the result being the minimum length"
        :doing(function()
            local a = {1, 2, 3}
            local b = {4, 5}

            local zipped = fntable.zip(a, b)

            expect(zipped[1]):is({1,4})
            expect(zipped[2]):is({2,5})
            expect(zipped[3]):is(nil)
        end),
    },

    context "zipAll" {
        it "zips two arrays into a single array with all values"
        :doing(function()
            local a = {1, 2, 3}
            local b = {4, 5, 6}

            local zipped = fntable.zipAll(a, b)

            expect(zipped[1]):is({1,4})
            expect(zipped[2]):is({2,5})
            expect(zipped[3]):is({3,6})
        end),

        it "zips two arrays of different length with the result being the maximum length"
        :doing(function()
            local a = {1, 2, 3}
            local b = {4, 5}

            local zipped = fntable.zipAll(a, b)

            expect(zipped[1]):is({1,4})
            expect(zipped[2]):is({2,5})
            expect(zipped[3]):is({3,nil})
            expect(zipped[4]):is(nil)
        end),
    },
}
