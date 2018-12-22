--- === cp.apple.finalcutpro.cmd.CommandEditor ===
---
--- Command Editor Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require                       = require
local log                           = require("hs.logger").new("PrefsDlg")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
--local inspect                       = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local Button                        = require("cp.ui.Button")
local Window                        = require("cp.ui.Window")
local just                          = require("cp.just")
local prop                          = require("cp.prop")

local strings                       = require("cp.apple.finalcutpro.strings")

local If                            = require("cp.rx.go.If")
local Throw                         = require("cp.rx.go.Throw")
local WaitUntil                     = require("cp.rx.go.WaitUntil")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local CommandEditor = {}

-- _findWindowUI(windows) -> window | nil
-- Function
-- Gets the Window UI.
--
-- Parameters:
--  * windows - Table of windows.
--
-- Returns:
--  * An `axuielementObject` or `nil`
local function _findWindowUI(windows)
    for _,window in ipairs(windows) do
        if CommandEditor.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.cmd.CommandEditor.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function CommandEditor.matches(element)
    if element then
        return element:attributeValue("AXSubrole") == "AXDialog"
           and element:attributeValue("AXModal")
           and axutils.childWithRole(element, "AXPopUpButton") ~= nil
           and #axutils.childrenWithRole(element, "AXGroup") == 4
    end
    return false
end

--- cp.apple.finalcutpro.cmd.CommandEditor.new(app) -> CommandEditor
--- Constructor
--- Creates a new Command Editor object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `CommandEditor` object.
function CommandEditor.new(app)
    local o = prop.extend({_app = app}, CommandEditor)

    local UI = app.windowsUI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        CommandEditor.matches)
    end)

    -- provides access to common AXWindow properties.
    local window = Window(app.app, UI)
    o._window = window

    prop.bind(o) {
--- cp.apple.finalcutpro.cmd.CommandEditor.UI <cp.prop: axuielement; read-only>
--- Field
--- The `axuielement` for the window.
        UI = UI,

--- cp.apple.finalcutpro.cmd.CommandEditor.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
        hsWindow = window.hsWindow,

--- cp.apple.finalcutpro.cmd.CommandEditor.isShowing <cp.prop: boolean; live>
--- Field
--- Is `true` if the window is visible.
        isShowing = window.visible,

--- cp.apple.finalcutpro.cmd.CommandEditor.isFullScreen <cp.prop: boolean; live>
--- Field
--- Is `true` if the window is full-screen.
        isFullScreen = window.fullScreen,

--- cp.apple.finalcutpro.cmd.CommandEditor.frame <cp.prop: frame; live>
--- Field
--- The current position (x, y, width, height) of the window.
        frame = window.frame,
    }

--- cp.apple.finalcutpro.cmd.CommandEditor.save <cp.ui.Button>
--- Field
--- The "Save" [Button](cp.ui.Button.md).
    o.save = Button(o, UI:mutate(function(original)
        return axutils.childFromRight(original(), 1, Button.matches)
    end))

--- cp.apple.finalcutpro.cmd.CommandEditor.close <cp.ui.Button>
--- Field
--- The "Close" [Button](cp.ui.Button.md).
    o.close = Button(o, UI:mutate(function(original)
        return axutils.childFromRight(original(), 2, Button.matches)
    end))

    return o
end

--- cp.apple.finalcutpro.cmd.CommandEditor:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function CommandEditor:app()
    return self._app
end

--- cp.apple.finalcutpro.cmd.CommandEditor:window() -> cp.ui.Window
--- Method
--- Returns the `Window` for the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Window`.
function CommandEditor:window()
    return self._window
end

--- cp.apple.finalcutpro.cmd.CommandEditor:show() -> cp.apple.finalcutpro.cmd.CommandEditor
--- Method
--- Shows the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.cmd.CommandEditor` object for method chaining.
function CommandEditor:show()
    if not self:isShowing() then
        -- open the window
        if self:app():menu():isEnabled({"Final Cut Pro", "Commands", "Customize…"}) then
            self:app():menu():selectMenu({"Final Cut Pro", "Commands", "Customize…"})
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doShow() -> cp.rx.go.Statement <boolean>
--- Method
--- Creates a [Statement](cp.rx.go.Statement.md) that will attempt to show the Command Editor, if FCPX is running.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, which will resolve to `true` if the CommandEditor is showing or `false` if not.
function CommandEditor:doShow()
    return If(self:app().isRunning):Then(
        If(self.isShowing):Is(false):Then(
            self:app():menu():selectMenu({"Final Cut Pro", "Commands", "Customize…"})
        ):Then(
            WaitUntil(self.isShowing)
        ):Otherwise(true)
    )
    :Otherwise(false)
    :TimeoutAfter(10000)
    :ThenYield()
    :Label("CommandEditor:doShow")
end

--- cp.apple.finalcutpro.cmd.CommandEditor:hide() -> cp.apple.finalcutpro.cmd.CommandEditor
--- Method
--- Hides the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.cmd.CommandEditor` object for method chaining.
function CommandEditor:hide()
    local ui = self:UI()
    if ui then
        local closeBtn = axutils.childWith(ui, "AXSubrole", "AXCloseButton")
        if closeBtn then
            closeBtn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doShow() -> cp.rx.go.Statement <boolean>
--- Method
--- Creates a [Statement](cp.rx.go.Statement.md) that will attempt to hide the Command Editor, if FCPX is running.
--- If the changes have not been saved, they will be lost.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, which will resolve to `true` if the CommandEditor is not showing or `false` if not.
function CommandEditor:doHide()
    local alert = self:alert()
    local isHidden = self.isShowing:NOT()
    return If(self.isShowing):Then(
        self:window():doClose()
    ):Then(
        WaitUntil(isHidden:OR(alert.isShowing))
    ):Then(
        If(alert.isShowing):Then(function()
            local msg = strings:find("ConfirmSaveAlertTitle")
            if msg then
                msg = msg:gsub("%?", "%%?"):gsub("%%@", ".*")
                log.df("msg: %s", msg)
                if alert:containsText(msg) then
                    -- Button 1 should be "Don't Save" or equivalent in current locale.
                    return alert:doPress(1)
                end
            end
            return Throw("Unable to close the Command Editor: Unexpected Alert")
        end)
    ):Then(WaitUntil(isHidden)
    ):Otherwise(true)
    :TimeoutAfter(10000)
    :ThenYield()
    :Label("CommandEditor:doHide")
end

--- cp.apple.finalcutpro.cmd.CommandEditor:saveButton() -> axuielementObject | nil
--- Method
--- Gets the Command Editor Save Button AX item.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `axuielementObject` of the Save Button or nil.
function CommandEditor:saveButton()
    return self.save
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doSave() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that triggers the Save button in the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if the button was found and pushed, otherwise `false`.
function CommandEditor:doSave()
    return self.save:doPress()
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doClose() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that triggers the Save button in the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if the button was found and pushed, otherwise `false`.
function CommandEditor:doSave()
    return self.save:doPress()
end

--- cp.apple.finalcutpro.cmd.CommandEditor:getTitle() -> string | nil
--- Method
--- The title of the Command Editor window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Command Editor window as a string or `nil`.
function CommandEditor:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

--- cp.apple.finalcutpro.cmd.CommandEditor:alert() -> cp.ui.Alert
--- Method
--- The [Alert](cp.ui.Alert.md) for the Command Editor window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Alert`.
function CommandEditor:alert()
    return self:window():alert()
end

return CommandEditor
