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

local finalCutProPreferencesPlistPath 		= "~/Library/Preferences/com.apple.FinalCut.plist"
local finalCutProLanguages 					= {"de", "en", "es", "fr", "ja", "zh_CN"}
local finalCutProFlexoLanguages				= {"de", "en", "es_419", "es", "fr", "id", "ja", "ms", "vi", "zh_CN"}

local App									= require("hs.finalcutpro.App")
local ax 									= require("hs._asm.axuielement")
local just									= require("hs.just")
local plist 								= require("hs.plist")

local application 							= require("hs.application")
local drawing								= require("hs.drawing")
local eventtap								= require("hs.eventtap")
local fs 									= require("hs.fs")
local geometry								= require("hs.geometry")
local inspect								= require("hs.inspect")
local json									= require("hs.json")
local keycodes								= require("hs.keycodes")
local log									= require("hs.logger").new("fcp")
local osascript 							= require("hs.osascript")
local timer									= require("hs.timer")

finalcutpro.cachedCurrentLanguage 			= nil
finalcutpro.cachedActiveCommandSet 			= nil

--- keyCodeTranslator() -> string
--- Function
--- Translates string into Keycode
---
--- Parameters:
---  * input - string
---
--- Returns:
---  * Keycode as String or ""
---
function finalcutpro.keyCodeTranslator(input)

	local englishKeyCodes = {
		["'"] = 39,
		[","] = 43,
		["-"] = 27,
		["."] = 47,
		["/"] = 44,
		["0"] = 29,
		["1"] = 18,
		["2"] = 19,
		["3"] = 20,
		["4"] = 21,
		["5"] = 23,
		["6"] = 22,
		["7"] = 26,
		["8"] = 28,
		["9"] = 25,
		[";"] = 41,
		["="] = 24,
		["["] = 33,
		["\\"] = 42,
		["]"] = 30,
		["`"] = 50,
		["a"] = 0,
		["b"] = 11,
		["c"] = 8,
		["d"] = 2,
		["delete"] = 51,
		["down"] = 125,
		["e"] = 14,
		["end"] = 119,
		["escape"] = 53,
		["f"] = 3,
		["f1"] = 122,
		["f10"] = 109,
		["f11"] = 103,
		["f12"] = 111,
		["f13"] = 105,
		["f14"] = 107,
		["f15"] = 113,
		["f16"] = 106,
		["f17"] = 64,
		["f18"] = 79,
		["f19"] = 80,
		["f2"] = 120,
		["f20"] = 90,
		["f3"] = 99,
		["f4"] = 118,
		["f5"] = 96,
		["f6"] = 97,
		["f7"] = 98,
		["f8"] = 100,
		["f9"] = 101,
		["forwarddelete"] = 117,
		["g"] = 5,
		["h"] = 4,
		["help"] = 114,
		["home"] = 115,
		["i"] = 34,
		["j"] = 38,
		["k"] = 40,
		["l"] = 37,
		["left"] = 123,
		["m"] = 46,
		["n"] = 45,
		["o"] = 31,
		["p"] = 35,
		["pad*"] = 67,
		["pad+"] = 69,
		["pad-"] = 78,
		["pad."] = 65,
		["pad/"] = 75,
		["pad0"] = 82,
		["pad1"] = 83,
		["pad2"] = 84,
		["pad3"] = 85,
		["pad4"] = 86,
		["pad5"] = 87,
		["pad6"] = 88,
		["pad7"] = 89,
		["pad8"] = 91,
		["pad9"] = 92,
		["pad="] = 81,
		["padclear"] = 71,
		["padenter"] = 76,
		["pagedown"] = 121,
		["pageup"] = 116,
		["q"] = 12,
		["r"] = 15,
		["return"] = 36,
		["right"] = 124,
		["s"] = 1,
		["space"] = 49,
		["t"] = 17,
		["tab"] = 48,
		["u"] = 32,
		["up"] = 126,
		["v"] = 9,
		["w"] = 13,
		["x"] = 7,
		["y"] = 16,
		["z"] = 6,
		["§"] = 10
	}

	if englishKeyCodes[input] == nil then
		if keycodes.map[input] == nil then
			return ""
		else
			return keycodes.map[input]
		end
	else
		return englishKeyCodes[input]
	end

