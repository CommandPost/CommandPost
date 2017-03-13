local application		= require("hs.application")
local log				= require("hs.logger").new("preferences")
local console			= require("hs.console")

local metadata			= require("cp.metadata")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")

--- The Function:

local PRIORITY = 90000
local MENUBAR_OPTIONS_PRIORITY = 10001

local DEFAULT_DISPLAY_MENUBAR_AS_ICON = true
local DEFAULT_ENABLE_PROXY_MENU_ICON = false

local function resetSettings()

	local finalCutProRunning = fcp:isRunning()

	local resetMessage = i18n("trashFCPXHacksPreferences")
	if finalCutProRunning then
		resetMessage = resetMessage .. "\n\n" .. i18n("adminPasswordRequiredAndRestart")
	else
		resetMessage = resetMessage .. "\n\n" .. i18n("adminPasswordRequired")
	end

	if not dialog.displayYesNoQuestion(resetMessage) then
		return
	end

	--------------------------------------------------------------------------------
	-- Remove Hacks Shortcut in Final Cut Pro:
	--------------------------------------------------------------------------------
	plugins("cp.plugins.hacks.shortcuts").disableHacksShortcuts()

	--------------------------------------------------------------------------------
	-- Trash all Script Settings:
	--------------------------------------------------------------------------------
	metadata.reset()

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro if running:
	--------------------------------------------------------------------------------
	if finalCutProRunning then
		if not fcp:restart() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			dialog.displayMessage(i18n("restartFinalCutProFailed"))
		end
	end

	--------------------------------------------------------------------------------
	-- Reload Hammerspoon:
	--------------------------------------------------------------------------------
	console.clearConsole()
	hs.reload()

end

local function toggleDeveloperMode()
	local debugMode = metadata.get("debugMode")
	metadata.set("debugMode", not debugMode)
	console.clearConsole()
	hs.reload()
end

local function toggleEnableProxyMenuIcon()
	local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
	metadata.set("enableProxyMenuIcon", not enableProxyMenuIcon)
	menuManager():updateMenubarIcon()
end

local function toggleDisplayMenubarAsIcon()
	local displayMenubarAsIcon = metadata.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
	metadata.set("displayMenubarAsIcon", not displayMenubarAsIcon)
	menuManager():updateMenubarIcon()
end

local function getDeveloperMode()
	return metadata.get("debugMode")
end

local function getEnableProxyMenuIcon()
	return metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
end

local function getDisplayMenubarAsIcon()
	return metadata.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
end

--- The Plugin:

local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.preferences"]	= "prefs",
	["cp.plugins.menu.preferences.menubar"] = "menubar",
}

function plugin.init(deps)

	deps.prefs:addItem(PRIORITY, function()
		return { title = i18n("launchAtStartup"),	fn = function() hs.autoLaunch(not hs.autoLaunch()) end, checked = hs.autoLaunch() }
	end)

	:addSeparator(PRIORITY+1)

	:addItem(PRIORITY+2, function()
		return { title = i18n("enableDeveloperMode"),	fn = toggleDeveloperMode, checked = getDeveloperMode() }
	end)

	:addSeparator(PRIORITY+3)

	:addItem(PRIORITY+4, function()
		return { title = i18n("openErrorLog"),	fn = function() hs.openConsole() end }
	end)

	:addItem(PRIORITY+5, function()
		return { title = i18n("trashPreferences"),	fn = resetSettings }
	end)

	-- MENUBAR:

	deps.menubar:addSeparator(MENUBAR_OPTIONS_PRIORITY)

	:addItem(MENUBAR_OPTIONS_PRIORITY+1, function()
		return { title = i18n("displayProxyOriginalIcon"),	fn = toggleEnableProxyMenuIcon, checked = getEnableProxyMenuIcon() }
	end)

	:addItem(MENUBAR_OPTIONS_PRIORITY+1, function()
		return { title = i18n("displayThisMenuAsIcon"),	fn = toggleDisplayMenubarAsIcon, checked = getDisplayMenubarAsIcon() }
	end)

end

return plugin