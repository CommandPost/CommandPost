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
--- require("cp.apple.finalcutpro"):plugins():scan("en")


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

local archiver									= require("cp.plist.archiver")
local config									= require("cp.config")
local plist										= require("cp.plist")
local tools										= require("cp.tools")
local protect									= require("cp.protect")

local text										= require("cp.web.text")
local localized									= require("cp.localized")
local strings									= require("cp.strings")

--------------------------------------------------------------------------------
--
-- HELPER FUNCTIONS:
--
--------------------------------------------------------------------------------

local unescapeXML				= text.unescapeXML
local isBinaryPlist				= plist.isBinaryPlist
local getLocalizedName			= localized.getLocalizedName
local insert, remove			= table.insert, table.remove
local contains					= fnutils.contains

-- string:split(delimiter) -> table
-- Function
-- Splits a string into a table, separated by a separator pattern.
--
-- Parameters:
--  * delimiter - Separator pattern
--
-- Returns:
--  * table
function string:split(delimiter)
   local list = {}
   local pos = 1
   if string.find("", delimiter, 1) then -- this would result in endless loops
      error("delimiter matches empty string: %s", delimiter)
   end
   while true do
      local first, last = self:find(delimiter, pos)
      if first then -- found?
         insert(list, self:sub(pos, first-1))
         pos = last+1
      else
         insert(list, self:sub(pos))
         break
      end
   end
   return list
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

-- scanUserEffectsPresets(language) -> none
-- Function
-- Scans Final Cut Pro Effects Presets
--
-- Parameters:
--  * `language`	- The language to scan for.
--
-- Returns:
--  * None
function mod.mt:scanUserEffectsPresets(language)
	local videoEffect, audioEffect = mod.types.videoEffect, mod.types.audioEffect

	for _, path in ipairs(self.userEffectPresetPaths) do
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
		while theme == nil or flags == nil do
			local line = file:read("*l")
			if line == nil then break end

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

		-- unescape the theme text
		theme = theme and unescapeXML(theme) or nil

		-- convert flags to a number for checking
		flags = flags and tonumber(flags) or 0
		local isObsolete = (flags & OBSOLETE_FLAG) == OBSOLETE_FLAG
		return theme, isObsolete
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
		local targetExt = "."..pluginExt
		for file in fs.dir(path) do
			if endsWith(file, targetExt) then
				local name = file:sub(1, (targetExt:len()+1)*-1)
				pluginPath = path .. "/" .. name .. targetExt
				if name == realName then
					name = localName
				end
				return name, getMotionTheme(pluginPath)
			end
		end
	end
	return nil
end

mod._getPluginName = getPluginName

-- cp.apple.finalcutpro.plugins:scanPluginsDirectory(language, path, filter) -> boolean
-- Method
-- Scans a root plugins directory. Plugins directories have a standard structure which comes in two flavours:
--
-- 1. <type>/<plugin name>/<plugin name>.<ext>
-- 2. <type>/<group>/<plugin name>/<plugin name>.<ext>
-- 3. <type>/<group>/<theme>/<plugin name>/<plugin name>.<ext>
--
-- This is somewhat complicated by 'localization', wherein each of the folder levels may have a `.localized` extension. If this is the case, it will contain a subfolder called `.localized`, which in turn contains files which describe the local name for the folder in any number of languages.
--
-- This function will drill down through the contents of the specified `path`, assuming the above structure, and then register any contained plugins in the `language` provided. Other languages are ignored, other than some use of English when checking for specific effect types (Effect, Generator, etc.).
--
-- Parameters:
--  * `language`	- The language code to scan for (e.g. "en" or "fr").
--  * `path`		- The path of the root plugin directory to scan.
--  * `checkFn`		- A function which will receive the path being scanned and return `true` if it should be scanned.
--
-- Returns:
--  * `true` if the plugin directory was successfully scanned.
function mod.mt:scanPluginsDirectory(language, path, checkFn)
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
				local plugin = {
					type = mt.type,
					extension = mt.extension,
					check = checkFn or function() return true end,
				}
				failure = failure or not self:scanPluginTypeDirectory(language, typePath, plugin)
			end
		end
	end

	return not failure
end

