--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                            P L I S T    T O O L S                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plist ===
---
--- Reads & Writes plist data.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("plist")

local fs			= require("hs.fs")

local plistParse 	= require("cp.plist.plistParse")
local tools 		= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local plist = {}

plist.log = log

--- cp.plist.base64ToTable(base64Data) -> table | nil, errorMessage
--- Function
--- Converts base64 encoded Property List string into a Table.
---
--- Parameters:
---  * base64Data - Binary data encoded in base64 as a string
---
--- Returns:
---  * A table of the plist data
---  * A error message as string if an error occurs
function plist.base64ToTable(base64Data)

	--------------------------------------------------------------------------------
	-- Trim Base64 data:
	--------------------------------------------------------------------------------
	if base64Data then
 		base64Data = tools.trim(base64Data)
 	end

	--------------------------------------------------------------------------------
	-- Define Temporary Files:
	--------------------------------------------------------------------------------
	local base64FileName = os.tmpname()
	local plistFileName	= os.tmpname()

	local err = ""
	local plistTable

	local file = io.open(base64FileName, "w")
	file:write(base64Data)
	file:close()

	--------------------------------------------------------------------------------
	-- Convert the base64 file to a binary plist:
	--------------------------------------------------------------------------------
	executeCommand = 'openssl base64 -in "' .. tostring(base64FileName) .. '" -out "' .. tostring(plistFileName) .. '" -d'
	executeOutput, executeStatus, _, _ = hs.execute(executeCommand)
	if not executeStatus then
		log.d("Failed to convert base64 data to a binary plist: " .. tostring(executeOutput))
	else
		-- Convert the Binary plist file to a LUA table:
		plistTable, err = plist.fileToTable(plistFileName)
	end

	--------------------------------------------------------------------------------
	-- Clean up the Temporary Files:
	--------------------------------------------------------------------------------
	os.remove(base64FileName)
	os.remove(plistFileName)

	-- Return the result:
	return plistTable, err

end

--- cp.plist.binaryToTable(binaryData) -> table | nil
--- Function
--- Converts Binary Data into a LUA Table.
---
--- Parameters:
---  * binaryData		- Binary data
---
--- Returns:
---  * data				- A string of XML data
---  * err				- The error message, or `nil` if there were no problems.
function plist.binaryToTable(binaryData)
	if not binaryData then
		return nil
	end

	-- Define Temporary File:
	local plistFileName	= os.tmpname()

	-- Write Clipboard Data to Temporary File:
	local plistFile = io.open(plistFileName, "wb")
	plistFile:write(binaryData)
	plistFile:close()

	-- Read the Binary plist File:
	local plistTable, err = plist.binaryFileToTable(plistFileName)

	-- Delete the Temporary File:
	os.remove(plistFileName)

	-- Return the result:
	return plistTable, err
end

--- cp.plist.binaryFileToTable(plistFileName) -> table | nil
--- Function
--- Converts the data from a Binary File into a LUA Table.
---
--- Parameters:
---  * plistFileName - Path & Filename of the Binary File
---
--- Returns:
---  * data				- A table of plist data, or `nil` if there was a problem.
---  * err				- The error message, or `nil` if there were no problems.
function plist.binaryFileToTable(plistFileName)

	local executeOutput 			= nil
	local executeStatus 			= nil
	local plistTable 				= nil

	if not plistFileName then
		return nil, "No plist filename was provided."
	else
		plistFileName = fs.pathToAbsolute(plistFileName)
		if not plistFileName then
			return nil, string.format("The file could not be found: %s", plistFileName)
		end
	end

	local executeOutput, executeStatus, _, _ = hs.execute([[
		plutil -convert xml1 "]] .. plistFileName .. [[" -o -
	]])

	if not executeStatus then
		return nil, string.format("Failed to convert binary plist to XML: %s", executeOutput)
	else
		-- Convert the XML to a LUA table:
		return plistParse(executeOutput)
	end
end

--- cp.plist.binaryFileToXML(plistFileName) -> string | nil
--- Function
--- Converts the data from a Binary plist File into XML as a string.
---
--- Parameters:
---  * plistFileName - Path & Filename of the Binary File
---
--- Returns:
---  * data				- A string of XML data
---  * err				- The error message, or `nil` if there were no problems.
function plist.binaryFileToXML(plistFileName)

	local executeOutput 			= nil
	local executeStatus 			= nil

	local executeOutput, executeStatus = hs.execute([[
		plutil -convert xml1 "]] .. plistFileName .. [[" -o -
	]])

	if not executeStatus then
		return nil, string.format("Failed to convert binary plist to XML: %s", executeOutput)
	end

	-- Return the result:
	return executeOutput, nil

end

--- cp.plist.xmlFileToTable(plistFileName) -> table | nil
--- Function
--- Converts XML data from a file into a LUA Table.
---
--- Parameters:
---  * plistFileName	- Path & Filename of the XML File
---
--- Returns:
---  * data				- A table of plist data, or `nil` if there was a problem.
---  * err				- The error message, or `nil` if there were no problems.
function plist.xmlFileToTable(plistFileName)
	if not plistFileName then
		return nil, "No plistFileName was provided"
	end

	local absoluteFilename = fs.pathToAbsolute(plistFileName)
	if not absoluteFilename then
		return nil, string.format("The provided path was not found: %s", plistFileName)
	end
	local file = io.open(absoluteFilename, "r") 		-- r read mode
    if not file then
		return nil, string.format("Unable to open '%s'", plistFileName)
	end
    local content = file:read "*a" 					-- *a or *all reads the whole file
    file:close()

	-- Convert the XML to a LUA table:
	plistTable = plistParse(content)

	-- Return the result:
	return plistTable, nil

end

--- cp.plist.fileToTable(plistFileName) -> table | nil
--- Function
--- Converts plist data from a binary or XML file into a LUA Table.
--- It will check the file prior to loading to determine which type it is.
--- If you know which type of file you're dealing with in advance, you can use
--- cp.plist.xmlFileToTable() or hs.plist.binaryFileToTable() instead.
---
--- Parameters:
---  * plistFileName	- Path & Filename of the XML File
---
--- Returns:
---  * data				- A table of plist data, or `nil` if there was a problem.
---  * err				- The error message, or `nil` if there were no problems.
function plist.fileToTable(plistFileName)
	if not plistFileName then
		return nil, "No plistFileName provided."
	end

	-- find it
	local absoluteFilename = fs.pathToAbsolute(plistFileName)
	if not absoluteFilename then
		return nil, string.format("Unable to find '%s'", plistFileName)
	end

	if plist.isBinaryPlist(absoluteFilename) then
		-- it's a binary plist
		return plist.binaryFileToTable(absoluteFilename)
	else
		return plist.xmlFileToTable(absoluteFilename)
	end
end

--- cp.plist.isBinaryPlist(plistList) -> boolean
--- Function
--- Returns true if plistList is a binary plist file otherwise false
---
--- Parameters:
---  * plistList - Path to the file
---
--- Returns:
---  * Boolean
function plist.isBinaryPlist(plistFileName)

	if not plistFileName then
		return false
	end

	local file = io.open(plistFileName, "r")
	if not file then
		return false
	end

	-- Check for the marker
	local marker = file:read(6)
	file:close()

	return marker == "bplist"
end

return plist