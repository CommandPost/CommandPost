--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.plugins ===
---
--- Scan Final Cut Pro bundle for Effects, Generators, Titles & Transitions.
---
--- Usage:
--- require("cp.apple.finalcutpro"):scanPlugins()


--------------------------------------------------------------------------------
--
-- NOTE: This might be useful? But no cache for 'es'?
--
-- /Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/registryCache_de
-- /Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/registryCache_en
-- /Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/registryCache_fr
-- /Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/registryCache_ja
-- /Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/registryCache_zh-Hans
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- GREP NOTES:
--------------------------------------------------------------------------------
--[[
grep -lr "Cross Dissolve" /Applications/Final\ Cut\ Pro.app/Contents
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Resources/en.lproj/FFAnchoredTimelineModule-iMovie.nib
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Resources/en.lproj/FFAnchoredTimelineModule.nib
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFAnchoredTimelineModule-iMovie.nib
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFAnchoredTimelineModule.nib
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/Current/Resources/en.lproj/FFAnchoredTimelineModule-iMovie.nib
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/Current/Resources/en.lproj/FFAnchoredTimelineModule.nib
/Applications/Final Cut Pro.app/Contents/PlugIns/FxPlug/FiltersLegacyPath.bundle/Contents/Resources/English.lproj/Localizable.strings
/Applications/Final Cut Pro.app/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/English.lproj/Localizable.strings
/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/MacOS/MotionEffect

grep -lr "Draw Mask" /Applications/Final\ Cut\ Pro.app/Contents
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Resources/en.lproj/FFLocalizable.strings
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings
/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/Current/Resources/en.lproj/FFLocalizable.strings
/Applications/Final Cut Pro.app/Contents/Resources/FinalCutPro10.help/Contents/Resources/en.lproj/navigation.json
--]]
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("scan")
local bench										= require("cp.bench")

local fnutils									= require("hs.fnutils")
local fs 										= require("hs.fs")
local host										= require("hs.host")
local inspect									= require("hs.inspect")

local archiver									= require("cp.plist.archiver")
local config									= require("cp.config")
local plist										= require("cp.plist")
local tools										= require("cp.tools")

local text										= require("cp.web.text")
local localized									= require("cp.localized")

local prop										= require("cp.prop")

--------------------------------------------------------------------------------
--
-- HELPER FUNCTIONS:
--
--------------------------------------------------------------------------------

local escapeXML, unescapeXML	= text.escapeXML, text.unescapeXML
local isBinaryPlist				= plist.isBinaryPlist
local getLocalizedName			= localized.getLocalizedName
local insert					= table.insert

-- string:split(sep) -> table
-- Function
-- Splits a string into a table, separated by sep
--
-- Parameters:
--  * sep - Character to use as separator
--
-- Returns:
--  * Table
function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------


local mod = {}
-- The metatable
mod.mt = {}
mod.mt.__index = mod.mt


-- scanAudioUnits() -> none
-- Function
-- Scans for Validated Audio Units
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.mt:scanAudioUnits()
	local audioUnits = {}
	local output, status = hs.execute("auval -s aufx")
	if status and output then
		local coreAudioPlistPath = mod.coreAudioPreferences
		local coreAudioPlistData = plist.fileToTable(coreAudioPlistPath)
		local lines = tools.lines(output)
		for _, line in pairs(lines) do
			if string.find(line, "%w%w%w%w%s%w%w%w%w%s%w%w%w%w%s-%s") then
				local result = string.sub(line, 19)
				if result and string.find(result, ":") then
					local values = string.split(result)
					local key = tools.trim(values[1])
					--------------------------------------------------------------------------------
					-- CoreAudio Audio Units:
					--------------------------------------------------------------------------------
					if coreAudioPlistData and key == "Apple" then
						for _, component in pairs(coreAudioPlistData["AudioComponents"]) do
							if component["name"] and component["name"] == tools.trim(result) then
								if component["tags"] then
									if fnutils.contains(component["tags"], "Pitch") then key = "Voice"
									elseif fnutils.contains(component["tags"], "Delay") then key = "Echo"
									elseif fnutils.contains(component["tags"], "Reverb") then key = "Spaces"
									elseif fnutils.contains(component["tags"], "Equalizer") then key = "EQ"
									elseif fnutils.contains(component["tags"], "Dynamics Processor") then key = "Levels"
									elseif fnutils.contains(component["tags"], "Distortion") then key = "Distortion"
									else
										key = "Specialized"
									end
								else
									key = "Specialized"
								end
							end
						end
					end
					local category = key
					local plugin = tools.trim(values[2])
					for _, currentLanguage in pairs(self:getSupportedLanguages()) do
						local scan = self._plugins[currentLanguage]
						
						if not scan["AudioEffects"] then
							scan["AudioEffects"] = {}
						end
						if not scan["AudioEffects"]["OS X"] then
							scan["AudioEffects"]["OS X"] = {}
						end
						if not scan["AudioEffects"]["OS X"][category] then
							scan["AudioEffects"]["OS X"][category] = {}
						end
						insert(scan["AudioEffects"]["OS X"][category], plugin)
					end
				end
			end
		end
	else
		log.ef("Failed to scan for Audio Units.")
	end
