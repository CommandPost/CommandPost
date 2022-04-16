local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it
local context       = spec.context
local expect        = require "cp.spec.expect"

local Builder       = require "cp.ui.Builder"
local Element       = require "cp.ui.Element"

return describe "cp.ui.Builder" {
    it "creates a Builder class on the Element subclass"
    :doing(function()
        local MyElement = Element:subclass("foo.MyElement"):defineBuilder("withAlpha")
        expect(type(MyElement.Builder)):is("table")
    end),

    it "allows one extra parameter"
    :doing(function()
        local MyElement = Element:subclass("MyElement"):defineBuilder("withAlpha")

        function MyElement:initialize(parent, uiFinder, alpha)
            Element.initialize(self, parent, uiFinder)
            self.alpha = alpha
        end

        local a = MyElement:withAlpha("alpha")({}, function() end)
        expect(a.alpha):is("alpha")
    end),

    it "allows multiple extra parameters"
    :doing(function()
        local MyElement = Element:subclass("MyElement"):defineBuilder("withAlpha", "withBeta")

        function MyElement:initialize(parent, uiFinder, alpha, beta)
            Element.initialize(self, parent, uiFinder)
            self.alpha = alpha
            self.beta = beta
        end

        local a = MyElement:withAlpha("alpha"):withBeta("beta")({}, function() end)
        expect(a.alpha):is("alpha")
        expect(a.beta):is("beta")

        local b = MyElement:withBeta("beta"):withAlpha("alpha")({}, function() end)
        expect(b.alpha):is("alpha")
        expect(b.beta):is("beta")
    end),
}