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
local plistParse 	= require("cp.plist.plistParse")
local fs			= require("hs.fs")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local plist = {}

plist.log = log

--- cp.plist.base64ToTable(base64Data) -> table or nil
--- Function
--- Converts base64 Data into a LUA Table.
---
--- Parameters:
---  * base64Data - Binary data encoded in base64
---
--- Returns:
---  * A table of the plist data
---
--- Notes:
---  * None
function plist.base64ToTable(base64Data)

	-- Define Temporary Files:
	local base64FileName = os.tmpname()
	local plistFileName	= os.tmpname()

	local plistTable = nil

	local file = io.open(base64FileName, "w")
	file:write(base64Data)
	file:close()

	-- Convert the base64 file to a binary plist:
	executeCommand = 'openssl base64 -in "' .. tostring(base64FileName) .. '" -out "' .. tostring(plistFileName) .. '" -d'
	executeOutput, executeStatus, _, _ = hs.execute(executeCommand)
	if not executeStatus then
		log.d("Failed to convert base64 data to a binary plist: " .. tostring(executeOutput))
	else
		-- Convert the Binary plist file to a LUA table:
		plistTable = plist.binaryFileToTable(plistFileName)
	end

	-- Clean up the Temporary Files:
	os.remove(base64FileName)
	os.remove(plistFileName)

	-- Return the result:
	return plistTable

end

--- cp.plist.binaryToTable(binaryData) -> table or nil
--- Function
--- Converts Binary Data into a LUA Table.
---
--- Parameters:
---  * binaryData - Binary data
---
--- Returns:
---  * A table of the plist data
---
--- Notes:
---  * None
function plist.binaryToTable(binaryData)
	if not binaryData then
		return nil
	end

	-- Define Temporary File:
	local plistFileName	= os.tmpname()

	-- Write Clipboard Data to Temporary File:
	local plistFile = io.open(plistFileName, "w")
	plistFile:write(binaryData)
	plistFile:close()

	-- Read the Binary plist File:
	local plistTable = plist.binaryFileToTable(plistFileName)


	-- Delete the Temporary File:
	os.remove(plistFileName)

	-- Return the result:
	return plistTable

end

--- cp.plist.binaryFileToTable(plistFileName) -> table or nil
--- Function
--- Converts the data from a Binary File into a LUA Table.
---
--- Parameters:
---  * plistFileName - Path & Filename of the Binary File
---
--- Returns:
---  * A table of the plist data
---
--- Notes:
---  * None
function plist.binaryFileToTable(plistFileName)

	local executeOutput 			= nil
	local executeStatus 			= nil
	local plistTable 				= nil

	if not plistFileName then
		log.d("No plist filename was provided.")
		return nil
	else
		plistFileName = fs.pathToAbsolute(plistFileName)
	end

	local executeOutput, executeStatus, _, _ = hs.execute([[
		plutil -convert xml1 "]] .. plistFileName .. [[" -o -
	]])

	if not executeStatus then
		log.d("Failed to convert binary plist to XML: "..tostring(executeOutput))
	else
		-- Convert the XML to a LUA table:
		plistTable = plistParse(executeOutput)
	end

	-- Return the result:
	return plistTable

end

--- cp.plist.binaryFileToXML(plistFileName) -> string | nil
--- Function
--- Converts the data from a Binary plist File into XML as a string.
---
--- Parameters:
---  * plistFileName - Path & Filename of the Binary File
---
--- Returns:
---  * A string of XML data
---
--- Notes:
---  * None
function plist.binaryFileToXML(plistFileName)

	local executeOutput 			= nil
	local executeStatus 			= nil
	local plistTable 				= nil

	local executeOutput, executeStatus, _, _ = hs.execute([[
		plutil -convert xml1 "]] .. plistFileName .. [[" -o -
	]])

	if not executeStatus then
		log.d("Failed to convert binary plist to XML: "..tostring(executeOutput))
	else
		plistTable = executeOutput
	end

	-- Return the result:
	return plistTable

end

--- cp.plist.xmlFileToTable(plistFileName) -> table or nil
--- Function
--- Converts XML data from a file into a LUA Table.
---
--- Parameters:
---  * plistFileName - Path & Filename of the XML File
---
--- Returns:
---  * A table of plist data
---
--- Notes:
---  * None
function plist.xmlFileToTable(plistFileName)
	if not plistFileName then
		log.d("No plistFileName was provided")
		return nil
	end

	local absoluteFilename = fs.pathToAbsolute(plistFileName)
	if not absoluteFilename then
		log.df("The provided path was not found: %s", plistFileName)
		return nil
	end
	local file = io.open(absoluteFilename, "r") 		-- r read mode
    if not file then
		log.d("Unable to open '".. plistFileName .."'")
		return nil
	end
    local content = file:read "*a" 					-- *a or *all reads the whole file
    file:close()

	-- Convert the XML to a LUA table:
	plistTable = plistParse(content)

	-- Return the result:
	return plistTable

end

--- cp.plist.fileToTable(plistFileName) -> table or nil
--- Function
--- Converts plist data from a binary or XML file into a LUA Table.
--- It will check the file prior to loading to determine which type it is.
--- If you know which type of file you're dealing with in advance, you can use
--- cp.plist.xmlFileToTable() or hs.plist.binaryFileToTable() instead to save an extra
--- (small) file read
---
--- Parameters:
---  * plistFileName - Path & Filename of the XML File
---
--- Returns:
---  * A table of plist data
---
--- Notes:
---  * None
function plist.fileToTable(plistFileName)
	if not plistFileName then
		log.d("No plistFileName was provided")
		return nil
	end

	local absoluteFilename = fs.pathToAbsolute(plistFileName)
	local file = io.open(absoluteFilename, "r")
	if not file then
		log.d("Unable to open '".. plistFileName .."'")
		return nil
	end

	-- Check for the marker
	local marker = file:read(6)
	file:close()

	-- log.d("Marker: "..marker)

	if marker == "bplist" then
		-- it's a binary plist
		return plist.binaryFileToTable(absoluteFilename)
	else
		return plist.xmlFileToTable(absoluteFilename)
	end
end

return plist