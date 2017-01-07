--- === hs.finalcutpro ===
---
--- API for Final Cut Pro
---
--- Authors:
---
---   Chris Hocking 	https://latenitefilms.com
---   David Peterson 	https://randomphotons.com
---

local finalcutpro = {}

local App									= require("hs.finalcutpro.App")

--- hs.finalcutpro.currentLanguage() -> string
--- Function
--- Returns the language Final Cut Pro is currently using.
---
--- Parameters:
---  * none
---
--- Returns:
---  * Returns the current language as string (or 'en' if unknown).
---
function finalcutpro.currentLanguage(forceReload, forceLanguage)
	return finalcutpro.app():currentLanguage(forceReload, forceLanguage)
end

--- hs.finalcutpro.app() -> hs.application
--- Function
--- Returns the root Final Cut Pro application.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The root Final Cut Pro application.
---
function finalcutpro.app()
	if not finalcutpro._app then
		finalcutpro._app = App:new()
	end
	return finalcutpro._app
end

--- hs.finalcutpro.importXML() -> boolean
--- Function
--- Imports an XML file into Final Cut Pro
---
--- Parameters:
---  * path = Path to XML File
---
--- Returns:
---  * A boolean value indicating whether the AppleScript succeeded or not
---
function finalcutpro.importXML(path)
	return finalcutpro.app():importXML(path)
end

--- hs.finalcutpro.flexoLanguages() -> table
--- Function
--- Returns a table of languages Final Cut Pro's Flexo Framework supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
---
function finalcutpro.flexoLanguages()
	return finalcutpro.app():getFlexoLanguages()
end

--- hs.finalcutpro.languages() -> table
--- Function
--- Returns a table of languages Final Cut Pro supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
---
function finalcutpro.languages()
	return finalcutpro.app():getSupportedLanguages()
end

--- hs.finalcutpro.clipboardUTI() -> string
--- Function
--- Returns the Final Cut Pro Bundle ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing the Final Cut Pro Bundle ID
---
function finalcutpro.bundleID()
	return App.BUNDLE_ID
end

--- hs.finalcutpro.clipboardUTI() -> string
--- Function
--- Returns the Final Cut Pro Clipboard UTI
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing the Final Cut Pro Clipboard UTI
---
function finalcutpro.clipboardUTI()
	return App.PASTEBOARD_UTI
end

--- hs.finalcutpro.getPreferences() -> table or nil
--- Function
--- Gets Final Cut Pro's Preferences as a table. It checks if the preferences
--- file has been modified and reloads when necessary.
---
--- Parameters:
---  * forceReload	- (optional) if true, a reload will be forced even if the file hasn't been modified.
---
--- Returns:
---  * A table with all of Final Cut Pro's preferences, or nil if an error occurred
---
function finalcutpro.getPreferences(forceReload)
	return finalcutpro.app():getPreferences(forceReload)
end

--- hs.finalcutpro.getPreference(preferenceName) -> string or nil
--- Function
--- Get an individual Final Cut Pro preference
---
--- Parameters:
---  * preferenceName 	- The preference you want to return
---  * default			- (optional) The default value to return if the preference is not set.
---
--- Returns:
---  * A string with the preference value, or nil if an error occurred
---
function finalcutpro.getPreference(value, default, forceReload)
	return finalcutpro.app():getPreference(value, default, forceReload)
end

--- hs.finalcutpro.setPreference(key, value) -> boolean
--- Function
--- Sets an individual Final Cut Pro preference
---
--- Parameters:
---  * key - The preference you want to change
---  * value - The value you want to set for that preference
---
--- Returns:
---  * True if executed successfully otherwise False
---
function finalcutpro.setPreference(key, value)
	return finalcutpro.app():setPreference(key, value)
end

--- hs.finalcutpro.getActiveCommandSetPath() -> string or nil
--- Function
--- Gets the 'Active Command Set' value from the Final Cut Pro preferences
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Active Command Set' value, or nil if an error occurred
---
function finalcutpro.getActiveCommandSetPath()
	return finalcutpro.app():getActiveCommandSetPath()
end

--- hs.finalcutpro.getActiveCommandSet([optionalPath]) -> table or nil
--- Function
--- Returns the 'Active Command Set' as a Table
---
--- Parameters:
---  * optionalPath - The optional path of the Command Set
---
--- Returns:
---  * A table of the Active Command Set's contents, or nil if an error occurred
---
function finalcutpro.getActiveCommandSet(optionalPath, forceReload)
	return finalcutpro.app():getActiveCommandSet(optionalPath, forceReload)
end

--- hs.finalcutpro.installed() -> boolean
--- Function
--- Is Final Cut Pro Installed?
---
--- Parameters:
---  * None
---
--- Returns:
---  * Boolean value
---
function finalcutpro.installed()
	return finalcutpro.app():isInstalled()
end

--- hs.finalcutpro.path() -> string or nil
--- Function
--- Path to Final Cut Pro Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Final Cut Pro's filesystem path, or nil if the bundle identifier could not be located
---
function finalcutpro.path()
	return finalcutpro.app():getPath()
end

--- hs.finalcutpro.version() -> string or nil
--- Function
--- Version of Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * Version as string or nil if an error occurred
---
function finalcutpro.version()
	return finalcutpro.app():getVersion()
end

--- hs.finalcutpro.application() -> hs.application or nil
--- Function
--- Returns the Final Cut Pro application (as hs.application)
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro application (as hs.application) or nil if an error occurred
---
function finalcutpro.application()
	return finalcutpro.app():application()
end

--- hs.finalcutpro.launch() -> boolean
--- Function
--- Launches Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Final Cut Pro was either launched or focused, otherwise false (e.g. if Final Cut Pro doesn't exist)
---
function finalcutpro.launch()
	return finalcutpro.app():launch()
end

--- hs.finalcutpro.running() -> boolean
--- Function
--- Is Final Cut Pro Running?
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is running otherwise False
---
function finalcutpro.running()
	return finalcutpro.app():isRunning()
end

--- hs.finalcutpro.restart() -> boolean
--- Function
--- Restart Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is running otherwise False if Final Cut Pro is not running, or fails to close or restart
---
function finalcutpro.restart()
	return finalcutpro.app():restart()
end

--- hs.finalcutpro.frontmost() -> boolean
--- Function
--- Is Final Cut Pro Frontmost?
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if Final Cut Pro is Frontmost otherwise false.
---
function finalcutpro.frontmost()
	return finalcutpro.app():isFrontmost()
end

--- hs.finalcutpro.performShortcut() -> Boolean
--- Function
--- Performs a Final Cut Pro Shortcut
---
--- Parameters:
---  * whichShortcut - As per the Command Set name
---
--- Returns:
---  * true if successful otherwise false
---
function finalcutpro.performShortcut(whichShortcut)
	return finalcutpro.app():performShortcut(whichShortcut)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   D E V E L O P M E N T      T O O L S                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- hs.finalcutpro._generateMenuMap() -> Table
--- Function
--- Generates a map of the menu bar and saves it in '/hs/finalcutpro/menumap.json'.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * True is successful otherwise Nil
---
function finalcutpro._generateMenuMap()
	return finalcutpro.app():menuBar():generateMenuMap()
end

return finalcutpro