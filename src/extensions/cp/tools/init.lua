--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T O O L S     S U P P O R T     L I B R A R Y               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.tools ===
---
--- A collection of handy Lua tools for CommandPost.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("tools")

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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local tools = {}

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

--- cp.tools.safeFilename(value[, defaultValue]) -> string
--- Function
--- Returns a Safe Filename.
---
--- Parameters:
---  * value - a string you want to make safe
---  * defaultValue - the optional default filename to use if the value is not valid
---
--- Returns:
---  * A string of the safe filename
---
--- Notes:
---  * Returns "filename" is both `value` and `defaultValue` are `nil`.
function tools.safeFilename(value, defaultValue)

	--------------------------------------------------------------------------------
	-- Return default value.
	--------------------------------------------------------------------------------
	if not value then
		if defaultValue then
			return defaultValue
		else
			return "filename"
		end
	end

	--------------------------------------------------------------------------------
	-- Trim whitespaces:
	--------------------------------------------------------------------------------
	result = string.gsub(value, "^%s*(.-)%s*$", "%1")

	--------------------------------------------------------------------------------
	-- Remove Unfriendly Symbols:
	--------------------------------------------------------------------------------
	--result = string.gsub(result, "[^a-zA-Z0-9 ]","") -- This is probably too overkill.
	result = string.gsub(result, ":", "")
	result = string.gsub(result, "/", "")
	result = string.gsub(result, "\"", "")

	--------------------------------------------------------------------------------
	-- Remove Line Breaks:
	--------------------------------------------------------------------------------
	result = string.gsub(result, "\n", "")

	--------------------------------------------------------------------------------
	-- Limit to 255 characters (including extension):
	--------------------------------------------------------------------------------
	result = string.sub(result, 1, 255 - 4)

	return result

end

--- cp.tools.macOSVersion() -> string
--- Function
--- Returns a the macOS Version as a single string.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing the macOS version
function tools.macOSVersion()
	local osVersion = host.operatingSystemVersion()
	local osVersionString = (tostring(osVersion["major"]) .. "." .. tostring(osVersion["minor"]) .. "." .. tostring(osVersion["patch"]))
	return osVersionString
end

--- cp.tools.doesDirectoryExist(path) -> boolean
--- Function
--- Returns whether or not a directory exists.
---
--- Parameters:
---  * path - Path to the directory
---
--- Returns:
---  * `true` if the directory exists otherwise `false`
function tools.doesDirectoryExist(path)
	if path then
	    local attr = fs.attributes(path)
    	return attr and attr.mode == 'directory'
    else
    	return false
    end
end

--- cp.tools.doesFileExist(path) -> boolean
--- Function
--- Returns whether or not a file exists.
---
--- Parameters:
---  * path - Path to the file
---
--- Returns:
---  * `true` if the file exists otherwise `false`
function tools.doesFileExist(path)
	if path == nil then return nil end
    local attr = fs.attributes(path)
    if type(attr) == "table" then
    	return true
    else
    	return false
    end
end

--- cp.tools.trim(string) -> string
--- Function
--- Trims the whitespaces from a string
---
--- Parameters:
---  * string - the string you want to trim
---
--- Returns:
---  * A trimmed string
function tools.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--- cp.tools.lines(string) -> table
--- Function
--- Splits a string containing multiple lines of text into a table.
---
--- Parameters:
---  * string - the string you want to process
---
--- Returns:
---  * A table
function tools.lines(str)
	local t = {}
	local function helper(line)
		line = tools.trim(line)
		if line ~= nil and line ~= "" then
			table.insert(t, line)
		end
		return ""
	end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

--- cp.tools.executeWithAdministratorPrivileges(input[, stopOnError]) -> boolean or string
--- Function
--- Executes a single or multiple shell commands with Administrator Privileges.
---
--- Parameters:
---  * input - either a string or a table of strings of commands you want to execute
---  * stopOnError - an optional variable that stops processing multiple commands when an individual commands returns an error
---
--- Returns:
---  * `true` if successful, `false` if cancelled and a string if there's an error.
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

