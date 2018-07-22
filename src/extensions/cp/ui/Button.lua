--- === cp.ui.Button ===
---
--- Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("button")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")
local go                            = require("cp.rx.go")

local Do, Throw                     = go.Do, go.Throw

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Button = {}

--- cp.ui.Button.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Button`, returning `true` if so.
---
--- Parameters:
---  * element		- The `hs._asm.axuielement` to check.
---
--- Returns:
---  * `true` if the `element` is a `Button`, or `false` if not.
function Button.matches(element)
    return element and element:attributeValue("AXRole") == "AXButton"
end

--- cp.ui.Button.new(parent, finderFn) -> cp.ui.Button
--- Constructor
--- Creates a new `Button` instance.
---
--- Parameters:
---  * parent		- The parent object. Should have a `UI` and `isShowing` field.
---  * finderFn		- A function which will return the `hs._asm.axuielement` the button belongs to, or `nil` if not available.
---
--- Returns:
--- The new `Button` instance.
function Button.new(parent, finderFn)
    local o = prop.extend(
        {
            _parent = parent,
        }, Button
    )

    local UI
    if prop.is(finderFn) then
        UI = finderFn
    else
        UI = prop(function()
            return axutils.cache(o, "_ui", function()
                local ui = finderFn()
                return Button.matches(ui) and ui or nil
            end,
            Button.matches)
        end)
    end

    prop.bind(o) {
--- cp.ui.Button.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Retrieves the `axuielement` for the `Button`, or `nil` if not available..
        UI = UI,

--- cp.ui.Button.isShowing <cp.prop: boolean; read-only>
--- Field
--- If `true`, the `Button` is showing on screen.
        isShowing = UI:mutate(function(original, self)
            return original() ~= nil and self:parent():isShowing()
        end),

--- cp.ui.Button.title <cp.prop: string; read-only>
--- Field
--- The button title, if available.
        title   = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXTitle")
        end),

--- cp.ui.Button.frame <cp.prop: table; read-only>
--- Field
--- Returns the table containing the `x`, `y`, `w`, and `h` values for the button frame, or `nil` if not available.
        frame = UI:mutate(function(original)
            local ui = original()
            return ui and ui:frame() or nil
        end),
    }

    if prop.is(parent.UI) then
        o.UI:monitor(parent.UI)
    end

    if prop.is(parent.isShowing) then
        o.isShowing:monitor(parent.isShowing)
    end

    return o
end

--- cp.ui.Button:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function Button:parent()
    return self._parent
end

--- cp.ui.Button:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Button:app()
    return self:parent():app()
end

--- cp.ui.Button:isEnabled() -> boolean
--- Method
--- Returns `true` if the button is visible and enabled.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the button is visible and enabled.
function Button:isEnabled()
    local ui = self:UI()
    return ui ~= nil and ui:enabled()
end

--- cp.ui.Button:press() -> self, boolean
--- Method
--- Performs a button press action, if the button is available.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` instance.
---  * `true` if the button was actually pressed successfully.
function Button:press()
    local success = false
    local ui = self:UI()
    if ui then success = ui:doPress() == true end
    return self, success
end

--- cp.ui.Button:doPress() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will press the button when executed, if available at the time.
--- If not an `error` is sent.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will press the button when executed.
function Button:doPress()
    return Do(function()
        local ui = self:UI()
        if ui then
            ui:doPress()
        else
            return Throw("Button not found.")
        end
    end)
end

-- cp.ui.Button:__call() -> self, boolean
-- Method
-- Allows the button to be called like a function which will trigger a `press`.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The `Button` instance.
--  * `true` if the button was actually pressed successfully.
function Button:__call()
    return self:press()
end

--- cp.ui.Button:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the button in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created.
function Button:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

function Button:__tostring()
    return string.format("cp.ui.Button: %s (%s)", self:title(), self:parent())
end

return Button
