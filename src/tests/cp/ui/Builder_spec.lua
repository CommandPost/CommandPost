local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it
local context       = spec.context
local expect        = require "cp.spec.expect"

local Builder       = require "cp.ui.Builder"
local Element       = require "cp.ui.Element"

local log           = require "hs.logger" .new("Builderspec")

return describe "cp.ui.Builder" {
    it "defines one parameter with one value"
    :doing(function()
        local MyElement = Element:subclass("MyElement")
        function MyElement:initialize(parent, uiFinder, value)
            Element.initialize(self, parent, uiFinder)
            self.value = value
        end

        local MyElementBuilder = Builder(MyElement, "withValue")
        expect(type(MyElementBuilder.withValue)):is("function")

        local myBuilder = MyElementBuilder:withValue(1)
        
        local myElement = myBuilder({}, function() end)
        expect(myElement.value):is(1)
    end),

    it "defines one parameter with multiple values"
    :doing(function()
        local MyElement = Element:subclass("MyElement")
        function MyElement:initialize(parent, uiFinder, ...)
            Element.initialize(self, parent, uiFinder)
            self.value = table.pack(...)
        end

        local MyElementBuilder = Builder(MyElement, "withValue")
        expect(type(MyElementBuilder.withValue)):is("function")

        local myBuilder = MyElementBuilder:withValue(1, 2, 3)
        
        local myElement = myBuilder({}, function() end)
        expect(myElement.value):is({1, 2, 3})
    end),

    it "defines multiple parameters with one value"
    :doing(function()
        local MyElement = Element:subclass("MyElement")
        function MyElement:initialize(parent, uiFinder, leftType, rightType)
            Element.initialize(self, parent, uiFinder)
            self.leftType = leftType
            self.rightType = rightType
        end

        local MyElementBuilder = Builder(MyElement, "withLeftOf", "withRightOf")
        expect(type(MyElementBuilder.withLeftOf)):is("function")
        expect(type(MyElementBuilder.withRightOf)):is("function")

        local myBuilder = MyElementBuilder:withLeftOf("alpha"):withRightOf("beta")
        
        local myElement = myBuilder({}, function() end)
        expect(myElement.leftType):is("alpha")
        expect(myElement.rightType):is("beta")
    end),

    it "defines multiple parameters with multiple values"
    :doing(function()
        local MyElement = Element:subclass("MyElement")
        function MyElement:initialize(parent, uiFinder, ...)
            Element.initialize(self, parent, uiFinder)
            self.value = table.pack(...)
        end

        local MyElementBuilder = Builder(MyElement, "withLeftOf", "withRightOf")
        expect(type(MyElementBuilder.withLeftOf)):is("function")
        expect(type(MyElementBuilder.withRightOf)):is("function")

        local myBuilder = MyElementBuilder:withLeftOf("alpha", "beta"):withRightOf("gamma", "delta")
        
        local myElement = myBuilder({}, function() end)
        expect(myElement.value):is({ "alpha", "beta", "gamma", "delta" })
    end),

    it "defines multiple parameters with the first given nil"
    :doing(function()
        local MyElement = Element:subclass("MyElement")
        function MyElement:initialize(parent, uiFinder, ...)
            Element.initialize(self, parent, uiFinder)
            self.value = table.pack(...)
        end

        local MyElementBuilder = Builder(MyElement, "withLeftOf", "withRightOf")
        expect(type(MyElementBuilder.withLeftOf)):is("function")
        expect(type(MyElementBuilder.withRightOf)):is("function")

        local myBuilder = MyElementBuilder:withLeftOf(nil, "beta"):withRightOf("gamma", "delta")
        
        local myElement = myBuilder({}, function() end)
        expect(myElement.value):is({ nil, "beta", "gamma", "delta" })
    end),

    context "Element:defineBuilder" {
        it "creates a Builder class on the Element subclass"
        :doing(function()
            local MyElement = Element:subclass("MyElement"):defineBuilder("withAlpha")
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

            local c = MyElement:withBeta("beta")({}, function() end)
            expect(c.alpha):is(nil)
            expect(c.beta):is("beta")
        end),
    
        it "allows multiple values to one parameter"
        :doing(function()
            local MyElement = Element:subclass("MyElement"):defineBuilder("withAlpha", "withBeta")
    
            function MyElement:initialize(parent, uiFinder, alpha1, alpha2, beta)
                Element.initialize(self, parent, uiFinder)
                self.alpha1 = alpha1
                self.alpha2 = alpha2
                self.beta = beta
            end
    
            local a = MyElement:withAlpha("alpha1", "alpha2"):withBeta("beta")({}, function() end)
            expect(a.alpha1):is("alpha1")
            expect(a.alpha2):is("alpha2")
            expect(a.beta):is("beta")
    
            local b = MyElement:withBeta("beta"):withAlpha("alpha1", "alpha2")({}, function() end)
            expect(a.alpha1):is("alpha1")
            expect(a.alpha2):is("alpha2")
            expect(a.beta):is("beta")

            local c = MyElement:withAlpha(nil, nil):withBeta("beta")({}, function() end)
            expect(c.alpha1):is(nil)
            expect(c.alpha2):is(nil)
            expect(c.beta):is("beta")
        end),
    }
}
