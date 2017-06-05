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

local fnutils									= require("hs.fnutils")
local fs 										= require("hs.fs")
local host										= require("hs.host")
local inspect									= require("hs.inspect")

local archiver									= require("cp.plist.archiver")
local config									= require("cp.config")
local plist										= require("cp.plist")
local tools										= require("cp.tools")

local slaxdom 									= require("slaxml.slaxdom")

--------------------------------------------------------------------------------
--
-- HELPER FUNCTIONS:
--
--------------------------------------------------------------------------------

local sbyte, schar = string.byte, string.char
local sfind, ssub, gsub = string.find, string.sub, string.gsub

local function sub_hex_ent(s)
	return schar(tonumber(s, 16))
end

local function sub_dec_ent(s)
	return schar(tonumber(s))
end

-- unescape(s) -> string
-- Function
-- Unescapes a string
--
-- Parameters:
--  * s - The string you want to unescape
--
-- Returns:
--  * String
local function unescape(s)
	s = gsub(s, "&lt;", "<")
	s = gsub(s, "&gt;", ">")
	s = gsub(s, "&apos;", "'")
	s = gsub(s, "&quot;", '"')
	s = gsub(s, "&#x(%x+);", sub_hex_ent)
	s = gsub(s, "&#(%d+);", sub_dec_ent)
	s = gsub(s, "&amp;", "&")
	return s
end

-- escape(s) -> string
-- Function
-- Escapes a string
--
-- Parameters:
--  * s - The string you want to escape
--
-- Returns:
--  * String
local function escape(s)
	s = gsub(s, "&", "&amp;")
	s = gsub(s, "<", "&lt;")
	s = gsub(s, ">", "&gt;")
	s = gsub(s, "'", "&apos;")
	s = gsub(s, '"', "&quot;")
	return s
end

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

-- isBinaryPlist(plistList) -> boolean
-- Function
-- Returns true if plistList is a binary plist file otherwise false
--
-- Parameters:
--  * plistList - Path to the file
--
-- Returns:
--  * Boolean
local function isBinaryPlist(plistList)

	if not plistList then
		return false
	end

	local file = io.open(plistList, "r")
	if not file then
		return false
	end

	-- Check for the marker
	local marker = file:read(6)
	file:close()

	if marker == "bplist" then
		return true
	end

	return false

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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
				folderCode = escape(folderCode)

				--------------------------------------------------------------------------------
				-- Unescape Result:
				--------------------------------------------------------------------------------
				if plistValues[folderCode] then
					return unescape(plistValues[folderCode])
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

-- scanAudioUnits() -> none
-- Function
-- Scans for Validated Audio Units
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function scanAudioUnits()
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
					for _, currentLanguage in pairs(mod.supportedLanguages) do
						if not mod._currentScan[currentLanguage]["AudioEffects"] then
							mod._currentScan[currentLanguage]["AudioEffects"] = {}
						end
						if not mod._currentScan[currentLanguage]["AudioEffects"]["OS X"] then
							mod._currentScan[currentLanguage]["AudioEffects"]["OS X"] = {}
						end
						if not mod._currentScan[currentLanguage]["AudioEffects"]["OS X"][category] then
							mod._currentScan[currentLanguage]["AudioEffects"]["OS X"][category] = {}
						end
						local pluginID = #mod._currentScan[currentLanguage]["AudioEffects"]["OS X"][category] + 1
						mod._currentScan[currentLanguage]["AudioEffects"]["OS X"][category][pluginID] = plugin
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
local function scanEffectsPresets()
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
								for _, currentLanguage in pairs(mod.supportedLanguages) do
									if not mod._currentScan[currentLanguage]["Effects"] then
										mod._currentScan[currentLanguage]["Effects"] = {}
									end
									if not mod._currentScan[currentLanguage]["Effects"][category] then
										mod._currentScan[currentLanguage]["Effects"][category] = {}
									end
									local pluginID = #mod._currentScan[currentLanguage]["Effects"][category] + 1
									mod._currentScan[currentLanguage]["Effects"][category][pluginID] = plugin
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

