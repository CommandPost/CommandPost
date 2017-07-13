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
local protect									= require("cp.protect")

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
local insert, remove			= table.insert, table.remove
local contains					= fnutils.contains

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

mod.types = protect {
	videoEffect	= "videoEffect",
	audioEffect	= "audioEffect",
	title		= "title",
	generator	= "generator",
	transition	= "transition",
}

--------------------------------------------------------------------------------
-- Define Plugin Types:
--------------------------------------------------------------------------------
mod.motionTemplates = {
	["Effects"] = {
		type = mod.types.videoEffect,
		extension = "moef",
	},
	["Transitions"] = {
		type = mod.types.transition,
		extension = "motr",
	},
	["Generators"] = {
		type = mod.types.generator,
		extension = "motn",
	},
	["Titles"] = {
		type = mod.types.title,
		extension = "moti",
	}
}

-- scanAudioUnits() -> none
-- Function
-- Scans for Validated Audio Units
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.mt:scanAudioUnits(language)
	local audioEffect = mod.types.audioEffect
	
	local audioUnits = {}
	-- get the full list of aufx plugins
	local output, status = hs.execute("auval -s aufx")
	
	if status and output then
		
		local coreAudioPlistPath = mod.coreAudioPreferences
		local coreAudioPlistData = plist.fileToTable(coreAudioPlistPath)
		-- log.df("coreAudioPlistData: %s", hs.inspect(coreAudioPlistData))
		
		local lines = tools.lines(output)
		for _, line in pairs(lines) do
			local fullName = string.match(line, "^%w%w%w%w%s%w%w%w%w%s%w%w%w%w%s+%-%s+(.*)$")
			if fullName then
				local category, plugin = string.match(fullName, "^(.-):%s*(.*)$")
				--------------------------------------------------------------------------------
				-- CoreAudio Audio Units:
				--------------------------------------------------------------------------------
				if coreAudioPlistData and category == "Apple" then
					-- look up the alternate name
					for _, component in pairs(coreAudioPlistData["AudioComponents"]) do
						if component.name == fullName then
							category = "Specialized"
							local tags = component.tags
							if tags then
								if contains(tags, "Pitch") then category = "Voice"
								elseif contains(tags, "Delay") then category = "Echo"
								elseif contains(tags, "Reverb") then category = "Spaces"
								elseif contains(tags, "Equalizer") then category = "EQ"
								elseif contains(tags, "Dynamics Processor") then category = "Levels"
								elseif contains(tags, "Distortion") then category = "Distortion" end
							end
						end
					end
				end
				self:registerPlugin(coreAudioPlistPath, audioEffect, category, "OS X", plugin, language)
			end
		end
	else
		log.ef("Failed to scan for Audio Units.")
	end
end

-- scanEffectsPresets(language) -> none
-- Function
-- Scans Final Cut Pro Effects Presets
--
-- Parameters:
--  * `language`	- The language to scan for.
--
-- Returns:
--  * None
function mod.mt:scanEffectsPresets(language)
	local videoEffect, audioEffect = mod.types.videoEffect, mod.types.audioEffect
	
	for _, path in ipairs(self.effectPresetPaths) do
		if tools.doesDirectoryExist(path) then
			for file in fs.dir(path) do
				local plugin = string.match(file, "(.+)%.effectsPreset")
				if plugin then
					local effectPath = path .. "/" .. file
					local preset = archiver.unarchiveFile(effectPath)
					if preset then
						local category = preset.category
						local effectType = preset.effectType or preset.presetEffectType
						if category then
							local type = effectType == "effect.audio.effect" and audioEffect or videoEffect
							self:registerPlugin(effectPath, type, category, "Final Cut", plugin, language)
						end
					end
				end
			end
		end
	end
end

local TEMPLATE_START_PATTERN	= ".*<template>.*"
local THEME_PATTERN				= ".*<theme>(.+)</theme>.*"
local FLAGS_PATTERN				= ".*<flags>(.+)</flags>.*"
local TEMPLATE_END_PATTERN		= ".*</template>.*"

local OBSOLETE_FLAG				= 2

local firstTheme = true

local function endsWith(str, ending)
	local len = #ending
	return str:len() >= len and str:sub(len * -1) == ending
