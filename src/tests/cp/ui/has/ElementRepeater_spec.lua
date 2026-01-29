local require               = require
local spec                  = require "cp.spec"
local describe, it          = spec.describe, spec.it
local context               = spec.context
local expect                = require "cp.spec.expect"

local prop                  = require "cp.prop"
local has                   = require "cp.ui.has"
local Element               = require "cp.ui.Element"
local ElementRepeater       = require "cp.ui.has.ElementRepeater"

local axmock                = require "cp.ui.mock.axuielement"

local MockElement = Element:subclass("MockElement")

function MockElement.static.matches(element)
    return element ~= nil and element.AXRole == "AXMock"
end

return describe "cp.ui.has.ElementRepeater" {
    context "StaticText" {
        it "matches with mocks"
        :doing(function()
            local mock = axmock { AXRole = "AXMock", AXValue = "Hello World" }
            expect(mock:isValid()):is(true)
            expect(MockElement.matches(mock)):is(true)
        end),
    },

    context "item" {
        it "supports a single item"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            local item1 = element:item(1)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(item1:UI()):is(axmock { AXRole="AXMock" })
        end),

        it "supports multiple items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            local item1 = element:item(1)
            local item2 = element:item(2)
            local item3 = element:item(3)
            local item4 = element:item(4)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(MockElement:isClassFor(item2)):is(true)
            expect(MockElement:isClassFor(item3)):is(true)
            expect(MockElement:isClassFor(item4)):is(true)
            expect(item1:UI().AXValue):is("A")
            expect(item2:UI().AXValue):is("B")
            expect(item3:UI().AXValue):is("C")
            expect(item4:UI()):is(nil)
        end),

        it "supports zero items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {}
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            local item1 = element:item(1)
            local item2 = element:item(2)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(MockElement:isClassFor(item2)):is(true)
            expect(item1:UI()):is(nil)
            expect(item2:UI()):is(nil)
        end),

        it "returns values when there are at least minCount items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler, 2)
            local item1 = element:item(1)
            local item2 = element:item(2)
            local item3 = element:item(3)
            local item4 = element:item(4)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(MockElement:isClassFor(item2)):is(true)
            expect(MockElement:isClassFor(item3)):is(true)
            expect(MockElement:isClassFor(item4)):is(true)
            expect(item1:UI().AXValue):is("A")
            expect(item2:UI().AXValue):is("B")
            expect(item3:UI().AXValue):is("C")
            expect(item4:UI()):is(nil)
        end),

        it "returns nil when there are less than minCount items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler, 3)
            local item1 = element:item(1)
            local item2 = element:item(2)
            local item3 = element:item(3)
            local item4 = element:item(4)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(MockElement:isClassFor(item2)):is(true)
            expect(MockElement:isClassFor(item3)):is(true)
            expect(MockElement:isClassFor(item4)):is(true)
            expect(item1:UI()):is(nil)
            expect(item2:UI()):is(nil)
            expect(item3:UI()):is(nil)
            expect(item4:UI()):is(nil)
        end),

        it "returns nil when accessing items above the maxCount"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                    axmock { AXRole="AXMock", AXValue="D" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler, nil, 3)
            local item1 = element:item(1)
            local item2 = element:item(2)
            local item3 = element:item(3)
            local item4 = element:item(4)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(MockElement:isClassFor(item2)):is(true)
            expect(MockElement:isClassFor(item3)):is(true)
            expect(item4):is(nil)

            expect(item1:UI().AXValue):is("A")
            expect(item2:UI().AXValue):is("B")
            expect(item3:UI().AXValue):is("C")
        end),

        it "returns values when there are more than minCount and less than maxCount"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                    axmock { AXRole="AXMock", AXValue="D" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler, 2, 5)
            local item1 = element:item(1)
            local item2 = element:item(2)
            local item3 = element:item(3)
            local item4 = element:item(4)
            local item5 = element:item(5)
            local item6 = element:item(6)
            expect(MockElement:isClassFor(item1)):is(true)
            expect(MockElement:isClassFor(item2)):is(true)
            expect(MockElement:isClassFor(item3)):is(true)
            expect(MockElement:isClassFor(item4)):is(true)
            expect(MockElement:isClassFor(item5)):is(true)
            expect(item6):is(nil)

            expect(item1:UI().AXValue):is("A")
            expect(item2:UI().AXValue):is("B")
            expect(item3:UI().AXValue):is("C")
            expect(item4:UI().AXValue):is("D")
        end),
    },

    context "count" {
        it "supports a single item"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(element:count()):is(1)
        end),

        it "supports multiple items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(element:count()):is(3)
        end),

        it "supports zero items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {}
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(element:count()):is(0)
        end),
    },

    context "len" {
        it "supports a single item"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(#element):is(1)
        end),

        it "supports multiple items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(#element):is(3)
        end),

        it "supports zero items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {}
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(#element):is(0)
        end),
    },

    context "list index" {
        it "supports a single item"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(element[1]):is(element:item(1))
            expect(element[2]):is(nil)
        end),

        it "supports multiple items"
        :doing(function()
            local parent = {}
            local uiFinder = prop(function()
                return {
                    axmock { AXRole="AXMock", AXValue="A" },
                    axmock { AXRole="AXMock", AXValue="B" },
                    axmock { AXRole="AXMock", AXValue="C" },
                }
            end)
            local handler = has.element(MockElement)

            local element = ElementRepeater(parent, uiFinder, handler)
            expect(element[1]):is(element:item(1))
            expect(element[2]):is(element:item(2))
            expect(element[3]):is(element:item(3))
            expect(element[4]):is(nil)
        end),

    }
}