--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        W E L C O M E   S C R E E N                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.welcome.manager ===
---
--- Manager for the CommandPost Welcome Screen.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("welcome")

local screen									= require("hs.screen")
local timer										= require("hs.timer")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local config									= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local WEBVIEW_LABEL								= "welcome"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWidth 							= 900
mod.defaultHeight 							= 470
mod.defaultTitle 							= i18n("welcomeTitle")
mod._panels									= {}

--------------------------------------------------------------------------------
-- SET PANEL TEMPLATE PATH:
--------------------------------------------------------------------------------
function mod.setPanelRenderer(renderer)
	mod.renderPanel = renderer
end

--------------------------------------------------------------------------------
-- GET LABEL:
--------------------------------------------------------------------------------
function mod.getLabel()
	return WEBVIEW_LABEL
end

--------------------------------------------------------------------------------
-- HIGHEST PRIORITY ID:
--------------------------------------------------------------------------------
local function highestPriorityID()

	local sortedPanels = mod._panels
	table.sort(sortedPanels, function(a, b) return a.priority < b.priority end)
	return mod._panels[1]["id"]

end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML()

	local env = {}

	env.panels = mod._panels
	env.highestPriorityID = highestPriorityID()

	local result, err = mod.renderPanel(env)
	if err then
		log.ef("Error while rendering Welcome Panel: %s", err)
		return err
	else
		return result
	end
end

--------------------------------------------------------------------------------
-- SETUP THE USER INTERFACE ONCE WELCOME SCREEN IS COMPLETE:
--------------------------------------------------------------------------------
function mod.setupUserInterface(showNotification)

	--------------------------------------------------------------------------------
	-- Initialise Menu Manager:
	--------------------------------------------------------------------------------
	mod.menumanager.init()

	--------------------------------------------------------------------------------
	-- Initialise Shortcuts:
	--------------------------------------------------------------------------------
	mod.shortcuts.init()

	--------------------------------------------------------------------------------
	-- Enable Shortcuts:
	--------------------------------------------------------------------------------
	mod.enableUserInterface()

	--------------------------------------------------------------------------------
	-- Notifications:
	--------------------------------------------------------------------------------
	if showNotification then
		log.df("Successfully loaded.")
		dialog.displayNotification(config.appName .. " (v" .. config.appVersion .. ") " .. i18n("hasLoaded"))
	end

end

--------------------------------------------------------------------------------
-- DISABLE THE USER INTERFACE:
--------------------------------------------------------------------------------
function mod.disableUserInterface()

	mod.menumanager.disable()

	local allGroups = commands.groupIds()
	for i, v in ipairs(allGroups) do
    	commands.group(v):disable()
    end

end

--------------------------------------------------------------------------------
-- ENABLE THE USER INTERFACE:
--------------------------------------------------------------------------------
function mod.enableUserInterface()

	mod.menumanager.enable()

	local allGroups = commands.groupIds()
	for i, v in ipairs(allGroups) do
    	commands.group(v):enable()
    end

end

--------------------------------------------------------------------------------
-- CHECK IF WE NEED THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.init()
	--------------------------------------------------------------------------------
	-- Can we just skip the welcome screen?
	--------------------------------------------------------------------------------
	if hs.accessibilityState() and config.get("welcomeComplete", false) then
		mod.setupUserInterface(true)
	else
		mod.new()
	end
end

