--- === hs.plist ===
---
--- Reads & Writes plist data.
---
--- Thrown together by:
---   David Peterson (https://github.com/randomeizer)
---   Chris Hocking (https://github.com/latenitefilms)
---

local plist = {}

local log			= require("hs.logger").new("plister")
local plistParse 	= require("hs.plist.plistParse")

--- hs.plist.base64ToTable(base64Data) -> table or nil
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
	executeCommand = "openssl base64 -in " .. tostring(base64FileName) .. " -out " .. tostring(plistFileName) .. " -d"
	executeOutput, executeStatus, _, _ = hs.execute(executeCommand)
	if not executeStatus then
		log.e("Failed to convert base64 data to a binary plist: " .. tostring(executeOutput))
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

--- hs.plist.binaryToTable(binaryData) -> table or nil
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

--- hs.plist.binaryFileToTable(plistFileName) -> table or nil
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

	local executeOutput, executeStatus, _, _ = hs.execute([[
		plutil -convert xml1 ]] .. plistFileName .. [[ -o -
	]])

	if not executeStatus then
		log.e("Failed to convert binary plist to XML: "..tostring(executeOutput))
	else
		-- Convert the XML to a LUA table:
		plistTable = plistParse(executeOutput)
	end

	-- Return the result:
	return plistTable

end

--- hs.plist.binaryFileToXML(plistFileName) -> string or nil
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
		plutil -convert xml1 ]] .. plistFileName .. [[ -o -
	]])

	if not executeStatus then
		log.e("Failed to convert binary plist to XML: "..tostring(executeOutput))
	else
		plistTable = executeOutput
	end

	-- Return the result:
	return plistTable

end

--- hs.plist.xmlFileToTable(plistFileName) -> table or nil
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

	local file = io.open(plistFileName, "r") 		-- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" 					-- *a or *all reads the whole file
    file:close()

	-- Convert the XML to a LUA table:
	plistTable = plistParse(content)

	-- Return the result:
	return plistTable

end

return plist