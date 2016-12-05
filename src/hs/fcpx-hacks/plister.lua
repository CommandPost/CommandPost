-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- plist support libary
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

local log							= hs.logger.new("plister")

local json  						= require("hs.json")
local inspect						= require("hs.inspect")

-- import the plistParser function
local plistParse 					= require("hs.fcpx-hacks.plistParse")

local plist = {}

--------------------------------------------------------------------------------
-- Convert base64 plist binary data to human readable:
--------------------------------------------------------------------------------
function plist.base64ToTable(base64Data)
	local base64FileName = os.tmpname()
	local plistFileName	= os.tmpname()
	local plistTable = nil

	local file = io.open(base64FileName, "w")
	file:write(base64Data)
	file:close()

	-- Convert the base64 file to a binary plist
	executeCommand = "openssl base64 -in " .. tostring(base64FileName) .. " -out " .. tostring(plistFileName) .. " -d"
	executeOutput, executeStatus, _, _ = hs.execute(executeCommand)
	if not executeStatus then
		log.e("Failed to convert base64 data to a binary plist: " .. tostring(executeOutput))
	else
		-- convert the binary plist file to a LUA table
		plistTable = plist.binaryFileToTable(plistFileName)
	end

	-- Clean up the temp files
	os.remove(base64FileName)
	os.remove(plistFileName)

	return plistTable
end

--------------------------------------------------------------------------------
-- Converts binary plist data into a LUA table
--------------------------------------------------------------------------------
function plist.binaryToTable(binaryData)
	-- Define Temporary File:
	local plistFileName	= os.tmpname()

	--------------------------------------------------------------------------------
	-- Write Clipboard Data to Temporary File:
	--------------------------------------------------------------------------------
	local plistFile = io.open(plistFileName, "w")
	plistFile:write(binaryData)
	plistFile:close()

	-- Read the binary plist file
	local plistTable = plist.binaryFileToTable(plistFileName)

	-- Delete the temporary file
	os.remove(plistFileName)

	return plistTable
end

function plist.binaryFileToTable(plistFileName)
	local executeOutput 			= nil
	local executeStatus 			= nil
	local plistTable 				= nil

	--------------------------------------------------------------------------------
	-- Convert binary plist file to XML then return in JSON:
	--------------------------------------------------------------------------------
	-- local executeOutput, executeStatus, _, _ = hs.execute([[
	-- 	plutil -convert xml1 ]] .. plistFileName .. [[ -o - |
	-- 	sed 's/data>/string>/g;s/date>/string>/g;s/<true\/>/<string>true<\/string>/g;s/<false\/>/<string>false<\/string>/g;s/real>/string>/g' |
	-- 	plutil -convert json - -o -
	-- ]])

	local executeOutput, executeStatus, _, _ = hs.execute([[
		plutil -convert xml1 ]] .. plistFileName .. [[ -o -
	]])

	if not executeStatus then
		log.e("Failed to convert binary plist to XML: "..tostring(executeOutput))
	else
		-- Convert the XML to a LUA table
		plistTable = plistParse(executeOutput)
	end

	return plistTable
end

function plist.binaryFileToXML(plistFileName)
	local executeOutput 			= nil
	local executeStatus 			= nil
	local plistTable 				= nil

	--------------------------------------------------------------------------------
	-- Convert binary plist file to XML then return in JSON:
	--------------------------------------------------------------------------------
	local executeOutput, executeStatus, _, _ = hs.execute([[
		plutil -convert xml1 ]] .. plistFileName .. [[ -o -
	]])


	if not executeStatus then
		log.e("Failed to convert binary plist to XML: "..tostring(executeOutput))
	else
		plistTable = executeOutput
	end

	return plistTable
end

function plist.xmlFileToTable(plistFileName)
	--------------------------------------------------------------------------------
	-- Convert binary plist file to XML then return in JSON:
	--------------------------------------------------------------------------------
	local file = io.open(plistFileName, "r") -- r read mode and b binary mode
    if not file then return nil end

    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()

	-- Convert the JSON to a LUA table
	plistTable = plistParse(content)

	return plistTable
end

return plist

