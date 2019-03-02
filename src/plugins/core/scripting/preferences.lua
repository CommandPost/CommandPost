--- === plugins.core.scripting.preferences ===
---
--- Scripting Preferences.

local require           = require

local hs                = hs

local dialog			= require("hs.dialog")
local ipc				= require("hs.ipc")
local timer             = require("hs.timer")

local config			= require("cp.config")
local html				= require("cp.web.html")
local i18n              = require("cp.i18n")

local execute           = hs.execute
local allowAppleScript  = hs.allowAppleScript

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- getCommandLineToolTitle() -> string
-- Function
-- Returns either "Install" or "Uninstall" as a string.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string
local function getCommandLineToolTitle()
    local cliStatus = ipc.cliStatus()
    if cliStatus then
        return i18n("uninstall")
    else
        return i18n("install")
    end
end

-- updatePreferences() -> none
-- Function
-- Updates the Preferences Panel UI.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updatePreferences()
    mod.manager.injectScript([[changeCheckedByID('commandLineTool', ]] .. tostring(ipc.cliStatus(nil, true)) .. [[);]])
    --------------------------------------------------------------------------------
    -- Sometimes it takes a little while to uninstall the CLI:
    --------------------------------------------------------------------------------
    timer.doAfter(0.5, function()
        mod.manager.injectScript([[changeCheckedByID('commandLineTool', ]] .. tostring(ipc.cliStatus(nil, true)) .. [[);]])
    end)
end

-- toggleCommandLineTool() -> none
-- Function
-- Toggles the Command Line Tool
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function toggleCommandLineTool()
    local cliStatus = ipc.cliStatus()
    if cliStatus then
        ipc.cliUninstall()
    else
        ipc.cliInstall()
    end
    local newCliStatus = ipc.cliStatus()
    if cliStatus == newCliStatus then
        if cliStatus then
            dialog.webviewAlert(mod.manager.getWebview(), function()
                updatePreferences()
            end, i18n("cliUninstallError"), "", i18n("ok"), nil, "informational")
        else
            dialog.webviewAlert(mod.manager.getWebview(), function()
                updatePreferences()
            end, i18n("cliInstallError"), "", i18n("ok"), nil, "informational")
        end
    else
        updatePreferences()
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "core.preferences.advanced",
    group			= "core",
    dependencies	= {
        ["core.preferences.manager"]			= "manager",
        ["core.preferences.panels.scripting"]	= "scripting",
    }
}

function plugin.init(deps)
    mod.manager = deps.manager
    local scripting = deps.scripting
    scripting

        --------------------------------------------------------------------------------
        -- Command Line Tool:
        --------------------------------------------------------------------------------
        :addHeading(1, i18n("scriptingTools"))
        :addCheckbox(2,
            {
                label		= i18n("enableCommandLineSupport"),
                checked		= function() return ipc.cliStatus() end,
                onchange	= toggleCommandLineTool,
                id		    = "commandLineTool",
            }
        )

        --------------------------------------------------------------------------------
        -- AppleScript:
        --------------------------------------------------------------------------------
        :addCheckbox(3,
            {
                label		= i18n("enableAppleScriptSupport"),
                checked		= function() return allowAppleScript() end,
                onchange	= function()
                                local value = allowAppleScript()
                                allowAppleScript(not value)
                            end,
            }
        )

        --------------------------------------------------------------------------------
        -- Learn More Button:
        --------------------------------------------------------------------------------
        :addContent(4, [[<br />]], false)
        :addButton(5,
            {
                label 	    = "Learn More...",
                width       = 100,
                onclick	    = function() execute("open 'https://help.commandpost.io/advanced/controlling_commandpost'") end,
            }
        )
end

return plugin