--- === cp.ui.Toolbar ===
---
--- Toolbar Module.

local require = require

local axutils						= require("cp.ui.axutils")
local Button            = require("cp.ui.Button")
local Do                = require("cp.rx.go").Do
local Element           = require("cp.ui.Element")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Toolbar = Element:subclass("cp.ui.Toolbar")

--- cp.ui.Toolbar.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Button`, returning `true` if so.
---
--- Parameters:
---  * element		- The `hs._asm.axuielement` to check.
---
--- Returns:
---  * `true` if the `element` is a `Button`, or `false` if not.
function Toolbar.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXToolbar"
end

--- cp.ui.Toolbar(parent, uiFinder) -> cp.ui.Toolbar
--- Constructor
--- Creates a new `Toolbar` instance, given the specified `parent` and `uiFinder`
---
--- Parameters:
---  * parent   - The parent object.
---  * uiFinder   - The `cp.prop` or `function` that finds the `hs._asm.axuielement` that represents the `Toolbar`.
---
--- Returns:
---  * The new `Toolbar` instance.
function Toolbar:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)

    if prop.is(parent.UI) then
        self.UI:monitor(parent.UI)
    end

    if prop.is(parent.isShowing) then
        self.isShowing:monitor(parent.isShowing)
    end

end

--- cp.ui.Toolbar.selectedTitle <cp.prop: string; read-only>
--- Field
--- The title of the first selected item, if available.
function Toolbar.lazy.prop:selectedTitle()
    return self.UI:mutate(function(original)
        local ui = original()
        local selected = ui and ui:attributeValue("AXSelectedChildren")
        if selected and #selected > 0 then
            return selected[1]:attributeValue("AXTitle")
        end
    end)
end

--- cp.ui.Toolbar.overflowButton <cp.ui.Button>
--- Field
--- The "overflow" button which appears if there are more toolbar items
--- available than can be fit on screen.
function Toolbar.lazy.value:overflowButton()
    return Button(self, self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXOverflowButton")
    end))
end

--- cp.ui.Toolbar:doSelect(title) -> Statement
--- Method
--- Returns a `Statement` that will select the toolbar item with the specified title.
---
--- Parameters:
--- * title - The title to select, if present.
---
--- Returns:
--- * A `Statement` that when executed returns `true` if the item was found and selected, otherwise `false`.
function Toolbar:doSelect(title)
    return Do(self:doShow())
    :Then(function()
        local ui = self:UI()
        local selectedTitle = self:selectedTitle()
        if selectedTitle ~= title then
            local button = ui and axutils.childWith(ui, "AXTitle", title)
            if button then
                button:doPress()
                return true
            end
        end
        return false
    end)
end

function Toolbar.lazy.method:doShow()
    return self:parent():doShow()
end

function Toolbar.lazy.method:doHide()
    return self:parent():doHide()
end

function Toolbar.__tostring()
    return "cp.ui.Toolbar"
end

return Toolbar