end

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

	--------------------------------------------------------------------------------
	-- Force a Language:
	--------------------------------------------------------------------------------
	if forceReload and forceLanguage ~= nil then
		finalcutpro.cachedCurrentLanguage = forceLanguage
		return finalcutpro.cachedCurrentLanguage
	end

	--------------------------------------------------------------------------------
	-- Caching:
	--------------------------------------------------------------------------------
	if finalcutpro.cachedCurrentLanguage ~= nil then
		if not forceReload then
			return finalcutpro.cachedCurrentLanguage
		end
	end

	--------------------------------------------------------------------------------
	-- If FCPX is already run, we determine the language off the menu:
	--------------------------------------------------------------------------------
	if finalcutpro.running() then
		local fcpxElements = ax.applicationElement(finalcutpro.application())
		if fcpxElements ~= nil then
			local whichMenuBar = nil
			if fcpxElements:attributeValueCount("AXChildren") ~= nil then
				if fcpxElements:attributeValueCount("AXChildren") > 0 then
					for i=1, fcpxElements:attributeValueCount("AXChildren") do
						if fcpxElements[i]:attributeValue("AXRole") == "AXMenuBar" then
							whichMenuBar = i
						end
					end
					if fcpxElements[whichMenuBar][3] ~= nil then
						local fileValue
						fileValue = fcpxElements[whichMenuBar][3]:attributeValue("AXTitle") or nil
						--------------------------------------------------------------------------------
						-- ENGLISH:		File
						-- GERMAN: 		Ablage
						-- SPANISH: 	Archivo
						-- FRENCH: 		Fichier
						-- JAPANESE:	ファイル
						-- CHINESE:		文件
						--------------------------------------------------------------------------------
						if fileValue == "File" 		then
							finalcutpro.cachedCurrentLanguage = "en"
							return "en"
						end
						if fileValue == "Ablage" 	then
							finalcutpro.cachedCurrentLanguage = "de"
							return "de"
						end
						if fileValue == "Archivo" 	then
							finalcutpro.cachedCurrentLanguage = "es"
							return "es"
						end
						if fileValue == "Fichier" 	then
							finalcutpro.cachedCurrentLanguage = "fr"
							return "fr"
						end
						if fileValue == "ファイル" 	then
							finalcutpro.cachedCurrentLanguage = "ja"
							return "ja"
						end
						if fileValue == "文件" 		then
							finalcutpro.cachedCurrentLanguage = "zh_CN"
							return "zh_CN"
						end
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If FCPX is not running, we next try to determine the language using
	-- the Final Cut Pro Plist File:
	--------------------------------------------------------------------------------
	local finalCutProLanguage = finalcutpro.getPreference("AppleLanguages", nil)
	if finalCutProLanguage ~= nil and next(finalCutProLanguage) ~= nil then
		if finalCutProLanguage[1] ~= nil then
			finalcutpro.cachedCurrentLanguage = finalCutProLanguage[1]
			return finalCutProLanguage[1]
		end
	end

	--------------------------------------------------------------------------------
	-- If that fails, we try and use the user locale:
	--------------------------------------------------------------------------------
	local a, userLocale = osascript.applescript("return user locale of (get system info)")
	if userLocale ~= nil then

		--------------------------------------------------------------------------------
		-- Only return languages Final Cut Pro actually supports:
		--------------------------------------------------------------------------------
		for i=1, #finalCutProLanguages do
			if userLocale == finalCutProLanguages[i] then
				finalcutpro.cachedCurrentLanguage = userLocale
				return userLocale
			else
				if string.sub(userLocale, 1, string.find(userLocale, "_") - 1) == finalCutProLanguages[i] then
					finalcutpro.cachedCurrentLanguage = string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
					return string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
				end
			end
		end

	end

	--------------------------------------------------------------------------------
	-- If that also fails, we try and use NSGlobalDomain AppleLanguages:
	--------------------------------------------------------------------------------
	local a, AppleLanguages = hs.osascript.applescript([[
		set lang to do shell script "defaults read NSGlobalDomain AppleLanguages"
			tell application "System Events"
				set pl to make new property list item with properties {text:lang}
				set r to value of pl
			end tell
		return item 1 of r ]])
	if AppleLanguages ~= nil then

		--------------------------------------------------------------------------------
		-- Only return languages Final Cut Pro actually supports:
		--------------------------------------------------------------------------------
		for i=1, #finalCutProLanguages do
			if AppleLanguages == finalCutProLanguages[i] then
				finalcutpro.cachedCurrentLanguage = AppleLanguages
				return AppleLanguages
			else
				if string.sub(AppleLanguages, 1, string.find(AppleLanguages, "-") - 1) == finalCutProLanguages[i] then
					finalcutpro.cachedCurrentLanguage = string.sub(AppleLanguages, 1, string.find(AppleLanguages, "-") - 1)
					return string.sub(AppleLanguages, 1, string.find(AppleLanguages, "-") - 1)
				end
			end
		end

	end

	--------------------------------------------------------------------------------
	-- If all else fails, assume it's English:
	--------------------------------------------------------------------------------
	return "en"

