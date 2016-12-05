--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  			  ===========================================
--
--  			             F C P X    H A C K S
--
--			      ===========================================
--
--
--  Thrown together by Chris Hocking @ LateNite Films
--  https://latenitefilms.com
--
--  You can download the latest version here:
--  https://latenitefilms.com/blog/final-cut-pro-hacks/
--
--  Please be aware that I'm a filmmaker, not a programmer, so... apologies!
--
--------------------------------------------------------------------------------
--  LICENSE:
--------------------------------------------------------------------------------
--
-- The MIT License (MIT)
--
-- Copyright (c) 2016 Chris Hocking.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               P L I S T     S U P P O R T     L I B R A R Y                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- This module contains code by David Peterson (https://github.com/randomeizer)





--------------------------------------------------------------------------------
-- STANDARD EXTENSIONS:
--------------------------------------------------------------------------------

local log							= hs.logger.new("plister")
local json  						= require("hs.json")
local inspect						= require("hs.inspect")
local base64						= require("hs.base64")

--------------------------------------------------------------------------------
-- INTERNAL EXTENSIONS:
--------------------------------------------------------------------------------

local plistParse 					= require("hs.fcpx-hacks.plistParse")

--------------------------------------------------------------------------------
-- LOCAL VARIABLES:
--------------------------------------------------------------------------------

local plist = {}

--------------------------------------------------------------------------------
-- CONVERT BASE64 DATA TO LUA TABLE:
--------------------------------------------------------------------------------
function plist.base64ToTable(base64Data)

	--------------------------------------------------------------------------------
	-- Define Temporary Files:
	--------------------------------------------------------------------------------
	local base64FileName = os.tmpname()
	local plistFileName	= os.tmpname()

	local plistTable = nil

	local file = io.open(base64FileName, "w")
	file:write(base64Data)
	file:close()

	--------------------------------------------------------------------------------
	-- Convert the base64 file to a binary plist:
	--------------------------------------------------------------------------------
	executeCommand = "openssl base64 -in " .. tostring(base64FileName) .. " -out " .. tostring(plistFileName) .. " -d"
	executeOutput, executeStatus, _, _ = hs.execute(executeCommand)
	if not executeStatus then
		log.e("Failed to convert base64 data to a binary plist: " .. tostring(executeOutput))
	else
		--------------------------------------------------------------------------------
		-- Convert the Binary plist file to a LUA table:
		--------------------------------------------------------------------------------
		plistTable = plist.binaryFileToTable(plistFileName)
	end

	--------------------------------------------------------------------------------
	-- Clean up the Temporary Files:
	--------------------------------------------------------------------------------
	os.remove(base64FileName)
	os.remove(plistFileName)

	--------------------------------------------------------------------------------
	-- Return the result:
	--------------------------------------------------------------------------------
	return plistTable

end

--------------------------------------------------------------------------------
-- CONVERT BINARY PLIST DATA TO LUA TABLE:
--------------------------------------------------------------------------------
function plist.binaryToTable(binaryData)

	--------------------------------------------------------------------------------
	-- Define Temporary File:
	--------------------------------------------------------------------------------
	local plistFileName	= os.tmpname()

	--------------------------------------------------------------------------------
	-- Write Clipboard Data to Temporary File:
	--------------------------------------------------------------------------------
	local plistFile = io.open(plistFileName, "w")
	plistFile:write(binaryData)
	plistFile:close()

	--------------------------------------------------------------------------------
	-- Read the Binary plist File:
	--------------------------------------------------------------------------------
	local plistTable = plist.binaryFileToTable(plistFileName)

	--------------------------------------------------------------------------------
	-- Delete the Temporary File:
	--------------------------------------------------------------------------------
	os.remove(plistFileName)

	--------------------------------------------------------------------------------
	-- Return the result:
	--------------------------------------------------------------------------------
	return plistTable

end

--------------------------------------------------------------------------------
-- CONVERT BINARY PLIST FILE TO LUA TABLE:
--------------------------------------------------------------------------------
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
		--------------------------------------------------------------------------------
		-- Convert the XML to a LUA table:
		--------------------------------------------------------------------------------
		plistTable = plistParse(executeOutput)
	end

	--------------------------------------------------------------------------------
	-- Return the result:
	--------------------------------------------------------------------------------
	return plistTable

end

--------------------------------------------------------------------------------
-- CONVERT BINARY PLIST FILE TO XML:
--------------------------------------------------------------------------------
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

	--------------------------------------------------------------------------------
	-- Return the result:
	--------------------------------------------------------------------------------
	return plistTable

end

--------------------------------------------------------------------------------
-- CONVERT XML PLIST FILE TO LUA TABLE:
--------------------------------------------------------------------------------
function plist.xmlFileToTable(plistFileName)

	local file = io.open(plistFileName, "r") 		-- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" 					-- *a or *all reads the whole file
    file:close()

	--------------------------------------------------------------------------------
	-- Convert the XML to a LUA table:
	--------------------------------------------------------------------------------
	plistTable = plistParse(content)

	--------------------------------------------------------------------------------
	-- Return the result:
	--------------------------------------------------------------------------------
	return plistTable

end

return plist