--- cp.tools.leftClick(point[, delay, clickNumber]) -> none
--- Function
--- Performs a Left Mouse Click.
---
--- Parameters:
---  * point - A point-table containing the absolute x and y co-ordinates to move the mouse pointer to
---  * delay - The optional delay between multiple mouse clicks
---  * clickNumber - The optional number of times you want to perform the click.
---
--- Returns:
---  * None
function tools.leftClick(point, delay, clickNumber)
	delay = delay or tools.DEFAULT_DELAY
	clickNumber = clickNumber or 1
    eventtap.event.newMouseEvent(leftMouseDown, point):setProperty(clickState, clickNumber):post()
	if delay > 0 then timer.usleep(delay) end
	eventtap.event.newMouseEvent(leftMouseUp, point):setProperty(clickState, clickNumber):post()
end

--- cp.tools.doubleLeftClick(point[, delay]) -> none
--- Function
--- Performs a Left Mouse Double Click.
---
--- Parameters:
---  * point - A point-table containing the absolute x and y co-ordinates to move the mouse pointer to
---  * delay - The optional delay between multiple mouse clicks
---
--- Returns:
---  * None
function tools.doubleLeftClick(point, delay)
	delay = delay or tools.DEFAULT_DELAY
	tools.leftClick(point, delay, 1)
	tools.leftClick(point, delay, 2)
end

--- cp.tools.ninjaMouseClick(point[, delay]) -> none
--- Function
--- Performs a mouse click, but returns the mouse to the original position without the users knowledge.
---
--- Parameters:
---  * point - A point-table containing the absolute x and y co-ordinates to move the mouse pointer to
---  * delay - The optional delay between multiple mouse clicks
---
--- Returns:
---  * None
function tools.ninjaMouseClick(point, delay)
	delay = delay or tools.DEFAULT_DELAY
	local originalMousePoint = mouse.getAbsolutePosition()
	tools.leftClick(point, delay)
	if delay > 0 then timer.usleep(delay) end
	mouse.setAbsolutePosition(originalMousePoint)
end

--- cp.tools.ninjaDoubleClick(point[, delay]) -> none
--- Function
--- Performs a mouse double click, but returns the mouse to the original position without the users knowledge.
---
--- Parameters:
---  * point - A point-table containing the absolute x and y co-ordinates to move the mouse pointer to
---  * delay - The optional delay between multiple mouse clicks
---
--- Returns:
---  * None
function tools.ninjaDoubleClick(point, delay)
	delay = delay or tools.DEFAULT_DELAY
	local originalMousePoint = mouse.getAbsolutePosition()
	tools.doubleLeftClick(point, delay)
	if delay > 0 then timer.usleep(delay) end
	mouse.setAbsolutePosition(originalMousePoint)
end

--- cp.tools.ninjaMouseAction(point, fn) -> none
--- Function
--- Moves the mouse to a point, performs a function, then returns the mouse to the original point.
---
--- Parameters:
---  * point - A point-table containing the absolute x and y co-ordinates to move the mouse pointer to
---  * fn - A function you want to perform
---
--- Returns:
---  * None
function tools.ninjaMouseAction(point, fn)
	local originalMousePoint = mouse.getAbsolutePosition()
	mouse.setAbsolutePosition(point)
	fn()
	mouse.setAbsolutePosition(originalMousePoint)
end

--- cp.tools.tableCount(table) -> number
--- Function
--- Returns how many items are in a table.
---
--- Parameters:
---  * table - The table you want to count.
---
--- Returns:
---  * The number of items in the table.
function tools.tableCount(table)
	local count = 0
	for _ in pairs(table) do count = count + 1 end
	return count
end

--- cp.tools.removeFilenameFromPath(string) -> string
--- Function
--- Removes the filename from a path.
---
--- Parameters:
---  * string - The path
---
--- Returns:
---  * A string of the path without the filename.
function tools.removeFilenameFromPath(input)
	return (string.sub(input, 1, (string.find(input, "/[^/]*$"))))
