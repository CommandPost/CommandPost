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
local application               = require("hs.application")
local console                   = require("hs.console")
local drawing                   = require("hs.drawing")
local fs                        = require("hs.fs")
local geometry                  = require("hs.geometry")
local inspect                   = require("hs.inspect")
local keycodes                  = require("hs.keycodes")
local logger                    = require("hs.logger")
local mouse                     = require("hs.mouse")
local pathwatcher				= require("hs.pathwatcher")
local styledtext                = require("hs.styledtext")
local timer                     = require("hs.timer")
local drawing					= require("hs.drawing")

--------------------------------------------------------------------------------
-- 3RD PARTY EXTENSIONS:
--------------------------------------------------------------------------------
local ax                        = require("hs._asm.axuielement")
local semver                    = require("semver.semver")

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
    console.level(drawing.windowLevels["_MaximumWindowLevelKey"])

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
    console.printStyledtext(styledtext.new("Developed by Chris Hocking & David Peterson", {
		color = drawing.color.definedCollections.hammerspoon["black"],
		font = { name = "Helvetica", size = 14 },
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
    											writeToConsoleDebug("Debug Mode:                     " .. tostring(debugMode))
                                                writeToConsoleDebug("", true)
    console.printStyledtext(styledtext.new("Start of Log:\n", {
		color = drawing.color.definedCollections.hammerspoon["black"],
		font = { name = "Helvetica", size = 14 },

	}))

	--------------------------------------------------------------------------------
	-- Display the content that was displayed before loading...
	--------------------------------------------------------------------------------
	print(consoleLoadingContent)

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
	-- Accessibility Check:
	--------------------------------------------------------------------------------
	if not hs.accessibilityState() then
		local result = dialog.displayMessage(i18n("accessibilityError", {scriptName = metadata.scriptName}), {i18n("Continue"), i18n("Quit")})
		if result == "Quit" then
			application.applicationsForBundleID(hsBundleID)[1]:kill()
		else
			hs.accessibilityState(true)
			timer.doEvery(3, function()
				if hs.accessibilityState() then
					loadScriptVersion()
				end
			end)
		end
	else
		loadScriptVersion()
	end

    return self

end

--------------------------------------------------------------------------------
-- LOAD MAIN SCRIPT:
--------------------------------------------------------------------------------
function loadScriptVersion()
	local fcpVersion = fcp:getVersion()
    local validFinalCutProVersion = false
    if fcpVersion:sub(1,4) == "10.3" then
        validFinalCutProVersion = true
        require("cp.fcpx10-3")
    end
    if not validFinalCutProVersion then
        dialog.displayAlertMessage(i18n("noValidFinalCutPro", {scriptName = metadata.scriptName}))
        application.applicationsForBundleID(hsBundleID)[1]:kill()
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return mod.init()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------