--- === cp.ui.StaticText ===
---
--- Static Text Module.

local require = require

local timer               = require("hs.timer")

local Element             = require("cp.ui.element")
local notifier						= require("cp.ui.notifier")
local prop							  = require("cp.prop")

local delayedTimer        = timer.delayed

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local StaticText = Element:subclass("StaticText")

--- cp.ui.StaticText.matches(element) -> boolean
--- Function
--- Checks if the element is a Static Text element.
---
--- Parameters:
---  * element		- The `axuielement` to check.
---
--- Returns:
---  * If `true`, the element is a Static Text element.
function StaticText.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXStaticText"
end

--- cp.ui.StaticText(parent, uiFinder[, convertFn]) -> StaticText
--- Method
--- Creates a new StaticText. They have a parent and a finder function.
--- Additionally, an optional `convert` function can be provided, with the following signature:
---
--- `function(textValue) -> anything`
---
--- The `value` will be passed to the function before being returned, if present. All values
--- passed into `value(x)` will be converted to a `string` first via `tostring`.
---
--- For example, to have the value be converted into a `number`, simply use `tonumber` like this:
---
--- ```lua
--- local numberField = StaticText(parent, function() return ... end, tonumber)
--- ```
---
--- Parameters:
---  * parent	- The parent object.
---  * uiFinder	- The function will return the `axuielement` for the StaticText.
---  * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
---  * The new `StaticText`.
function StaticText:initialize(parent, uiFinder, convertFn)
    Element.initialize(self, parent, uiFinder)

    self._convertFn = convertFn

    -- watch for changes in parent visibility, and update the notifier if it changes.
    if prop.is(parent.isShowing) then
        self.isShowing:monitor(parent.isShowing)
        self.isShowing:watch(function()
            self:notifier():update()
        end)
    end
end

--- cp.ui.StaticText.value <cp.prop: anything>
--- Field
--- The current value of the text field.
function StaticText.lazy.prop:value()
    local value = self.UI:mutate(
        function(original)
            local ui = original()
            local value = ui and ui:attributeValue("AXValue") or nil
            if value and self._convertFn then
                value = self._convertFn(value)
            end
            return value
        end,
        function(value, original)
            local ui = original()
            if ui then
                value = tostring(value)
                local focused = ui:attributeValue("AXFocused")
                ui:setAttributeValue("AXFocused", true)
                ui:setAttributeValue("AXValue", value)
                ui:performAction("AXConfirm")
                ui:setAttributeValue("AXFocused", focused)
            end
        end
    )

    -----------------------------------------------------------------------
    -- Reduce the amount of AX notifications when timecode is updated:
    -----------------------------------------------------------------------
    local timecodeUpdater
    timecodeUpdater = delayedTimer.new(0.001, function()
        value:update()
    end)

    -- wire up a notifier to watch for value changes.
    value:preWatch(function()
        self:notifier():watchFor("AXValueChanged", function()
            timecodeUpdater:start()
        end):start()
    end)

    return value
end

-- Deprecated: use the `value` property directly
function StaticText:getValue()
    return self:value()
end

-- Deprecated: use the `value` property directly
function StaticText:setValue(value)
    self.value:set(value)
    return self
end

--- cp.ui.StaticText:clear() -> self
--- Method
--- Clears the value of a Static Text box.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function StaticText:clear()
    self.value:set("")
    return self
end

function StaticText.lazy.method:notifier()
    return notifier.new(self:app():bundleID(), self.UI)
end

--- cp.ui.StaticText:saveLayout() -> table
--- Method
--- Saves the current Static Text layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Static Text Layout.
function StaticText:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

--- cp.ui.StaticText:loadLayout(layout) -> none
--- Method
--- Loads a Static Text layout.
---
--- Parameters:
---  * layout - A table containing the Static Text layout settings - created using `cp.ui.StaticText:saveLayout()`.
---
--- Returns:
---  * None
function StaticText:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

-- cp.ui.xxx:__call(parent, value) -> parent, string
-- Method
-- Allows the StaticText instance to be called as a function/method which will get/set the value.
--
-- Parameters:
--  * parent - (optional) The parent object.
--  * value - The value you want to set the slider to.
--
-- Returns:
--  * The value of the Static Text box.
function StaticText:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

return StaticText
