local spec              = require "cp.spec"
local timer             = require "hs.timer"
local describe, it      = spec.describe, spec.it

return describe "Simple Suite" {
    it("Success", function()
        assert(true, "OK")
    end),

    it("Failure", function()
        assert(false, "Not OK")
    end),

    it("Async", function(this)
        this:continues()
        timer.doAfter(2, function()
            assert(true, "Asynched!")
            this:passed()
        end)
    end),

    it("Timeout", function(this)
        this:continues(1)
        timer.doAfter(2, function()
            assert(not this:isActive(), "Timeout failed!")
        end)
    end),

    describe "Sub Suite" {
        it("Sub Success", function()
            assert(true, "Sub Success")
        end),
    },
}