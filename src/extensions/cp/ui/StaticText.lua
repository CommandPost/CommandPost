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
--- * element		- The `axuielement` to check.
---
--- Returns:
--- * If `true`, the element is a Static Text element.
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
--- * parent	- The parent object.
--- * finderFn	- The function will return the `axuielement` for the StaticText.
--- * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
--- * The new `StaticText`.
function StaticText.new(parent, finderFn, convertFn)
    local o = prop.extend({
        _parent = parent,
        _finder = finderFn,
        _convert = convertFn,
    }, StaticText)

    local UI
    if prop.is(finderFn) then
        UI = finderFn
    else
        UI = prop(function()
            return axutils.cache(o, "_ui", function()
                local ui = finderFn()
                return StaticText.matches(ui) and ui or nil
            end,
            StaticText.matches)
        end)
    end

    prop.bind(o) {
        --- cp.ui.StaticText.UI <cp.prop: hs._asm.axuielement | nil>
        --- Field
        --- The `axuielement` or `nil` if it's not available currently.
        UI = UI,

        --- cp.ui.StaticText.isShowing <cp.prop: boolean>
        --- Field
        --- Checks if the static text is currently showing.
        isShowing = UI:mutate(function(original, self)
            local ui = original()
            return ui ~= nil and self:parent():isShowing()
        end),

        --- cp.ui.StaticText.isShowing <cp.prop: table | nil>
        --- Field
        --- The frame table (`{x, y, w, h}`) for the UI element, or `nil` if not.
        frame = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXFrame")
        end),

        --- cp.ui.StaticText.value <cp.prop: anything>
        --- Field
        --- The current value of the text field.
        value = UI:mutate(
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
                    ui:performAction("AXConfirm")
                    ui:setAttributeValue("AXFocused", focused)
                end
            end
        ),
    }

    -- wire up a notifier to watch for value changes.
    o.value:preWatch(function()
        o:notifier():addWatcher("AXValueChanged", function() o.value:update() end):start()
    end)

    -- watch for changes in parent visibility, and update the notifier if it changes.
    if prop.is(parent.isShowing) then
        o.isShowing:monitor(parent.isShowing)
        o.isShowing:watch(function()
            o:notifier():update()
        end)
    end

    return o
end

--- cp.ui.StaticText:parent() -> table
--- Method
--- Returns the parent object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The parent.
function StaticText:parent()
    return self._parent
end

--- cp.ui.StaticText:app() -> table
--- Method
--- Returns the app object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The app.
function StaticText:app()
    return self:parent():app()
end

-- Deprecated: use the `value` property directly
function StaticText:getValue()
    return self:value()
end

-- Deprecated: use the `value` property directly
function StaticText:setValue(value)
    self.value:set(value)
end

-- TODO: Add documentation
function StaticText:clear()
    self.value:set("")
end

-- TODO: Add documentation
function StaticText:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
end

function StaticText:notifier()
    if not self._notifier then
        self._notifier = notifier.new(self:app():bundleID(), function() return self:UI() end)
    end
    return self._notifier
end

-- TODO: Add documentation
function StaticText:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

-- TODO: Add documentation
function StaticText:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

-- Allows the StaticText instance to be called as a function/method which will get/set the value.
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
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function StaticText:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return StaticText
