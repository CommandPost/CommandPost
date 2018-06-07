--- === cp.ui.StaticText ===
---
--- Static Text Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log							= require("hs.logger").new("textField")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
--local inspect                       = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local notifier						= require("cp.ui.notifier")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local StaticText = {}

--- cp.ui.StaticText.matches(element) -> boolean
--- Function
--- Checks if the element is a Static Text element.
---
--- Parameters:
---  * element		- The `axuielement` to check.
---
--- Returns:
---  * If `true`, the element is a Static Text element.
function StaticText.matches(element)
    return element and element:attributeValue("AXRole") == "AXStaticText"
end

--- cp.ui.StaticText.new(parent, finderFn[, convertFn]) -> StaticText
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
--- local numberField = StaticText.new(parent, function() return ... end, tonumber)
--- ```
---
--- Parameters:
---  * parent	- The parent object.
---  * finderFn	- The function will return the `axuielement` for the StaticText.
---  * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
---  * The new `StaticText`.
function StaticText.new(parent, finderFn, convertFn)
    local o

    o = prop.extend({
        _parent = parent,
        _finder = finderFn,
        _convert = convertFn,

        --- cp.ui.StaticText.UI <cp.prop: hs._asm.axuielement | nil>
        --- Field
        --- The `axuielement` or `nil` if it's not available currently.
        UI = prop(function()
            return axutils.cache(o, "_ui", function()
                local ui = finderFn()
                return StaticText.matches(ui) and ui or nil
            end,
            StaticText.matches)
        end),
    }, StaticText)

    prop.bind(o) {

        --- cp.ui.StaticText:isShowing() -> boolean
        --- Method
        --- Checks if the static text is currently showing.
        ---
        --- Parameters:
        ---  * None
        ---
        --- Returns:
        ---  * `true` if it's visible.
        isShowing = o.UI:mutate(function(original, self)
            local ui = original()
            return ui ~= nil and self:parent():isShowing()
        end),

        --- cp.ui.StaticText.value <cp.prop: string>
        --- Field
        --- The current value of the text field.
        value = o.UI:mutate(
            function(original)
                local ui = original()
                local value = ui and ui:attributeValue("AXValue") or nil
                if value and convertFn then
                    value = convertFn(value)
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
                    ui:setAttributeValue("AXFocused", focused)
                    ui:performAction("AXConfirm")
                end
            end
        ),
    }

    o._notifier = notifier.new(o:app():bundleID(), function() return o:UI() end)

    -- wire up a notifier to watch for value changes.
    o.value:preWatch(function()
        o._notifier:addWatcher("AXValueChanged", function() o.value:update() end):start()
    end)

    -- watch for changes in parent visibility, and update the notifier if it changes.
    if prop.is(parent.isShowing) then
        o.isShowing:monitor(parent.isShowing)
        o.isShowing:watch(function()
            o._notifier:update()
        end)
    end

    return o
end

--- cp.ui.StaticText:parent() -> table
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent.
function StaticText:parent()
    return self._parent
end

--- cp.ui.StaticText:app() -> table
--- Method
--- Returns the app object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The app.
function StaticText:app()
    return self:parent():app()
end

--- cp.ui.StaticText:getValue() -> string
--- Method
--- Gets the value of the Static Text.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The value of the Static Text as a string.
function StaticText:getValue()
    return self:value()
end

--- cp.ui.StaticText:setValue(value) -> self
--- Method
--- Sets the value of the Static Text.
---
--- Parameters:
---  * value - The value you want to set the Static Text to as a string.
---
--- Returns:
---  * Self
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

--- cp.ui.StaticText:isEnabled() -> boolean
--- Method
--- Is the Static Text box enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if enabled, otherwise `false`.
function StaticText:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
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

--- cp.ui.StaticText:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created, or `nil` if the UI is not available.
function StaticText:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return StaticText