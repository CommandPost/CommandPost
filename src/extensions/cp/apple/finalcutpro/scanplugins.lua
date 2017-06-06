--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.scanplugins ===
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

--------------------------------------------------------------------------------
--
-- HELPER FUNCTIONS:
--
--------------------------------------------------------------------------------

local escapeXML, unescapeXML	= text.escapeXML, text.unescapeXML
local isBinaryPlist				= plist.isBinaryPlist
local getLocalizedName			= localized.getLocalizedName

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

-- linesFrom(file) -> table
-- Function
-- Returns all the individual lines from a file as a table
--
-- Parameters:
--  * file - Path to the file
--
-- Returns:
--  * Table
local function linesFrom(file)
	if not tools.doesFileExist(file) then return {} end
	file = fs.pathToAbsolute(file)
	lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

-- fixDashes(input) -> string
-- Function
-- Replaces columns with dashes
--
-- Parameters:
--  * input - The string you want to process
--
-- Returns:
--  * The string with columns replaced with dashes
local function fixDashes(input)
	return string.gsub(input, ":", "/")
end


-- readLocalizedFile(currentLanguageFile) -> string or nil
-- Function
-- Reads a .localized file
--
-- Parameters:
--  * currentLanguageFile - Path to the current language file.
--
-- Returns:
--  * The translated file name or `nil`
local function readLocalizedFile(folder, currentLanguageFile)

	if tools.doesFileExist(currentLanguageFile) then
		--------------------------------------------------------------------------------
		-- Binary Plist:
		--------------------------------------------------------------------------------
		if isBinaryPlist(currentLanguageFile) then
			local plistValues = plist.fileToTable(currentLanguageFile)

			if plistValues then
				local folderCode = folder
				if string.sub(folder, -10) == ".localized" then
					folderCode = string.sub(folder, 1, -11)
				end

				--------------------------------------------------------------------------------
				-- Escape folderCode:
				--------------------------------------------------------------------------------
				folderCode = escapeXML(folderCode)

				--------------------------------------------------------------------------------
				-- Unescape Result:
				--------------------------------------------------------------------------------
				if plistValues[folderCode] then
					return unescapeXML(plistValues[folderCode])
				end
			end
		--------------------------------------------------------------------------------
		--
		-- Plain Text:
		--
		-- Example:
		-- "03EF6CA6-E3E2-4DA0-B68F-26B2762A46BC" = "Perspective Reflection";
		--
		--------------------------------------------------------------------------------
		else
			local values = {}
			local data = linesFrom(currentLanguageFile)
			if next(data) ~= nil then
				for i, v in ipairs(data) do
					local unescape = string.gsub(v, [[\"]], "@!@")
					if unescape then
						local key, value = string.match(unescape, '%"([^%"]+)%"[^%"]+%"([^%"]+)%"')
						if key and value then
							values[key] = string.gsub(value, "@!@", '"')
						end
					end
				end
				if string.sub(folder, -10) == ".localized" then
					folder = string.sub(folder, 1, -11)
				end
				if values[folder] then
					return values[folder]
				end
			end
		end
	end
	return nil
end

-- getLocalizedFolderName(path, folder) -> string
-- Function
-- Gets the localised folder name
--
-- Parameters:
--  * path - Path to the file
--  * folder - Folder name
--
-- Returns:
--  * Localised folder name as a string
--
-- Notes:
--  * getLocalizedFolderName("/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/Transitions.localized/Stylized.localized", "Sports.localized", "de")
--  * getLocalizedFolderName("/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Distortion.localized", "Crop & Feather.localized", "de")
local function getLocalizedFolderName(path, folder, languageCode)
	local localizedFolder = path .. "/" .. folder .. "/.localized"
	
-- return bench(string.format("localizedFolderName: %s : %s", folder, languageCode), function()
	local localizedFolderExists = tools.doesDirectoryExist(localizedFolder)
	if localizedFolderExists then
		--------------------------------------------------------------------------------
		-- Try languageCode first:
		--------------------------------------------------------------------------------
		local currentLanguageFile = localizedFolder .. "/" .. languageCode .. ".strings"
		local result = readLocalizedFile(folder, currentLanguageFile)
		if result then
			return fixDashes(result)
		end
		--------------------------------------------------------------------------------
		-- If that fails try English:
		--------------------------------------------------------------------------------
		local currentLanguageFile = localizedFolder .. "/en.strings"
		local result = readLocalizedFile(folder, currentLanguageFile)
		if result then
			return fixDashes(result)
		end
	end
	if string.sub(folder, -10) == ".localized" then
		return fixDashes(string.sub(folder, 1, -11))
	else
		return fixDashes(folder)
	end
-- end) --bench
end

-- getLocalizedFileName(path, folder) -> string
-- Function
-- Gets the localised file name
--
-- Parameters:
--  * path - Path to the file
--  * file - File name
--
-- Returns:
--  * Localised file name as a string
--
-- Notes:
--  * getLocalizedFileName("/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/Transitions.localized/Stylized.localized/Sports.localized/Diagonal Slide.localized", "Diagonal Slide.motr", "de")
--  * getLocalizedFileName("/Applications/Final Cut Pro.app/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized/Effects.localized/Distortion.localized/Crop & Feather.localized", "Crop & Feather.moef", "de")
local function getLocalizedFileName(path, file, languageCode)

	local fileWithoutExtension = string.match(file, "(.+)%..+")

	local localizedFolder = path .. "/.localized"
	local localizedFolderExists = tools.doesDirectoryExist(localizedFolder)

	if localizedFolderExists then

		--------------------------------------------------------------------------------
		-- Try languageCode first:
		--------------------------------------------------------------------------------
		local currentLanguageFile = localizedFolder .. "/" .. languageCode .. ".strings"
		local result = readLocalizedFile(fileWithoutExtension, currentLanguageFile)
		if result then
			return fixDashes(result)
		end

		--------------------------------------------------------------------------------
		-- If that fails try English:
		--------------------------------------------------------------------------------
		local currentLanguageFile = localizedFolder .. "/en.strings"
		local result = readLocalizedFile(fileWithoutExtension, currentLanguageFile)
		if result then
			return fixDashes(result)
		end
	end

	return fixDashes(fileWithoutExtension)

end

local aliases = {
	de	= "German",
	en	= "English",
	es	= "Spanish",
	fr	= "French",
	it	= "Italian",
	ja	= "Japanese",
}

-- readLocalizedFile(currentLanguageFile) -> string or nil
-- Function
-- Reads a .localized file
--
-- Parameters:
--  * currentLanguageFile - Path to the current language file.
--
-- Returns:
--  * The translated file name or `nil`
local function readLocalizedStrings(stringsFile, name)
	local stringsPath = fs.pathToAbsolute(stringsFile)
	if stringsPath then
		--------------------------------------------------------------------------------
		-- Binary Plist:
		--------------------------------------------------------------------------------
		if isBinaryPlist(stringsFile) then
			local plistValues = plist.binaryFileToTable(stringsFile)

			if plistValues then
				--------------------------------------------------------------------------------
				-- Escape folderCode:
				--------------------------------------------------------------------------------
				local localName = plistValues[escapeXML(name)]
				return localName and unescapeXML(localName)
			end
		--------------------------------------------------------------------------------
		--
		-- Plain Text:
		--
		-- Example:
		-- "03EF6CA6-E3E2-4DA0-B68F-26B2762A46BC" = "Perspective Reflection";
		--
		--------------------------------------------------------------------------------
		else
			local values = {}
			local data = linesFrom(currentLanguageFile)
			for i, v in ipairs(data) do
				local key, value = string.match(unescape, '^%"(.+)%"%s*%=%s*%"(.+)%";$')
				if key and value then
					-- unescape the key.
					key = key:gsub('%\\(.)', '%1')
					if key == name then
						-- unescape the value.
						return value:gsub('%\\(.)', '%1')
					end
				end
			end
		end
	end
	return nil
end

local function readLocalizedName(path, name, language)
	local localizedPath = path .. "/.localized/"
	local localized = readLocalizedStrings(localizedPath .. language .. ".strings", name)
	if not localized then
		local alias = aliases[language]
		if alias then
			localized = readLocalizedStrings(localizedPath .. alias .. ".strings", name)
		end
		if not localized and name ~= "en" then
			localized = readLocalizedName(path, name, "en")
		end
	end
	return localized or name
end

local function getLocalizedName(path, language)
	local file = path:match("^.-([^/%.]+)%.localized$")
	if file then -- it's localized
		return readLocalizedName(path, file, language)
	else
		return path:match("^.-([^/%.]+)$")
	end
end

--------------------------------------------------------------------------------
--
-- KIND:
--
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.plugins.kind ===
---
--- Represents a kind of plugin, such as `Effect`, `Transition`. `Generator`, or `Title`.

local kind = {}
kind.mt = {}
kind.mt.__index = kind.mt

function kind.new(app, titleKey)
	local o = {
		_app 		= app,
		_titleKey	= titleKey,
		_categories	= {},
	}
	return setmetatable(o, kind.mt)
end

function kind.mt:app()
	return self._app
end

function kind.mt:title(language)
	-- TODO: look up the title based on the key
	-- language = language or self:app():getCurrentLanguage()
	return self._titleKey
end

function kind.mt:addCategory(category)
	table.insert(self._categories, category)
	return self
end

function kind.mt:categories()
	return self._categories
end

--------------------------------------------------------------------------------
--
-- CATEGORY:
--
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.plugins.category ===
---
--- Represents a category of plugins.

local category = {}
category.mt = {}
category.mt.__index = category.mt

function category.new(kind, path)
	local o = {
		_kind		= kind,
		_path		= path,
		_plugins	= {},
		_themes		= {},
	}
	return setmetatable(o, category.mt)
end

function category.mt:app()
	return self:kind():app()
end

function category.mt:kind()
	return self._kind
end

function category.mt:title(language)
	language = language or self:app():getCurrentLanguage()
	local title = self[language]
	if not title then
		title = getLocalizedName(self._path, language)
		self[language] = title
	end
	return title
end

function category.mt:addPlugin(plugin)
	table.insert(self._plugins, plugin)
	return self
end

function category.mt:plugins()
	return self._plugins
end

--------------------------------------------------------------------------------
--
-- THEME:
--
--------------------------------------------------------------------------------

local theme = {}
theme.mt = {}
theme.mt.__index = theme.mt

function theme.new(app, path)
	local o = {
		_app 		= app,
		_path		= path,
		_plugins	= {},
	}
	return setmetatable(o, theme.mt)
end

--------------------------------------------------------------------------------
--
-- PLUGIN:
--
--------------------------------------------------------------------------------

local plugin = {}
plugin.mt = {}
plugin.mt.__index = plugin.mt

function plugin.new(app, path, type, category, theme)
	local o = {
		_app 		= app,
		_pluginPath = pluginPath,
		_type		= type,
		_category	= category,
		_theme		= theme,
	}
	return setmetatable(o, plugin.mt)
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
						table.insert(scan["AudioEffects"]["OS X"][category], plugin)
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
									table.insert(scan["Effects"][category], plugin)
								end
							end
						end
					end
				end
			end
		end
	end
end

-- isPluginExtension(path) -> boolean
-- Function
-- Does the path have a Plugin File Extension?
--
-- Parameters:
--  * path - Path to the plugin
--
-- Returns:
--  * Boolean
local function isPluginExtension(path)
	local pluginTypes = mod.pluginTypes
	for _, extensions in pairs(mod.pluginTypes) do
		for _, extension in pairs(extensions) do
			if path:sub(extension:len() * -1) == extension then
				return true
			end
		end
	end
	return false
end

-- combinePath(pathTable, number) -> string
-- Function
-- Does the path have a Plugin File Extension?
--
-- Parameters:
--  * pathTable - A table containing all the components of a path
--  * number - How many components you want to combine
--
-- Returns:
--  * A string
local function combinePath(pathTable, number)
	local path = "/" .. pathTable[1]
	for i=2,number do
		path = path .. "/" .. pathTable[i]
	end
	return path
end

local function fileToString(file)
    local f = io.open(file, "r")
    local content = f:read("*all")
    f:close()
    return content
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

--- cp.apple.finalcutpro.scanplugins:processPlugin(path, file) -> boolean
--- Method
--- Process a plugin so that it's added to the current scan
---
--- Parameters:
---  * path - Path to the plugin
---  * file - Filename of the plugin
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.mt:processPlugin(path, file)

	local fullPath = path .. "/" .. file
	local pathComponents = fullPath:split("/")
	local pathCount = #pathComponents

	for pluginType,_ in pairs(mod.pluginTypes) do
		local pathType = pathComponents[pathCount - 4]
		if pathType == pluginType or pathType == pluginType .. ".localized" then

			--------------------------------------------------------------------------------
			-- Get Motion Theme if available:
			--------------------------------------------------------------------------------
			local motionTheme = mod.getMotionTheme(fullPath)

			--------------------------------------------------------------------------------
			-- Has Subcategory:
			--------------------------------------------------------------------------------
			for _, currentLanguage in pairs(self:getSupportedLanguages()) do

				local subcategory = motionTheme

				local category = getLocalizedFolderName(combinePath(pathComponents, pathCount - 4), pathComponents[pathCount - 3], currentLanguage)

				if not subcategory then
					--------------------------------------------------------------------------------
					-- There was no Motion Theme:
					--------------------------------------------------------------------------------
					subcategory = getLocalizedFolderName(combinePath(pathComponents, pathCount - 3), pathComponents[pathCount - 2], currentLanguage)
				else
					--------------------------------------------------------------------------------
					-- There was a Motion Theme but maybe it should be overridden:
					--------------------------------------------------------------------------------
					local localisedSubcategory = getLocalizedFolderName(combinePath(pathComponents, pathCount - 3), pathComponents[pathCount - 2], currentLanguage)
					local folderName = pathComponents[pathCount - 2]

					if string.sub(folderName, -10) == ".localized" then
						folderName = string.sub(folderName, 1, -11)
					end

					if folderName ~= localisedSubcategory then
						subcategory = localisedSubcategory
					end
				end

				local plugin = getLocalizedFileName(combinePath(pathComponents, pathCount - 1), pathComponents[pathCount], currentLanguage)
				local categoryList = self._plugins[currentLanguage][pluginType][category]
				if not categoryList then
					categoryList = {}
					self._plugins[currentLanguage][pluginType][category] = categoryList
				end

				if not categoryList[subcategory] then
					categoryList[subcategory] = {}
				end

				table.insert(categoryList[subcategory], plugin)
			end
			return true
		elseif pathComponents[pathCount - 3] == pluginType or pathComponents[pathCount - 3] == pluginType .. ".localized" then

			--------------------------------------------------------------------------------
			-- Get Motion Theme if available:
			--------------------------------------------------------------------------------
			local motionTheme = mod.getMotionTheme(fullPath)

			if motionTheme then

				--------------------------------------------------------------------------------
				-- Has a Motion Theme:
				--------------------------------------------------------------------------------
				for _, currentLanguage in pairs(self:getSupportedLanguages()) do

					local category = getLocalizedFolderName(combinePath(pathComponents, pathCount - 4), pathComponents[pathCount - 3], currentLanguage)
					local subcategory = motionTheme
					local plugin = getLocalizedFileName(combinePath(pathComponents, pathCount - 1), pathComponents[pathCount], currentLanguage)

					local pluginTypeList = self._plugins[currentLanguage][pluginType]
					local categoryList = pluginTypeList[category] or {}
					pluginTypeList[category] = categoryList

					categoryList[subcategory] = categoryList[subcategory] or {}
					
					table.insert(categoryList[subcategory], plugin)
				end
			else
				--------------------------------------------------------------------------------
				-- No Subcategory:
				--------------------------------------------------------------------------------
				for _, currentLanguage in pairs(self:getSupportedLanguages()) do

					local category = getLocalizedFolderName(combinePath(pathComponents, pathCount - 3), pathComponents[pathCount - 2], currentLanguage)
					local plugin = getLocalizedFileName(combinePath(pathComponents, pathCount - 1), pathComponents[pathCount], currentLanguage)

					local pluginTypeList = self._plugins[currentLanguage][pluginType]
					local categoryList = pluginTypeList[category] or {}
					pluginTypeList[category] = categoryList

					table.insert(categoryList, plugin)
				end
			end
			return true
		end
	end
	return false
end

-- cp.apple.finalcutpro.scanplugins:scanDirectory(directoryPath) -> boolean
-- Method
-- Scans a directory for plugins
--
-- Parameters:
--  * directoryPath - Directory to scan
--
-- Returns:
--  * `true` if successful otherwise `false`
function mod.mt:scanDirectory(directoryPath)

return bench("scanDirectory: "..directoryPath, function()
	--------------------------------------------------------------------------------
	-- Check that the directoryPath actually exists:
	--------------------------------------------------------------------------------
	local path = fs.pathToAbsolute(directoryPath)
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

	--------------------------------------------------------------------------------
	-- Scan directoryPath:
	--------------------------------------------------------------------------------
	local files = tools.dirFiles(path)
	local success = true
	for i,file in ipairs(files) do
		--------------------------------------------------------------------------------
		-- If it's not a hidden directory/file then:
		--------------------------------------------------------------------------------
		if file:sub(1,1) ~= "." then
			local filePath = path .. "/" .. file
			attrs = fs.attributes(filePath)
			if attrs.mode == "directory" then
				--------------------------------------------------------------------------------
				-- Scan Directory:
				--------------------------------------------------------------------------------
				success = self:scanDirectory(filePath) and success
			elseif isPluginExtension(file) then
				--------------------------------------------------------------------------------
				-- Process Plugin:
				--------------------------------------------------------------------------------
				self:processPlugin(path, file)
			end
		end
	end
	return success
end) --bench

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
local function translateEffectBundle(input, language)
	local prefsPath = mod.effectBundlesPreferencesPath .. language .. ".lproj/FFEffectBundleLocalizable.strings"
	local plistResult = plist.fileToTable(prefsPath)
	if plistResult then
		if plistResult[input] then
			return plistResult[input]
		else
			return input
		end
	end
end

-- scanEffectBundles() -> none
-- Function
-- Scans the Effect Bundles directories
--
-- Parameters:
--  * directoryPath - Directory to scan
--
-- Returns:
--  * None
local function scanEffectBundles()
	for _, path in pairs(mod.effectBundlesPaths) do
		if tools.doesDirectoryExist(path) then
			for file in fs.dir(path) do
				if string.sub(file, -13) == ".effectBundle" then
					local effectComponents = string.split(file, ".")
					--------------------------------------------------------------------------------
					-- Example: Alien.Voice.audio.effectBundle
					--------------------------------------------------------------------------------
					if effectComponents and effectComponents[3] and effectComponents[3] == "audio" then
						local category = effectComponents[2]

						for _, currentLanguage in pairs(mod.supportedLanguages) do

							local plugin = translateEffectBundle(effectComponents[1], currentLanguage)

							local scan = mod._plugins[currentLanguage]
							scan["AudioEffects"] = scan["AudioEffects"] or {}

							if not scan["AudioEffects"][category] then
								scan["AudioEffects"][category] = {}
							end

							table.insert(scan["AudioEffects"][category], plugin)
						end
					end
				end
			end
		end
	end
end

-- scanPlugins() -> none
-- Function
-- Scans for Final Cut Pro Plugins
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.mt:scanPlugins()
	for _, path in pairs(self.scanPaths) do
bench("scanPlugins:path: "..path, function()
		for pluginType, _ in pairs(mod.pluginTypes) do
bench("scanPlugins:type: "..pluginType, function()
			self:scanDirectory(string.gsub(path, "{type}", pluginType))
end) --bench
		end
end) --bench
	end
end

-- cp.apple.finalcutpro.scanplugins:scanSoundtrackProEDELEffects() -> none
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
			"~/Movies/Motion Templates.localized/{type}.localized",
			"/Library/Application Support/Final Cut Pro/Templates.localized/{type}.localized",
			fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized/{type}.localized",
			fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/{type}.localized",
		}

		--------------------------------------------------------------------------------
		-- Define Effect Bundles Paths:
		--------------------------------------------------------------------------------
		self.effectBundlesPaths = {
			fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/Effect Bundles",
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

--- cp.apple.finalcutpro.scanplugins:scan() -> none
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

bench("scan:setup", function()
	--------------------------------------------------------------------------------
	-- Add Supported Languages, Plugin Types & Built-in Effects to Results Table:
	--------------------------------------------------------------------------------
	for _, currentLanguage in pairs(mod.supportedLanguages) do
		local scan = {}
		mod._plugins[currentLanguage] = scan
		for pluginType, _ in pairs(mod.pluginTypes) do
			local pluginTypeList = {}
			scan[pluginType] = pluginTypeList
			
			if pluginType == "Effects" then
				--------------------------------------------------------------------------------
				-- Add Built-in Effects:
				--------------------------------------------------------------------------------
				for category, effects in pairs(mod.builtinEffects) do
					local categoryList = pluginTypeList[category] or {}
					pluginTypeList[category] = categoryList
					for _, effect in pairs(effects) do
						table.insert(categoryList, translateInternalEffect(effect, currentLanguage))
					end
				end
			elseif pluginType == "Transitions" then
				--------------------------------------------------------------------------------
				-- Add Built-in Transitions:
				--------------------------------------------------------------------------------
				for category, transitions in pairs(mod.builtinTransitions) do
					local categoryList = pluginTypeList[category] or {}
					pluginTypeList[category] = categoryList
					for _, transition in pairs(transitions) do
						table.insert(categoryList, translateInternalEffect(transition, currentLanguage))
					end
				end
			end
		end
	end
 end) --bench	

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
-- 	--------------------------------------------------------------------------------
-- 	-- Scan Effect Bundles:
-- 	--------------------------------------------------------------------------------
-- bench("scan:effectBundles", function()
-- 	self:scanEffectBundles()
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
bench("scan:plugins", function()
	self:scanPlugins()
end) --bench

-- 	--------------------------------------------------------------------------------
-- 	-- Test to compare these scans to previous GUI Scripted scans:
-- 	--------------------------------------------------------------------------------
-- bench("scan:compare", function()
-- 	compareOldMethodToNewMethodResults()
-- end) --bench

	return mod._plugins

end

function mod.new(fcp)
	local o = {
		_app = fcp,
		_plugins = {}
	}
	return setmetatable(o, mod.mt):init()
end

return mod