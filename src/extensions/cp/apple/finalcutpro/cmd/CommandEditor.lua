--- === cp.apple.finalcutpro.cmd.CommandEditor ===
---
--- Command Editor Module.

local require                       = require

local log                           = require "hs.logger" .new "CmdEditor"

local just                          = require "cp.just"

local has                           = require "cp.ui.has"
local Button                        = require "cp.ui.Button"
local CheckBox                      = require "cp.ui.CheckBox"
local Dialog                        = require "cp.ui.Dialog"
local Group                         = require "cp.ui.Group"
local PopUpButton                   = require "cp.ui.PopUpButton"
local StaticText                    = require "cp.ui.StaticText"
local TextField                     = require "cp.ui.TextField"

local CommandDetail                 = require "cp.apple.finalcutpro.cmd.CommandDetail"
local CommandList                   = require "cp.apple.finalcutpro.cmd.CommandList"
local KeyDetail                     = require "cp.apple.finalcutpro.cmd.KeyDetail"

local strings                       = require "cp.apple.finalcutpro.strings"

local Do                            = require "cp.rx.go.Do"
local If                            = require "cp.rx.go.If"
local Throw                         = require "cp.rx.go.Throw"
local WaitUntil                     = require "cp.rx.go.WaitUntil"

local fn                            = require "cp.fn"
local ax                            = require "cp.fn.ax"
local chain                         = fn.chain
local get                           = fn.table.get

local list, alias, oneOf            = has.list, has.alias, has.oneOf

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
    -- It's modal
    get "AXModal",
    -- It has the required children:
    chain // ax.childrenTopDown >> fn.all(
        -- The `commandSet` PopUpButton ...
        chain // get(5) >> PopUpButton.matches,
        -- The `keyboard` Group...
        chain // get(9) >> Group.matches,
        -- The `commandList`...
        chain // get(10) >> CommandList.matches
    )
)

