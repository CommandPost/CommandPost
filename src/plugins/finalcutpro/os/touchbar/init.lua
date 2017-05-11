--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       T O U C H B A R     P L U G I N                      --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.os.touchbar ===
---
--- Virtual Touch Bar Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("touchbar")

local eventtap									= require("hs.eventtap")

local touchbar 									= require("hs._asm.touchbar")

local dialog									= require("cp.dialog")
local fcp										= require("cp.apple.finalcutpro")
local config									= require("cp.config")
local prop										= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY				= 1000

local LOCATION_DRAGGABLE 	= "Draggable"
local LOCATION_MOUSE		= "Mouse"
local LOCATION_TIMELINE		= "TimelineTopCentre"

local DEFAULT_VALUE 		= LOCATION_DRAGGABLE

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.os.touchbar.lastLocation <cp.prop: point table>
--- Field
--- The last known Virtual Touch Bar Location
mod.lastLocation = config.prop("lastTouchBarLocation")

--- plugins.finalcutpro.os.touchbar.location <cp.prop: string>
--- Field
--- The Virtual Touch Bar Location Setting
mod.location = config.prop("displayTouchBarLocation", DEFAULT_VALUE):watch(function() mod.update() end)

--- plugins.finalcutpro.os.touchbar.supported <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the plugin is supported on this OS.
mod.supported = prop(function() return touchbar.supported() end)

--- plugins.finalcutpro.os.touchbar.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("displayTouchBar", false):watch(function(enabled)
	--------------------------------------------------------------------------------
	-- Check for compatibility:
	--------------------------------------------------------------------------------
	if enabled and not mod.supported() then
		dialog.displayMessage(i18n("touchBarError"))
		mod.enabled(false)
	end
	if not enabled then
		mod.stop()
	end
end)

--- plugins.finalcutpro.os.touchbar.isActive <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the plugin is enabled and the TouchBar is supported on this OS.
mod.isActive = mod.enabled:AND(mod.supported):watch(function(active)
	if active then
		mod.show()
	else
		mod.hide()
	end
end)

--- plugins.finalcutpro.os.touchbar.updateLocation() -> none
--- Function
--- Updates the Location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateLocation()

	--------------------------------------------------------------------------------
	-- Get Settings:
	--------------------------------------------------------------------------------
	local displayTouchBarLocation = mod.location()

	--------------------------------------------------------------------------------
	-- Put it back to last known position:
	--------------------------------------------------------------------------------
	local lastLocation = mod.lastLocation()
	if lastLocation then
		mod.touchBar:topLeft(lastLocation)
	end

	--------------------------------------------------------------------------------
	-- Show Touch Bar at Top Centre of Timeline:
	--------------------------------------------------------------------------------
	local timeline = fcp:timeline()
	if displayTouchBarLocation == LOCATION_TIMELINE and timeline:isShowing() then
		--------------------------------------------------------------------------------
		-- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
		--------------------------------------------------------------------------------
		local viewFrame = timeline:contents():viewFrame()
		if viewFrame then
			local topLeft = {x = viewFrame.x + viewFrame.w/2 - mod.touchBar:getFrame().w/2, y = viewFrame.y + 20}
			mod.touchBar:topLeft(topLeft)
		end
	elseif displayTouchBarLocation == LOCATION_MOUSE then

		--------------------------------------------------------------------------------
		-- Position Touch Bar to Mouse Pointer Location:
		--------------------------------------------------------------------------------
		mod.touchBar:atMousePosition()

	end

	--------------------------------------------------------------------------------
	-- Save last Touch Bar Location to Settings:
	--------------------------------------------------------------------------------
	mod.lastLocation(mod.touchBar:topLeft())
end

--- plugins.finalcutpro.os.touchbar.update() -> none
--- Function
--- Updates the visibility and location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	-- Check if it's active.
	mod.isActive:update()
end

--- plugins.finalcutpro.os.touchbar.show() -> none
--- Function
--- Show the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
	--------------------------------------------------------------------------------
	-- Check if we need to show the Touch Bar:
	--------------------------------------------------------------------------------
	if fcp:isFrontmost() and mod.supported() and mod.enabled() then
		mod.start()
		mod.updateLocation()
		mod.touchBar:show()
	end
end

--- plugins.finalcutpro.os.touchbar.hide() -> none
--- Function
--- Hide the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.hide()
	if mod.supported() and mod.enabled() then
		mod.touchBar:hide()
	end
end

