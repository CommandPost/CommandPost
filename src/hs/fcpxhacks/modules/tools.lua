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
local fs										= require("hs.fs")
local host										= require("hs.host")
local keycodes									= require("hs.keycodes")
local mouse										= require("hs.mouse")
local osascript									= require("hs.osascript")
local timer										= require("hs.timer")

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
function tools.executeWithAdministratorPrivileges(input)
	local appleScriptA = 'set shellScriptInput to "' .. input .. '"\n\n'
	local appleScriptB = [[
		try
			tell me to activate
			do shell script shellScriptInput with administrator privileges
			return true
		on error
			return false
		end try
	]]

	ok,result = osascript.applescript(appleScriptA .. appleScriptB)
	return result
end

--------------------------------------------------------------------------------
-- DOUBLE LEFT CLICK:
--------------------------------------------------------------------------------
function tools.doubleLeftClick(point)
	local clickState = eventtap.event.properties.mouseEventClickState
	eventtap.event.newMouseEvent(eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1):post()
	eventtap.event.newMouseEvent(eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):post()
	timer.usleep(1000)
	eventtap.event.newMouseEvent(eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 2):post()
	eventtap.event.newMouseEvent(eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 2):post()
end

--------------------------------------------------------------------------------
-- NINJA MOUSE CLICK:
--------------------------------------------------------------------------------
function tools.ninjaMouseClick(point)
	local originalMousePoint = mouse.getAbsolutePosition()
	local clickState = eventtap.event.properties.mouseEventClickState
	eventtap.event.newMouseEvent(eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1):post()
	eventtap.event.newMouseEvent(eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):post()
	timer.usleep(1000)
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
-- KEYCODE TRANSLATOR:
--------------------------------------------------------------------------------
function tools.keyCodeTranslator(input)

	local englishKeyCodes = {
		["'"] = 39,
		[","] = 43,
		["-"] = 27,
		["."] = 47,
		["/"] = 44,
		["0"] = 29,
		["1"] = 18,
		["2"] = 19,
		["3"] = 20,
		["4"] = 21,
		["5"] = 23,
		["6"] = 22,
		["7"] = 26,
		["8"] = 28,
		["9"] = 25,
		[";"] = 41,
		["="] = 24,
		["["] = 33,
		["\\"] = 42,
		["]"] = 30,
		["`"] = 50,
		["a"] = 0,
		["b"] = 11,
		["c"] = 8,
		["d"] = 2,
		["delete"] = 51,
		["down"] = 125,
		["e"] = 14,
		["end"] = 119,
		["escape"] = 53,
		["f"] = 3,
		["f1"] = 122,
		["f10"] = 109,
		["f11"] = 103,
		["f12"] = 111,
		["f13"] = 105,
		["f14"] = 107,
		["f15"] = 113,
		["f16"] = 106,
		["f17"] = 64,
		["f18"] = 79,
		["f19"] = 80,
		["f2"] = 120,
		["f20"] = 90,
		["f3"] = 99,
		["f4"] = 118,
		["f5"] = 96,
		["f6"] = 97,
		["f7"] = 98,
		["f8"] = 100,
		["f9"] = 101,
		["forwarddelete"] = 117,
		["g"] = 5,
		["h"] = 4,
		["help"] = 114,
		["home"] = 115,
		["i"] = 34,
		["j"] = 38,
		["k"] = 40,
		["l"] = 37,
		["left"] = 123,
		["m"] = 46,
		["n"] = 45,
		["o"] = 31,
		["p"] = 35,
		["pad*"] = 67,
		["pad+"] = 69,
		["pad-"] = 78,
		["pad."] = 65,
		["pad/"] = 75,
		["pad0"] = 82,
		["pad1"] = 83,
		["pad2"] = 84,
		["pad3"] = 85,
		["pad4"] = 86,
		["pad5"] = 87,
		["pad6"] = 88,
		["pad7"] = 89,
		["pad8"] = 91,
		["pad9"] = 92,
		["pad="] = 81,
		["padclear"] = 71,
		["padenter"] = 76,
		["pagedown"] = 121,
		["pageup"] = 116,
		["q"] = 12,
		["r"] = 15,
		["return"] = 36,
		["right"] = 124,
		["s"] = 1,
		["space"] = 49,
		["t"] = 17,
		["tab"] = 48,
		["u"] = 32,
		["up"] = 126,
		["v"] = 9,
		["w"] = 13,
		["x"] = 7,
		["y"] = 16,
		["z"] = 6,
		["§"] = 10
	}

	if englishKeyCodes[input] == nil then
		if keycodes.map[input] == nil then
			return ""
		else
			return keycodes.map[input]
		end
	else
		return englishKeyCodes[input]
	end

end

return tools