end

-- scanEffectsPresets() -> none
-- Function
-- Scans Final Cut Pro Effects Presets
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.mt:scanEffectsPresets()
	for _, path in pairs(mod.effectPresetPaths) do
		if tools.doesDirectoryExist(path) then
			for file in fs.dir(path) do
				if string.sub(file, -14) == ".effectsPreset" then
					local plistResult = plist.fileToTable(path .. file)
					if plistResult then
						local unarchivedPlist = archiver.unarchive(plistResult)
						if unarchivedPlist then
							local category = unarchivedPlist["category"]
							if category then
								local plugin = string.sub(file, 1, -15)
								for _, currentLanguage in pairs(self:getSupportedLanguages()) do
									local scan = self._plugins[currentLanguage]
									if not scan["Effects"] then
										scan["Effects"] = {}
									end
									if not scan["Effects"][category] then
										scan["Effects"][category] = {}
									end
									insert(scan["Effects"][category], plugin)
								end
							end
						end
					end
				end
			end
		end
	end
end

local TEMPLATE_PATTERN	= ".*<template>.*"
local THEME_PATTERN		= ".*<theme>(.+)</theme>.*"

--- cp.apple.finalcutpro.scannplugins.getMotionTheme(filename) -> string | nil
--- Function
--- Process a plugin so that it's added to the current scan
---
--- Parameters:
---  * filename - Filename of the plugin
---
--- Returns:
---  * The theme name, or `nil` if not found.
---
--- Notes:
---  * getMotionTheme("~/Movies/Motion Templates.localized/Effects.localized/3065D03D-92D7-4FD9-B472-E524B87B5012.localized/DAEB0CAD-E702-4BF9-94B5-AE89D7F8FB00.localized/DAEB0CAD-E702-4BF9-94B5-AE89D7F8FB00.moef")
function mod.getMotionTheme(filename)
	local filename = fs.pathToAbsolute(filename)
	if filename then
		local inTemplate = false
		local theme = nil
		
		-- reads through the motion file, looking for the template/theme elements.
		local file = io.open(filename,"r")
		while not theme do
			local line = file:read("*l")
			if line == nil then break end
			
			if not inTemplate then
				local start = line:find(TEMPLATE_PATTERN)
				inTemplate = start ~= nil
			end
			
			if inTemplate then
				theme = line:match(THEME_PATTERN)
			end
		end
		file:close()
		
		return theme ~= "~Obsolete" and theme or nil
	end
	return nil
end

-- cp.apple.finalcutpro.plugins.isPluginFactory(path, pluginExt) -> boolean
-- Function
-- Checks if the specified path is a plugin directory with the specified extension(s).
--
-- Parameters:
--  * `path`		- The path to the directory to check
--  * `pluginExt`	- The plugin extensions to check for.
--
-- Returns:
--  * `true` if the path is a plugin path for the specified extension type.
local function isPluginDirectory(path, pluginExt)
	local _,realName = getLocalizedName(path, "en")
	if realName then
		for _,ext in ipairs(pluginExt) do
			if fs.pathToAbsolute(path .. "/" .. realName .. "." .. ext) ~= nil then -- the plugin file exists.
				return true
			end
		end
	end
	return false
end