end

--- hs.finalcutpro.getTranslation() -> string/table or nil
--- Function
--- Returns a specific translation if language is set otherwise returns
--- a table of all different translations
---
--- Parameters:
---  * value - the value you want to translate
---  * [language] - (optional) the language you want to translate to (i.e. "en" for English)
---
--- Returns:
---  * Returns either the translation as a string or table, or nil if an error has occurred.
---
function finalcutpro.getTranslation(value, language)

	local result = nil
	if value == "Playhead" then
		--------------------------------------------------------------------------------
		-- ENGLISH:		Playhead
		-- GERMAN: 		Abspielposition
		-- SPANISH: 	Cursor de reproducción
		-- FRENCH: 		Tête de lecture
		-- JAPANESE:	再生ヘッド
		-- CHINESE:		播放头
		--------------------------------------------------------------------------------
		result = {
			["en"] 		= "Playhead",					-- English
			["de"] 		= "Abspielposition", 			-- German
			["es"] 		= "Cursor de reproducción",		-- Spanish
			["fr"] 		= "Tête de lecture",			-- French
			["ja"] 		= "再生ヘッド",					-- Japanese
			["zh_CN"] 	= "播放头",						-- Chinese
		}
	end
	if value == "Command Editor" then
		--------------------------------------------------------------------------------
		-- ENGLISH:		Command Editor
		-- GERMAN: 		Befehl-Editor
		-- SPANISH: 	Editor de comandos
		-- FRENCH: 		Éditeur de commandes
		-- JAPANESE:	コマンドエディタ
		-- CHINESE:		命令编辑器
		--------------------------------------------------------------------------------
			result = {
			["en"] 		= "Command Editor",				-- English
			["de"] 		= "Befehl-Editor", 				-- German
			["es"] 		= "Editor de comandos",			-- Spanish
			["fr"] 		= "Éditeur de commandes",		-- French
			["ja"] 		= "コマンドエディタ",				-- Japanese
			["zh_CN"] 	= "命令编辑器",					-- Chinese
		}
	end
	if value == "Media Import" then
		--------------------------------------------------------------------------------
		-- ENGLISH:		Media Import
		-- GERMAN: 		Medien importieren
		-- SPANISH: 	Importación de contenido
		-- FRENCH: 		Importation des médias
		-- JAPANESE:	メディアの読み込み
		-- CHINESE:		媒体导入
		--------------------------------------------------------------------------------
			result = {
			["en"] 		= "Media Import",				-- English
			["de"] 		= "Medien importieren", 		-- German
			["es"] 		= "Importación de contenido",	-- Spanish
			["fr"] 		= "Importation des médias",		-- French
			["ja"] 		= "メディアの読み込み",			-- Japanese
			["zh_CN"] 	= "媒体导入",					-- Chinese
		}
	end

	if result ~= nil then
		if language ~= nil then
			if result[language] ~= nil then
				local temp = result[language]
				result = nil
				result = temp
			end
		else
			language = finalcutpro.currentLanguage()
			if result[language] ~= nil then
				local temp = result[language]
				result = nil
				result = temp
			end
		end
	end

	return result

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

	if finalcutpro.running() then
		local appleScriptA = 'set whichSharedXMLPath to "' .. path .. '"' .. '\n\n'
		local appleScriptB = [[
			tell application "Final Cut Pro"
				activate
				open POSIX file whichSharedXMLPath as string
			end tell
		]]
		local bool, object, descriptor = osascript.applescript(appleScriptA .. appleScriptB)
		return bool
	end

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
	return finalCutProFlexoLanguages
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
	return finalCutProLanguages
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
	local modified = fs.attributes(finalCutProPreferencesPlistPath, "modification")
	if forceReload or modified ~= finalcutpro._preferencesModified then
		log.d("Reloading FCPX preferences from file...")
		finalcutpro._preferences = plist.binaryFileToTable(finalCutProPreferencesPlistPath) or nil
		finalcutpro._preferencesModified = modified
	 end
	return finalcutpro._preferences
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

	if forceReload == nil then forceReload = false end

	local result = nil

	local preferencesTable = finalcutpro.getPreferences(forceReload)
	if preferencesTable ~= nil then
		result = preferencesTable[value]
	end

	if result == nil then
		result = default
	end

	return result

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

	local executeResult, executeStatus

	if type(value) == "boolean" then
		executeResult, executeStatus = hs.execute("defaults write " .. finalCutProPreferencesPlistPath .. " '" .. key .. "' -bool " .. tostring(value))
	elseif type(value) == "table" then
		local arrayString = ""
		for i=1, #value do
			arrayString = arrayString .. value[i]
			if i ~= #value then
				arrayString = arrayString .. ","
			end
		end
		executeResult, executeStatus = hs.execute("defaults write " .. finalCutProPreferencesPlistPath .. " '" .. key .. "' -array '" .. arrayString .. "'")
	elseif type(value) == "string" then
		executeResult, executeStatus = hs.execute("defaults write " .. finalCutProPreferencesPlistPath .. " '" .. key .. "' -string '" .. value .. "'")
	end

	if executeStatus == nil then
		return false
	else
		return true
	end

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
	local result = finalcutpro.getPreference("Active Command Set") or nil
	if result == nil then
		-- In the unlikely scenario that this is the first time FCPX has been run:
		return "/Applications/Final Cut Pro.app/Contents/Resources/" .. finalcutpro.currentLanguage() .. ".lproj/Default.commandset"
	end
	return result
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

	if not forceReload then
		if finalcutpro.cachedActiveCommandSet ~= nil then
			return finalcutpro.cachedActiveCommandSet
		end
	end

	local result = nil
	local activeCommandSetPath = nil

	if optionalPath == nil then
		activeCommandSetPath = finalcutpro.getActiveCommandSetPath()
	else
		activeCommandSetPath = optionalPath
	end

	if activeCommandSetPath ~= nil then
		if fs.attributes(activeCommandSetPath) ~= nil then
			result = plist.fileToTable(activeCommandSetPath)
		end
	end

	if result ~= nil then
		finalcutpro.cachedActiveCommandSet = result
	end

	return result

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

