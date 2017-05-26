--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.scan ===
---
--- Scan Final Cut Pro files for Effects, Generators, Titles & Transitions

-- require("cp.apple.finalcutpro.scan").scan()

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("scan")

local fnutils									= require("hs.fnutils")
local fs 										= require("hs.fs")
local inspect									= require("hs.inspect")
local host										= require("hs.host")

local tools										= require("cp.tools")
local fcp										= require("cp.apple.finalcutpro")

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
function linesFrom(file)
	if not tools.doesFileExist(file) then return {} end
	file = fs.pathToAbsolute(file)
	lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
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
		local values = {}
		local data = linesFrom(currentLanguageFile)
		if next(data) ~= nil then
			for i, v in ipairs(data) do

				--"68A64C00-10FE-43E6-840A-BED9034B9A6C" = "Stereographic \"Little Planet\"";

				local unescape = string.gsub(v, [[\"]], "@!@")
				if unescape then
					local key, value = string.match(unescape, '%"([^%"]+)%"[^%"]+%"([^%"]+)%"')
					if key and value then
						values[key] = string.gsub(value, "@!@", '"')
					end
				end
			end
			local folderCode = string.sub(folder, 1, -11)
			if values[folderCode] then
				return values[folderCode]
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

	local locale = host.locale.current()
	local languageCode = host.locale.details(locale).languageCode

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
			-- If that fails try anything else:
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
				result[#result + 1] = effectComponents[1]
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
						local specificElement = specificGroup .. "/" .. element
						if tools.doesDirectoryExist(specificElement) then
							for file in fs.dir(specificElement) do
								if string.sub(file, -(string.len(extension) + 1) ) == "." .. extension then
									local friendlyFolderName = getLocalizedFolderName(specificGroup, element)
									if string.sub(friendlyFolderName, -10) ~= "(Obsolete)" then
										result[#result + 1] = friendlyFolderName
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

--- cp.apple.finalcutpro.scan() -> string or nil
--- Function
--- Scans Final Cut Pro for Effects, Transitions, Generators & Titles
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.scan()

	local fcpPath = fcp:getPath()

	local types = {
		["AudioEffects"] = "effectBundle",
		["Effects"] = "moef",
		["Transitions"] = "motr",
		["Generators"] = "motn",
		["Titles"] = "moti",
	}

	local paths = {
		"~/Movies/Motion Templates.localized/{type}.localized",
		"/Library/Application Support/Final Cut Pro/Templates.localized/{type}.localized",
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/PETemplates.localized/{type}.localized",
		fcpPath .. "/Contents/PlugIns/MediaProviders/MotionEffect.fxp/Contents/Resources/Templates.localized/{type}.localized",
		fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/Effect Bundles",
		"/Library/Audio/Plug-Ins/Components",
		"~/Library/Audio/Plug-Ins/Components",
	}

	local scans = {}

	for whichType, whichExtension in pairs(types) do
		for _, whichPath in ipairs(paths) do
			local currentPath = string.gsub(whichPath, "{type}", whichType)
			local result = scanFolder(currentPath, whichExtension)
			if result then
				if scans[whichType] == nil then
					scans[whichType] = {}
				end
				scans[whichType] = fnutils.concat(scans[whichType], result)
			end
		end
    end

    log.df("Scans: %s", hs.inspect(scans))

end

return mod