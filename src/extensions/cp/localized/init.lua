--- === cp.localized ===
---
--- Helps look up localized names for folders.
local log										= require("hs.logger").new("localized")

local fs 										= require("hs.fs")
local plist										= require("cp.plist")
local tools										= require("cp.tools")

local text										= require("cp.web.text")

local lines, flush								= io.lines, io.flush
local pathToAbsolute							= fs.pathToAbsolute
local escapeXML, unescapeXML 					= text.escapeXML, text.unescapeXML
local isBinaryPlist, binaryFileToTable			= plist.isBinaryPlist, plist.binaryFileToTable
local match, gsub								= string.match, string.gsub

local aliases = {
	de	= "German",
	en	= "English",
	es	= "Spanish",
	fr	= "French",
	it	= "Italian",
	ja	= "Japanese",
}

-- cp.localized.readLocalizedStrings(stringsFile, name) -> string | nil
-- Function
-- Returns the localized string value contained in the strings file for the specified `name`.
--
-- Parameters:
--  * `stringsFile`	- Path to the .localized strings file.
--  * `name`			- The name to match. If not present in the file, `nil` is returned.
--
-- Returns:
--  * The matching key value, or `nil` if not available.
local function readLocalizedStrings(stringsFile, name)
	local stringsPath = pathToAbsolute(stringsFile)
	if stringsPath then
		log.df("readLocalizedStrings: %s", stringsPath)
		--------------------------------------------------------------------------------
		-- Binary Plist:
		--------------------------------------------------------------------------------
		if isBinaryPlist(stringsFile) then
			log.df("It's a plist")
			local plistValues = binaryFileToTable(stringsFile)

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
			log.df("It's a string file")
			local file = io.open(stringsFile, "rb")
			local localized = nil
			while true do
				local line = file:read("*l")
				if not line then break end
				log.df("line: %s", line)
				local key, value = match(line, '^%"(.+)%"%s*%=%s*%"(.+)%";$')
				log.df("%s = %s", key, value)
				if key and value then
					-- unescape the key.
					key = gsub(key, '%\\(.)', '%1')
					if key == name then
						-- unescape the value.
						localized = gsub(value, '%\\(.)', '%1')
						break
					end
				end
			end
			file:close()
			return localized
		end
	end
	return nil
end

-- cp.localized.readLocalizedName(path, name, language) -> string
-- Function
-- Returns the localized `name` for the `path` in the specified `language`. It will check
-- for common aliases for language codes (e.g. 'en' is sometimes 'English'). If no localization
-- for the specified language is available, it will try English, and if all else fails, the
-- original `name` is returned.
--
-- Parameters:
--  * `path`			- The full path to the folder
--  * `name`			- The name to match. If not present in the file, `nil` is returned.
--  * `language`		- The language to retrieve the name for.
--
-- Returns:
--  * The localized name, or `name` if not available.
local function readLocalizedName(path, name, language)
	local localizedPath = path .. "/.localized/"
	local localized = readLocalizedStrings(localizedPath .. language .. ".strings", name)
	if not localized then
		local alias = aliases[language]
		if alias then
			localized = readLocalizedStrings(localizedPath .. alias .. ".strings", name)
		end
		if not localized and language ~= "en" then
			localized = readLocalizedName(path, name, "en")
		end
	end
	return localized or name
end

--- cp.localized.getLocalizedName(path[, language]) -> string
--- Function
--- Returns the localized name for the `path` in the specified `language`. If all else fails, the
--- original folder name is returned.
---
--- Parameters:
---  * `path`			- The full path to the folder
---  * `language`		- The language to retrieve the name for.
---
--- Returns:
---  * The localized name, or `name` if not available.
function getLocalizedName(path, language)
	local file = match(path, "^.-([^/%.]+)%.local$")
	if file then -- it's localized
		return readLocalizedName(path, file, language)
	else
		return match(path, "^.-([^/%.]+)$")
	end
end

return {
	readLocalizedStrings 	= readLocalizedStrings,
	readLocalizedName		= readLocalizedName,
	getLocalizedName		= getLocalizedName,
}