--- hs.finalcutpro.getTimelineSplitGroup() -> axuielementObject or nil
--- Function
--- Get Timeline Split Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Timeline Split Group or nil if failed
---
function finalcutpro.getTimelineSplitGroup()

	-- Which Split Group:
	local whichSplitGroup = nil

	-- Define Final Cut Pro:
	local sw = ax.applicationElement(finalcutpro.application())

	-- Single Screen:
	whichSplitGroup = sw:searchPath({
		{ role = "AXWindow", Title = "Final Cut Pro"},								-- AXWindow "Final Cut Pro" (window 2)
		{ role = "AXSplitGroup", },												 	-- AXSplitGroup (splitter group 1)
		{ role = "AXGroup", },													    -- AXGroup (group 1)
		{ role = "AXSplitGroup", },												    -- AXSplitGroup (splitter group 1)
		{ role = "AXGroup", },												        -- AXGroup (group 2)
		{ role = "AXSplitGroup", },												 	-- AXSplitGroup (splitter group 1)
		{ role = "AXGroup", },														-- AXGroup (group 1)
		{ role = "AXSplitGroup", Identifier = "_NS:237"},							-- AXSplitGroup (splitter group 1)
	}, 1)

	-- Dual Screen:
	if whichSplitGroup == nil then

		whichSplitGroup = sw:searchPath({
			{ role = "AXWindow", Title = "Final Cut Pro"},							-- AXWindow "Final Cut Pro" (window 2)
			{ role = "AXSplitGroup", },											 	-- AXSplitGroup (splitter group 1)
			{ role = "AXGroup", },												    -- AXGroup (group 1)
			{ role = "AXSplitGroup", },											    -- AXSplitGroup (splitter group 1)
			{ role = "AXGroup", },											        -- AXGroup (group 2)
			{ role = "AXSplitGroup", Identifier = "_NS:237"},					 	-- AXSplitGroup (splitter group 1)
		}, 1)

	end

	return whichSplitGroup

end

