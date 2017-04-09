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
local image						= require("hs.image")
local keycodes                  = require("hs.keycodes")
local styledtext                = require("hs.styledtext")
local toolbar                   = require("hs.webview.toolbar")

local config					= require("cp.config")
local tools                     = require("cp.tools")
local plugins					= require("cp.plugins")

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
	userLocale = tools.userLocale()
else
	userLocale = config.get("language")
end
i18n.setLocale(userLocale)

--------------------------------------------------------------------------------
-- EXTENSIONS (THAT REQUIRE i18N):
--------------------------------------------------------------------------------
local dialog                    = require("cp.dialog")
local fcp                       = require("cp.finalcutpro")

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
	-- Debug Mode:
	--------------------------------------------------------------------------------
	local debugMode = config.get("debugMode")
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
	local toolbar = require("hs.webview.toolbar")
	errorLogToolbar = toolbar.new("myConsole", {
			{ id = i18n("reload"), image = image.imageFromName("NSPreferencesGeneral"),
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
		})
		:canCustomize(true)
		:autosaves(true)
	console.toolbar(errorLogToolbar)

	--------------------------------------------------------------------------------
	-- Open Error Log:
	--------------------------------------------------------------------------------
	local errorLogOpenOnClose = config.get("errorLogOpenOnClose", false)
	if errorLogOpenOnClose then
		hs.openConsole()
		local lastErrorLogFrame = config.get("lastErrorLogFrame", nil)
		if lastErrorLogFrame then
			local frame = hs.geometry.rect(lastErrorLogFrame["_x"], lastErrorLogFrame["_y"], lastErrorLogFrame["_w"], lastErrorLogFrame["_h"])
			console.hswindow():setFrame(frame)
		end
	end

	--------------------------------------------------------------------------------
	-- Shutdown Callback:
	--------------------------------------------------------------------------------
	hs.shuttingDown = false
	hs.shutdownCallback = function()
		hs.shuttingDown = true
		if console.hswindow() then
			config.set("errorLogOpenOnClose", true)
			config.set("lastErrorLogFrame", console.hswindow():frame())
		else
			config.set("errorLogOpenOnClose", false)
		end
		console.clearConsole()
	end

	--------------------------------------------------------------------------------
	-- Check Versions & Language:
	--------------------------------------------------------------------------------
	local fcpVersion    		= fcp:getVersion()
	local fcpPath				= fcp:getPath()
	local osVersion    			= tools.macOSVersion()
	local fcpLanguage   		= fcp:getCurrentLanguage()

	--------------------------------------------------------------------------------
	-- Clear The Console:
	--------------------------------------------------------------------------------
	consoleLoadingContent = console.getConsole()
	console.clearConsole()

	--------------------------------------------------------------------------------
	-- Display Welcome Message In The Console:
	--------------------------------------------------------------------------------
	console.printStyledtext(styledtext.new(config.appName .. " v" .. config.appVersion, {
		color = drawing.color.definedCollections.hammerspoon["black"],
		font = { name = "Helvetica", size = 18 },
	}))

	--------------------------------------------------------------------------------
	-- Write To Console For Debug Messages:
	--------------------------------------------------------------------------------
	local writeToConsoleDebug = function(value)
		console.printStyledtext(styledtext.new(value, {
			color = drawing.color.definedCollections.hammerspoon["black"],
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
												writeToConsoleDebug("Loaded from Bundle:             " .. tostring(not hs.hasinitfile))
												writeToConsoleDebug("Developer Mode:                 " .. tostring(debugMode))
	console.printStyledtext("")

	--------------------------------------------------------------------------------
	-- Display the content that was displayed before loading...
	--------------------------------------------------------------------------------
	print(tools.trim(consoleLoadingContent))

	--------------------------------------------------------------------------------
	-- Load Plugins:
	--------------------------------------------------------------------------------
	log.df("Loading Plugins:")
	plugins.init(config.pluginPaths)

	return mod

end

return mod.init()