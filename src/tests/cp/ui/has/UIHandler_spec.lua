local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it

local UIHandler     = require "cp.ui.has.UIHandler"

return describe "cp.ui.has.UIHandler" {
    it "throws an error when calling matches"
    :doing(function(this)
        local handler = UIHandler()
        this:expectAbort("cp.ui.has.UIHandler:matches() is not implemented.")
        handler:matches({})
    end),

    it "throws an error when calling build"
    :doing(function(this)
        local handler = UIHandler()
        this:expectAbort("cp.ui.has.UIHandler:build() is not implemented.")
        handler:build({}, {})
    end),
}