-- cp.apple.finalcutpro.plugins:scanPluginsDirectory(path, language) -> boolean
-- Method
-- Scans a root plugins directory. Plugins directories have a standard structure which comes in two flavours:
--
-- 1. <type>/<group>/<plugin name>/<plugin name>.<ext>
-- 2. <type>/<group>/<theme>/<plugin name>/<plugin name>.<ext>
--
-- This is somewhat complicated by 'localization', wherein each of the folder levels may have a `.localized` extension. If this is the case, it will contain a subfolder called `.localized`, which in turn contains files which describe the local name for the folder in any number of languages.
--
-- This function will drill down through the contents of the specified `path`, assuming the above structure, and then register any contained plugins in the `language` provided. Other languages are ignored, other than some use of English when checking for specific effect types (Effect, Generator, etc.).
--
-- Parameters:
--  * `path`		- The path of the root plugin directory to scan.
--  * `language`	- The language code to scan for (e.g. "en" or "fr").
--
-- Returns:
--  * `true` if the plugin directory was successfully scanned.
function mod.mt:scanPluginsDirectory(path, language)
	--------------------------------------------------------------------------------
	-- Check that the directoryPath actually exists:
	--------------------------------------------------------------------------------
	path = fs.pathToAbsolute(path)
	if not path then
		log.wf("The provided path does not exist: '%s'", directoryPath)
		return false
	end
	
	--------------------------------------------------------------------------------
	-- Check that the directoryPath is actually a directory:
	--------------------------------------------------------------------------------
	local attrs = fs.attributes(path)
	if not attrs or attrs.mode ~= "directory" then
		log.ef("The provided path is not a directory: '%s'", directoryPath)
		return false
	end
	
	local failure = false
	
	-- loop through the files in the directory
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local typePath = path .. "/" .. file
			local typeName = getLocalizedName(typePath, "en")
			local typeExt = mod.pluginTypes[typeName]
			if typeExt then -- it's a recognised plugin type
				failure = failure or not self:scanPluginTypeDirectory(typePath, typeName, typeExt, language)
			end
		end
	end
	
	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginTypeDirectory(path, typeName, typeExt, language) -> boolean
-- Method
-- Scans a folder as a plugin type folder, such as 'Effects', 'Transitions', etc. The contents will be folders that are 'groups' of plugins, containing related plugins.
--
-- Parameters:
--  * `path`		- The path to the plugin type directory
--  * `typeName`	- The plugin type name, in English (e.g. "Effects")
--  * `typeExt`		- The plugin file extension for the type.
--  * `language`	- The language to scan with.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginTypeDirectory(path, typeName, typeExt, language)
	local failure = false
	
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local categoryPath = path .. "/" .. file
			local categoryName = getLocalizedName(categoryPath, language)
			failure = failure or not self:scanPluginCategoryDirectory(categoryPath, typeName, typeExt, categoryName, language)
		end
	end
	
	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginCategoryDirectory(path, typeName, typeExt, categoryName, language) -> boolean
-- Method
-- Scans a folder as a plugin category folder. The contents will be folders that are either theme folders or actual plugins.
--
-- Parameters:
--  * `path`			- The path to the plugin type directory
--  * `typeName`		- The plugin type name, in English (e.g. "Effects")
--  * `typeExt`			- The plugin file extension for the type.
--  * `categoryName`	- The category name, in the target language.
--  * `language`		- The language to scan with.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginCategoryDirectory(path, typeName, typeExt, categoryName, language)
	local failure = false
	
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local childPath = path .. "/" .. file
			local childName = getLocalizedName(childPath, language)
			if isPluginDirectory(childPath, typeExt) then
				self:registerPlugin(childPath, typeName, categoryName, nil, childName, language)
			else
				local attrs = fs.attributes(childPath)
				if attrs.mode == "directory" then
					failure = failure or not self:scanPluginThemeDirectory(childPath, typeName, typeExt, categoryName, childName, language)
				end
			end
		end
	end
	
	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginThemeDirectory(path, typeName, typeExt, categoryName, themeName, language) -> boolean
