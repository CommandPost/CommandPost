--- === cp.apple.finalcutpro.cmd.CommandEditor ===
---
--- Command Editor Module.

local require                       = require

-- local log                           = require "hs.logger" .new "CmdEditor"

local just                          = require "cp.just"

local Button                        = require "cp.ui.Button"
local CheckBox                      = require "cp.ui.CheckBox"
local Dialog                        = require "cp.ui.Dialog"
local Group                         = require "cp.ui.Group"
local PopUpButton                   = require "cp.ui.PopUpButton"
local TextField                     = require "cp.ui.TextField"

local CommandList                   = require "cp.apple.finalcutpro.cmd.CommandList"

local strings                       = require "cp.apple.finalcutpro.strings"

local If                            = require "cp.rx.go.If"
local Throw                         = require "cp.rx.go.Throw"
local WaitUntil                     = require "cp.rx.go.WaitUntil"

local fn                            = require "cp.fn"
local ax                            = require "cp.fn.ax"
local chain                         = fn.chain
local get, ifilter                  = fn.table.get, fn.table.ifilter

local CommandEditor = Dialog:subclass("cp.apple.finalcutpro.cmd.CommandEditor")

--- cp.apple.finalcutpro.cmd.CommandEditor.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
CommandEditor.static.matches = ax.matchesIf(
    -- It's a Dialog
    Dialog.matches,
    -- It's a modal
    get "AXModal",
    -- It has a PopUpButton
    chain // ax.children >> ifilter(PopUpButton.matches) >> fn.table.hasAtLeast(1),
    -- It has 4 Groups
    chain // ax.children >> ifilter(Group.matches) >> fn.table.hasExactly(4)
)

-- _findWindowUI(windows) -> window | nil
-- Function
-- Gets the Window UI.
--
-- Parameters:
--  * windows - Table of windows.
--
-- Returns:
--  * An `axuielementObject` or `nil`
local _findWindowUI = fn.table.firstMatching(CommandEditor.matches)

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
    local UI = app.windowsUI:mutate(
        chain // ax.uielement >> _findWindowUI >> ax.cache(self, "_ui", CommandEditor.matches)
    )

    Dialog.initialize(self, app.app, UI)
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
    self.close:press()
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
                -- log.df("msg: %s", msg)
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
    return self.closeButton:doPress()
end

-- ==== Command Editor UI ====

--- cp.apple.finalcutpro.cmd.CommandEditor.save <cp.ui.Button>
--- Field
--- The "Save" [Button](cp.ui.Button.md).
function CommandEditor.lazy.value:save()
    return Button(self, self.UI:mutate(
        ax.childMatching(Button.matches, 1, ax.bottomUp)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.closeButton <cp.ui.Button>
--- Field
--- The "Close" [Button](cp.ui.Button.md).
function CommandEditor.lazy.value:closeButton()
    return Button(self, self.UI:mutate(
        ax.childMatching(Button.matches, 2, ax.bottomUp)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commandSet <cp.ui.PopUpButton>
--- Field
--- The "Command Set" [PopUpButton](cp.ui.PopUpButton.md).
function CommandEditor.lazy.value:commandSet()
    return PopUpButton(self, self.UI:mutate(
        ax.childMatching(PopUpButton.matches)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.modifiers <cp.ui.Group>
--- Field
--- The [Group](cp.ui.Group.md) containing 'modifier' checkboxes (Cmd, Shift, etc).
function CommandEditor.lazy.value:modifiers()
    return Group(self, self.UI:mutate(
        ax.childMatching(Group.matches, 1)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.command <cp.ui.CheckBox>
--- Field
--- The "Command" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:command()
    return CheckBox(self, self.modifiers.UI:mutate(
        ax.childMatching(CheckBox.matches, 1)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.shift <cp.ui.CheckBox>
--- Field
--- The "Shift" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:shift()
    return CheckBox(self, self.modifiers.UI:mutate(
        ax.childMatching(CheckBox.matches, 2)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.option <cp.ui.CheckBox>
--- Field
--- The "Option" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:option()
    return CheckBox(self, self.modifiers.UI:mutate(
        ax.childMatching(CheckBox.matches, 3)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.control <cp.ui.CheckBox>
--- Field
--- The "Control" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:control()
    return CheckBox(self, self.modifiers.UI:mutate(
        ax.childMatching(CheckBox.matches, 4)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.keyboardToggle <cp.ui.CheckBox>
--- Field
--- The "Keyboard Toggle" [CheckBox](cp.ui.CheckBox.md) (next to the Search field).
function CommandEditor.lazy.value:keyboardToggle()
    return CheckBox(self, self.UI:mutate(
        ax.childMatching(CheckBox.matches)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.search <cp.ui.TextField>
--- Field
--- The "Search" [TextField](cp.ui.TextField.md).
function CommandEditor.lazy.value:search()
    return TextField(self, self.UI:mutate(
        ax.childMatching(TextField.matches)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.keyboard <cp.ui.Group>
--- Field
--- The [Group](cp.ui.Group.md) containing the keyboard shortcuts. Does not seem to expose the actual key buttons.
function CommandEditor.lazy.value:keyboard()
    return Group(self, self.UI:mutate(
        ax.childMatching(Group.matches, 2)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commandList <cp.apple.finalcutpro.cmd.CommandList>
--- Field
--- The [CommandList](cp.apple.finalcutpro.cmd.CommandList.md).
function CommandEditor.lazy.value:commandList()
    return CommandList(self, self.UI:mutate(
        ax.childMatching(Group.matches, 3)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandEditor.keyDetail <cp.appple.finalcutpro.cmd.KeyDetail>
--- Field
--- The [KeyDetail](cp.apple.finalcutpro.cmd.KeyDetail.md) section.
function CommandEditor.lazy.value:keyDetail()
    return Group(self, self.UI:mutate(
        ax.childMatching(Group.matches, 4)
    ))
end

return CommandEditor
