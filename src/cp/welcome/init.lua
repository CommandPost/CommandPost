--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        W E L C O M E   S C R E E N                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------

local application								= require("hs.application")
local drawing									= require("hs.drawing")
local geometry									= require("hs.geometry")
local screen									= require("hs.screen")
local timer										= require("hs.timer")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")
local template									= require("cp.template")
local tools										= require("cp.tools")

local log										= require("hs.logger").new("welcome")

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------

mod.defaultWidth 		= 900
mod.defaultHeight 		= 470
mod.defaultTitle 		= i18n("welcomeTitle")

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML(whichTemplate)

	local env = template.defaultEnv()

	env.i18n = i18n
	env.scriptName = metadata.scriptName
	env.content = template.compileFile(metadata.scriptPath .. "/cp/welcome/html/" .. whichTemplate .. ".htm", env)

	return template.compileFile(metadata.scriptPath .. "/cp/welcome/html/template.htm", env)

end

--------------------------------------------------------------------------------
-- RETRIEVES THE PLUGINS MANAGER:
-- If `pluginPath` is provided, the named plugin will be returned. If not,
-- the plugins module is returned.
--------------------------------------------------------------------------------
function plugins(pluginPath)
	if not mod._plugins then
		mod._plugins = require("cp.plugins")
		mod._plugins.init("cp.plugins")
	end

	if pluginPath then
		return mod._plugins(pluginPath)
	else
		return mod._plugins
	end
end

--------------------------------------------------------------------------------
-- RETRIEVES THE MENU MANAGER:
--------------------------------------------------------------------------------
function menuManager()
	if not mod._menuManager then
		mod._menuManager = plugins("cp.plugins.menu.manager")
	end
	return mod._menuManager
end

--------------------------------------------------------------------------------
-- LOAD COMMANDPOST:
--------------------------------------------------------------------------------
local function loadCommandPost(showNotification)
	menuManager()
	if showNotification then
		log.df("Successfully loaded.")
		dialog.displayNotification(metadata.scriptName .. " (v" .. metadata.scriptVersion .. ") " .. i18n("hasLoaded"))
	end
end

--------------------------------------------------------------------------------
-- CREATE THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.init()

	--------------------------------------------------------------------------------
	-- Can we just skip the welcome screen?
	--------------------------------------------------------------------------------
	if hs.accessibilityState() and metadata.get("welcomeComplete", false) then
		loadCommandPost(true)
		return
	end

	--------------------------------------------------------------------------------
	-- Centre on Screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultRect = {x = (screenFrame['w']/2) - (mod.defaultWidth/2), y = (screenFrame['h']/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	mod.welcomeWebView = webview.new(defaultRect)
		:windowStyle({"titled"})
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)

	--------------------------------------------------------------------------------
	-- Check Final Cut Pro Version:
	--------------------------------------------------------------------------------
	local fcpVersion = fcp:getVersion()
    if fcpVersion:sub(1,4) == "10.3" then
		mod.welcomeWebView:html(generateHTML("intro"))
	else
		mod.welcomeWebView:html(generateHTML("finalcutpromissing"))
	end

	--------------------------------------------------------------------------------
	-- Setup URL Events:
	--------------------------------------------------------------------------------
	mod.urlEvent = urlevent.bind("welcome", function(eventName, params)

		if params["screen"] == "accessibility" then
			if not hs.accessibilityState() then
				mod.welcomeWebView:html(generateHTML("accessibility"))
			else
				mod.welcomeWebView:html(generateHTML("scanfinalcutpro"))
			end
		elseif params["screen"] == "commandset" then
			if metadata.get("enableHacksShortcutsInFinalCutPro", false) then
				loadCommandPost()
				metadata.set("welcomeComplete", true)
				mod.welcomeWebView:html(generateHTML("complete"))
			else
				mod.welcomeWebView:html(generateHTML("commandset"))
			end
		elseif params["screen"] == "complete" then
			loadCommandPost()
			metadata.set("welcomeComplete", true)
			mod.welcomeWebView:html(generateHTML("complete"))
		elseif params["action"] == "checkaccessibility" then
			hs.accessibilityState(true)
			local accessibilityStateCheck = timer.doEvery(1, function()
				if hs.accessibilityState() then
					mod.welcomeWebView:html(generateHTML("scanfinalcutpro"))
					timer.doAfter(0.1, function() mod.welcomeWebView:hswindow():focus() end)
					if accessibilityStateCheck then accessibilityStateCheck:stop() end
				end
			end)
		elseif params["action"] == "scanfinalcutpro" then
			local scanFCP = plugins("cp.plugins.cp.scanfinalcutpro")
			local scanResult = scanFCP.scanFinalCutPro()
			if scanResult then
				mod.welcomeWebView:html(generateHTML("commandset"))
			else
				mod.welcomeWebView:html(generateHTML("scanfinalcutpro"))
			end
			timer.doAfter(0.1, function() mod.welcomeWebView:hswindow():focus() end)
		elseif params["action"] == "addshortcuts" then
			local shortcutsPlugin = plugins("cp.plugins.hacks.shortcuts")
			local result = shortcutsPlugin.enableHacksShortcuts()
			if result then
				if fcp:isRunning() then fcp:restart() end
				metadata.set("enableHacksShortcutsInFinalCutPro", true)
				mod.welcomeWebView:html(generateHTML("complete"))
				timer.doAfter(0.1, function() mod.welcomeWebView:hswindow():focus() end)
			end
		elseif params["action"] == "close" then
			mod.welcomeWebView:delete()
		elseif params["action"] == "quit" then
			metadata.application():kill()
		else
			dialog.displayMessage("Opps! Something went wrong. CommandPost will now quit.")
			metadata.application():kill()
		end

	end)

	--------------------------------------------------------------------------------
	-- Show Welcome Screen:
	--------------------------------------------------------------------------------
	mod.welcomeWebView:show()
	timer.doAfter(0.1, function() mod.welcomeWebView:hswindow():focus() end)

	return mod

end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------
return mod.init()