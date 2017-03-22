--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp ===
---
--- Core CommandPost functionality

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("cp")

local console                   = require("hs.console")
local drawing                   = require("hs.drawing")
local fs                        = require("hs.fs")
local image						= require("hs.image")
local keycodes                  = require("hs.keycodes")
local logger					= require("hs.logger")
local mouse                     = require("hs.mouse")
local pathwatcher				= require("hs.pathwatcher")
local styledtext                = require("hs.styledtext")
local toolbar                   = require("hs.webview.toolbar")

local metadata					= require("cp.metadata")
local tools                     = require("cp.tools")

--------------------------------------------------------------------------------
-- SHUTDOWN CALLBACK:
--------------------------------------------------------------------------------
function hs.shutdownCallback()
	console.clearConsole()
end

--------------------------------------------------------------------------------
-- DEBUG MODE:
--------------------------------------------------------------------------------
local debugMode 				= metadata.get("debugMode")
if debugMode then
    logger.defaultLogLevel = 'debug'
else
	logger.defaultLogLevel = 'warning'
end

--------------------------------------------------------------------------------
-- SETUP I18N LANGUAGES:
--------------------------------------------------------------------------------
i18n = require("i18n")
local languagePath = metadata.scriptPath .. "/cp/resources/languages/"
for file in fs.dir(languagePath) do
	if file:sub(-4) == ".lua" then
		i18n.loadFile(languagePath .. file)
	end
end
local userLocale = nil
if metadata.get("language") == nil then
	userLocale = tools.userLocale()
else
	userLocale = metadata.get("language")
end
i18n.setLocale(userLocale)

--------------------------------------------------------------------------------
-- ADD TOOLBAR TO ERROR LOG:
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
-- EXTENSIONS (THAT REQUIRE i18N):
--------------------------------------------------------------------------------
local dialog                    = require("cp.dialog")
local fcp                       = require("cp.finalcutpro")

--------------------------------------------------------------------------------
-- WRITE TO CONSOLE FOR DEBUG MESSAGES:
--------------------------------------------------------------------------------
local function writeToConsoleDebug(value)
    console.printStyledtext(styledtext.new(value, {
		color = drawing.color.definedCollections.hammerspoon["black"],
		font = { name = "Menlo", size = 12 },
	}))
end

--------------------------------------------------------------------------------
-- THE MODULE:
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
		-- Check Versions & Language:
		--------------------------------------------------------------------------------
		local fcpVersion    		= fcp:getVersion()
		local fcpPath				= fcp:getPath()
		local osVersion    			= tools.macOSVersion()
		local fcpLanguage   		= fcp:getCurrentLanguage()
		local hammerspoonVersion	= hs.processInfo["version"]

		--------------------------------------------------------------------------------
		-- Console should always be on top:
		--------------------------------------------------------------------------------
		-- console.level(drawing.windowLevels["_MaximumWindowLevelKey"])

		--------------------------------------------------------------------------------
		-- Clear The Console:
		--------------------------------------------------------------------------------
		consoleLoadingContent = console.getConsole()
		console.clearConsole()

		--------------------------------------------------------------------------------
		-- Display Welcome Message In The Console:
		--------------------------------------------------------------------------------
		console.printStyledtext(styledtext.new(metadata.scriptName .. " v" .. metadata.scriptVersion, {
			color = drawing.color.definedCollections.hammerspoon["black"],
			font = { name = "Helvetica", size = 18 },
		}))

		--------------------------------------------------------------------------------
		-- Blank Line:
		--------------------------------------------------------------------------------
		console.printStyledtext("")

		--------------------------------------------------------------------------------
		-- Display Useful Debugging Information in Console:
		--------------------------------------------------------------------------------
		if osVersion ~= nil then                    writeToConsoleDebug("macOS Version:                  " .. tostring(osVersion),                   true) end
													writeToConsoleDebug(metadata.scriptName .. " Locale:             " .. tostring(i18n.getLocale()),          	true)
		if keycodes.currentLayout() ~= nil then     writeToConsoleDebug("Current Keyboard Layout:        " .. tostring(keycodes.currentLayout()),    true) end
		if fcpPath ~= nil then						writeToConsoleDebug("Final Cut Pro Path:             " .. tostring(fcpPath),                 	true) end
		if fcpVersion ~= nil then                   writeToConsoleDebug("Final Cut Pro Version:          " .. tostring(fcpVersion),                  true) end
		if fcpLanguage ~= nil then                  writeToConsoleDebug("Final Cut Pro Language:         " .. tostring(fcpLanguage),                 true) end
													writeToConsoleDebug("Loaded from Bundle:             " .. tostring(not hs.hasinitfile))
													writeToConsoleDebug("Developer Mode:                 " .. tostring(debugMode))

		--------------------------------------------------------------------------------
		-- Blank Line:
		--------------------------------------------------------------------------------
		console.printStyledtext("")

		--------------------------------------------------------------------------------
		-- Display the content that was displayed before loading...
		--------------------------------------------------------------------------------
		print(tools.trim(consoleLoadingContent))

		--------------------------------------------------------------------------------
		-- Watch for Script Updates:
		--------------------------------------------------------------------------------
		scriptWatcher = pathwatcher.new(hs.configdir, function(files)
			local doReload = false
			for _,file in pairs(files) do
				if file:sub(-4) == ".lua" or file:sub(-5) == ".html" or file:sub(-4) == ".htm" then
					doReload = true
				end
			end
			if doReload then
				console.clearConsole()
				hs.reload()
			end
		end):start()

		--------------------------------------------------------------------------------
		-- Load Welcome Screen:
		--------------------------------------------------------------------------------
		local welcome = require("cp.welcome")

		return mod

	end

return mod.init()