-- Method
-- Scans a folder as a plugin theme folder. The contents will be plugin folders.
--
-- Parameters:
--  * `path`			- The path to the plugin type directory
--  * `typeName`		- The plugin type name, in English (e.g. "Effects")
--  * `typeExt`			- The plugin file extension for the type.
--  * `categoryName`	- The plugin category name, in the target language.
--  * `themeName`		- The plugin theme name, in the target language.
--  * `language`		- The language to scan with.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginThemeDirectory(path, typeName, typeExt, categoryName, themeName, language)
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local pluginPath = path .. "/" .. file
			local pluginName = getLocalizedName(pluginPath, language)
			if isPluginDirectory(pluginPath, typeExt) then
				self:registerPlugin(pluginPath, typeName, categoryName, themeName, pluginName, language)
			end
		end
	end
	return true
end

--- cp.apple.finalcutpro.plugins:registerPlugin(path, typeName, categoryName, themeName, pluginName, langauge) -> plugin
--- Method
--- Registers a plugin with the specified details.
---
--- Parameters:
---  * `path`			- The path to the plugin directory.
---  * `typeName`		- The type of plugin, in English (e.g. 'Effect')
---  * `categoryName`	- The category name, in the specified language.
---  * `themeName`		- The theme name, in the specified langauge. May be `nil` if not in a theme.
---  * `pluginName`		- The plugin name, in the specified language.
---  * `language`		- The language code (e.g. "en", "fr", "de")
function mod.mt:registerPlugin(path, typeName, categoryName, themeName, pluginName, language)
	local plugins = self._plugins
	if not plugins then
		plugins = {}
		self._plugins = plugins
	end

	local lang = plugins[language]
	if not lang then
		lang = {}
		plugins[language] = lang
	end
	
	local type = lang[typeName]
	if not type then
		type = {}
		lang[typeName] = type
	end
	
	local plugin = {
		path = path,
		type = typeName,
		category = categoryName,
		theme = themeName,
		name = pluginName,
		language = language,
	}
	insert(type, plugin)
	return plugin
end

function mod.mt:reset()
	self._plugins = {}
end

-- translateEffectBundle(input, language) -> none
-- Function
-- Translates an Effect Bundle Item
--
-- Parameters:
--  * input - The original name
--  * language - The language code you want to attempt to translate to
--
-- Returns:
--  * require("cp.plist").fileToTable("/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/de.lproj/FFEffectBundleLocalizable.strings")
function mod.mt:translateEffectBundle(input, language)
	local prefsPath = self.effectBundlesPreferencesPath .. language .. ".lproj/FFEffectBundleLocalizable.strings"
	local plistResult = plist.fileToTable(prefsPath)
	if plistResult then
		if plistResult[input] then
			return plistResult[input]
		else
			return input
		end
	end
end

-- scanAudioEffectBundles() -> none
-- Function
-- Scans the Audio Effect Bundles directories
--
-- Parameters:
--  * directoryPath - Directory to scan
--
-- Returns:
--  * None
function mod.mt:scanAudioEffectBundles(language)
	for _, path in pairs(self.effectBundlesPaths) do
		if tools.doesDirectoryExist(path) then
			for file in fs.dir(path) do
				if string.sub(file, -13) == ".effectBundle" then
					local effectComponents = string.split(file, ".")
					--------------------------------------------------------------------------------
					-- Example: Alien.Voice.audio.effectBundle
					--------------------------------------------------------------------------------
					if effectComponents and effectComponents[3] and effectComponents[3] == "audio" then
						local category = effectComponents[2]

						local plugin = self:translateEffectBundle(effectComponents[1], language)
						self:registerPlugin(path, "AudioEffects", category, nil, plugin, language)
					end
				end
			end
		end
	end
end

-- scanPlugins(language) -> none
-- Function
-- Scans for Final Cut Pro Plugins
--
-- Parameters:
--  * `language`	- The language to scan for.
--
-- Returns:
--  * None
function mod.mt:scanPlugins(language)
	for _, path in pairs(self.scanPaths) do
		self:scanPluginsDirectory(path, language)
	end
end

