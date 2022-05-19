local spec                  = require("cp.spec")
local expect                = require("cp.spec.expect")
local slice                 = require("cp.slice")

local describe, it, context = spec.describe, spec.it, spec.context

return describe "cp.slice" {
    context "new" {
        it "returns a new slice of a table from an index"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2)
            expect(s):is({2,3,4,5})
        end),

        it "returns a new slice of a table from a range"
        :doing(function()
            local t = {1,2,3,4,5}
            local s = slice.new(t, 2, 3)
            expect(s):is({2,3,4})
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

        it "throws an error when the table is not a table"
        :doing(function(this)
            this:expectAbort("expected table, got nil")
            slice.new(nil, 1)
        end),

        it "throws an error when the count is less than 0"
        :doing(function(this)
            local t = {1,2,3,4,5}

            this:expectAbort("invalid count: -1")
            slice.new(t, 1, -1)
        end),
    }
}