function mod.mt:handlePluginDirectory(language, path, plugin)
	local pluginName, themeName, obsolete = getPluginName(path, plugin.extension, language)
	if pluginName then
		plugin.name = pluginName
		plugin.themeLocal = plugin.themeLocal or themeName
		-- only register it if not obsolete and if the check function passes (if present)
		if not obsolete and plugin:check() then
			self:registerPlugin(
				path,
				plugin.type,
				plugin.categoryLocal,
				plugin.themeLocal,
				plugin.name,
				language
			)
		end
		-- return true if it's a legit plugin directory, even if we didn't register it.
		return true
	end
	-- return false if it's not a plugin directory.
	return false
end

-- cp.apple.finalcutpro.plugins:scanPluginTypeDirectory(language, path, plugin) -> boolean
-- Method
-- Scans a folder as a plugin type folder, such as 'Effects', 'Transitions', etc. The contents will be folders that are 'groups' of plugins, containing related plugins.
--
-- Parameters:
--  * `language`	- The language to scan with.
--  * `path`		- The path to the plugin type directory.
--  * `plugin`		- A table containing the plugin details collected so far.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginTypeDirectory(language, path, plugin)
	local failure = false

	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local childPath = path .. "/" .. file
			local attrs = fs.attributes(childPath)
			if attrs and attrs.mode == "directory" then
				if not self:handlePluginDirectory(language, childPath, plugin) then
					plugin.categoryLocal, plugin.categoryReal = getLocalizedName(childPath, language)
					failure = failure or not self:scanPluginCategoryDirectory(language, childPath, plugin)
				end
			end
		end
	end

	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginCategoryDirectory(language, path, plugin) -> boolean
-- Method
-- Scans a folder as a plugin category folder. The contents will be folders that are either theme folders or actual plugins.
--
-- Parameters:
--  * `language`		- The language to scan with.
--  * `path`			- The path to the plugin type directory
--  * `plugin`		- A table containing the plugin details collected so far.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginCategoryDirectory(language, path, plugin)
	local failure = false

	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local childPath = path .. "/" .. file
			local attrs = fs.attributes(childPath)
			if attrs and attrs.mode == "directory" then
				if not self:handlePluginDirectory(language, childPath, plugin) then
					plugin.themeLocal, plugin.themeReal = getLocalizedName(childPath, language)
					failure = failure or not self:scanPluginThemeDirectory(language, childPath, plugin)
				end
			end
		end
	end

	return not failure
end

-- cp.apple.finalcutpro.plugins:scanPluginThemeDirectory(language, path, plugin) -> boolean
-- Method
-- Scans a folder as a plugin theme folder. The contents will be plugin folders.
--
-- Parameters:
--  * `language`		- The language to scan with.
--  * `path`			- The path to the plugin type directory
--  * `plugin`			- A table containing the plugin details collected so far.
--
-- Returns:
-- * `true` if the folder was scanned successfully.
function mod.mt:scanPluginThemeDirectory(language, path, plugin)
	for file in fs.dir(path) do
		if file:sub(1,1) ~= "." then
			local pluginPath = path .. "/" .. file
			if fs.attributes(pluginPath).mode == "directory" then
				self:handlePluginDirectory(language, pluginPath, plugin)
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

function mod.mt:effectBundleStrings()
	local source = self._effectBundleStrings
	if not source then
		source = strings.new():fromPlist(self:app():getPath() .. "/Contents/Frameworks/Flexo.framework/Resources/${language}.lproj/FFEffectBundleLocalizable.strings")
		self._effectBundleStrings = source
	end
	return source
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
--  * The translated value for `input` in the specified language, if present.
function mod.mt:translateEffectBundle(input, language)
	return self:effectBundleStrings():find(language, input) or input
end

-- scanAudioEffectBundles() -> none
-- Function
-- Scans the Audio Effect Bundles directories.
--
-- Parameters:
--  * directoryPath - Directory to scan
--
-- Returns:
--  * None
function mod.mt:scanAudioEffectBundles(language)
	local audioEffect = mod.types.audioEffect
	for _, path in pairs(self.appEffectBundlesPaths) do
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

