local spec  = require "cp.spec"
local timer = require "hs.timer"
local log   = require "hs.logger" .new "asyncspec"

local it = spec.it

return it "fails asynchronously"
:doing(function(this)
    log.df("waiting...")
    this:wait(5)
    log.df("asserting...")
    assert(true, "should not fail")

    log.df("doAfter...")
    timer.doAfter(1, function()
        log.df("done after...")
        assert(false, "this should fail")
        this:done()
        log.df("done.")
    end)
    log.df("doAfter sent.")
end)