-- cp.apple.finalcutpro.plugins:scanSoundtrackProEDELEffects() -> none
-- Method
-- Scans for Soundtrack Pro EDEL Effects.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.mt:scanSoundtrackProEDELEffects()

	for _, currentLanguage in pairs(self:getSupportedLanguages()) do
		local scan = self._plugins[currentLanguage]
		scan["AudioEffects"] = scan["AudioEffects"] or {}
		scan["AudioEffects"]["Logic"]  = scan["AudioEffects"]["Logic"] or {}
		local logic = scan["AudioEffects"]["Logic"]
		for category, plugins in pairs(mod.builtinSoundtrackProEDELEffects) do
			local categoryList = logic[category] or {}
			logic[category] = categoryList
			for _, plugin in pairs(plugins) do
				table.insert(categoryList, plugin)
			end
		end
	end

	--------------------------------------------------------------------------------
	-- NOTE: I haven't worked out a way to programatically work out the category
	-- yet, so aborted this method:
	--------------------------------------------------------------------------------
	--[[
 	for _, path in pairs(mod.edelEffectPaths) do
		if tools.doesDirectoryExist(path) then
			for file in fs.dir(path) do
				local filePath = fs.pathToAbsolute(path .. "/" .. file)
				attrs = fs.attributes(filePath)
				if attrs.mode == "directory" then

					local category = "All"
					local plugin = file

					for _, currentLanguage in pairs(mod.supportedLanguages) do

						if not mod._plugins[currentLanguage]["AudioEffects"] then
							mod._plugins[currentLanguage]["AudioEffects"] = {}
						end

						if not mod._plugins[currentLanguage]["AudioEffects"][category] then
							mod._plugins[currentLanguage]["AudioEffects"][category] = {}
						end

						local pluginID = #mod._plugins[currentLanguage]["AudioEffects"][category] + 1
						mod._plugins[currentLanguage]["AudioEffects"][category][pluginID] = plugin

					end
				end
			end
		end
	end
	--]]

end

-- translateInternalEffect(input, language) -> none
-- Function
-- Translates an Effect Bundle Item
--
-- Parameters:
--  * input - The original name
--  * language - The language code you want to attempt to translate to
--
-- Returns:
--  * Result as string
--
-- Notes:
--  * require("cp.plist").fileToTable("/Applications/Final Cut Pro.app/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/English.lproj/Localizable.strings")
--  * translateInternalEffect("Draw Mask", "en")
function mod.mt:translateInternalEffect(input, language)

	--------------------------------------------------------------------------------
	-- Ignore if English:
	--------------------------------------------------------------------------------
	if language == "en" then
		return input
	end

	--------------------------------------------------------------------------------
	-- For debugging:
	--------------------------------------------------------------------------------
	--[[
	if not mod.internalEffectPreferencesPath then
		mod.internalEffectPreferencesPath =  "/Applications/Final Cut Pro.app/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/"
	end

	if not mod.internalEffectFlexoPath then
		mod.internalEffectFlexoPath = "/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/"
	end
	--]]

	--------------------------------------------------------------------------------
	-- Language Codes for InternalFiltersXPC.pluginkit:
	--------------------------------------------------------------------------------
	languageCodes = {
		fr	= "French",
		de	= "German",
		ja	= "Japanese",
		es	= "Spanish",
		zh_CN = "zh_CN",
	}

	--------------------------------------------------------------------------------
	-- Check InternalFiltersXPC.pluginkit first:
	--------------------------------------------------------------------------------
	if languageCodes[language] then
		local prefsPath = self.internalEffectPreferencesPath .. "English.lproj/Localizable.strings"
		local plistResult = plist.fileToTable(prefsPath)
		if plistResult then
			for key, string in pairs(plistResult) do
				if string == input then
					local newPrefsPath = self.internalEffectPreferencesPath .. languageCodes[language] .. ".lproj/Localizable.strings"
					local newPlistResult = plist.fileToTable(newPrefsPath)
					if newPlistResult and newPlistResult[key] then
						return newPlistResult[key]
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If that fails check Flexo.framework:
	--------------------------------------------------------------------------------
	local prefsPath = self.internalEffectFlexoPath .. "en.lproj/FFLocalizable.strings"
	local plistResult = plist.fileToTable(prefsPath)
	if plistResult then
		for key, string in pairs(plistResult) do
			if string == input then
				local newPrefsPath = self.internalEffectFlexoPath .. language .. ".lproj/FFLocalizable.strings"
				local newPlistResult = plist.fileToTable(newPrefsPath)
				if newPlistResult and newPlistResult[key] then
					return newPlistResult[key]
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If that fails just return input:
	--------------------------------------------------------------------------------
	log.df("Failed to find a match:")
	return input

end

