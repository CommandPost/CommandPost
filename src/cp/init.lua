--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        T H E    M O D U L E                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    T H E    M A I N    S C R I P T                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- LOGGING:
--------------------------------------------------------------------------------
local logger					= require("hs.logger")
local log						= logger.new("cp")

--------------------------------------------------------------------------------
-- HAMMERSPOON EXTENSIONS:
--------------------------------------------------------------------------------
local console                   = require("hs.console")
local drawing                   = require("hs.drawing")
local fs                        = require("hs.fs")
local image						= require("hs.image")
local keycodes                  = require("hs.keycodes")
local mouse                     = require("hs.mouse")
local pathwatcher				= require("hs.pathwatcher")
local styledtext                = require("hs.styledtext")
local toolbar                   = require("hs.webview.toolbar")

--------------------------------------------------------------------------------
-- INTERNAL EXTENSIONS:
--------------------------------------------------------------------------------
local metadata					= require("cp.metadata")
local tools                     = require("cp.tools")

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
		{ id = "Reload", image = image.imageFromName("NSPreferencesGeneral"),
			fn = function()
				console.clearConsole()
				print("Reloading CommandPost...")
				hs.reload()
			end
		},
		{ id = "Clear Console", image = image.imageFromName("NSTrashFull"),
			fn = function()
				console.clearConsole()
			end
		},
		{ id = "Always On Top", image = consoleOnTopIcon(),
			fn = function()
				hs.consoleOnTop(not hs.consoleOnTop())
				errorLogToolbar:modifyItem({id = "Always On Top", image = consoleOnTopIcon()})
			end
		},
    })
	:canCustomize(true)
    :autosaves(true)
console.toolbar(errorLogToolbar)

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
-- INTERNAL EXTENSIONS (THAT REQUIRE I18N):
--------------------------------------------------------------------------------
local dialog                    = require("cp.dialog")
local fcp                       = require("cp.finalcutpro")

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------
local hsBundleID                = hs.processInfo["bundleID"]

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
-- INITIALISE:
--------------------------------------------------------------------------------
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
			if file:sub(-4) == ".lua" then
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

--------------------------------------------------------------------------------
-- SHUTDOWN CALLBACK:
--------------------------------------------------------------------------------
function hs.shutdownCallback()
	console.clearConsole()
end

--------------------------------------------------------------------------------
-- RETURN MODULE:
--------------------------------------------------------------------------------
return mod.init()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------