--- plugins.finalcutpro.os.touchbar.callback() -> none
--- Function
--- Callback Function for the Virtual Touch Bar
---
--- Parameters:
---  * obj - the touchbarObject the callback is for
---  * message - the message to the callback, either "didEnter" or "didExit"
---
--- Returns:
---  * None
function mod.callback(obj, message)
	if message == "didEnter" then
		mod.mouseInsideTouchbar = true
	elseif message == "didExit" then
		mod.mouseInsideTouchbar = false

		--------------------------------------------------------------------------------
		-- Just in case we got here before the eventtap returned the Touch Bar to normal:
		--------------------------------------------------------------------------------
		mod.touchBar:movable(false)
		mod.touchBar:acceptsMouseEvents(true)
		mod.lastLocation(mod.touchBar:topLeft())
	end
end

--- plugins.finalcutpro.os.touchbar.start() -> none
--- Function
--- Initialises the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
	if mod.supported() and not mod.touchBar then
		--------------------------------------------------------------------------------
		-- New Touch Bar:
		--------------------------------------------------------------------------------
		mod.touchBar = touchbar.new()

		--------------------------------------------------------------------------------
		-- Touch Bar Watcher:
		--------------------------------------------------------------------------------
		mod.touchBar:setCallback(mod.callback)

		--------------------------------------------------------------------------------
		-- Get last Touch Bar Location from Settings:
		--------------------------------------------------------------------------------
		local lastTouchBarLocation = mod.lastLocation()
		if lastTouchBarLocation ~= nil then	mod.touchBar:topLeft(lastTouchBarLocation) end

		--------------------------------------------------------------------------------
		-- Draggable Touch Bar:
		--------------------------------------------------------------------------------
		local events = eventtap.event.types
		mod.keyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
			if mod.mouseInsideTouchbar and mod.location() == LOCATION_DRAGGABLE then
				if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
					mod.touchBar:backgroundColor{ red = 1 }
									:movable(true)
									:acceptsMouseEvents(false)
				elseif ev:getType() ~= events.leftMouseDown then
					mod.touchBar:backgroundColor{ white = 0 }
								  :movable(false)
								  :acceptsMouseEvents(true)
					mod.lastLocation(mod.touchBar:topLeft())
				end
			end
			return false
		end):start()

		mod.update()

	end
end

--- plugins.finalcutpro.os.touchbar.stop() -> none
--- Function
--- Stops the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	--
	-- TO-DO: This needs better garbage collection (see: https://github.com/asmagill/hammerspoon_asm/issues/10)
	--
	mod.touchBar:hide()
	mod.touchBar = nil
	mod.keyboardWatcher:stop()
	mod.keyboardWatcher = nil
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.os.touchbar",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.tools"]		= "prefs",
		["finalcutpro.commands"]		= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Disable/Enable the Touchbar when the Command Editor/etc is open:
	--------------------------------------------------------------------------------
	fcp:commandEditor():watch({
		show		= function() mod.hide() end,
		hide		= function() mod.show() end,
	})
	fcp:mediaImport():watch({
		show		= function() mod.hide() end,
		hide		= function() mod.show() end,
	})
	fcp:watch({
		active		= function() mod.show() end,
		inactive	= function() mod.hide() end,
		move		= function() mod.update() end,
	})

	--------------------------------------------------------------------------------
	-- Menu items:
	--------------------------------------------------------------------------------
	local section = deps.prefs:addSection(PRIORITY)

	section:addMenu(2000, function() return i18n("touchBar") end)
		:addItems(1000, function()
			local location = mod.location()
			return {
				{ title = i18n("enableTouchBar"), 		fn = function() mod.enabled:toggle() end, 				checked = mod.enabled(),					disabled = not mod.supported() },
				{ title = "-" },
				{ title = string.upper(i18n("touchBarLocation") .. ":"),		disabled = true },
				{ title = i18n("topCentreOfTimeline"), 	fn = function() mod.setLocation(LOCATION_TIMELINE) end,		checked = location == LOCATION_TIMELINE,	disabled = not mod.supported() },
				{ title = i18n("mouseLocation"), 		fn = function() mod.setLocation(LOCATION_MOUSE) end,		checked = location == LOCATION_MOUSE, 		disabled = not mod.supported() },
				{ title = i18n("draggable"), 			fn = function() mod.setLocation(LOCATION_DRAGGABLE) end,	checked = location == LOCATION_DRAGGABLE, 	disabled = not mod.supported() },
				{ title = "-" },
				{ title = i18n("touchBarTipOne"), 		disabled = true },
				{ title = i18n("touchBarTipTwo"), 		disabled = true },
			}
		end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpToggleTouchBar")
		:activatedBy():ctrl():option():cmd("z")
		:whenActivated(function() mod.enabled:toggle() end)

	return mod
end

return plugin