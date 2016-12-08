--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              T O O L S     S U P P O R T     L I B R A R Y                 --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://github.com/latenitefilms).
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
function doubleLeftClick(point)
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
function ninjaMouseClick(position)
		local originalMousePoint = mouse.getAbsolutePosition()
		eventtap.leftClick(position)
		mouse.setAbsolutePosition(originalMousePoint)
end

--------------------------------------------------------------------------------
-- HOW MANY ITEMS IN A TABLE?
--------------------------------------------------------------------------------
function tableCount(table)
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


return tools