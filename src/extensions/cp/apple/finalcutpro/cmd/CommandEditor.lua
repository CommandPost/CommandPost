--- === cp.apple.finalcutpro.cmd.CommandEditor ===
---
--- Command Editor Module.

local require                       = require

local log                           = require("hs.logger").new("PrefsDlg")

local axutils                       = require("cp.ui.axutils")
local Button                        = require("cp.ui.Button")
local Dialog                        = require("cp.ui.Dialog")
local just                          = require("cp.just")

local strings                       = require("cp.apple.finalcutpro.strings")

local If                            = require("cp.rx.go.If")
local Throw                         = require("cp.rx.go.Throw")
local WaitUntil                     = require("cp.rx.go.WaitUntil")


local CommandEditor = Dialog:subclass("cp.apple.finalcutpro.cmd.CommandEditor")

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
function CommandEditor.static.matches(element)
    if Dialog.matches(element) then
        return element:attributeValue("AXModal")
           and axutils.childWithRole(element, "AXPopUpButton") ~= nil
           and #axutils.childrenWithRole(element, "AXGroup") == 4
    end
    return false
end

--- cp.apple.finalcutpro.cmd.CommandEditor(app) -> CommandEditor
--- Constructor
--- Creates a new Command Editor object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `CommandEditor` object.
function CommandEditor:initialize(app)
    self._app = app

--- cp.apple.finalcutpro.cmd.CommandEditor.UI <cp.prop: axuielement; read-only>
--- Field
--- The `axuielement` for the window.
    local UI = app.windowsUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        CommandEditor.matches)
    end)

    Dialog.initialize(self, app.app, UI)
end

--- cp.apple.finalcutpro.cmd.CommandEditor.save <cp.ui.Button>
--- Field
--- The "Save" [Button](cp.ui.Button.md).
function CommandEditor.lazy.value:save()
    return Button(self, self.UI:mutate(function(original)
        return axutils.childFromRight(original(), 1, Button.matches)
    end))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.close <cp.ui.Button>
--- Field
--- The "Close" [Button](cp.ui.Button.md).
function CommandEditor.lazy.value:close()
    return Button(self, self.UI:mutate(function(original)
        return axutils.childFromRight(original(), 2, Button.matches)
    end))
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
        if self:app().menu:isEnabled({"Final Cut Pro", "Commands", "Customize…"}) then
            self:app().menu:selectMenu({"Final Cut Pro", "Commands", "Customize…"})
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
function CommandEditor.lazy.method:doShow()
    return If(self:app().isRunning):Then(
        If(self.isShowing):Is(false):Then(
            self:app().menu:selectMenu({"Final Cut Pro", "Commands", "Customize…"})
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
function CommandEditor.lazy.method:doHide()
    local alert = self:alert()
    local isHidden = self.isShowing:NOT()
    return If(self.isShowing):Then(
        self:doClose()
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

--- cp.apple.finalcutpro.cmd.CommandEditor:doSave() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that triggers the Save button in the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if the button was found and pushed, otherwise `false`.
function CommandEditor.lazy.method:doSave()
    return self.save:doPress()
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doClose() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that triggers the Close button in the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if the button was found and pushed, otherwise `false`.
function CommandEditor.lazy.method:doClose()
    return self.close:doPress()
end

return CommandEditor
