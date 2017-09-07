--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp ===
---
--- Core CommandPost functionality

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local logger					= require("hs.logger"); logger.defaultLogLevel = 'debug'
local log						= logger.new("cp")

local console                   = require("hs.console")
local drawing                   = require("hs.drawing")
local fs                        = require("hs.fs")
local geometry					= require("hs.geometry")
local host						= require("hs.host")
local image						= require("hs.image")
local keycodes                  = require("hs.keycodes")
local notify					= require("hs.notify")
local styledtext                = require("hs.styledtext")
local toolbar                   = require("hs.webview.toolbar")

local config					= require("cp.config")
local plugins					= require("cp.plugins")
local tools                     = require("cp.tools")

--------------------------------------------------------------------------------
-- SETUP I18N LANGUAGES:
--------------------------------------------------------------------------------
i18n = require("i18n")
local languagePath = config.scriptPath .. "/cp/resources/languages/"
for file in fs.dir(languagePath) do
	if file:sub(-4) == ".lua" then
		i18n.loadFile(languagePath .. file)
	end
end
local userLocale = nil
if config.get("language") == nil then
	userLocale = host.locale.current()
else
	userLocale = config.get("language")
end
i18n.setLocale(userLocale)

--------------------------------------------------------------------------------
-- EXTENSIONS (THAT REQUIRE i18N):
--------------------------------------------------------------------------------
local dialog                    = require("cp.dialog")
local fcp                       = require("cp.apple.finalcutpro")
local feedback					= require("cp.feedback")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.init()
--- Function
--- Initialise CommandPost
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()

	--------------------------------------------------------------------------------
	-- Console Colour Scheme:
	--------------------------------------------------------------------------------
	console.consoleCommandColor{ white = 1 }
	console.outputBackgroundColor{ white = 0 }

	--------------------------------------------------------------------------------
	-- Debug Mode:
	--------------------------------------------------------------------------------
	local debugMode = config.developerMode()
	if debugMode then
		logger.defaultLogLevel = 'debug'
		require("cp.developer")
	else
		logger.defaultLogLevel = 'warning'
	end

	--------------------------------------------------------------------------------
	-- Add Toolbar To Error Log:
	--------------------------------------------------------------------------------
	function consoleOnTopIcon()
		if hs.consoleOnTop() then
			return image.imageFromName("NSStatusAvailable")
		else
			return image.imageFromName("NSStatusUnavailable")
		end
	end
	errorLogToolbar = toolbar.new("myConsole", {
			{ id = i18n("reload"), image = image.imageFromName("NSSynchronize"),
				fn = function()
					console.clearConsole()
					print("Reloading CommandPost...")
					hs.reload()
				end
			},
			{ id = i18n("clearLog"), image = image.imageFromName("NSTrashFull"),
				fn = function()
					console.clearConsole()
				end
			},
			{ id = i18n("alwaysOnTop"), image = consoleOnTopIcon(),
				fn = function()
					hs.consoleOnTop(not hs.consoleOnTop())
					errorLogToolbar:modifyItem({id = i18n("alwaysOnTop"), image = consoleOnTopIcon()})
				end
			},
			{ id = "NSToolbarFlexibleSpaceItem" },
			{ id = i18n("preferences"), image = image.imageFromName("NSPreferencesGeneral"),
				fn = function()
					plugins("core.preferences.manager").show()
				end
			},
			{ id = i18n("feedback"), image = image.imageFromName("NSInfo"),
				fn = function()
					feedback.showFeedback()
				end
			},
		})
		:canCustomize(true)
		:autosaves(true)
	console.toolbar(errorLogToolbar)

	--------------------------------------------------------------------------------
	-- Kill any existing Notifications:
	--------------------------------------------------------------------------------
	notify.withdrawAll()

	--------------------------------------------------------------------------------
	-- Open Error Log:
	--------------------------------------------------------------------------------
	local errorLogOpenOnClose = config.get("errorLogOpenOnClose", false)
	if errorLogOpenOnClose then hs.openConsole() end

	--------------------------------------------------------------------------------
	-- Setup Global Shutdown Callback:
	--------------------------------------------------------------------------------
	hs.shutdownCallback = function()
		local shutdownCallbacks = config.shutdownCallback:getAll()
		if shutdownCallbacks and type(shutdownCallbacks) == "table" then
			for i, v in pairs(shutdownCallbacks) do
				local fn = v:callbackFn()
				if fn and type(fn) == "function" then
					fn()
				end
		    end
		end
	end

	--------------------------------------------------------------------------------
	-- Setup Global Text Dropped to Dock Icon Callback:
	--------------------------------------------------------------------------------
	hs.textDroppedToDockIconCallback = function(value)
		local textDroppedToDockIconCallbacks = config.textDroppedToDockIconCallback:getAll()
		if textDroppedToDockIconCallbacks and type(textDroppedToDockIconCallbacks) == "table" then
			for i, v in pairs(textDroppedToDockIconCallbacks) do
				local fn = v:callbackFn()
				if fn and type(fn) == "function" then
					fn(value)
				end
		    end
		end
	end

	--------------------------------------------------------------------------------
	-- Setup Global File Dropped to Dock Icon Callback:
	--------------------------------------------------------------------------------
	hs.fileDroppedToDockIconCallback = function(value)
		local fileDroppedToDockIconCallbacks = config.fileDroppedToDockIconCallback:getAll()
		if fileDroppedToDockIconCallbacks and type(fileDroppedToDockIconCallbacks) == "table" then
			for i, v in pairs(fileDroppedToDockIconCallbacks) do
				local fn = v:callbackFn()
				if fn and type(fn) == "function" then
					fn(value)
				end
		    end
		end
	end

	--------------------------------------------------------------------------------
	-- Setup Global Dock Icon Click Callback:
	--------------------------------------------------------------------------------
	hs.dockIconClickCallback = function(value)
		local dockIconClickCallbacks = config.dockIconClickCallback:getAll()
		if dockIconClickCallbacks and type(dockIconClickCallbacks) == "table" then
			for i, v in pairs(dockIconClickCallbacks) do
				local fn = v:callbackFn()
				if fn and type(fn) == "function" then
					fn(value)
				end
		    end
		end
	end

	--------------------------------------------------------------------------------
	-- Create CommandPost Shutdown Callback:
	--------------------------------------------------------------------------------
	hs.shuttingDown = false
	config.shutdownCallback:new("cp", function()
		hs.shuttingDown = true
		if console.hswindow() then
			config.set("errorLogOpenOnClose", true)
		else
			config.set("errorLogOpenOnClose", false)
		end
		console.clearConsole()
	end)

	--------------------------------------------------------------------------------
	-- Enable "Launch at Startup" by default:
	--------------------------------------------------------------------------------
	if not config.get("hasRunOnce", false) then
		hs.autoLaunch(true)
		config.set("hasRunOnce", true)
	end

	--------------------------------------------------------------------------------
	-- Check Versions & Language:
	--------------------------------------------------------------------------------
	local fcpVersion    		= fcp:getVersion() or "Unknown"
	local fcpPath				= fcp:getPath() or "Unknown"
	local osVersion    			= tools.macOSVersion() or "Unknown"
	local fcpLanguage   		= fcp:currentLanguage() or "Unknown"

	--------------------------------------------------------------------------------
	-- Clear The Console:
	--------------------------------------------------------------------------------
	consoleLoadingContent = console.getConsole()
	console.clearConsole()

	--------------------------------------------------------------------------------
	-- Display Welcome Message In The Console:
	--------------------------------------------------------------------------------
	console.printStyledtext(styledtext.new(config.appName .. " v" .. config.appVersion, {
		color = drawing.color.definedCollections.hammerspoon["white"],
		font = { name = "Helvetica", size = 18 },
	}))

	--------------------------------------------------------------------------------
	-- Write To Console For Debug Messages:
	--------------------------------------------------------------------------------
	local writeToConsoleDebug = function(value)
		console.printStyledtext(styledtext.new(value, {
			color = drawing.color.definedCollections.hammerspoon["white"],
			font = { name = "Menlo", size = 12 },
		}))
	end

	--------------------------------------------------------------------------------
	-- Display Useful Debugging Information in Console:
	--------------------------------------------------------------------------------
	console.printStyledtext("")
	if osVersion ~= nil then                    writeToConsoleDebug("macOS Version:                  " .. tostring(osVersion),                   true) end
												writeToConsoleDebug(config.appName .. " Locale:             " .. tostring(i18n.getLocale()),          	true)
	if keycodes.currentLayout() ~= nil then     writeToConsoleDebug("Current Keyboard Layout:        " .. tostring(keycodes.currentLayout()),    true) end
	if fcpPath ~= nil then						writeToConsoleDebug("Final Cut Pro Path:             " .. tostring(fcpPath),                 	true) end
	if fcpVersion ~= nil then                   writeToConsoleDebug("Final Cut Pro Version:          " .. tostring(fcpVersion),                  true) end
	if fcpLanguage ~= nil then                  writeToConsoleDebug("Final Cut Pro Language:         " .. tostring(fcpLanguage),                 true) end
												writeToConsoleDebug("Developer Mode:                 " .. tostring(debugMode))
	console.printStyledtext("")

	--------------------------------------------------------------------------------
	-- Display the content that was displayed before loading...
	--------------------------------------------------------------------------------
	print(tools.trim(consoleLoadingContent))

	--------------------------------------------------------------------------------
	-- Load Plugins:
	--------------------------------------------------------------------------------
	log.df("Loading Plugins...")
	plugins.init(config.pluginPaths)
	log.df("Plugins Loaded.")

	--------------------------------------------------------------------------------
	-- Loaded notification:
	--------------------------------------------------------------------------------
	dialog.displayNotification(config.appName .. " (v" .. config.appVersion .. ") " .. i18n("hasLoaded"))

	return mod

end

return mod.init()