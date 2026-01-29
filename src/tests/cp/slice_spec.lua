local spec                  = require("cp.spec")
local expect                = require("cp.spec.expect")
local slice                 = require("cp.slice")

local describe, it, context = spec.describe, spec.it, spec.context

return describe "cp.slice" {
    context "is" {
        it "returns true if the value is a slice"
        :doing(function()
            local t = slice.new({1,2,3,4,5}, 2)
            expect(slice.is(t)):is(true)
        end),

        it "returns false if the value is a regular table"
        :doing(function()
            local t = {1,2,3,4,5}
            expect(slice.is(t)):is(false)
        end),

        it "returns false if the value any other type"
        :doing(function()
            expect(slice.is(nil)):is(false)
            expect(slice.is(1)):is(false)
            expect(slice.is("hello")):is(false)
            expect(slice.is(true)):is(false)
        end),
    },

    context "new" {
        it "returns a new slice of a table from an index"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)
        end),

        it "returns a new slice of a table from a range"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 3)
            expect(s):is({2,3,4})
            expect(#s):is(3)
        end),

        it "returns a new slice of a table where the count exceeds the original table contents"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 10)
            expect(s):is({2,3,4,5,nil,nil,nil,nil,nil,nil})
            expect(#s):is(10)
        end),

        it "returns an empty table where the start index is higher than the original table count"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 10)
            expect(s):is({})
            expect(#s):is(0)
        end),

        it "throws an error when the start index is less than 1"
        :doing(function(this)
            local t = {1,2,3,4,5}

            this:expectAbort("start index must be 1 or higher, but was 0")
            slice.new(t, 0)
        end),

        -- it "throws an error when the table is not a table"
        -- :doing(function(this)
        --     this:expectAbort("expected table, got nil")
        --     slice.new(nil, 1)
        -- end),

        it "throws an error when the count is less than 0"
        :doing(function(this)
            local t = {1,2,3,4,5}

            this:expectAbort("invalid count: -1")
            slice.new(t, 1, -1)
        end),
    },

    context "from" {
        it "returns a new slice when given a non-slice table"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.from(t)
            expect(s):is({1,2,3,4,5})
            expect(#s):is(5)
        end),

        it "returns the same slice when given a slice table"
        :doing(function()
            local t = {1,2,3,4,5}
            local s0 = slice.new(t, 2)
            local s = slice.from(s0)
            expect(s):is(s0)
            expect(#s):is(4)
        end),

        it "throws an error when the value is not a slice or table"
        :doing(function(this)
            this:expectAbort("expected table or slice, got number")
            slice.from(1)
        end),
    },

    context "drop" {
        it "returns a new slice which is shifted by the specified number of items, and the length is reduced by the specified number of items"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 3)
            expect(s):is({2,3,4})
            expect(#s):is(3)
            local s2 = s:drop(1)
            expect(s2):is({3,4})
            expect(#s2):is(2)

            local s3 = s2:drop(1)
            expect(s3):is({4})
            expect(#s3):is(1)

            expect(s):is({2,3,4})
            expect(#s):is(3)
        end),

        it "returns an empty table when the count matches the slice length"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 3)
            expect(s):is({2,3,4})
            expect(#s):is(3)
            local s2 = s:drop(3)
            expect(s2):is({})
            expect(#s2):is(0)
        end),

        it "throws an error when the count is less than 0"
        :doing(function(this)
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 3)
            expect(s):is({2,3,4})
            expect(#s):is(3)

            this:expectAbort("invalid drop: -1")
            s:drop(-1)
        end),

        it "throws an error when the count is greater than the slice length"
        :doing(function(this)
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 3)
            expect(s):is({2,3,4})
            expect(#s):is(3)

            this:expectAbort("dropping 4 but only 3 are available")
            s:drop(4)
        end),
    },

    context "pop" {
        it "returns the first item from the front of the slice"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(#s):is(4)
            local v, s2 = s:pop()
            expect(v):is(2)
            expect(s2):is({3,4,5})
            expect(#s2):is(3)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)
        end),

        it "throws an error when the slice is empty"
        :doing(function(this)
            local t = {1}
            local s = slice.new(t, 2)

            this:expectAbort("pop from empty slice")
            s:pop()
        end),
    },

    context "shift" {
        it "shifts the slice by the specified number of items"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)

            local s2 = s:shift(2)
            expect(s2):is({4,5,nil,nil})
            expect(#s2):is(4)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)
        end),
    },

    context "split" {
        it "splits the slice into two slices"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)
            local s1, s2 = s:split(2)
            expect(s1):is({2,3})
            expect(s2):is({4,5})
            expect(#s1):is(2)
            expect(#s2):is(2)
        end),

        it "splits the slice into two slices where the count equals the original table contents"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)
            local s1, s2 = s:split(4)
            expect(s1):is({2,3,4,5})
            expect(s2):is({})
            expect(#s1):is(4)
            expect(#s2):is(0)
        end),

        -- it "splits the slice into two slices where the count exceeds the original table contents"
        -- :doing(function(this)
        --     local t = {1,2,3,4,5}
        --     local s = slice.new(t, 2)
        --     expect(s):is({2,3,4,5})
        --     expect(#s):is(4)
        --     this:expectAbort("split size (10) is greater than slice size (4)")
        --     local _, _ = s:split(10)
        -- end),
    },

    context "clone" {
        it "returns a new slice with the same contents"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(s):is({2,3,4,5})
            expect(#s):is(4)
            local s2 = s:clone()
            expect(s2):is({2,3,4,5})
            expect(#s2):is(4)
        end),
    }
}