end

--- cp.tools.stringMaxLength(string, maxLength[, optionalEnd]) -> string
--- Function
--- Trims a string based on a maximum length.
---
--- Parameters:
---  * maxLength - The length of the string as a number
---  * optionalEnd - A string that is applied to the end of the input string if the input string is larger than the maximum length.
---
--- Returns:
---  * A string
function tools.stringMaxLength(string, maxLength, optionalEnd)

	local result = string
	if maxLength ~= nil and string.len(string) > maxLength then
		result = string.sub(string, 1, maxLength)
		if optionalEnd ~= nil then
			result = result .. optionalEnd
		end
	end
	return result

end

--- cp.tools.cleanupButtonText(value) -> string
--- Function
--- Removes the … symbol and multiple >'s from a string.
---
--- Parameters:
---  * value - A string
---
--- Returns:
---  * A cleaned string
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

--- cp.tools.modifierMatch(inputA, inputB) -> boolean
--- Function
--- Compares two modifier tables.
---
--- Parameters:
---  * inputA - table of modifiers
---  * inputB - table of modifiers
---
--- Returns:
---  * `true` if there's a match otherwise `false`
---
--- Notes:
---  * This function only takes into account 'ctrl', 'alt', 'cmd', 'shift'.
function tools.modifierMatch(inputA, inputB)

	local match = true

	if fnutils.contains(inputA, "ctrl") and not fnutils.contains(inputB, "ctrl") then match = false end
	if fnutils.contains(inputA, "alt") and not fnutils.contains(inputB, "alt") then match = false end
	if fnutils.contains(inputA, "cmd") and not fnutils.contains(inputB, "cmd") then match = false end
	if fnutils.contains(inputA, "shift") and not fnutils.contains(inputB, "shift") then match = false end

	return match

end

--- cp.tools.modifierMaskToModifiers() -> table
--- Function
--- Translate Keyboard Modifiers from Apple's Plist Format into Hammerspoon Format
---
--- Parameters:
---  * value - Modifiers String
---
--- Returns:
---  * table
function tools.modifierMaskToModifiers(value)

	local modifiers = {
		["alphashift"] 	= 1 << 16,
		["shift"]      	= 1 << 17,
		["control"]    	= 1 << 18,
		["option"]	   	= 1 << 19,
		["command"]    	= 1 << 20,
		["numericpad"] 	= 1 << 21,
		["help"]       	= 1 << 22,
		["function"]   	= 1 << 23,
	}

	local answer = {}

	for k, v in pairs(modifiers) do
		if (value & v) == v then
			table.insert(answer, k)
		end
	end

	return answer

end

--- cp.tools.incrementFilename(value) -> string
--- Function
--- Increments the filename.
---
--- Parameters:
---  * value - A string
---
--- Returns:
---  * A string
function tools.incrementFilename(value)
	if value == nil then return nil end
	if type(value) ~= "string" then return nil end

	local name, counter = string.match(value, '^(.*)%s(%d+)$')
	if name == nil or counter == nil then
		return value .. " 1"
	end

	return name .. " " .. tostring(tonumber(counter) + 1)
end

--- cp.tools.incrementFilename(value) -> string
--- Function
--- Returns a table of file names for the given path.
---
--- Parameters:
---  * path - A path as string
---
--- Returns:
---  * A table containing filenames as strings.
function tools.dirFiles(path)
	path = fs.pathToAbsolute(path)
	if not path then
		return nil
	end
	local contents, data = fs.dir(path)

	local files = {}
	for file in function() return contents(data) end do
		files[#files+1] = file
	end
	return files
end

--- cp.tools.numberToWord(number) -> string
--- Function
--- Converts a number to a string (i.e. 1 becomes "One").
---
--- Parameters:
---  * number - A whole number between 0 and 10
---
--- Returns:
---  * A string
function tools.numberToWord(number)
	if number == 0 then return "Zero" end
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