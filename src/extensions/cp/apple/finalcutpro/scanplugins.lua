--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.scanplugins ===
---
--- Scan Final Cut Pro files for Effects, Generators, Titles & Transitions
---
--- Usage: require("cp.apple.finalcutpro"):scanPlugins()

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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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

-- readLocalizedFile(currentLanguageFile) -> string or nil
-- Function
-- Reads a .localized file
--
-- Parameters:
--  * currentLanguageFile - Path to the current language file.
--
-- Returns:
--  * The translated file name or nil
local function readLocalizedFile(folder, currentLanguageFile)
	if tools.doesFileExist(currentLanguageFile) then
		--------------------------------------------------------------------------------
		-- Binary Plist:
		--------------------------------------------------------------------------------
		if isBinaryPlist(currentLanguageFile) then

			local plistValues = plist.fileToTable(currentLanguageFile)
			if plistValues then
				local folderCode = string.sub(folder, 1, -11)
				if plistValues[folderCode] then
					return plistValues[folderCode]
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
--  * String
local function getLocalizedFolderName(path, folder)
	local languageCode = mod.currentLanguage
	if string.sub(folder, -10) == ".localized" then
		local localizedFolder = path .. "/" .. folder .. "/.localized"
		local localizedFolderExists = tools.doesDirectoryExist(localizedFolder)
		if localizedFolderExists then
			--------------------------------------------------------------------------------
			-- Try current locale first:
			--------------------------------------------------------------------------------
			local currentLanguageFile = localizedFolder .. "/" .. languageCode .. ".strings"
			local result = readLocalizedFile(folder, currentLanguageFile)
			if result then
				return result
			end
			--------------------------------------------------------------------------------
			-- If that fails try English:
			--------------------------------------------------------------------------------
			local currentLanguageFile = localizedFolder .. "/en.strings"
			local result = readLocalizedFile(folder, currentLanguageFile)
			if result then
				return result
			end
			--------------------------------------------------------------------------------
			-- If that fails try whatever is left:
			--------------------------------------------------------------------------------
			for localizedFile in fs.dir(localizedFolder) do
				if string.sub(localizedFile, -8) == ".strings" then
					local result = readLocalizedFile(folder, localizedFolder .. "/" .. localizedFile)
					if result then
						return result
					end
				end
			end
		end
		return string.sub(folder, 1, -11)
	end
	return folder
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
--  * String
local function getLocalizedFileName(path, file)

	local fileWithoutExtension = string.match(file, "(.+)%..+")

	local languageCode = mod.currentLanguage

	local localizedFolder = path .. "/.localized"
	local localizedFolderExists = tools.doesDirectoryExist(localizedFolder)

	if localizedFolderExists then

		--------------------------------------------------------------------------------
		-- Try current locale first:
		--------------------------------------------------------------------------------
		local currentLanguageFile = localizedFolder .. "/" .. languageCode .. ".strings"
		local result = readLocalizedFile(fileWithoutExtension, currentLanguageFile)
		if result then
			return result
		end

		--------------------------------------------------------------------------------
		-- If that fails try English:
		--------------------------------------------------------------------------------
		local currentLanguageFile = localizedFolder .. "/en.strings"
		local result = readLocalizedFile(fileWithoutExtension, currentLanguageFile)
		if result then
			return result
		end

		--------------------------------------------------------------------------------
		-- If that fails try anything else:
		--------------------------------------------------------------------------------
		for localizedFile in fs.dir(localizedFolder) do
			if string.sub(localizedFile, -8) == ".strings" then
				local result = readLocalizedFile(fileWithoutExtension, localizedFolder .. "/" .. localizedFile)
				if result then
					return result
				end
			end
		end

	end

	return fileWithoutExtension

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

