--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              T O O L S     S U P P O R T     L I B R A R Y                 --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://latenitefilms.com).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local tools = {}

local eventtap									= require("hs.eventtap")
local fnutils									= require("hs.fnutils")
local fs										= require("hs.fs")
local host										= require("hs.host")
local inspect									= require("hs.inspect")
local keycodes									= require("hs.keycodes")
local mouse										= require("hs.mouse")
local osascript									= require("hs.osascript")
local timer										= require("hs.timer")

local just										= require("cp.just")

local log										= require("hs.logger").new("tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------

tools.DEFAULT_DELAY 	= 0

--------------------------------------------------------------------------------
-- LOCAL VARIABLES:
--------------------------------------------------------------------------------

local leftMouseDown 	= eventtap.event.types["leftMouseDown"]
local leftMouseUp 		= eventtap.event.types["leftMouseUp"]
local clickState 		= eventtap.event.properties.mouseEventClickState

-------------------------------------------------------------------------------
-- RETURNS MACOS VERSION:
-------------------------------------------------------------------------------
function tools.macOSVersion()
	local osVersion = host.operatingSystemVersion()
	local osVersionString = (tostring(osVersion["major"]) .. "." .. tostring(osVersion["minor"]) .. "." .. tostring(osVersion["patch"]))
	return osVersionString
end

--------------------------------------------------------------------------------
-- DOES DIRECTORY EXIST:
--------------------------------------------------------------------------------
function tools.doesDirectoryExist(path)
    local attr = fs.attributes(path)
    return attr and attr.mode == 'directory'
end

--------------------------------------------------------------------------------
-- DOES FILE EXIST:
--------------------------------------------------------------------------------
function tools.doesFileExist(path)
    local attr = fs.attributes(path)
    if type(attr) == "table" then
    	return true
    else
    	return false
    end
end

--------------------------------------------------------------------------------
-- TRIM STRING:
--------------------------------------------------------------------------------
function tools.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--------------------------------------------------------------------------------
-- EXECUTE WITH ADMINISTRATOR PRIVILEGES:
--------------------------------------------------------------------------------
-- Returns: 'true' if successful, 'false' if cancelled, and a 'string' if error
function tools.executeWithAdministratorPrivileges(input, stopOnError)
	local hsBundleID = hs.processInfo["bundleID"]
	if type(stopOnError) ~= "boolean" then stopOnError = true end
	if type(input) == "table" then
		local appleScript = [[
			set stopOnError to ]] .. tostring(stopOnError) .. "\n\n" .. [[
			set errorMessage to ""
			set frontmostApplication to (path to frontmost application as text)
			tell application id "]] .. hsBundleID .. [["
				activate
				set shellScriptInputs to ]] .. inspect(input) .. "\n\n" .. [[
				try
					repeat with theItem in shellScriptInputs
						try
							do shell script theItem with administrator privileges
						on error errStr number errorNumber
							if the errorNumber is equal to -128 then
								-- Cancel is pressed:
								return false
							else
								if the stopOnError is equal to true then
									tell application frontmostApplication to activate
									return errStr as text & "(" & errorNumber as text & ")\n\nWhen trying to execute:\n\n" & theItem
								else
									set errorMessage to errorMessage & "Error: " & errStr as text & "(" & errorNumber as text & "), when trying to execute: " & theItem & ".\n\n"
								end if
							end if
						end try
					end repeat
					if the errorMessage is equal to "" then
						tell application frontmostApplication to activate
						return true
					else
						tell application frontmostApplication to activate
						return errorMessage
					end
				end try
			end tell
		]]
		_,result = osascript.applescript(appleScript)
		return result
	elseif type(input) == "string" then
		local appleScript = [[
			set frontmostApplication to (path to frontmost application as text)
			tell application id "]] .. hsBundleID .. [["
				activate
				set shellScriptInput to "]] .. input .. [["
				try
					do shell script shellScriptInput with administrator privileges
					tell application frontmostApplication to activate
					return true
				on error errStr number errorNumber
					if the errorNumber is equal to -128 then
						tell application frontmostApplication to activate
						return false
					else
						tell application frontmostApplication to activate
						return errStr as text & "(" & errorNumber as text & ")\n\nWhen trying to execute:\n\n" & theItem
					end if
				end try
			end tell
		]]
		_,result = osascript.applescript(appleScript)
		return result
	else
		log.ef("ERROR: Expected a Table or String in tools.executeWithAdministratorPrivileges()")
		return nil
	end
end

--------------------------------------------------------------------------------
-- LEFT CLICK:
--------------------------------------------------------------------------------
function tools.leftClick(point, delay, clickNumber)
	delay = delay or tools.DEFAULT_DELAY
	clickNumber = clickNumber or 1
    eventtap.event.newMouseEvent(leftMouseDown, point):setProperty(clickState, clickNumber):post()
	if delay > 0 then timer.usleep(delay) end
	eventtap.event.newMouseEvent(leftMouseUp, point):setProperty(clickState, clickNumber):post()
end

--------------------------------------------------------------------------------
-- DOUBLE LEFT CLICK:
--------------------------------------------------------------------------------
function tools.doubleLeftClick(point, delay)
	delay = delay or tools.DEFAULT_DELAY
	tools.leftClick(point, delay, 1)
	tools.leftClick(point, delay, 2)
end

--------------------------------------------------------------------------------
-- NINJA MOUSE CLICK:
--------------------------------------------------------------------------------
function tools.ninjaMouseClick(point, delay)
	delay = delay or tools.DEFAULT_DELAY
	local originalMousePoint = mouse.getAbsolutePosition()
	tools.leftClick(point, delay)
	if delay > 0 then timer.usleep(delay) end
	mouse.setAbsolutePosition(originalMousePoint)
end

--------------------------------------------------------------------------------
-- NINJA DOUBLE MOUSE CLICK:
--------------------------------------------------------------------------------
function tools.ninjaDoubleClick(point, delay)
	delay = delay or tools.DEFAULT_DELAY
	local originalMousePoint = mouse.getAbsolutePosition()
	tools.doubleLeftClick(point, delay)
	if delay > 0 then timer.usleep(delay) end
	mouse.setAbsolutePosition(originalMousePoint)
end

--------------------------------------------------------------------------------
-- NINJA MOUSE ACTION:
--------------------------------------------------------------------------------
function tools.ninjaMouseAction(point, fn)
	local originalMousePoint = mouse.getAbsolutePosition()
	mouse.setAbsolutePosition(point)
	fn()
	mouse.setAbsolutePosition(originalMousePoint)
end

--------------------------------------------------------------------------------
-- HOW MANY ITEMS IN A TABLE?
--------------------------------------------------------------------------------
function tools.tableCount(table)
	local count = 0
	for _ in pairs(table) do count = count + 1 end
	return count
end

--------------------------------------------------------------------------------
-- REMOVE FILENAME FROM PATH:
--------------------------------------------------------------------------------
function tools.removeFilenameFromPath(input)
	return (string.sub(input, 1, (string.find(input, "/[^/]*$"))))
end

--------------------------------------------------------------------------------
-- STRING MAX LENGTH
--------------------------------------------------------------------------------
function tools.stringMaxLength(string, maxLength, optionalEnd)

	local result = string
	if string.len(string) > maxLength then
		result = string.sub(string, 1, maxLength)
		if optionalEnd ~= nil then
			result = result .. optionalEnd
		end
	end
	return result

end

--------------------------------------------------------------------------------
-- CLEAN UP BUTTON TEXT:
--------------------------------------------------------------------------------
function tools.cleanupButtonText(value)

	--------------------------------------------------------------------------------
	-- Get rid of …
	--------------------------------------------------------------------------------
	value = string.gsub(value, "…", "")

	--------------------------------------------------------------------------------
	-- Only get last value of menu items:
	--------------------------------------------------------------------------------
	if string.find(value, " > ", 1) ~= nil then
		value = string.reverse(value)
		local lastArrow = string.find(value, " > ", 1)
		value = string.sub(value, 1, lastArrow - 1)
		value = string.reverse(value)
	end

	return value

end

--------------------------------------------------------------------------------
-- GET USER LOCALE:
--------------------------------------------------------------------------------
function tools.userLocale()
	local a, userLocale = osascript.applescript("return user locale of (get system info)")
	return userLocale
end

--------------------------------------------------------------------------------
-- MODIFIER MATCH:
--------------------------------------------------------------------------------
function tools.modifierMatch(inputA, inputB)

	local match = true

	if fnutils.contains(inputA, "ctrl") and not fnutils.contains(inputB, "ctrl") then match = false end
	if fnutils.contains(inputA, "alt") and not fnutils.contains(inputB, "alt") then match = false end
	if fnutils.contains(inputA, "cmd") and not fnutils.contains(inputB, "cmd") then match = false end
	if fnutils.contains(inputA, "shift") and not fnutils.contains(inputB, "shift") then match = false end

	return match

end

--------------------------------------------------------------------------------
-- INCREMENT FILENAME:
--------------------------------------------------------------------------------
function tools.incrementFilename(value)
	if value == nil then return nil end
	if type(value) ~= "string" then return nil end

	local name, counter = string.match(value, '^(.*)%s(%d+)$')
	if name == nil or counter == nil then
		return value .. " 1"
	end

	return name .. " " .. tostring(tonumber(counter) + 1)
end

--------------------------------------------------------------------------------
-- Returns a list of file names for the path in an array.
--------------------------------------------------------------------------------
function tools.dirFiles(path)
	path = fs.pathToAbsolute(path)
	local contents, data = fs.dir(path)

	local files = {}
	for file in function() return contents(data) end do
		files[#files+1] = file
	end
	return files
end

function tools.numberToWord(number)
	if number == 1 then return "One" end
	if number == 2 then return "Two" end
	if number == 3 then return "Three" end
	if number == 4 then return "Four" end
	if number == 5 then return "Five" end
	if number == 6 then return "Six" end
	if number == 7 then return "Seven" end
	if number == 8 then return "Eight" end
	if number == 9 then return "Nine" end
	if number == 10 then return "Ten" end
	return nil
end

return tools