end

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
function getMotionTheme(filename)
	-- if not firstTheme then
	-- 	return nil
	-- end
	-- firstTheme = false
	--
	filename = fs.pathToAbsolute(filename)
	if filename then
		local inTemplate = false
		local theme = nil
		local flags = nil
		
		-- reads through the motion file, looking for the template/theme elements.
		local file = io.open(filename,"r")
		while theme == nil and flags == nil do
			local line = file:read("*l")
			if line == nil then return nil end
			
			if not inTemplate then
				-- local start = line:find(TEMPLATE_START_PATTERN)
				-- inTemplate = start ~= nil
				inTemplate = endsWith(line, "<template>")
			end
			
			if inTemplate then
				theme = theme or line:match(THEME_PATTERN)
				flags = line:match(FLAGS_PATTERN) or flags
				-- if line:find(TEMPLATE_END_PATTERN) ~= nil then
				if endsWith(line, "</template>") then
					break
				end
			end
		end
		file:close()
		
		flags = flags and tonumber(flags) or 0
		log.df("Theme: %s, Flags: %d", theme, flags)
		return theme, flags & OBSOLETE_FLAG == OBSOLETE_FLAG
	end
	return nil
end

-- cp.apple.finalcutpro.plugins.getPluginName(path, pluginExt) -> boolean
-- Function
-- Checks if the specified path is a plugin directory, and returns the plugin name.
--
-- Parameters:
--  * `path`		- The path to the directory to check
--  * `pluginExt`	- The plugin extensions to check for.
--
-- Returns:
--  * The plugin name.
--  * The plugin theme.
local function getPluginName(path, pluginExt, language)
	local localName, realName = getLocalizedName(path, language)
	if realName then
		local pluginPath = path .. "/" .. realName .. "." .. pluginExt
		if fs.pathToAbsolute(pluginPath) ~= nil then -- the plugin file exists.
			
			return localName, getMotionTheme(pluginPath)
		else -- check there aren't any other files with the extension
			for file in fs.dir(path) do
				local name, ext = file:match("^(.+)%.([^%.]+)")
				if ext == pluginExt then
					pluginPath = path .. "/" .. name .. "." .. ext
					return name, getMotionTheme(pluginPath)
				end
			end
		end
	end
	return nil
end

-- cp.apple.finalcutpro.plugins.getPluginName(path, pluginExt) -> boolean
-- Function
-- Checks if the specified path is a plugin directory, and returns the plugin name.
--
-- Parameters:
--  * `path`		- The path to the directory to check
--  * `pluginExt`	- The plugin extensions to check for.
--
-- Returns:
--  * The plugin name.
--  * The plugin theme.
local function getPlugin(path, pluginExt, language)
	local localName, realName = getLocalizedName(path, language)
	if realName then
		local pluginPath = path .. "/" .. realName .. "." .. pluginExt
		if fs.pathToAbsolute(pluginPath) ~= nil then -- the plugin file exists.
			
			return localName, getMotionTheme(pluginPath)
		else -- check there aren't any other files with the extension
			for file in fs.dir(path) do
				local name, ext = file:match("^(.+)%.([^%.]+)")
				if ext == pluginExt then
					pluginPath = path .. "/" .. name .. "." .. ext
					return name, getMotionTheme(pluginPath)
				end
			end
		end
	end
	return nil
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
			local typeNameEN = getLocalizedName(typePath, "en")
			local mt = mod.motionTemplates[typeNameEN]
			if mt then
				local type = mt.type
				local typeExt = mt.extension
				if typeExt then -- it's a recognised plugin type
					failure = failure or not self:scanPluginTypeDirectory(typePath, type, typeExt, language)
				end
			end
		end
	end
	
	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginTypeDirectory(path, type, typeExt, language) -> boolean
-- Method
-- Scans a folder as a plugin type folder, such as 'Effects', 'Transitions', etc. The contents will be folders that are 'groups' of plugins, containing related plugins.
--
-- Parameters:
--  * `path`		- The path to the plugin type directory
--  * `type`		- The plugin type
--  * `typeExt`		- The plugin file extension for the type.
--  * `language`	- The language to scan with.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginTypeDirectory(path, type, typeExt, language)
	local failure = false
	
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local childPath = path .. "/" .. file
			local pluginName, themeName, obsolete = getPluginName(childPath, typeExt, language)
			if not obsolete then
				if pluginName then
					self:registerPlugin(childPath, type, categoryName, themeName, pluginName, language)
				else
					local categoryName = getLocalizedName(childPath, language)
					local attrs = fs.attributes(childPath)
					if attrs.mode == "directory" then
						failure = failure or not self:scanPluginCategoryDirectory(childPath, type, typeExt, categoryName, language)
					end
				end
			else
				log.df("Obsolete %s plugin: %s", type, pluginName)
			end
		end
	end
	
	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginCategoryDirectory(path, type, typeExt, categoryName, language) -> boolean