-- scanFolder(path, extension) -> table
-- Function
-- Scan a folder for specific plugins
--
-- Parameters:
--  * path - Path to search
--  * extension - Type of extension to look for
--
-- Returns:
--  * Table
function scanFolder(path, extension)

	local result = {}

	--------------------------------------------------------------------------------
	-- Does directory exist?
	--------------------------------------------------------------------------------
	local exist = tools.doesDirectoryExist(path)
	if not exist then
		return nil
	end

	--------------------------------------------------------------------------------
	-- Scan Folder:
	--------------------------------------------------------------------------------
	if extension == "effectBundle" then
		--------------------------------------------------------------------------------
		-- Audio Effects:
		--------------------------------------------------------------------------------
		for file in fs.dir(path) do
			if string.sub(file, -13) == ".effectBundle" then
				local effectComponents = string.split(file, ".")
				if result[effectComponents[2]] == nil then
					result[effectComponents[2]] = {}
				end
				result[effectComponents[2]][#result[effectComponents[2]] + 1] = effectComponents[1]
			end
		end
	else
		--------------------------------------------------------------------------------
		-- Everything Else:
		--------------------------------------------------------------------------------
		for group in fs.dir(path) do
			if string.sub(group, 1, 1) ~= "." then
				local specificGroup = path .. "/" .. group
				if tools.doesDirectoryExist(specificGroup) then
					for element in fs.dir(specificGroup) do
						if string.sub(element, 1, 1) ~= "." then
							local specificElement = specificGroup .. "/" .. element
							if tools.doesDirectoryExist(specificElement) then
								for file in fs.dir(specificElement) do
									if string.sub(file, 1, 1) ~= "." then
										if string.sub(file, -(string.len(extension) + 1) ) == "." .. extension then
											local friendlyGroupName = getLocalizedFolderName(path, group)
											local friendlyEffectName = nil
											local localisedFileName = getLocalizedFileName(specificElement, file)
											if localisedFileName then
												friendlyEffectName = localisedFileName
											else
												friendlyEffectName = getLocalizedFolderName(specificGroup, element)
												if not string.find(element, ".localized") then
													local fileWithoutExtension = string.sub(file, 1, -6)
													if fileWithoutExtension ~= element then
														friendlyEffectName = fileWithoutExtension
													end
												end
											end

											if result[friendlyGroupName] == nil then
												result[friendlyGroupName] = {}
											end
											result[friendlyGroupName][#result[friendlyGroupName] + 1] = friendlyEffectName
										else
											--------------------------------------------------------------------------------
											-- Sub Category:
											--------------------------------------------------------------------------------
											local subCategoryPath = specificElement .. "/" .. file
											if tools.doesDirectoryExist(subCategoryPath) then

												for subfile in fs.dir(subCategoryPath) do
													if string.sub(subfile, 1, 1) ~= "." then
														if string.sub(subfile, -(string.len(extension) + 1) ) == "." .. extension then
															local friendlyGroupName = getLocalizedFolderName(path, group)
															local friendlyEffectName = nil
															local localisedFileName = getLocalizedFileName(subCategoryPath, subfile)
															local subcategory = element

															if localisedFileName then
																friendlyEffectName = localisedFileName
															else
																friendlyEffectName = getLocalizedFolderName(specificElement, file)
																if not string.find(element, ".localized") then
																	local fileWithoutExtension = string.sub(file, 1, -6)
																	if fileWithoutExtension ~= element then
																		friendlyEffectName = fileWithoutExtension
																	end
																end
															end

															if result[friendlyGroupName] == nil then
																result[friendlyGroupName] = {}
															end
															if result[friendlyGroupName][subcategory] == nil then
																result[friendlyGroupName][subcategory] = {}
															end

															result[friendlyGroupName][subcategory][#result[friendlyGroupName][subcategory] + 1] = friendlyEffectName

														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return result

end

-- scanAudioUnits() -> table
-- Function
-- Returns a list of Validated Audio Units as a table
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
function scanAudioUnits()
	local audioUnits = {}
	local output, status = hs.execute("auval -s aufx")
	if status and output then
		local coreAudioPlistPath = "/System/Library/Components/CoreAudio.component/Contents/Info.plist"
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
					local value = tools.trim(values[2])
					if audioUnits[key] == nil then
						audioUnits[key] = {}
					end
					audioUnits[key][#audioUnits[key] + 1] = value
				end
			end
		end
	else
		log.ef("Failed to scan for Audio Units.")
	end
	return audioUnits
end

-- scanEffectsPresets() -> table
-- Function
-- Returns a list of Effects Presets as a table
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
function scanEffectsPresets()

	local path = "~/Library/Application Support/ProApps/Effects Presets/"

	local exist = tools.doesDirectoryExist(path)
	if not exist then
		return nil
	end

	local result = {}

	for file in fs.dir(path) do
		if string.sub(file, -14) == ".effectsPreset" then
			local plistResult = plist.fileToTable(path .. file)
			if plistResult then
				local unarchivedPlist = archiver.unarchive(plistResult)
				if unarchivedPlist then
					local category = unarchivedPlist["category"]
					if category then
						if result[category] == nil then
							result[category] = {}
						end
						result[category][#result[category] + 1] = string.sub(file, 1, -15)
					end
				end
			end
		end
	end

	return result

end

--- cp.apple.finalcutpro.scanplugins:scan() -> string or nil
--- Function
--- Scans Final Cut Pro for Effects, Transitions, Generators & Titles
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod:scan(fcp)

	--------------------------------------------------------------------------------
	-- Setup Final Cut Pro Variables:
	--------------------------------------------------------------------------------
	local fcpPath = fcp:getPath()
	local supportedLanguages = fcp.SUPPORTED_LANGUAGES

	--------------------------------------------------------------------------------
	-- Define Search Paths:
	--------------------------------------------------------------------------------
	local paths = {
		"~/Movies/Motion Templates.localized/{type}.localized",
		"/Library/Application Support/Final Cut Pro/Templates.localized/{type}.localized",
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized/{type}.localized",
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/{type}.localized",
		fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/Effect Bundles",
	}

	--------------------------------------------------------------------------------
	-- Define Plugin Types:
	--------------------------------------------------------------------------------
	local types = {
		["AudioEffects"] 	= 	{ "effectBundle" },
		["Effects"] 		= 	{ "moef" },
		["Transitions"]		= 	{ "motr" },
		["Generators"] 		= 	{ "motn" },
		["Titles"] 			= 	{ "moti" },
	}

	--------------------------------------------------------------------------------
	-- Built-in Effects:
	--------------------------------------------------------------------------------
	local builtinEffects = {
		["Color"] 			= 	{ "Color Correction" },
		["Masks"] 			= 	{ "Draw Mask", "Shape Mask" },
		["Stylize"] 		= 	{ "Drop Shadow" },
		["Keying"] 			=	{ "Keyer", "Luma Keyer" }
	}

	--------------------------------------------------------------------------------
	-- Setup Results Table:
	--------------------------------------------------------------------------------
	local scanResults = {}

	--------------------------------------------------------------------------------
	-- Scan Plugins for Every Supported Language:
	--------------------------------------------------------------------------------
	for _, currentLanguage in pairs(supportedLanguages) do

		--------------------------------------------------------------------------------
		-- Define Current Language we're working with:
		--------------------------------------------------------------------------------
		mod.currentLanguage = currentLanguage

		--------------------------------------------------------------------------------
		-- Setup Blank Table for each Language:
		--------------------------------------------------------------------------------
		scanResults[currentLanguage] = {}

		--------------------------------------------------------------------------------
		-- Setup Blank Table for each Type:
		--------------------------------------------------------------------------------
		for v, _ in pairs(types) do
			scanResults[currentLanguage][v] = {}
		end

		--------------------------------------------------------------------------------
		-- Scan Audio Units:
		--------------------------------------------------------------------------------
		local audioUnits = scanAudioUnits()
		for key, value in pairs(audioUnits) do
			if scanResults[currentLanguage]["AudioEffects"][key] == nil then
				scanResults[currentLanguage]["AudioEffects"][key] = {}
			end
			for _, individualValue in pairs(value) do
				scanResults[currentLanguage]["AudioEffects"][key][#scanResults[currentLanguage]["AudioEffects"][key] + 1] = individualValue
			end
		end

		--------------------------------------------------------------------------------
		-- Add Built-in Effects:
		--------------------------------------------------------------------------------
		for group, effects in pairs(builtinEffects) do
			if scanResults[currentLanguage]["Effects"][group] == nil then
				scanResults[currentLanguage]["Effects"][group] = {}
			end
			for _, effect in pairs(effects) do
				scanResults[currentLanguage]["Effects"][group][#scanResults[currentLanguage]["Effects"][group] + 1] = effect
			end
		end

		--------------------------------------------------------------------------------
		-- Scan Effects Presets:
		--------------------------------------------------------------------------------
		local effectsPresets = scanEffectsPresets()
		for group, effects in pairs(effectsPresets) do
			if scanResults[currentLanguage]["Effects"][group] == nil then
				scanResults[currentLanguage]["Effects"][group] = {}
			end
			for _, effect in pairs(effects) do
				scanResults[currentLanguage]["Effects"][group][#scanResults[currentLanguage]["Effects"][group] + 1] = effect
			end
		end

		--------------------------------------------------------------------------------
		-- Scan Plugins:
		--------------------------------------------------------------------------------
		for whichType, whichExtensions in pairs(types) do
			for _, whichExtension in pairs(whichExtensions) do
				for _, whichPath in ipairs(paths) do
					local currentPath = string.gsub(whichPath, "{type}", whichType)
					local result = scanFolder(currentPath, whichExtension)
					if result then
						for key, value in pairs(result) do
							if scanResults[currentLanguage][whichType][key] == nil then
								scanResults[currentLanguage][whichType][key] = {}
							end
							for subcategory, individualValue in pairs(value) do
								if type(individualValue) == "table" then
									--------------------------------------------------------------------------------
									-- Has Subcategory:
									--------------------------------------------------------------------------------
									for _, subcategoryItem in pairs(individualValue) do
										if scanResults[currentLanguage][whichType][key][subcategory] == nil then
											scanResults[currentLanguage][whichType][key][subcategory] = {}
										end
										scanResults[currentLanguage][whichType][key][subcategory][#scanResults[currentLanguage][whichType][key][subcategory] + 1] = subcategoryItem
									end
								else
									--------------------------------------------------------------------------------
									-- No Subcategory:
									--------------------------------------------------------------------------------
									scanResults[currentLanguage][whichType][key][#scanResults[currentLanguage][whichType][key] + 1] = individualValue
								end
							end
						end
					end
				end
			end
		end

	end

	--------------------------------------------------------------------------------
	-- Compare GUI Scripting Results to this method:
	--------------------------------------------------------------------------------
	--[[
	local guiVideoEffects = config.get(fcp:getCurrentLanguage() .. ".allVideoEffects")

	local effects = {}
	for _, videoEffects in pairs(scanResults["en"]["Effects"]) do
		for _, videoEffect in pairs(videoEffects) do
			effects[#effects + 1] = videoEffect
		end
	end

	for _, guiVideoEffect in pairs(guiVideoEffects) do

		local match = false
		for _, videoEffect in pairs(effects) do

			if guiVideoEffect == videoEffect then
				match = true
			end
			if string.find(guiVideoEffect, "%s%-%s") then
				if string.sub(guiVideoEffect, string.find(guiVideoEffect, "%s%-%s") + 3) == videoEffect then
					match = true
				end
			end
		end
		if not match then
			log.df("Missing Effect: %s", guiVideoEffect)
		end
	end

	log.df("------")

	log.df("effects: %s", hs.inspect(effects))
	--]]


	--log.df("scanResults: %s", hs.inspect(scanResults))

	return scanResults

end

return mod