-- cp.apple.finalcutpro.plugins:scanAppPlugins(language) -> none
-- Function
-- Scans for app-provided Final Cut Pro Plugins.
--
-- Parameters:
--  * `language`	- The language to scan for.
--
-- Returns:
--  * None
function mod.mt:scanAppPlugins(language)
	local fcpPath = self:app():getPath()
	self:scanPluginsDirectory(language, fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized")
	self:scanPluginsDirectory(
		language,
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized",
		-- we filter out the 'Simple' category here, since it contains unlisted iMovie titles.
		function(plugin) return plugin.categoryReal ~= "Simple" end
	)
end

-- cp.apple.finalcutpro.plugins:scanUserPlugins(language) -> none
-- Function
-- Scans for user-provided Final Cut Pro Plugins.
--
-- Parameters:
--  * `language`	- The language to scan for.
--
-- Returns:
--  * None
function mod.mt:scanUserPlugins(language)
	for _, path in pairs(self.userPluginPaths) do
		self:scanPluginsDirectory(language, path)
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
	for category, plugins in pairs(mod.appEdelEffects) do
		for _, plugin in ipairs(plugins) do
			self:registerPlugin(nil, audioEffect, "Logic", category, plugin, language)
		end
	end

	--------------------------------------------------------------------------------
	-- NOTE: I haven't worked out a way to programatically work out the category
	-- yet, so aborted this method:
	--------------------------------------------------------------------------------
	--[[
 	for _, path in pairs(mod.appEdelEffectPaths) do
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

function mod.mt:effectStrings()
	local source = self._effectStrings
	if not source then
		source = strings.new()
		local fcpPath = self:app():getPath()
		source:fromPlist(fcpPath .. "/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/${language}.lproj/Localizable.strings")
		source:fromPlist(fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/${language}.lproj/FFLocalizable.strings")
		self._effectStrings = source
	end
	return source
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
	return self:effectStrings():find(language, input) or input
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
					local plugins = newPluginNames[name]
					local unmatched = nil
					if not plugins then
						plugins = {
							matched = {},
							unmatched = {},
							partials = {},
						}
						newPluginNames[name] = plugins
					end
					insert(plugins.unmatched, plugin)
				end
			end

			--------------------------------------------------------------------------------
			-- Compare Results:
			--------------------------------------------------------------------------------
			local errorCount = 0
			for _, oldFullName in pairs(oldPlugins) do
				local oldTheme, oldName = string.match(oldFullName, "^(.-) %- (.+)$")
				oldName = oldName or oldFullName
				local newPlugins = newPluginNames[oldFullName] or newPluginNames[oldName]
				if not newPlugins then
					log.df("  - ERROR: Missing %s: %s", oldType, oldFullName)
					errorCount = errorCount + 1
				else
					local unmatched = newPlugins.unmatched
					local found = false
					for i,plugin in ipairs(unmatched) do
						-- log.df("  - INFO:  Checking plugin: %s (%s)", plugin.name, plugin.theme)
						if plugin.theme == oldTheme then
							-- log.df("  - INFO:  Exact match for plugin: %s (%s)", oldName, oldTheme)
							insert(newPlugins.matched, plugin)
							remove(unmatched, i)
							found = true
							break
						end
					end
					if not found then
						-- log.df("  - INFO:  Partial for '%s' plugin.", oldFullName)
						insert(newPlugins.partials, oldFullName)
					end
				end
			end

			for newName, plugins in pairs(newPluginNames) do
				if #plugins.partials ~= #plugins.unmatched then
					for _,oldFullName in ipairs(plugins.partials) do
						log.df("  - ERROR: Old %s plugin unmatched: %s", newType, oldFullName)
						errorCount = errorCount + 1
					end

					for _,plugin in ipairs(plugins.unmatched) do
						local newFullName = plugin.name
						if plugin.theme then
							newFullName = plugin.theme .." - "..newFullName
						end
						log.df("  - ERROR: New %s plugin unmatched: %s\n\t\t%s", newType, newFullName, plugin.path)
						errorCount = errorCount + 1
					end
				end
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


mod.builtInPlugins = {
	--------------------------------------------------------------------------------
	-- Built-in Effects:
	--------------------------------------------------------------------------------
	[mod.types.videoEffect] = {
		["FFEffectCategoryColor"]	= { "FFCorrectorEffectName" },
		["FFMaskEffect"]			= { "FFSplineMaskEffect", "FFShapeMaskEffect" },
		["Stylize"] 				= { "DropShadow::Filter Name" },
		["FFEffectCategoryKeying"]	= { "Keyer::Filter Name", "LumaKeyer::Filter Name" }
	},

	--------------------------------------------------------------------------------
	-- Built-in Transitions:
	--------------------------------------------------------------------------------
	[mod.types.transition] = {
		["Transitions::Dissolves"] = { "CrossDissolve::Filter Name", "DipToColorDissolve::Transition Name", "FFTransition_OpticalFlow" },
		["Movements"] = { "SpinSlide::Transition Name", "Swap::Transition Name", "RippleTransition::Transition Name", "Mosaic::Transition Name", "PageCurl::Transition Name", "PuzzleSlide::Transition Name", "Slide::Transition Name" },
		["Objects"] = { "Cube::Transition Name", "StarIris::Transition Name", "Doorway::Transition Name" },
		["Wipes"] = { "BandWipe::Transition Name", "CenterWipe::Transition Name", "CheckerWipe::Transition Name", "ChevronWipe::Transition Name", "OvalIris::Transition Name", "ClockWipe::Transition Name", "GradientImageWipe::Transition Name", "Inset Wipe::Transition Name", "X-Wipe::Transition Name", "EdgeWipe::Transition Name" },
		["Blurs"] = { "CrossZoom::Transition Name", "CrossBlur::Transition Name" },
	},
}


--------------------------------------------------------------------------------
-- Built-in Soundtrack Pro EDEL Effects:
--------------------------------------------------------------------------------
mod.appEdelEffects = {
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
		self.userPluginPaths = {
			"~/Movies/Motion Templates.localized",
			"/Library/Application Support/Final Cut Pro/Templates.localized",
		}

		self.appPluginPaths = {
			fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized",
			fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized",
		}

		--------------------------------------------------------------------------------
		-- Define Effect Bundles Paths:
		--------------------------------------------------------------------------------
		self.appEffectBundlesPaths = {
			fcpPath .. "/Contents/Frameworks/Flexo.framework/Resources/Effect Bundles",
		}

		--------------------------------------------------------------------------------
		-- Define Effect Presets Paths:
		--------------------------------------------------------------------------------
		self.userEffectPresetPaths = {
			"~/Library/Application Support/ProApps/Effects Presets",
		}

		--------------------------------------------------------------------------------
		-- Define Soundtrack Pro EDEL Effects Paths:
		--------------------------------------------------------------------------------
		self.appEdelEffectPaths = {
			fcpPath .. "/Contents/Frameworks/Flexo.framework/PlugIns/Audio/EDEL.bundle/Contents/Resources/Plug-In Settings"
		}
	end) --bench

	return self
end

function mod.mt:plugins()
	if not self._plugins then
		self:scan()
	end
	return self._plugins
end

function mod.mt:scanAppBuiltInPlugins(language)
	--------------------------------------------------------------------------------
	-- Add Supported Languages, Plugin Types & Built-in Effects to Results Table:
	--------------------------------------------------------------------------------
	local videoEffect, transitionType = mod.types.videoEffect, mod.types.transition

	for pluginType,categories in pairs(mod.builtInPlugins) do
		for category,plugins in pairs(categories) do
			category = self:translateInternalEffect(category, language)
			for _,plugin in pairs(plugins) do
				self:registerPlugin(nil, pluginType, category, nil, self:translateInternalEffect(plugin, language), language)
			end
		end
	end
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
function mod.mt:scan(language)
	--------------------------------------------------------------------------------
	-- Reset Results Table:
	--------------------------------------------------------------------------------
	self._plugins = {}

	language = language or self:getCurrentLanguage()
	log.df("scan: language = '%s'", language)

bench("scan:setup", function()
	self:scanAppBuiltInPlugins(language)
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


	--------------------------------------------------------------------------------
	-- Scan App Plugins:
	--------------------------------------------------------------------------------
bench("scan:appPlugins", function()
	self:scanAppPlugins(language)
end) --bench

-- 	--------------------------------------------------------------------------------
-- 	-- Scan User Effect Presets:
-- 	--------------------------------------------------------------------------------
bench("scan:effectPresets", function()
	self:scanUserEffectsPresets(language)
end) --bench

	--------------------------------------------------------------------------------
	-- Scan User Plugins:
	--------------------------------------------------------------------------------
bench("scan:userPlugins", function()
	self:scanUserPlugins(language)
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