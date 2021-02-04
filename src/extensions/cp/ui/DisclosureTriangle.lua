--- === cp.ui.DisclosureTriangle ===
---
--- Disclosure Triangle UI Module.
---
--- This represents an `hs.axuielement` with a `AXDisclosureTriangle` role.
--- It allows checking and modifying the `opened` status like so:
---
--- ```lua
--- myButton:opened() == true			-- happens to be opened already
--- myButton:opened(false) == false	-- update to unopened.
--- myButton.opened:toggle() == true	-- toggled back to being opened.
--- ```
---
--- You can also call instances of `DisclosureTriangle` as a function, which will return
--- the `opened` status:
---
--- ```lua
--- myButton() == true			-- still true
--- myButton(false) == false	-- now false
--- ```

local require = require

local axutils           = require "cp.ui.axutils"
local Element			= require "cp.ui.Element"
local tools             = require "cp.tools"

local If                = require "cp.rx.go.If"
local Do                = require "cp.rx.go.Do"

local centre            = tools.centre
local ninjaMouseClick	= tools.ninjaMouseClick

local DisclosureTriangle = Element:subclass("cp.ui.DisclosureTriangle")

--- cp.ui.DisclosureTriangle.matches(element) -> boolean
--- Function
--- Checks if the provided `hs.axuielement` is a DisclosureTriangle.
---
--- Parameters:
---  * element		- The `axuielement` to check.
---
--- Returns:
---  * `true` if it's a match, or `false` if not.
function DisclosureTriangle.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXDisclosureTriangle"
end

--- cp.ui.DisclosureTriangle(parent, uiFinder) -> cp.ui.DisclosureTriangle
--- Constructor
--- Creates a new DisclosureTriangle.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder		- A function which will return the `hs.axuielement` when available.
---
--- Returns:
---  * The new `DisclosureTriangle`.
function DisclosureTriangle:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

--- cp.ui.DisclosureTriangle.title <cp.prop: string; read-only>
--- Field
--- The button title, if available.
function DisclosureTriangle.lazy.prop:title()
    return axutils.prop(self.UI, "AXTitle")
end

--- cp.ui.DisclosureTriangle.opened <cp.prop: boolean>
--- Field
--- Indicates if the disclosure triangle is currently opened.
--- May be set by calling as a function with `true` or `false` to the function.
function DisclosureTriangle.lazy.prop:opened()
    return self.UI:mutate(
        function(original) -- get
            local ui = original()
            return ui ~= nil and ui:attributeValue("AXValue") == 1
        end,
        function(value, original) -- set
            local ui = original()
            if ui and value ~= (ui:attributeValue("AXValue") == 1) and ui:attributeValue("AXEnabled") == true then
                ui:performAction("AXPress")
            end
        end
    )
end

--- cp.ui.DisclosureTriangle:click() -> self
--- Method
--- Performs a single mouse click on the triangle.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `DisclosureTriangle` instance.
function DisclosureTriangle:click()
    local ui = self:UI()
    if ui then
        local frame = ui:attributeValue("AXFrame")
        if frame then
            ninjaMouseClick(centre(frame))
        end
    end
    return self
end

--- cp.ui.DisclosureTriangle:toggle() -> self
--- Method
--- Toggles the `opened` status of the button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `DisclosureTriangle` instance.
function DisclosureTriangle:toggle()
    self.opened:toggle()
    return self
end

--- cp.ui.DisclosureTriangle:press() -> self
--- Method
--- Attempts to press the button. May fail if the `UI` is not available.
---
--- Parameters:
---  * None
---
--- Returns:
--- The `DisclosureTriangle` instance.
function DisclosureTriangle:press()
    local ui = self:UI()
    if ui then
        ui:performAction("AXPress")
    end
    return self
end

--- cp.ui.DisclosureTriangle:doPress() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will press the button when executed, if available at the time.
--- If not an `error` is sent.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will press the button when executed.
function DisclosureTriangle.lazy.method:doPress()
    return Do(self:parent():doShow())
        :Then(
            If(self.UI):Then(function(ui)
                ui:doPress()
                return true
            end)
            :Otherwise(false)
            :ThenYield()
            :Label("DisclosureTriangle:doPress")
        )
end

--- cp.ui.DisclosureTriangle:doOpen() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will ensure the `DisclosureTriangle` is opened.
function DisclosureTriangle.lazy.method:doOpen()
    return Do(self:parent():doShow())
        :Then(
            If(self.opened):Is(false)
            :Then(self:doPress())
            :Otherwise(true)
            :ThenYield()
            :Label("DisclosureTriangle:doOpen")
        )
end

--- cp.ui.DisclosureTriangle:doClose() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will ensure the `DisclosureTriangle` is unopened.
function DisclosureTriangle.lazy.method:doClose()
    return Do(self:parent():doShow())
        :Then(
            If(self.opened)
            :Then(self:doPress())
            :Otherwise(true)
            :ThenYield()
            :Label("DisclosureTriangle:doClose")
        )
end

--- cp.ui.DisclosureTriangle:saveLayout() -> table
--- Method
--- Returns a table containing the layout settings.
--- This table may be passed to the `loadLayout` method to restore the saved layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A settings table.
function DisclosureTriangle:saveLayout()
    return {
        opened = self:opened()
    }
end

--- cp.ui.DisclosureTriangle:loadLayout(layout) -> nil
--- Method
--- Applies the settings in the provided layout table.
---
--- Parameters:
---  * layout		- The table containing layout settings. Usually created by the `saveLayout` method.
---
--- Returns:
---  * nil
function DisclosureTriangle:loadLayout(layout)
    if layout then
        self:opened(layout.opened)
    end
end

-- cp.ui.Button:__call() -> boolean
-- Method
-- Allows the DisclosureTriangle to be called as a function and will return the `opened` value.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The value of the DisclosureTriangle.
function DisclosureTriangle:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:opened(value)
end

return DisclosureTriangle