-- Method
-- Scans a folder as a plugin category folder. The contents will be folders that are either theme folders or actual plugins.
--
-- Parameters:
--  * `path`			- The path to the plugin type directory
--  * `type`			- The plugin type
--  * `typeExt`			- The plugin file extension for the type.
--  * `categoryName`	- The category name, in the target language.
--  * `language`		- The language to scan with.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginCategoryDirectory(path, type, typeExt, categoryName, language)
	local failure = false
	
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local childPath = path .. "/" .. file
			if fs.attributes(childPath).mode == "directory" then
				local pluginName, themeName, obsolete = getPluginName(childPath, typeExt, language)
				if not obsolete then
					if pluginName then
						self:registerPlugin(childPath, type, categoryName, themeName, pluginName, language)
					else
						local themeName = getLocalizedName(childPath, language)
						local attrs = fs.attributes(childPath)
						if attrs.mode == "directory" then
							failure = failure or not self:scanPluginThemeDirectory(childPath, type, typeExt, categoryName, themeName, language)
						end
					end
				else
					log.df("Obsolete %s plugin: %s", type, pluginName)
				end
			end
		end
	end
	
	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginThemeDirectory(path, type, typeExt, categoryName, themeName, language) -> boolean
-- Method
-- Scans a folder as a plugin theme folder. The contents will be plugin folders.
--
-- Parameters:
--  * `path`			- The path to the plugin type directory
--  * `type`			- The plugin type
--  * `typeExt`			- The plugin file extension for the type.
--  * `categoryName`	- The plugin category name, in the target language.
--  * `themeName`		- The plugin theme name, in the target language.
--  * `language`		- The language to scan with.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginThemeDirectory(path, type, typeExt, categoryName, themeName, language)
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local pluginPath = path .. "/" .. file
			if fs.attributes(pluginPath).mode == "directory" then
				local pluginName, pluginThemeName, obsolete = getPluginName(pluginPath, typeExt, language)
				if pluginName and not obsolete then
					themeName = pluginThemeName or themeName
					self:registerPlugin(pluginPath, type, categoryName, themeName, pluginName, language)
				else
					log.df("Obsolete %s plugin: %s", type, pluginName)
				end
			end
		end
	end
	return true
end

--- cp.apple.finalcutpro.plugins:registerPlugin(path, type, categoryName, themeName, pluginName, langauge) -> plugin
--- Method
--- Registers a plugin with the specified details.
---
--- Parameters:
---  * `path`			- The path to the plugin directory.
---  * `type`			- The type of plugin
---  * `categoryName`	- The category name, in the specified language.
---  * `themeName`		- The theme name, in the specified langauge. May be `nil` if not in a theme.
---  * `pluginName`		- The plugin name, in the specified language.
---  * `language`		- The language code (e.g. "en", "fr", "de")
function mod.mt:registerPlugin(path, type, categoryName, themeName, pluginName, language)
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
	
	local types = lang[type]
	if not types then
		types = {}
		lang[type] = types
	end
	
	local plugin = {
		path = path,
		type = type,
		category = categoryName,
		theme = themeName,
		name = pluginName,
		language = language,
	}
	insert(types, plugin)
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
	local audioEffect = mod.types.audioEffect
	for _, path in pairs(self.effectBundlesPaths) do
		if tools.doesDirectoryExist(path) then
			for file in fs.dir(path) do
				--------------------------------------------------------------------------------
				-- Example: Alien.Voice.audio.effectBundle
				--------------------------------------------------------------------------------
				local name, category, type = string.match(file, "^([^%.]+)%.([^%.]+)%.([^%.]+)%.effectBundle$")
				if name and type == "audio" then
					local plugin = self:translateEffectBundle(name, language)
					self:registerPlugin(path .. "/" .. file, audioEffect, category, "Final Cut", plugin, language)
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
function mod.mt:scanSoundtrackProEDELEffects(language)
	local audioEffect = mod.types.audioEffect
	for category, plugins in pairs(mod.builtinSoundtrackProEDELEffects) do
		for _, plugin in ipairs(plugins) do
			self:registerPlugin(nil, audioEffect, "Logic", category, plugin, language)
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
			local newPrefsPath = self.internalEffectPreferencesPath .. languageCodes[language] .. ".lproj/Localizable.strings"
			local newPlistResult = plist.fileToTable(newPrefsPath)
			for key, string in pairs(plistResult) do
				if string == input then
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
		local newPrefsPath = self.internalEffectFlexoPath .. language .. ".lproj/FFLocalizable.strings"
		local newPlistResult = plist.fileToTable(newPrefsPath)
		for key, string in pairs(plistResult) do
			if string == input then
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
function mod.mt:compareOldMethodToNewMethodResults(language)

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
		["AudioEffects"] = mod.types.audioEffect,
		["VideoEffects"] = mod.types.videoEffect,
		["Transitions"] = mod.types.transition,
		["Generators"] = mod.types.generator,
		["Titles"] = mod.types.title,
	}

	--------------------------------------------------------------------------------
	-- Begin Scan:
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	-- Debug Message:
	--------------------------------------------------------------------------------
	log.df("---------------------------------------------------------")
	log.df(" CHECKING LANGUAGE: %s", language)
	log.df("---------------------------------------------------------")
	
	for oldType,newType in pairs(pluginTypes) do
		--------------------------------------------------------------------------------
		-- Get settings from GUI Scripting Results:
		--------------------------------------------------------------------------------
		local oldPlugins = config.get(language .. ".all" .. oldType)

		if oldPlugins then

			--------------------------------------------------------------------------------
			-- Debug Message:
			--------------------------------------------------------------------------------
			log.df(" - Checking Plugin Type: %s", oldType)

			local newPlugins = self._plugins[language][newType]
			local newPluginNames = {}
			if newPlugins then
				for _,plugin in ipairs(newPlugins) do
					local name = plugin.name
					newPluginNames[name] = plugin
				end
			end
			
			--------------------------------------------------------------------------------
			-- Compare Results:
			--------------------------------------------------------------------------------
			local errorCount = 0
			for _, oldFullName in pairs(oldPlugins) do
				local oldCategory, oldName = string.match(oldFullName, "^(.-) %- (.+)$")
				oldName = oldName or oldFullName
				if not newPluginNames[oldName] and not newPluginNames[oldFullName] then
					log.df("  - ERROR: Missing %s: %s", oldType, oldFullName)
					errorCount = errorCount + 1
				else
					newPluginNames[oldName] = nil
				end
			end
			
			for newName, plugin in pairs(newPluginNames) do
				log.df("  - ERROR: Unmatched %s: %s (%s)", newType, newName, plugin.path)
				errorCount = errorCount + 1
			end
			
			--------------------------------------------------------------------------------
			-- If all results matched:
			--------------------------------------------------------------------------------
			if errorCount == 0 then
				log.df("  - SUCCESS: %s all matched!\n", oldType)
			else
				log.df("")
			end
		else
			log.df(" - SKIPPING: Could not find settings for: %s (%s)", oldType, language)
		end
	end
	log.df("")
	log.df("---------------------------------------------------------")
	log.df(" DEBUGGING:")
	log.df("---------------------------------------------------------")
	log.df(" - Scan Results saved to global table: debugScanPlugin")
	debugScanPlugin = self._plugins