--- hs.finalcutpro.getTimelineButtonBar() -> axuielementObject or nil
--- Function
--- Gets Timeline Button Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Timeline Button Bar or nil if failed
---
function finalcutpro.getTimelineButtonBar()

	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()
	return finalCutProTimelineSplitGroup:attributeValue("AXParent")[2]

end

--- hs.finalcutpro.getEffectsTransitionsBrowserGroup() -> axuielementObject or nil
--- Function
--- Gets Effects/Transitions Browser Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Effects/Transitions Browser Group or nil if failed
---
function finalcutpro.getEffectsTransitionsBrowserGroup()

	-- Get Timeline Split Group:
	local finalCutProTimelineSplitGroup = finalcutpro.getTimelineSplitGroup()

	local result = nil

	-- Get the LAST Group:
	for i=1, finalCutProTimelineSplitGroup:attributeValueCount("AXChildren") do
		if finalCutProTimelineSplitGroup[i]:attributeValue("AXRole") == "AXGroup" then
			result = finalCutProTimelineSplitGroup[i]
		end
	end

	return result

end

--- hs.finalcutpro.getBrowserSplitGroup() -> axuielementObject or nil
--- Function
--- Gets Browser Split Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Browser Split Group or nil if failed
---
function finalcutpro.getBrowserSplitGroup()

	-- Different Split Group Identifiers for Different Languages:
	local splitGroupIdentifier = nil
	currentLanguage = finalcutpro.currentLanguage()
	if currentLanguage == "en" then
		splitGroupIdentifier = "_NS:344"
	elseif currentLanguage == "de" then
		splitGroupIdentifier = "_NS:346"
	elseif currentLanguage == "es" then
		splitGroupIdentifier = "_NS:347"
	elseif currentLanguage == "fr" then
		splitGroupIdentifier = "_NS:345"
	elseif currentLanguage == "ja" then
		splitGroupIdentifier = "_NS:347"
	elseif currentLanguage == "zh_CN" then
		splitGroupIdentifier = "_NS:347"
	end

	-- Define Final Cut Pro:
	sw = ax.applicationElement(finalcutpro.application())

	-- Single Screen:
	local browserSplitGroup = sw:searchPath({
		{ role = "AXWindow", Title = "Final Cut Pro"},
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", Identifier = splitGroupIdentifier},
	}, 1)

	-- Dual Screen:
	if browserSplitGroup == nil then
		browserSplitGroup = sw:searchPath({
			{ role = "AXWindow", },
			{ role = "AXSplitGroup", },
			{ role = "AXGroup", },
			{ role = "AXSplitGroup", Identifier = splitGroupIdentifier},
		}, 1)
	end

	return browserSplitGroup

end

--- hs.finalcutpro.getBrowserButtonBar() -> axuielementObject or nil
--- Function
--- Gets Browser Button Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Browser Button Bar or nil if failed
---
function finalcutpro.getBrowserButtonBar()
	local finalCutProBrowserSplitGroup = finalcutpro.getBrowserSplitGroup()
	if finalCutProBrowserSplitGroup ~= nil then
		return finalCutProBrowserSplitGroup:attributeValue("AXParent")
	else
		return nil
	end
end

--- hs.finalcutpro.getColorBoardRadioGroup() -> axuielementObject or nil
--- Function
--- Gets the Color Board Radio Group
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Color Board Radio Group or nil if failed
---
function finalcutpro.getColorBoardRadioGroup()

	-- Define Final Cut Pro:
	sw = ax.applicationElement(finalcutpro.application())

	-- Find Color Button:
	local result = sw:searchPath({
		{ role = "AXWindow", Title = "Final Cut Pro"},
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup", },
		{ role = "AXGroup", },
		{ role = "AXRadioGroup", Identifier = "_NS:128"},
	}, 1)

	return result

end