-- processPlugin(path, file) -> boolean
-- Function
-- Process a plugin so that it's added to the current scan
--
-- Parameters:
--  * path - Path to the plugin
--  * file - Filename of the plugin
--
-- Returns:
--  * `true` if successful otherwise `false`
--
-- Notes:
--  * getMotionTheme("/Users/latenitechris/Movies/Motion Templates.localized/Effects.localized/3065D03D-92D7-4FD9-B472-E524B87B5012.localized/DAEB0CAD-E702-4BF9-94B5-AE89D7F8FB00.localized/DAEB0CAD-E702-4BF9-94B5-AE89D7F8FB00.moef")
local function getMotionTheme(file)
	if tools.doesFileExist(file) then
		local content = fileToString(file)
		if content then
			local xml = slaxdom:dom(tostring(content))
			if xml and xml.root and xml.root.kids then
				for _,n in ipairs(xml.root.kids) do
					if n.name and n.name == "template" then
						local theme = nil
						for _,x in ipairs(n.kids) do
							if x.name and x.name == "theme" and x.kids[1] and x.kids[1].value then
								theme = x.kids[1].value
							end
						end
						if theme and theme ~= "~Obsolete" then
							return theme
						end
					end
				end
			end
		end
	end
	return false
end

-- processPlugin(path, file) -> boolean
-- Function
-- Process a plugin so that it's added to the current scan
--
-- Parameters:
--  * path - Path to the plugin
--  * file - Filename of the plugin
--
-- Returns:
--  * `true` if successful otherwise `false`
local function processPlugin(path, file)

	local fullPath = path .. "/" .. file
	local pathCompontents = fullPath:split("/")

	for pluginType,_ in pairs(mod.pluginTypes) do

		if pathCompontents[#pathCompontents - 4] == pluginType or pathCompontents[#pathCompontents - 4] == pluginType .. ".localized" then

			--------------------------------------------------------------------------------
			-- Get Motion Theme if available:
			--------------------------------------------------------------------------------
			local motionTheme = getMotionTheme(fullPath)

			--------------------------------------------------------------------------------
			-- Has Subcategory:
			--------------------------------------------------------------------------------
			for _, currentLanguage in pairs(mod.supportedLanguages) do

				local subcategory = nil
				if motionTheme then
					subcategory = motionTheme
				end

				local category = getLocalizedFolderName(combinePath(pathCompontents, #pathCompontents - 4), pathCompontents[#pathCompontents - 3], currentLanguage)

				if not subcategory then
					--------------------------------------------------------------------------------
					-- There was no Motion Theme:
					--------------------------------------------------------------------------------
					subcategory = getLocalizedFolderName(combinePath(pathCompontents, #pathCompontents - 3), pathCompontents[#pathCompontents - 2], currentLanguage)
				else
					--------------------------------------------------------------------------------
					-- There was a Motion Theme but maybe it should be overridden:
					--------------------------------------------------------------------------------
					local localisedSubcategory = getLocalizedFolderName(combinePath(pathCompontents, #pathCompontents - 3), pathCompontents[#pathCompontents - 2], currentLanguage)
					local folderName = pathCompontents[#pathCompontents - 2]

					if string.sub(folderName, -10) == ".localized" then
						folderName = string.sub(folderName, 1, -11)
					end

					if folderName ~= localisedSubcategory then
						subcategory = localisedSubcategory
					end
				end

				local plugin = getLocalizedFileName(combinePath(pathCompontents, #pathCompontents - 1), pathCompontents[#pathCompontents], currentLanguage)

				if not mod._currentScan[currentLanguage][pluginType][category] then
					mod._currentScan[currentLanguage][pluginType][category] = {}
				end

				if not mod._currentScan[currentLanguage][pluginType][category][subcategory] then
					mod._currentScan[currentLanguage][pluginType][category][subcategory] = {}
				end

				local pluginID = #mod._currentScan[currentLanguage][pluginType][category][subcategory] + 1
				mod._currentScan[currentLanguage][pluginType][category][subcategory][pluginID] = plugin

			end
			return true
		elseif pathCompontents[#pathCompontents - 3] == pluginType or pathCompontents[#pathCompontents - 3] == pluginType .. ".localized" then

			--------------------------------------------------------------------------------
			-- Get Motion Theme if available:
			--------------------------------------------------------------------------------
			local motionTheme = getMotionTheme(fullPath)

			if motionTheme then

				--------------------------------------------------------------------------------
				-- Has a Motion Theme:
				--------------------------------------------------------------------------------
				for _, currentLanguage in pairs(mod.supportedLanguages) do

					local category = getLocalizedFolderName(combinePath(pathCompontents, #pathCompontents - 4), pathCompontents[#pathCompontents - 3], currentLanguage)
					local subcategory = motionTheme
					local plugin = getLocalizedFileName(combinePath(pathCompontents, #pathCompontents - 1), pathCompontents[#pathCompontents], currentLanguage)

					if not mod._currentScan[currentLanguage][pluginType][category] then
						mod._currentScan[currentLanguage][pluginType][category] = {}
					end

					if not mod._currentScan[currentLanguage][pluginType][category][subcategory] then
						mod._currentScan[currentLanguage][pluginType][category][subcategory] = {}
					end

					local pluginID = #mod._currentScan[currentLanguage][pluginType][category][subcategory] + 1
					mod._currentScan[currentLanguage][pluginType][category][subcategory][pluginID] = plugin

				end
			else
				--------------------------------------------------------------------------------
				-- No Subcategory:
				--------------------------------------------------------------------------------
				for _, currentLanguage in pairs(mod.supportedLanguages) do

					local category = getLocalizedFolderName(combinePath(pathCompontents, #pathCompontents - 3), pathCompontents[#pathCompontents - 2], currentLanguage)
					local plugin = getLocalizedFileName(combinePath(pathCompontents, #pathCompontents - 1), pathCompontents[#pathCompontents], currentLanguage)

					if not mod._currentScan[currentLanguage][pluginType][category] then
						mod._currentScan[currentLanguage][pluginType][category] = {}
					end

					local pluginID = #mod._currentScan[currentLanguage][pluginType][category] + 1
					mod._currentScan[currentLanguage][pluginType][category][pluginID] = plugin

				end
			end
			return true
		end
	end
	return false
end

-- scanDirectory(directoryPath) -> boolean
-- Function
-- Scans a directory for plugins
--
-- Parameters:
--  * directoryPath - Directory to scan
--
-- Returns:
--  * `true` if successful otherwise `false`
local function scanDirectory(directoryPath)

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
			local filePath = fs.pathToAbsolute(path .. "/" .. file)
			attrs = fs.attributes(filePath)
			if attrs.mode == "directory" then
				--------------------------------------------------------------------------------
				-- Scan Directory:
				--------------------------------------------------------------------------------
				success = scanDirectory(filePath) and success
			elseif isPluginExtension(file) then
				--------------------------------------------------------------------------------
				-- Process Plugin:
				--------------------------------------------------------------------------------
				processPlugin(path, file)
			end
		end
	end
	return success
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

							if not mod._currentScan[currentLanguage]["AudioEffects"] then
								mod._currentScan[currentLanguage]["AudioEffects"] = {}
							end

							if not mod._currentScan[currentLanguage]["AudioEffects"][category] then
								mod._currentScan[currentLanguage]["AudioEffects"][category] = {}
							end

							local pluginID = #mod._currentScan[currentLanguage]["AudioEffects"][category] + 1
							mod._currentScan[currentLanguage]["AudioEffects"][category][pluginID] = plugin

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
local function scanPlugins()
	for _, path in pairs(mod.scanPaths) do
		for pluginType, _ in pairs(mod.pluginTypes) do
			scanDirectory(string.gsub(path, "{type}", pluginType))
		end
	end
end

-- scanSoundtrackProEDELEffects() -> none
-- Function
-- Scans for Soundtrack Pro EDEL Effects.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function scanSoundtrackProEDELEffects()

	for _, currentLanguage in pairs(mod.supportedLanguages) do
		for category, plugins in pairs(mod.buildinSoundtrackProEDELEffects) do
			for _, plugin in pairs(plugins) do

				if not mod._currentScan[currentLanguage]["AudioEffects"] then
					mod._currentScan[currentLanguage]["AudioEffects"] = {}
				end

				if not mod._currentScan[currentLanguage]["AudioEffects"]["Logic"] then
					mod._currentScan[currentLanguage]["AudioEffects"]["Logic"] = {}
				end

				if not mod._currentScan[currentLanguage]["AudioEffects"]["Logic"][category] then
					mod._currentScan[currentLanguage]["AudioEffects"]["Logic"][category] = {}
				end

				local pluginID = #mod._currentScan[currentLanguage]["AudioEffects"]["Logic"][category] + 1
				mod._currentScan[currentLanguage]["AudioEffects"]["Logic"][category][pluginID] = plugin

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

						if not mod._currentScan[currentLanguage]["AudioEffects"] then
							mod._currentScan[currentLanguage]["AudioEffects"] = {}
						end

						if not mod._currentScan[currentLanguage]["AudioEffects"][category] then
							mod._currentScan[currentLanguage]["AudioEffects"][category] = {}
						end

						local pluginID = #mod._currentScan[currentLanguage]["AudioEffects"][category] + 1
						mod._currentScan[currentLanguage]["AudioEffects"][category][pluginID] = plugin

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
local function translateInternalEffect(input, language)

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
		local prefsPath = mod.internalEffectPreferencesPath .. "English.lproj/Localizable.strings"
		local plistResult = plist.fileToTable(prefsPath)
		if plistResult then
			for key, string in pairs(plistResult) do
				if string == input then
					local newPrefsPath = mod.internalEffectPreferencesPath .. languageCodes[language] .. ".lproj/Localizable.strings"
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
	local prefsPath = mod.internalEffectFlexoPath .. "en.lproj/FFLocalizable.strings"
	local plistResult = plist.fileToTable(prefsPath)
	if plistResult then
		for key, string in pairs(plistResult) do
			if string == input then
				local newPrefsPath = mod.internalEffectFlexoPath .. language .. ".lproj/FFLocalizable.strings"
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
local function compareOldMethodToNewMethodResults()

	--------------------------------------------------------------------------------
	-- Debug Message:
	--------------------------------------------------------------------------------
	--[[
	log.df("---------------------------------------------------------")
	log.df(" RESULTS FROM NEW SCAN:")
	log.df("---------------------------------------------------------")
	log.df("Scan Results: %s", hs.inspect(mod._currentScan))
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
	for _, language in pairs(mod.supportedLanguages) do

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
				for _, pluginResults in pairs(mod._currentScan[language][pluginType]) do
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
		debugScanPlugin = mod._currentScan

	end
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
function mod:scan(fcp)

	--------------------------------------------------------------------------------
	-- Reset Results Table:
	--------------------------------------------------------------------------------
	mod._currentScan = {}

	--------------------------------------------------------------------------------
	-- Setup Final Cut Pro Variables:
	--------------------------------------------------------------------------------
	local fcpPath = fcp:getPath()

	--------------------------------------------------------------------------------
	-- Define Supported Languages:
	--------------------------------------------------------------------------------
	mod.supportedLanguages = fcp.SUPPORTED_LANGUAGES

	--------------------------------------------------------------------------------
	-- Core Audio Preferences File:
	--------------------------------------------------------------------------------
	mod.coreAudioPreferences = "/System/Library/Components/CoreAudio.component/Contents/Info.plist"

	--------------------------------------------------------------------------------
	-- Define Search Paths:
	--------------------------------------------------------------------------------
	mod.scanPaths = {
		"~/Movies/Motion Templates.localized/{type}.localized",
		"/Library/Application Support/Final Cut Pro/Templates.localized/{type}.localized",
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized/{type}.localized",
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/{type}.localized",
	}

	--------------------------------------------------------------------------------
	-- Define Effect Bundles Paths:
	--------------------------------------------------------------------------------
	mod.effectBundlesPaths = {
		fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/Effect Bundles",
	}

	--------------------------------------------------------------------------------
	-- Effect Bundles Preferences Path:
	--------------------------------------------------------------------------------
	mod.effectBundlesPreferencesPath = fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/"

	--------------------------------------------------------------------------------
	-- Define Effect Presets Paths:
	--------------------------------------------------------------------------------
	mod.effectPresetPaths = {
		"~/Library/Application Support/ProApps/Effects Presets/",
	}

	--------------------------------------------------------------------------------
	-- Define Soundtrack Pro EDEL Effects Paths:
	--------------------------------------------------------------------------------
	mod.edelEffectPaths = {
		fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/PlugIns/Audio/EDEL.bundle/Contents/Resources/Plug-In Settings"
	}

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
	-- Define Internal Effect Preferences Path:
	--------------------------------------------------------------------------------
	mod.internalEffectPreferencesPath = fcpPath .. "/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/"
	mod.internalEffectFlexoPath = fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/"

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
	mod.buildinSoundtrackProEDELEffects = {
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

	--------------------------------------------------------------------------------
	-- Add Supported Languages, Plugin Types & Built-in Effects to Results Table:
	--------------------------------------------------------------------------------
	for _, currentLanguage in pairs(mod.supportedLanguages) do
		mod._currentScan[currentLanguage] = {}
		for pluginType, _ in pairs(mod.pluginTypes) do
			mod._currentScan[currentLanguage][pluginType] = {}
			if pluginType == "Effects" then
				--------------------------------------------------------------------------------
				-- Add Built-in Effects:
				--------------------------------------------------------------------------------
				for category, effects in pairs(mod.builtinEffects) do
					for _, effect in pairs(effects) do
						if not mod._currentScan[currentLanguage][pluginType][category] then
							mod._currentScan[currentLanguage][pluginType][category] = {}
						end
						mod._currentScan[currentLanguage][pluginType][category][#mod._currentScan[currentLanguage][pluginType][category] + 1] = translateInternalEffect(effect, currentLanguage)
					end
				end
			elseif pluginType == "Transitions" then
				--------------------------------------------------------------------------------
				-- Add Built-in Transitions:
				--------------------------------------------------------------------------------
				for category, transitions in pairs(mod.builtinTransitions) do
					for _, transition in pairs(transitions) do
						if not mod._currentScan[currentLanguage][pluginType][category] then
							mod._currentScan[currentLanguage][pluginType][category] = {}
						end
						mod._currentScan[currentLanguage][pluginType][category][#mod._currentScan[currentLanguage][pluginType][category] + 1] = translateInternalEffect(transition, currentLanguage)
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Scan Audio Units:
	--------------------------------------------------------------------------------
	scanAudioUnits()

	--------------------------------------------------------------------------------
	-- Scan Soundtrack Pro EDEL Effects:
	--------------------------------------------------------------------------------
	scanSoundtrackProEDELEffects()

	--------------------------------------------------------------------------------
	-- Scan Effect Bundles:
	--------------------------------------------------------------------------------
	scanEffectBundles()

	--------------------------------------------------------------------------------
	-- Scan Effect Presets:
	--------------------------------------------------------------------------------
	scanEffectsPresets()

	--------------------------------------------------------------------------------
	-- Scan Plugins:
	--------------------------------------------------------------------------------
	scanPlugins()

	--------------------------------------------------------------------------------
	-- Test to compare these scans to previous GUI Scripted scans:
	--------------------------------------------------------------------------------
	compareOldMethodToNewMethodResults()

	return mod._currentScan

end

return mod