end

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
			"~/Library/Application Support/ProApps/Effects Presets",
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

bench("scan:setup", function()
	--------------------------------------------------------------------------------
	-- Add Supported Languages, Plugin Types & Built-in Effects to Results Table:
	--------------------------------------------------------------------------------
	local videoEffect, transitionType = mod.types.videoEffect, mod.types.transition
	for pluginType, _ in pairs(mod.motionTemplates) do
		if pluginType == "Effects" then
			--------------------------------------------------------------------------------
			-- Add Built-in Effects:
			--------------------------------------------------------------------------------
			for category, effects in pairs(mod.builtinEffects) do
				for _, effect in pairs(effects) do
					self:registerPlugin(nil, videoEffect, category, nil, self:translateInternalEffect(effect, language), language)
				end
			end
		elseif pluginType == "Transitions" then
			--------------------------------------------------------------------------------
			-- Add Built-in Transitions:
			--------------------------------------------------------------------------------
			for category, transitions in pairs(mod.builtinTransitions) do
				for _, transition in pairs(transitions) do
					self:registerPlugin(nil, transitionType, category, nil, self:translateInternalEffect(transition, language), language)
				end
			end
		end
	end
 end) --bench

-- 	--------------------------------------------------------------------------------
-- 	-- Scan Audio Units:
-- 	--------------------------------------------------------------------------------
bench("scan:audioUnits", function()
	self:scanAudioUnits(language)
end) --bench
--
-- 	--------------------------------------------------------------------------------
-- 	-- Scan Soundtrack Pro EDEL Effects:
-- 	--------------------------------------------------------------------------------
bench("scan:edelEffects", function()
	self:scanSoundtrackProEDELEffects(language)
end) --bench
--
-- 	--------------------------------------------------------------------------------
-- 	-- Scan Effect Bundles:
-- 	--------------------------------------------------------------------------------
bench("scan:audioEffectBundles", function()
	self:scanAudioEffectBundles(language)
end) --bench
--
-- 	--------------------------------------------------------------------------------
-- 	-- Scan Effect Presets:
-- 	--------------------------------------------------------------------------------
bench("scan:effectPresets", function()
	self:scanEffectsPresets(language)
end) --bench

	--------------------------------------------------------------------------------
	-- Scan Plugins:
	--------------------------------------------------------------------------------
bench("scan:plugins", function()
	self:scanPlugins(language)
end) --bench

-- 	--------------------------------------------------------------------------------
-- 	-- Test to compare these scans to previous GUI Scripted scans:
-- 	--------------------------------------------------------------------------------
bench("scan:compare", function()
	self:compareOldMethodToNewMethodResults(language)
end) --bench

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