--- === plugins.core.preferences.advanced ===
---
--- Advanced Preferences Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log				= require("hs.logger").new("prefadv")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog			= require("hs.dialog")
local ipc				  = require("hs.ipc")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config			= require("cp.config")
local html				= require("cp.web.html")
local i18n        = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.advanced.trashPreferences() -> none
--- Function
--- Resets all of the CommandPost Preferences to their default values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.trashPreferences()
    dialog.webviewAlert(mod.manager.getWebview(), function(result)
        if result == i18n("yes") then
            config.reset()
        end
    end, i18n("trashPreferencesConfirmation"), "", i18n("yes"), i18n("no"), "informational")
end

--- plugins.core.preferences.advanced.toggleEnableAutomaticScriptReloading() -> none
--- Function
--- Toggles the Automatic Script Reloading.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleEnableAutomaticScriptReloading()
    config.automaticScriptReloading:toggle()
end

--- plugins.core.preferences.advanced.developerMode <cp.prop: boolean>
--- Field
--- Enables or disables developer mode.
mod.developerMode = config.developerMode

--- plugins.core.preferences.advanced.toggleDeveloperMode() -> none
--- Function
--- Toggles the Developer Mode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleDeveloperMode()
    mod.developerMode:toggle()
    mod.manager.refresh()
end

--- plugins.core.preferences.advanced.openErrorLog() -> none
--- Function
--- Opens the Error Log
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openErrorLog()
    hs.openConsole()
end

--
-- Get Command Line Tool Title:
--
local function getCommandLineToolTitle()
    local cliStatus = ipc.cliStatus()
    if cliStatus then
        return i18n("uninstall")
    else
        return i18n("install")
    end
end

--- plugins.core.preferences.advanced.toggleCommandLineTool() -> none
--- Function
--- Toggles the Command Line Tool
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleCommandLineTool()

    local cliStatus = ipc.cliStatus()
    if cliStatus then
        --log.df("Uninstalling Command Line Tool")
        ipc.cliUninstall()
    else
        --log.df("Installing Command Line Tool")
        ipc.cliInstall()
    end

    local newCliStatus = ipc.cliStatus()
    if cliStatus == newCliStatus then
        if cliStatus then
            dialog.webviewAlert(mod.manager.getWebview(), function()
                mod.manager.refresh()
            end, i18n("cliUninstallError"), "", i18n("ok"), nil, "informational")
        else
            dialog.webviewAlert(mod.manager.getWebview(), function()
                mod.manager.refresh()
            end, i18n("cliInstallError"), "", i18n("ok"), nil, "informational")
        end
    else
        mod.manager.refresh()
    end

end

--- plugins.core.preferences.advanced.openErrorLogOnDockClick <cp.prop: boolean>
--- Variable
--- Open Error Log on Dock Icon Click.
mod.openErrorLogOnDockClick = config.prop("openErrorLogOnDockClick", true)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "core.preferences.advanced",
    group			= "core",
    dependencies	= {
        ["core.preferences.panels.advanced"]	= "advanced",
        ["core.preferences.manager"]			= "manager",
        ["core.commands.global"] 				= "global",
    }
}
--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    mod.manager = deps.manager

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpOpenErrorLog")
        :whenActivated(mod.openErrorLog)
        :groupedBy("commandPost")

    global:add("cpTrashPreferences")
        :whenActivated(mod.trashPreferences)
        :groupedBy("commandPost")

    --------------------------------------------------------------------------------
    -- Create Dock Icon Click Callback:
    --------------------------------------------------------------------------------
    config.dockIconClickCallback:new("cp", function()
        if mod.openErrorLogOnDockClick() then hs.openConsole() end
    end)

    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    deps.advanced

        :addHeading(60, i18n("developer"))

        :addCheckbox(61,
            {
                label = i18n("enableDeveloperMode"),
                onchange = mod.toggleDeveloperMode,
                checked = mod.developerMode,
            }
        )

        :addCheckbox(61.1,
            {
                label = i18n("enableAutomaticScriptReloading"),
                onchange = mod.toggleEnableAutomaticScriptReloading,
                checked = config.automaticScriptReloading(),
            }
        )

        :addHeading(62, i18n("errorLog"))

        :addCheckbox(63,
            {
                label = i18n("openErrorLogOnDockClick"),
                onchange = function() mod.openErrorLogOnDockClick:toggle() end,
                checked = mod.openErrorLogOnDockClick
            }
        )

        :addButton(64,
            {
                label = i18n("openErrorLog"),
                width = 200,
                onclick = mod.openErrorLog,
            }
        )

        :addHeading(70, i18n("commandLineTool"))
        :addButton(75,
            {
                label	= getCommandLineToolTitle(),
                width	= 200,
                onclick	= mod.toggleCommandLineTool,
                id		= "commandLineTool",
            }
        )
        :addParagraph(76, html.span {class="tip"} (
            html.strong(string.upper(i18n("tip") .. ": ")) .. html(i18n("commandLineToolDescription"), false)
        ))

        :addHeading(80, i18n("advanced"))
        :addButton(85,
            {
                label	= i18n("trashPreferences"),
                width	= 200,
                onclick	= mod.trashPreferences,
            }
        )
        :addParagraph(85.1, html.span {class="tip"} (
            html.strong(string.upper(i18n("tip")) .. ": ") .. html(i18n("trashPreferencesDescription"), false)
        ))

end

return plugin
