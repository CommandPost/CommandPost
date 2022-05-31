local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it
local context       = spec.context
local expect        = require "cp.spec.expect"

local UIHandler     = require "cp.ui.has.UIHandler"

return describe "cp.ui.has.UIHandler" {
    context "isClassOf" {
        it "returns true if the value is a UIHandler"
        :doing(function()
            local MyUIHandler = UIHandler:subclass("MyUIHandler")
            function MyUIHandler:initialize()
                UIHandler.initialize(self)
            end
            local myUIHandler = MyUIHandler()
            expect(MyUIHandler:isClassOf(myUIHandler)):is(true)
            expect(UIHandler:isClassOf(myUIHandler)):is(true)
        end),

        it "returns false if the value is not a UIHandler"
        :doing(function()
            expect(UIHandler:isClassOf("foo")):is(false)
        end),
    },
}