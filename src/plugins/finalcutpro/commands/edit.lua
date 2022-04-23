--- === plugins.finalcutpro.commands.edit ===
---
--- Provides support for allowing a user to assign a keyboard shortcut to a specific command.
--- This is particularly helpful if another plugin or feature requires a command to have a
--- keyboard shortcut, but it does not currently have one assigned.

local require               = require

local log                   = require "hs.logger".new "cmdedit"

local fcp                   = require "cp.apple.finalcutpro"
local go                    = require "cp.rx.go"
local i18n                  = require "cp.i18n"

local Do, Require           = go.Do, go.Require

local commandEditor         = fcp.commandEditor

local mod = {}

--- plugins.finalcutpro.commands.edit.doFindCommandIDInCommandEditor(commandID) -> cp.rx.go.Statement
--- Function
--- Returns a [Statement](cp.rx.go.Statement.md) that reveals the specified language-independent command ID in the Command Editor.
---
--- Parameters:
---  * commandID - The ID of the command to reveal, language-neutral. For example, "NextEdit", not "Go To Next Edit"
---
--- Returns:
---  * a [Statement](cp.rx.go.Statement.md) that returns `true` if the command was found and revealed, otherwise `false`.
function mod.doFindCommandIDInCommandEditor(commandID)
    return Do(
        Require(fcp:doLaunch()):Is(true):OrThrow(i18n("failedToLaunchFinalCutPro"))
    ):Then(
        Require(commandEditor:doFindCommandID(commandID)):Is(true):OrThrow(i18n("failedToFindCommandInCommandEditor", {command = commandID}))
    )
end

--- plugins.finalcutpro.commands.edit.doFindCommandNameInCommandEditor(commandID) -> cp.rx.go.Statement
--- Function
--- Returns a [Statement](cp.rx.go.Statement.md) that reveals the specified command name in the Command Editor, in the current language.
---
--- Parameters:
---  * commandName - The ID of the command to reveal, language-neutral. For example, "Go To Next Edit", not "NextEdit".
---
--- Returns:
---  * a [Statement](cp.rx.go.Statement.md) that returns `true` if the command was found and revealed, otherwise `false`.
function mod.doFindCommandNameInCommandEditor(commandName)
    return Do(
        Require(fcp:doLaunch()):Is(true):OrThrow(i18n("failedToLaunchFinalCutPro"))
    ):Then(
        Require(commandEditor:doFindCommandName(commandName)):Is(true):OrThrow(i18n("failedToFindCommandInCommandEditor", {command = commandName}))
    )
end


local plugin = {
    id = "finalcutpro.commands.edit",
    group = "finalcutpro",
}

function plugin.init()
    log.df("initializing finalcutpro.commands.edit plugin")
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    log.df("returning mod")

    return mod
end

return plugin