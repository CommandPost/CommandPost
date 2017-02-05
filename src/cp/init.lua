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
local settings                  = require("hs.settings")
local styledtext                = require("hs.styledtext")
local timer                     = require("hs.timer")

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
if settings.get(metadata.settingsPrefix .. ".debugMode") then
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
if settings.get(metadata.settingsPrefix .. ".language") == nil then
	userLocale = tools.userLocale()
else
	userLocale = settings.get(metadata.settingsPrefix .. ".language")
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
    -- Clear The Console:
    --------------------------------------------------------------------------------
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
    											writeToConsoleDebug("Loaded from Bundle:             " .. tostring(not hs.hasinitfile))
    if osVersion ~= nil then                    writeToConsoleDebug("macOS Version:                  " .. tostring(osVersion),                   true) end
        										writeToConsoleDebug(metadata.scriptName .. " Locale:             " .. tostring(i18n.getLocale()),          	true)
    if keycodes.currentLayout() ~= nil then     writeToConsoleDebug("Current Keyboard Layout:        " .. tostring(keycodes.currentLayout()),    true) end
	if fcpPath ~= nil then						writeToConsoleDebug("Final Cut Pro Path:             " .. tostring(fcpPath),                 	true) end
    if fcpVersion ~= nil then                   writeToConsoleDebug("Final Cut Pro Version:          " .. tostring(fcpVersion),                  true) end
    if fcpLanguage ~= nil then                  writeToConsoleDebug("Final Cut Pro Language:         " .. tostring(fcpLanguage),                 true) end
                                                writeToConsoleDebug("", true)

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
--                     C O M M O N    F U N C T I O N S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- REPLACE THE BUILT-IN PRINT FEATURE:
--------------------------------------------------------------------------------
print = function(value)
    if type(value) == "table" then
        value = inspect(value)
    else
        value = tostring(value)
    end

    --------------------------------------------------------------------------------
    -- Reformat hs.logger values:
    --------------------------------------------------------------------------------
    if string.sub(value, 1, 8) == string.match(value, "%d%d:%d%d:%d%d") then
        value = string.sub(value, 9, string.len(value)) .. " [" .. string.sub(value, 1, 8) .. "]"
        value = string.gsub(value, "     ", " ")
        value = " > " .. string.gsub(value, "^%s*(.-)%s*$", "%1")
        local consoleStyledText = styledtext.new(value, {
            color = drawing.color.definedCollections.hammerspoon["red"],
            font = { name = "Menlo", size = 12 },
        })
        console.printStyledtext(consoleStyledText)
        return
    end

    if (value:sub(1, 21) ~= "-- Loading extension:") and (value:sub(1, 8) ~= "-- Done.") then
        value = string.gsub(value, "     ", " ")
        value = string.gsub(value, "^%s*(.-)%s*$", "%1")
        local consoleStyledText = styledtext.new(" > " .. value, {
            color = drawing.color.definedCollections.hammerspoon["red"],
            font = { name = "Menlo", size = 12 },
        })
        console.printStyledtext(consoleStyledText)
    end
end

--------------------------------------------------------------------------------
-- WRITE TO CONSOLE:
--------------------------------------------------------------------------------
function writeToConsole(value, overrideLabel)
    if value ~= nil then
        if not overrideLabel then
            value = "> "..value
        end
        if type(value) == "string" then value = string.gsub(value, "\n\n", "\n > ") end
        local consoleStyledText = styledtext.new(tostring(value), {
            color = drawing.color.definedCollections.hammerspoon["blue"],
            font = { name = "Menlo", size = 12 },
        })
        console.printStyledtext(consoleStyledText)
    end
end

--------------------------------------------------------------------------------
-- DEBUG MESSAGE:
--------------------------------------------------------------------------------
function debugMessage(value, value2)
    if value2 ~= nil then
        local consoleStyledText = styledtext.new(" > " .. tostring(value) .. ": " .. tostring(value2), {
            color = drawing.color.definedCollections.hammerspoon["red"],
            font = { name = "Menlo", size = 12 },
        })
        console.printStyledtext(consoleStyledText)
    else
        if value ~= nil then
            if type(value) == "string" then value = string.gsub(value, "\n\n", "\n > ") end
            if settings.get(metadata.settingsPrefix .. ".debugMode") then
                local consoleStyledText = styledtext.new(" > " .. value, {
                    color = drawing.color.definedCollections.hammerspoon["red"],
                    font = { name = "Menlo", size = 12 },
                })
                console.printStyledtext(consoleStyledText)
            end
        end
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return mod.init()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