-- compareOldMethodToNewMethodResults() -> none
-- Function
-- Compares the new Scan Results to the original scan results stored in settings.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.mt:compareOldMethodToNewMethodResults()

	--------------------------------------------------------------------------------
	-- Debug Message:
	--------------------------------------------------------------------------------
	--[[
	log.df("---------------------------------------------------------")
	log.df(" RESULTS FROM NEW SCAN:")
	log.df("---------------------------------------------------------")
	log.df("Scan Results: %s", hs.inspect(mod._plugins))
	--]]
	log.df("-----------------------------------------------------------")
	log.df(" COMPARING RESULTS TO THE RESULTS STORED IN YOUR SETTINGS:")
	log.df("-----------------------------------------------------------\n")

	--------------------------------------------------------------------------------
	-- Plugin Types:
	--------------------------------------------------------------------------------
	local pluginTypes = {
		"AudioEffects",
		"VideoEffects",
		"Transitions",
		"Generators",
		"Titles",
	}

	--------------------------------------------------------------------------------
	-- Begin Scan:
	--------------------------------------------------------------------------------
	for _, language in pairs(self:getSupportedLanguages()) do

		--------------------------------------------------------------------------------
		-- Debug Message:
		--------------------------------------------------------------------------------
		log.df("---------------------------------------------------------")
		log.df(" CHECKING LANGUAGE: %s", language)
		log.df("---------------------------------------------------------")

		for _, pluginType in pairs(pluginTypes) do

			--------------------------------------------------------------------------------
			-- Get settings from GUI Scripting Results:
			--------------------------------------------------------------------------------
			local settingResults = config.get(language .. ".all" .. pluginType)

			if settingResults then

				--------------------------------------------------------------------------------
				-- Debug Message:
				--------------------------------------------------------------------------------
				log.df(" - Checking Plugin Type: %s", pluginType)

				--------------------------------------------------------------------------------
				-- Convert Scan Plugins result into similar format to GUI Scripting Method:
				--------------------------------------------------------------------------------
				local effects = {}
				if pluginType == "VideoEffects" then
					pluginType = "Effects"
				end
				for _, pluginResults in pairs(self._plugins[language][pluginType]) do
					for category, newPluginName in pairs(pluginResults) do
						if type(newPluginName) == "table" then
							for _, plugin in pairs(newPluginName) do
								if pluginType == "AudioEffects" then
									effects[#effects + 1] = plugin
								else
									effects[#effects + 1] = category .. " - " .. plugin
								end
							end
						else
							effects[#effects + 1] = newPluginName
						end
					end
				end

				--------------------------------------------------------------------------------
				-- Compare Results:
				--------------------------------------------------------------------------------
				local errorCount = 0
				for _, oldPluginName in pairs(settingResults) do
					local match = false
					for _, newPluginName in pairs(effects) do
						if oldPluginName == newPluginName then
							match = true
						end
					end
					if not match then
						log.df("  - ERROR: Missing " .. pluginType .. ": %s", oldPluginName)
						errorCount = errorCount + 1
					end
				end

				--------------------------------------------------------------------------------
				-- If all results matched:
				--------------------------------------------------------------------------------
				if errorCount == 0 then
					log.df("  - SUCCESS: %s all matched!\n", pluginType)
				else
					log.df("")
				end

			else
				log.df(" - SKIPPING: Could not find settings for: %s (%s)", pluginType, language)
			end
		end
		log.df("")
		log.df("---------------------------------------------------------")
		log.df(" DEBUGGING:")
		log.df("---------------------------------------------------------")
		log.df(" - Scan Results saved to global table: debugScanPlugin")
		debugScanPlugin = self._plugins

	end
end

--------------------------------------------------------------------------------
-- Define Plugin Types:
--------------------------------------------------------------------------------
mod.pluginTypes = {
	["Effects"] 		= 	{ "moef" },
	["Transitions"]		= 	{ "motr" },
	["Generators"] 		= 	{ "motn" },
	["Titles"] 			= 	{ "moti" },
}

--------------------------------------------------------------------------------
-- Core Audio Preferences File:
--------------------------------------------------------------------------------
mod.coreAudioPreferences = "/System/Library/Components/CoreAudio.component/Contents/Info.plist"


--------------------------------------------------------------------------------
-- Built-in Effects:
--------------------------------------------------------------------------------
mod.builtinEffects = {
	["Color"] 			= 	{ "Color Correction" },
	["Masks"] 			= 	{ "Draw Mask", "Shape Mask" },
	["Stylize"] 		= 	{ "Drop Shadow" },
	["Keying"] 			=	{ "Keyer", "Luma Keyer" }
}

--------------------------------------------------------------------------------
-- Built-in Transitions:
--------------------------------------------------------------------------------
mod.builtinTransitions = {
	["Dissolves"] = { "Cross Dissolve", "Fade To Color", "Flow" },
	["Movements"] = { "Spin", "Swap", "Ripple", "Mosaic", "Puzzle" },
	["Objects"] = { "Star", "Doorway" },
	["Wipes"] = { "Band", "Center", "Checker", "Chevron", "Circle", "Clock", "Gradient Image", "Inset Wipe", "Letter X", "Wipe" },
	["Blurs"] = { "Zoom & Pan", "Simple" },
}

--------------------------------------------------------------------------------
-- Built-in Soundtrack Pro EDEL Effects:
--------------------------------------------------------------------------------
mod.builtinSoundtrackProEDELEffects = {
	["Distortion"] = {
		"Bitcrusher",
		"Clip Distortion",
		"Distortion",
		"Distortion II",
		"Overdrive",
		"Phase Distortion",
		"Ringshifter",
	},
	["Echo"] = {
		"Delay Designer",
		"Modulation Delay",
		"Stereo Delay",
		"Tape Delay",
	},
	["EQ"] = {
		"AutoFilter",
		"Channel EQ", -- This isn't actually listed as a Logic plugin in FCPX, but it is.
		"Fat EQ",
		"Linear Phase EQ",
	},
	["Levels"] = {
		"Adaptive Limiter",
		"Compressor",
		"Enveloper",
		"Expander",
		"Gain",
		"Limiter",
		"Multichannel Gain",
		"Multipressor",
		"Noise Gate",
		"Spectral Gate",
		"Surround Compressor",
	},
	["Modulation"] = {
		"Chorus",
		"Ensemble",
		"Flanger",
		"Phaser",
		"Scanner Vibrato",
		"Tremolo"
	},
	["Spaces"] = {
		"PlatinumVerb",
		"Space Designer",
	},
	["Specialized"] = {
		"Correlation Meter",
		"Denoiser",
		"Direction Mixer",
		"Exciter",
		"MultiMeter",
		"Stereo Spread",
		"SubBass",
		"Test Oscillator",
	},
	["Voice"] = {
		"DeEsser",
		"Pitch Correction",
		"Pitch Shifter II",
		"Vocal Transformer",
	},
}

function mod.mt:app()
	return self._app
end

function mod.mt:getSupportedLanguages()
	return self._app:getSupportedLanguages()
end

function mod.mt:getCurrentLanguage()
	return self._app:getCurrentLanguage()
end

function mod.mt:init()
	bench("scan:init", function()

		--------------------------------------------------------------------------------
		-- Setup Final Cut Pro Variables:
		--------------------------------------------------------------------------------
		local fcpPath = self:app():getPath()

		--------------------------------------------------------------------------------
		-- Define Search Paths:
		--------------------------------------------------------------------------------
		self.scanPaths = {
			"~/Movies/Motion Templates.localized",
			"/Library/Application Support/Final Cut Pro/Templates.localized",
			fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized",
			fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized",
		}

		--------------------------------------------------------------------------------
		-- Define Effect Bundles Paths:
		--------------------------------------------------------------------------------
		self.effectBundlesPaths = {
			fcpPath .. "/Contents/Frameworks/Flexo.framework/Resources/Effect Bundles",
		}

		--------------------------------------------------------------------------------
		-- Effect Bundles Preferences Path:
		--------------------------------------------------------------------------------
		self.effectBundlesPreferencesPath = fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/"

		--------------------------------------------------------------------------------
		-- Define Effect Presets Paths:
		--------------------------------------------------------------------------------
		self.effectPresetPaths = {
			"~/Library/Application Support/ProApps/Effects Presets/",
		}

		--------------------------------------------------------------------------------
		-- Define Soundtrack Pro EDEL Effects Paths:
		--------------------------------------------------------------------------------
		self.edelEffectPaths = {
			fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/PlugIns/Audio/EDEL.bundle/Contents/Resources/Plug-In Settings"
		}

		--------------------------------------------------------------------------------
		-- Define Internal Effect Preferences Path:
		--------------------------------------------------------------------------------
		self.internalEffectPreferencesPath = fcpPath .. "/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/"
		self.internalEffectFlexoPath = fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/"

	end) --bench
	
	return self
end

function mod.mt:plugins()
	if not self._plugins then
		self:scan()
	end
	return self._plugins
end

--- cp.apple.finalcutpro.plugins:scan() -> none
--- Function
--- Scans Final Cut Pro for Effects, Transitions, Generators & Titles
---
--- Parameters:
---  * fcp - the `cp.apple.finalcutpro` instance
---
--- Returns:
---  * None
function mod.mt:scan()
	--------------------------------------------------------------------------------
	-- Reset Results Table:
	--------------------------------------------------------------------------------
	self._plugins = {}
	
	local language = self:getCurrentLanguage()
	log.df("scan: language = '%s'", language)

-- bench("scan:setup", function()
-- 	--------------------------------------------------------------------------------
-- 	-- Add Supported Languages, Plugin Types & Built-in Effects to Results Table:
-- 	--------------------------------------------------------------------------------
-- 	for _, currentLanguage in pairs(mod.supportedLanguages) do
-- 		local scan = {}
-- 		mod._plugins[currentLanguage] = scan
-- 		for pluginType, _ in pairs(mod.pluginTypes) do
-- 			local pluginTypeList = {}
-- 			scan[pluginType] = pluginTypeList
--
-- 			if pluginType == "Effects" then
-- 				--------------------------------------------------------------------------------
-- 				-- Add Built-in Effects:
-- 				--------------------------------------------------------------------------------
-- 				for category, effects in pairs(mod.builtinEffects) do
-- 					local categoryList = pluginTypeList[category] or {}
-- 					pluginTypeList[category] = categoryList
-- 					for _, effect in pairs(effects) do
-- 						table.insert(categoryList, translateInternalEffect(effect, currentLanguage))
-- 					end
-- 				end
-- 			elseif pluginType == "Transitions" then
-- 				--------------------------------------------------------------------------------
-- 				-- Add Built-in Transitions:
-- 				--------------------------------------------------------------------------------
-- 				for category, transitions in pairs(mod.builtinTransitions) do
-- 					local categoryList = pluginTypeList[category] or {}
-- 					pluginTypeList[category] = categoryList
-- 					for _, transition in pairs(transitions) do
-- 						table.insert(categoryList, translateInternalEffect(transition, currentLanguage))
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
--  end) --bench

-- 	--------------------------------------------------------------------------------
-- 	-- Scan Audio Units:
-- 	--------------------------------------------------------------------------------
-- bench("scan:audioUnits", function()
-- 	self:scanAudioUnits()
-- end) --bench
--
-- 	--------------------------------------------------------------------------------
-- 	-- Scan Soundtrack Pro EDEL Effects:
-- 	--------------------------------------------------------------------------------
-- bench("scan:edelEffects", function()
-- 	self:scanSoundtrackProEDELEffects()
-- end) --bench
--
	--------------------------------------------------------------------------------
	-- Scan Effect Bundles:
	--------------------------------------------------------------------------------
-- bench("scan:audioEffectBundles", function()
-- 	self:scanAudioEffectBundles(language)
-- end) --bench
--
-- 	--------------------------------------------------------------------------------
-- 	-- Scan Effect Presets:
-- 	--------------------------------------------------------------------------------
-- bench("scan:effectPresets", function()
-- 	self:scanEffectsPresets()
-- end) --bench

	--------------------------------------------------------------------------------
	-- Scan Plugins:
	--------------------------------------------------------------------------------
-- bench("scan:plugins", function()
-- 	self:scanPlugins(language)
-- end) --bench

-- 	--------------------------------------------------------------------------------
-- 	-- Test to compare these scans to previous GUI Scripted scans:
-- 	--------------------------------------------------------------------------------
-- bench("scan:compare", function()
-- 	compareOldMethodToNewMethodResults()
-- end) --bench

	return self._plugins

end

function mod.new(fcp)
	local o = {
		_app = fcp,
		_plugins = {}
	}
	return setmetatable(o, mod.mt):init()
end

return mod