--- hs.finalcutpro.getBrowserMode() -> string or nil
--- Function
--- Returns the current Browser Mode
---
--- Parameters:
---  * None
---
--- Returns:
---  * "List", "Filmstrip" or nil
---
function finalcutpro.getBrowserMode()

	--------------------------------------------------------------------------------
	-- Get Browser Split Group:
	--------------------------------------------------------------------------------
	browserSplitGroup = finalcutpro.getBrowserSplitGroup()
	if browserSplitGroup == nil then
		writeToConsole("ERROR: Failed to get Browser Split Group in finalcutpro.getBrowserMode().")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, browserSplitGroup:attributeValueCount("AXChildren") do
		if browserSplitGroup[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
		end
	end
	if whichGroup == nil then
		writeToConsole("ERROR: Unable to locate Group in finalcutpro.getBrowserMode().")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Which Scroll Area:
	--------------------------------------------------------------------------------
	local whichScrollArea = nil
	for i=1, browserSplitGroup[whichGroup]:attributeValueCount("AXChildren") do
		if browserSplitGroup[whichGroup][i]:attributeValue("AXRole") == "AXScrollArea" then
			whichScrollArea = i
		end
	end

	if whichScrollArea == nil then
		--------------------------------------------------------------------------------
		-- LIST VIEW:
		--------------------------------------------------------------------------------
		return "List"
	else
		return "Filmstrip"
	end

end

--- hs.finalcutpro.getBrowserPersistentPlayhead() -> axuielementObject or nil
--- Function
--- Gets the Browser Persistent Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject for the Browser Persistent Playhead or nil if failed
---
function finalcutpro.getBrowserPersistentPlayhead()

	local persistentPlayhead = nil

	--------------------------------------------------------------------------------
	-- Get Browser Split Group:
	--------------------------------------------------------------------------------
	browserSplitGroup = finalcutpro.getBrowserSplitGroup()
	if browserSplitGroup == nil then
		writeToConsole("ERROR: Failed to get Browser Split Group in finalcutpro.getBrowserPersistentPlayhead().")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, browserSplitGroup:attributeValueCount("AXChildren") do
		if browserSplitGroup[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
		end
	end
	if whichGroup == nil then
		writeToConsole("ERROR: Unable to locate Group in finalcutpro.getBrowserPersistentPlayhead().")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Which Scroll Area:
	--------------------------------------------------------------------------------
	local whichScrollArea = nil
	for i=1, browserSplitGroup[whichGroup]:attributeValueCount("AXChildren") do
		if browserSplitGroup[whichGroup][i]:attributeValue("AXRole") == "AXScrollArea" then
			whichScrollArea = i
		end
	end

	if whichScrollArea == nil then

		--------------------------------------------------------------------------------
		-- LIST VIEW:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Which Split Group:
			--------------------------------------------------------------------------------
			local whichSplitGroup = nil
			for i=1, browserSplitGroup[whichGroup]:attributeValueCount("AXChildren") do
				if browserSplitGroup[whichGroup][i]:attributeValue("AXRole") == "AXSplitGroup" then
					if browserSplitGroup[whichGroup][i]:attributeValue("AXIdentifier") == "_NS:658" then
						whichSplitGroup = i
						goto exitWhichSplitGroupLoop
					end
				end
			end
			::exitWhichSplitGroupLoop::
			if whichSplitGroup == nil then
				writeToConsole("ERROR: Unable to locate Split Group in finalcutpro.getBrowserPersistentPlayhead().")
				return nil
			end

			--------------------------------------------------------------------------------
			-- Which Group 2:
			--------------------------------------------------------------------------------
			local whichGroupTwo = nil
			for i=1, browserSplitGroup[whichGroup][whichSplitGroup]:attributeValueCount("AXChildren") do
				if browserSplitGroup[whichGroup][whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					if browserSplitGroup[whichGroup][whichSplitGroup][i]:attributeValue("AXIdentifier") == "_NS:590" then
						whichGroupTwo = i
						goto exitWhichGroupTwoLoop
					end
				end
			end
			::exitWhichGroupTwoLoop::
			if whichGroupTwo == nil then
				writeToConsole("ERROR: Unable to locate Group Two in finalcutpro.getBrowserPersistentPlayhead().")
				return nil
			end

			--------------------------------------------------------------------------------
			-- Which Value Indicator:
			--------------------------------------------------------------------------------
			local whichValueIndicator = nil
			whichValueIndicator = browserSplitGroup[whichGroup][whichSplitGroup][whichGroupTwo]:attributeValueCount("AXChildren") - 1
			persistentPlayhead = browserSplitGroup[whichGroup][whichSplitGroup][whichGroupTwo][whichValueIndicator]

	else

		--------------------------------------------------------------------------------
		-- FILMSTRIP VIEW:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Which Group 2:
			--------------------------------------------------------------------------------
			local whichGroupTwo = nil
			for i=1, browserSplitGroup[whichGroup][whichScrollArea]:attributeValueCount("AXChildren") do
				if browserSplitGroup[whichGroup][whichScrollArea][i]:attributeValue("AXRole") == "AXGroup" then
					if browserSplitGroup[whichGroup][whichScrollArea][i]:attributeValue("AXIdentifier") == "_NS:39" then
						whichGroupTwo = i
						goto exitWhichGroupTwoLoop
					end
				end
			end
			::exitWhichGroupTwoLoop::
			if whichGroupTwo == nil then
				writeToConsole("ERROR: Unable to locate Group Two in finalcutpro.getBrowserPersistentPlayhead().")
				return nil
			end

			--------------------------------------------------------------------------------
			-- Which Value Indicator:
			--------------------------------------------------------------------------------
			local whichValueIndicator = nil
			whichValueIndicator = browserSplitGroup[whichGroup][whichScrollArea][whichGroupTwo]:attributeValueCount("AXChildren") - 1
			persistentPlayhead = browserSplitGroup[whichGroup][whichScrollArea][whichGroupTwo][whichValueIndicator]
	end

	return persistentPlayhead

end

--- hs.finalcutpro.getBrowserSearchButton() -> axuielementObject or nil
--- Function
--- Gets the Browser Search Button
---
--- Parameters:
---  * [BrowserButtonBar] - If you already know the Browser Button Bar Group,
---                         you can supply it here for a slight speed increase
---
--- Returns:
---  * axuielementObject for the Browser Search Button or nil if failed
---
function finalcutpro.getBrowserSearchButton(optionalBrowserButtonBar)

	local browserButtonBar = nil
	if optionalBrowserButtonBar == nil then
		browserButtonBar = finalcutpro.getBrowserButtonBar()
	else
		browserButtonBar = optionalBrowserButtonBar
	end

	local searchButtonID = nil
	for i=1, browserButtonBar:attributeValueCount("AXChildren") do
		if browserButtonBar[i]:attributeValue("AXRole") == "AXButton" then
			if browserButtonBar[i]:attributeValue("AXIdentifier") == "_NS:92" then
				searchButtonID = i
			end
		end
	end
	if searchButtonID == nil then
		writeToConsole("Unable to find Search Button.\n\nError occured in finalcutpro.getBrowserSearchButton().")
		return nil
	end

	local result = nil
	result = browserButtonBar[searchButtonID]

	return result

end

--- hs.finalcutpro.translateKeyboardCharacters() -> string
--- Function
--- Translate Keyboard Character Strings from Command Set Format into Hammerspoon Format.
---
--- Parameters:
---  * input - Character String
---
--- Returns:
---  * Keycode as String or ""
---
function finalcutpro.translateKeyboardCharacters(input)

	local result = tostring(input)

	if input == " " 									then result = "space"		end
	if string.find(input, "NSF1FunctionKey") 			then result = "f1" 			end
	if string.find(input, "NSF2FunctionKey") 			then result = "f2" 			end
	if string.find(input, "NSF3FunctionKey") 			then result = "f3" 			end
	if string.find(input, "NSF4FunctionKey") 			then result = "f4" 			end
	if string.find(input, "NSF5FunctionKey") 			then result = "f5" 			end
	if string.find(input, "NSF6FunctionKey") 			then result = "f6" 			end
	if string.find(input, "NSF7FunctionKey") 			then result = "f7" 			end
	if string.find(input, "NSF8FunctionKey") 			then result = "f8" 			end
	if string.find(input, "NSF9FunctionKey") 			then result = "f9" 			end
	if string.find(input, "NSF10FunctionKey") 			then result = "f10" 		end
	if string.find(input, "NSF11FunctionKey") 			then result = "f11" 		end
	if string.find(input, "NSF12FunctionKey") 			then result = "f12" 		end
	if string.find(input, "NSF13FunctionKey") 			then result = "f13" 		end
	if string.find(input, "NSF14FunctionKey") 			then result = "f14" 		end
	if string.find(input, "NSF15FunctionKey") 			then result = "f15" 		end
	if string.find(input, "NSF16FunctionKey") 			then result = "f16" 		end
	if string.find(input, "NSF17FunctionKey") 			then result = "f17" 		end
	if string.find(input, "NSF18FunctionKey") 			then result = "f18" 		end
	if string.find(input, "NSF19FunctionKey") 			then result = "f19" 		end
	if string.find(input, "NSF20FunctionKey") 			then result = "f20" 		end
	if string.find(input, "NSUpArrowFunctionKey") 		then result = "up" 			end
	if string.find(input, "NSDownArrowFunctionKey") 	then result = "down" 		end
	if string.find(input, "NSLeftArrowFunctionKey") 	then result = "left" 		end
	if string.find(input, "NSRightArrowFunctionKey") 	then result = "right" 		end
	if string.find(input, "NSDeleteFunctionKey") 		then result = "delete" 		end
	if string.find(input, "NSHomeFunctionKey") 			then result = "home" 		end
	if string.find(input, "NSEndFunctionKey") 			then result = "end" 		end
	if string.find(input, "NSPageUpFunctionKey") 		then result = "pageup" 		end
	if string.find(input, "NSPageDownFunctionKey") 		then result = "pagedown" 	end

	--------------------------------------------------------------------------------
	-- Convert to lowercase:
	--------------------------------------------------------------------------------
	result = string.lower(result)

	local convertedToKeycode = finalcutpro.keyCodeTranslator(result)
	if convertedToKeycode == nil then
		writeToConsole("NON-FATAL ERROR: Failed to translate keyboard character (" .. tostring(input) .. ").")
		result = ""
	else
		result = convertedToKeycode
	end

	return result

end

--- hs.finalcutpro.translateKeyboardKeypadCharacters() -> string
--- Function
--- Translate Keyboard Keypad Character Strings from Command Set Format into Hammerspoon Format.
---
--- Parameters:
---  * input - Character String
---
--- Returns:
---  * string or nil
---
function finalcutpro.translateKeyboardKeypadCharacters(input)

	local result = nil
	local padKeys = { "*", "+", "/", "-", "=", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "enter" }
	for i=1, #padKeys do
		if input == padKeys[i] then result = "pad" .. input end
	end

	return finalcutpro.translateKeyboardCharacters(result)

end

--- hs.finalcutpro.translateKeyboardModifiers() -> table
--- Function
--- Translate Keyboard Modifiers from Command Set Format into Hammerspoon Format
---
--- Parameters:
---  * input - Modifiers String
---
--- Returns:
---  * table
---
function finalcutpro.translateKeyboardModifiers(input)

	local result = {}
	if string.find(input, "command") then result[#result + 1] = "command" end
	if string.find(input, "control") then result[#result + 1] = "control" end
	if string.find(input, "option") then result[#result + 1] = "option" end
	if string.find(input, "shift") then result[#result + 1] = "shift" end
	return result

end

--- hs.finalcutpro.translateModifierMask() -> table
--- Function
--- Translate Keyboard Modifiers from Command Set Format into Hammerspoon Format
---
--- Parameters:
---  * value - Modifiers String
---
--- Returns:
---  * table
---
function finalcutpro.translateModifierMask(value)

	local modifiers = {
		--AlphaShift = 1 << 16,
		shift      = 1 << 17,
		control    = 1 << 18,
		option	   = 1 << 19,
		command    = 1 << 20,
		--NumericPad = 1 << 21,
		--Help       = 1 << 22,
		--Function   = 1 << 23,
	}

	local answer = {}

	for k, v in pairs(modifiers) do
		if (value & v) == v then
			table.insert(answer, k)
		end
	end

	return answer

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

	local activeCommandSet = finalcutpro.getActiveCommandSet()

	if activeCommandSet[whichShortcut] == nil then return false end

	local currentShortcut = nil
	if activeCommandSet[whichShortcut][1] ~= nil then
		currentShortcut = activeCommandSet[whichShortcut][1]
	else
		currentShortcut = activeCommandSet[whichShortcut]
	end

	if currentShortcut == nil then
		print("error")
		return false
	end

	local tempModifiers = nil
	local tempCharacterString = nil

	if currentShortcut["modifiers"] ~= nil then
		tempModifiers = finalcutpro.translateKeyboardModifiers(currentShortcut["modifiers"])
	end

	if currentShortcut["modifierMask"] ~= nil then
		tempModifiers = finalcutpro.translateModifierMask(currentShortcut["modifierMask"])
	end

	if currentShortcut["characterString"] ~= nil then
		tempCharacterString = finalcutpro.translateKeyboardCharacters(currentShortcut["characterString"])
	end

	if currentShortcut["character"] ~= nil then
		if keypadModifier then
			tempCharacterString = finalcutpro.translateKeyboardKeypadCharacters(currentShortcut["character"])
		else
			tempCharacterString = finalcutpro.translateKeyboardCharacters(currentShortcut["character"])
		end
	end

	eventtap.keyStroke(tempModifiers, tempCharacterString)

	return true

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