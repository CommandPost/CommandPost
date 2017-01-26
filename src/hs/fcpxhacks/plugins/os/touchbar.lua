-- Includes
local touchbar 									= require("hs._asm.touchbar")
local settings									= require("hs.settings")
local eventtap									= require("hs.eventtap")

-- The Module
local mod = {}

function mod.isSupported()
	return touchbar.supported()
end

function mod.getLastLocation()
	settings.get("fcpxHacks.lastTouchBarLocation")
end

function mod.setLastLocation(value)
	settings.set("fcpxHacks.lastTouchBarLocation", value)
end

function mod.init()
	--------------------------------------------------------------------------------
	-- New Touch Bar:
	--------------------------------------------------------------------------------
	mod.touchBarWindow = touchbar.new()

	--------------------------------------------------------------------------------
	-- Touch Bar Watcher:
	--------------------------------------------------------------------------------
	mod.touchBarWindow:setCallback(touchbarWatcher)

	--------------------------------------------------------------------------------
	-- Get last Touch Bar Location from Settings:
	--------------------------------------------------------------------------------
	local lastTouchBarLocation = mod.getLastLocation()
	if lastTouchBarLocation ~= nil then	mod.touchBarWindow:topLeft(lastTouchBarLocation) end

	--------------------------------------------------------------------------------
	-- Draggable Touch Bar:
	--------------------------------------------------------------------------------
	local events = eventtap.event.types
	touchbarKeyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
		if mod.mouseInsideTouchbar then
			if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
				mod.touchBarWindow:backgroundColor{ red = 1 }
							  	:movable(true)
							  	:acceptsMouseEvents(false)
			elseif ev:getType() ~= events.leftMouseDown then
				mod.touchBarWindow:backgroundColor{ white = 0 }
							  :movable(false)
							  :acceptsMouseEvents(true)
				mod.setLastLocation(mod.touchBarWindow:topLeft())
			end
		end
		return false
	end):start()
end

-- The Plugin
local plugin = {}

function plugin.init(deps)
	return mod
end

return plugin