--------------------------------------------------------------------------------
-- CREATE THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.new()

	--------------------------------------------------------------------------------
	-- Centre on Screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultRect = {x = (screenFrame['w']/2) - (mod.defaultWidth/2), y = (screenFrame['h']/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.controller = webview.usercontent.new(WEBVIEW_LABEL)
		:setCallback(function(message)
			--------------------------------------------------------------------------------
			-- Trigger Callbacks:
			--------------------------------------------------------------------------------
			for i, v in ipairs(mod._panels) do
				if type(v["callbackFn"]) == "function" then
					v["callbackFn"](message)
				end
			end
		end)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local developerExtrasEnabled = {}
	if config.get("debugMode") then developerExtrasEnabled = {developerExtrasEnabled = true} end
	mod.webview = webview.new(defaultRect, developerExtrasEnabled, mod.controller)
		:windowStyle({"titled", "closable", "nonactivating"})
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:html(generateHTML())
		:toolbar(mod.toolbar)

	--------------------------------------------------------------------------------
	-- Select Panel:
	--------------------------------------------------------------------------------
	mod.selectPanel(highestPriorityID())

	--------------------------------------------------------------------------------
	-- Show Welcome Screen:
	--------------------------------------------------------------------------------
	mod.webview:show()
	timer.doAfter(0.1, function() mod.webview:hswindow():focus() end)

end

--------------------------------------------------------------------------------
-- DELETE WEBVIEW:
--------------------------------------------------------------------------------
function mod.delete()
	mod.webview:delete()
	mod.webview = nil
end

--------------------------------------------------------------------------------
-- INJECT SCRIPT:
--------------------------------------------------------------------------------
function mod.injectScript(script)
	if mod.webview then
		mod.webview:evaluateJavaScript(script)
	end
end

--------------------------------------------------------------------------------
-- NEXT PRIORITY ID:
--------------------------------------------------------------------------------
local function nextPriorityID(currentPanelPriority)

	local sortedPanels = mod._panels
	table.sort(sortedPanels, function(a, b) return a.priority < b.priority end)

	for i, v in ipairs(sortedPanels) do
		if v["priority"] > currentPanelPriority then
			return v["id"]
		end
	end

end

--------------------------------------------------------------------------------
-- NEXT PANEL:
--------------------------------------------------------------------------------
function mod.nextPanel(currentPanelPriority)

	currentPanelPriority = currentPanelPriority + 0.0000000000001

	local nextPanelID = nextPriorityID(currentPanelPriority)
	if nextPanelID then
		mod.selectPanel(nextPanelID)
	else
		log.ef("There is no next panel...")
	end

end

--------------------------------------------------------------------------------
-- SELECT PANEL:
--------------------------------------------------------------------------------
function mod.selectPanel(id)

	--log.df("Selecting Panel with ID: %s", id)

	local javascriptToInject = ""

	for i, v in ipairs(mod._panels) do
		if v["id"] == id then
			javascriptToInject = javascriptToInject .. [[
				document.getElementById(']] .. v["id"] .. [[').style.display = 'block';
				document.getElementById('dot]] .. v["id"] .. [[').className = 'selected-dot';
			]]
		else
			javascriptToInject = javascriptToInject .. [[
				document.getElementById(']] .. v["id"] .. [[').style.display = 'none';
				document.getElementById('dot]] .. v["id"] .. [[').className = '';
			]]
		end
	end

	mod.webview:evaluateJavaScript(javascriptToInject)

end

--------------------------------------------------------------------------------
-- ADD PANEL:
--------------------------------------------------------------------------------
function mod.addPanel(id, priority, contentFn, callbackFn)

	--log.df("Adding Welcome Panel with ID: %s", id)

	mod._panels[#mod._panels + 1] = {
		id = id,
		priority = priority,
		contentFn = contentFn,
		callbackFn = callbackFn,
	}

end

--------------------------------------------------------------------------------
-- ACCESSIBILITY STATE CALLBACK:
--------------------------------------------------------------------------------
function hs.accessibilityStateCallback()
	--log.df("Accessibility State Changed.")
	if not hs.accessibilityState() and config.get("welcomeComplete", false) and mod.webview == nil then
		mod.disableUserInterface()
		mod.new()
	end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.welcome.manager",
	group			= "core",
	dependencies	= {
		["core.menu.manager"]						= "menumanager",
		["finalcutpro.hacks.shortcuts"] 			= "shortcuts",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	mod.setPanelRenderer(env:compileTemplate("html/template.html"))
	return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)

	mod.menumanager = deps.menumanager
	mod.shortcuts = deps.shortcuts

	return mod.init()

end

return plugin