CommandEditor.static.children = list {
    alias "close" { Button }, alias "minimize" { Button }, alias "zoom" { Button },
    alias "windowTitle" { StaticText },
    alias "commandSet" { PopUpButton },
    alias "modifiers" {
        Group:containing {
            alias "command" { CheckBox },
            alias "shift" { CheckBox },
            alias "option" { CheckBox },
            alias "control" { CheckBox },
        }
    },
    alias "keyboardToggle" { CheckBox },
    alias "search" { TextField:forcingFocus(true) },
    alias "keyboard" { Group },
    alias "commandList" { CommandList },
    alias "detail" {
        oneOf {
            alias "commandDetail" { CommandDetail },
            alias "keyDetail" { KeyDetail },
        },
    },
    Button, -- "Close"
    alias "saveButton" { Button },
    has.ended
}

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
--- cp.apple.finalcutpro.cmd.CommandEditor.UI <cp.prop: axuielement; read-only>
--- Field
--- The `axuielement` for the window.
    local UI = app.windowsUI:mutate(
        ax.cache(self, "_ui", CommandEditor.matches)(
            chain // ax.children >> fn.table.firstMatching(CommandEditor.matches)
        )
    )

    Dialog.initialize(self, app.app, UI)
    self.__app = app
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
    return self.__app
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
    return If(self:app().isRunning)
    :Then(self:app():doShow())
    :Then(
        If(self.isShowing):Is(false):Then(
            self:app().menu:doSelectMenu({"Final Cut Pro", "Commands", "Customize…"})
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
    self.closeButton:press()
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

-----------------------------------------------------------------------
-- Command Editor UI
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.cmd.CommandEditor.childrenUI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` list for the children of the Command Editor.
function CommandEditor.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren")
end

--- cp.apple.finalcutpro.cmd.CommandEditor.childrenInNavigationOrderUI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` list for the children of the Command Editor, in navigation order.
function CommandEditor.lazy.prop:childrenInNavigationOrderUI()
    return ax.prop(self.UI, "AXChildrenInNavigationOrder")
end

--- cp.apple.finalcutpro.cmd.CommandEditor.children <cp.ui.has.ElementList>
--- Field
--- The [ElementList](cp.ui.ElementList.md) of the children of the Command Editor.
function CommandEditor.lazy.value:children()
    return self.class.children:build(self, self.childrenInNavigationOrderUI)
end

--- cp.apple.finalcutpro.cmd.CommandEditor.saveButton <cp.ui.Button>
--- Field
--- The "Save" [Button](cp.ui.Button.md).
function CommandEditor.lazy.value:saveButton()
    return self.children.saveButton
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commandSet <cp.ui.PopUpButton>
--- Field
--- The "Command Set" [PopUpButton](cp.ui.PopUpButton.md).

--- cp.apple.finalcutpro.cmd.CommandEditor.modifiers <cp.ui.Group>
--- Field
--- The [Group](cp.ui.Group.md) containing 'modifier' checkboxes (Cmd, Shift, etc).
function CommandEditor.lazy.value:modifiers()
    return self.children.modifiers
end

--- cp.apple.finalcutpro.cmd.CommandEditor.command <cp.ui.CheckBox>
--- Field
--- The "Command" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:command()
    return self.modifiers.children.command
end

--- cp.apple.finalcutpro.cmd.CommandEditor.shift <cp.ui.CheckBox>
--- Field
--- The "Shift" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:shift()
    return self.modifiers.children.shift
end

--- cp.apple.finalcutpro.cmd.CommandEditor.option <cp.ui.CheckBox>
--- Field
--- The "Option" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:option()
    return self.modifiers.children.option
end

--- cp.apple.finalcutpro.cmd.CommandEditor.control <cp.ui.CheckBox>
--- Field
--- The "Control" [CheckBox](cp.ui.CheckBox.md).
function CommandEditor.lazy.value:control()
    return self.modifiers.children.control
end

--- cp.apple.finalcutpro.cmd.CommandEditor.keyboardToggle <cp.ui.CheckBox>
--- Field
--- The "Keyboard Toggle" [CheckBox](cp.ui.CheckBox.md) (next to the Search field).
function CommandEditor.lazy.value:keyboardToggle()
    return self.children.keyboardToggle
end

--- cp.apple.finalcutpro.cmd.CommandEditor.search <cp.ui.TextField>
--- Field
--- The "Search" [TextField](cp.ui.TextField.md).
function CommandEditor.lazy.value:search()
    return self.children.search
end

--- cp.apple.finalcutpro.cmd.CommandEditor.keyboard <cp.ui.Group>
--- Field
--- The [Group](cp.ui.Group.md) containing the keyboard shortcuts. Does not seem to expose the actual key buttons.
function CommandEditor.lazy.value:keyboard()
    return self.children.keyboard
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commandList <cp.apple.finalcutpro.cmd.CommandList>
--- Field
--- The [CommandList](cp.apple.finalcutpro.cmd.CommandList.md).
function CommandEditor.lazy.value:commandList()
    return self.children.commandList
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commands <cp.apple.finalcutpro.cmd.Commands>
--- Field
--- The [Commands](cp.apple.finalcutpro.cmd.Commands.md).
function CommandEditor.lazy.value:commands()
    return self.commandList.commands
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commandGroups <cp.apple.finalcutpro.cmd.CommandGroups>
--- Field
--- The [CommandGroups](cp.apple.finalcutpro.cmd.CommandGroups.md).
function CommandEditor.lazy.value:commandGroups()
    return self.commandList.groups
end

--- cp.apple.finalcutpro.cmd.CommandEditor.keyDetail <cp.appple.finalcutpro.cmd.KeyDetail>
--- Field
--- The [KeyDetail](cp.apple.finalcutpro.cmd.KeyDetail.md) section.
--- Either this or [commandDetail](#commandDetail) will be visible at any given time.
function CommandEditor.lazy.value:keyDetail()
    return self.children.detail.keyDetail
end

--- cp.apple.finalcutpro.cmd.CommandEditor.commandDetail <cp.apple.finalcutpro.cmd.CommandDetail>
--- Field
--- The [CommandDetail](cp.apple.finalcutpro.cmd.CommandDetail.md) section.
--- Either this or [keyDetail](#keyDetail) will be visible at any given time.
function CommandEditor.lazy.value:commandDetail()
    return self.children.detail.commandDetail
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doFindCommandID(commandID, [highlight]) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will find the command with the given ID,
--- revealing it at the top of the [commands](#commands) list.
---
--- Parameters:
---  * commandID - The locale-neutral ID of the command to find. Eg. "NextEdit" (ID), not "Go To Next Edit" (English)
---  * highlight - (optional) If true, the command will be highlighted in the list.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md).
function CommandEditor:doFindCommandID(commandID, highlight)
    return Do(function()
        local commandName = self:app().commandNames:find(commandID)
        if commandName == nil then
            log.wf("Unable to find command with ID: %s", commandID)
            return false
        end
        return self:doFindCommandName(commandName, highlight)
    end)
    :Label("CommandEditor:doFindCommandID")
end

--- cp.apple.finalcutpro.cmd.CommandEditor:doFindCommandID(commandID, [highlight]) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will find the command with the given ID,
--- revealing it at the top of the [commands](#commands) list.
---
--- Parameters:
---  * commandID - The locale-neutral ID of the command to find. Eg. "NextEdit" (ID), not "Go To Next Edit" (English)
---  * highlight - (optional) If `true`, the command will be highlighted in the list.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md).
function CommandEditor:doFindCommandName(commandName, highlight)
    return If(self:doShow()):Then(function()
        self.search.value:set(commandName)
        local rowNumber = 1
        local row = self.commands:row(rowNumber)
        while row:isShowing() do
            if row:command() == commandName then
                row:selected(true)
                if highlight then
                    row:doHighlight():Now()
                end
                return true
            end
            rowNumber = rowNumber + 1
            row = self.commands:row(rowNumber)
        end
        return false
    end)
    :Otherwise(false)
    :Label("CommandEditor:doFindCommandName")
end



return CommandEditor
