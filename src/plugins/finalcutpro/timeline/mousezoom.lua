--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.mousezoom ===
---
--- Allows you to zoom in or out of a Final Cut Pro timeline using the mechanical scroll wheel on your mouse or the Touch Pad on the Magic Mouse when holding down the OPTION modifier key.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("mousezoom")

local distributednotifications			= require("hs.distributednotifications")
local eventtap							= require("hs.eventtap")
local mouse								= require("hs.mouse")
local pathwatcher						= require("hs.pathwatcher")
local settings							= require("hs.settings")
local timer								= require("hs.timer")

local touchdevice						= require("hs._asm.undocumented.touchdevice")

local config							= require("cp.config")
local fcp								= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local ENABLED_DEFAULT 	= false

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.foundMagicMouse = false
mod.touchDevices = {}
mod.magicMouseIDs = {}	
mod.numberOfTouchDevices = 0

--- plugins.finalcutpro.timeline.mousezoom.update() -> none
--- Function
--- Checks to see whether or not we should enable the timeline zoom watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	if mod.enabled() then 
		mod.start()
	else
		mod.stop()
	end
end

--- plugins.finalcutpro.timeline.mousezoom.enabled <cp.prop: boolean>
--- Variable
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enablemousezoom", ENABLED_DEFAULT):watch(mod.update)

--- plugins.finalcutpro.timeline.mousezoom.stop() -> none
--- Function
--- Disables the ability to zoom a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()

	--------------------------------------------------------------------------------
	-- Clear any existing existing Touch Devices:
	--------------------------------------------------------------------------------
	if mod.touchDevices then	
		log.df("Stopping Touch Device Watcher(s).")	
		for i=0, #mod.touchDevices do 
			mod.touchDevices[i] = nil 
		end
		mod.touchDevices = nil
	end
	
	--------------------------------------------------------------------------------
	-- Destroy Mouse Watcher:
	--------------------------------------------------------------------------------
	if mod.distributedObserver then
		log.df("Stopping Distributed Observer.")
		mod.distributedObserver:stop()
		mod.distributedObserver = nil
	end

	--------------------------------------------------------------------------------
	-- Destroy Preferences Watcher:
	--------------------------------------------------------------------------------	
	if mod.preferencesWatcher then
		log.df("Stopping Preferences Watcher.")
		mod.preferencesWatcher:stop()
		mod.preferencesWatcher = nil
	end
	
	--------------------------------------------------------------------------------
	-- Destory Mouse Scroll Wheel Watcher:
	--------------------------------------------------------------------------------
	if mod.mousetap then
		log.df("Stopping Mouse Scroll Wheel Watcher.")
		mod.mousetap:stop()
		mod.mousetap = nil
	end
		
end

--- plugins.finalcutpro.timeline.mousezoom.findMagicMouses() -> none
--- Function
--- Find Magic Mouse Devices and adds them to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.findMagicMouses()

	-- Clear any existing existing Touch Devices:
	mod.stop()
	mod.foundMagicMouse = false
	
	if touchdevice.available() then	
		mod.magicMouseIDs = {}	
		local devices = touchdevice.devices()
		mod.numberOfTouchDevices = #devices
		if devices then 
			for _, id in ipairs(devices) do		
				local selectedDevice = touchdevice.forDeviceID(id)
				if selectedDevice then
					local selectedProductName = selectedDevice:details().productName 				
					if selectedProductName == "Magic Mouse" or selectedProductName == "Magic Mouse 2" then
						log.df("Found a Magic Mouse! ID: %s", id)						
						mod.magicMouseIDs[#mod.magicMouseIDs + 1] = id
						mod.foundMagicMouse = true
					end
				end		
			end
		end
	end
end

--- plugins.finalcutpro.timeline.mousezoom.timeInterval -> number
--- Variable
--- Time Interval between touch events.
mod.timeInterval = 0.005

-- touchCallback(self, touches, time, frame) -> none
-- Function
-- Touch Callback.
--
-- Parameters:
--  * `self` - the touch device object for which the callback is being invoked for
--  * `touch` - a table containing an array of touch tables as described in `hs._asm.undocumented.touchdevice.touchData` for each of the current touches detected by the touch device.
--  * `timestamp` - a number specifying the timestamp for the frame.
--  * `frame` - an integer specifying the frame ID
--
-- Returns:
--  * None
local function touchCallback(self, touches, time, frame)

	--------------------------------------------------------------------------------
	-- Only do stuff if FCPX is active:
	--------------------------------------------------------------------------------
 	if not fcp.isFrontmost() or not fcp:timeline():isShowing() then
 		return 
 	end

	--------------------------------------------------------------------------------
	-- Only single touch allowed:
	--------------------------------------------------------------------------------
	local numberOfTouches = #touches 
	if numberOfTouches == 1 then 
		-- All good!
	else
		return
	end
	
	--------------------------------------------------------------------------------
	-- Touch has been broken/released:
	--------------------------------------------------------------------------------
	local stage = touches[1].stage
	if stage == "breakTouch" then
		log.df("Magic Mouse Released.")
		mod.lastAbsoluteTime = nil
		mod.startPosition = nil
		fcp:timeline():toolbar():appearance():hide()
		return 
	end		
	
	--------------------------------------------------------------------------------
	-- Check Modifier Keys & Mouse Buttons:
	--------------------------------------------------------------------------------
	local mods = eventtap.checkKeyboardModifiers()
	local mouseButtons = eventtap.checkMouseButtons()
	if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] and not next(mouseButtons) then
		-- All good!
	else
		return
	end	

	--------------------------------------------------------------------------------
	-- Setup Current Position & Time: 
	--------------------------------------------------------------------------------
	local currentPosition = touches[1].normalizedVector.position.x
	local currentTime = touchdevice.absoluteTime()

	--------------------------------------------------------------------------------
	-- User has made contact with the Touch Device:
	--------------------------------------------------------------------------------	
	if stage == "makeTouch" then
		log.df("Magic Mouse Touched.")		
		fcp:timeline():toolbar():appearance():show()	
		
		local horizontalScrollBarUI = fcp:timeline():contents():horizontalScrollBarUI()
		if horizontalScrollBarUI then 		
			mod.scrollBarValue = horizontalScrollBarUI:value()
		else
			mod.scrollBarValue = nil
		end
			
		mod.startPosition = currentPosition							
		mod.lastAbsoluteTime = currentTime
	end
		
	--------------------------------------------------------------------------------
	-- Prevent Horizontal Scrolling:
	--------------------------------------------------------------------------------
	local horizontalScrollBarUI = fcp:timeline():contents():horizontalScrollBarUI()	
	if horizontalScrollBarUI and mod.scrollBarValue then 
		horizontalScrollBarUI:setAttributeValue("AXValue", mod.scrollBarValue)
	end
		
	--------------------------------------------------------------------------------
	-- Only trigger when touching and time interval is valid:
	--------------------------------------------------------------------------------
	if stage == "touching" and ( currentTime > mod.lastAbsoluteTime + mod.timeInterval ) then	
		if mod.scrollDirection == "normal" then 		
		
			--------------------------------------------------------------------------------
			--------------------------------------------------------------------------------
			-- THIS ISN'T WORKING. NEED TO RETHINK THE MATHS/LOGIC.
			-- NEEDS TO BE MORE LIKE SCREENFLOW.
			--------------------------------------------------------------------------------
			--------------------------------------------------------------------------------
				
			local currentValue = fcp:timeline():toolbar():appearance():show():zoomAmount():getValue()			
			local difference = currentPosition - mod.startPosition
							
			fcp:timeline():toolbar():appearance():show():zoomAmount():setValue(currentValue + (difference * 10))

		else
		
			-- Do the opposite of the above, once we work out the above.
		
		end						
	end								
	
	--------------------------------------------------------------------------------
	-- Update Absolute Time:
	--------------------------------------------------------------------------------			
	mod.lastAbsoluteTime = currentTime
		
end			

--- plugins.finalcutpro.timeline.mousezoom.start() -> none
--- Function
--- Enables the ability to zoon a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()		

	--------------------------------------------------------------------------------
	-- Monitor Touch Devices:
	--------------------------------------------------------------------------------
	mod.findMagicMouses()
	if not mod.touchDevices then mod.touchDevices = {} end
	if mod.numberOfTouchDevices >= 1 then 	
		for _, id in ipairs(mod.magicMouseIDs) do					
			mod.touchDevices[id] = touchdevice.forDeviceID(id):frameCallback(touchCallback):start()		
		end								
	end	
	
	--------------------------------------------------------------------------------
	-- Debugging:
	--------------------------------------------------------------------------------
	if mod.foundMagicMouse then
		log.df("Magic Mouse Mode Enabled.")
	else
		log.df("Mechanical Mouse Mode Enabled.")
	end
	
	--------------------------------------------------------------------------------
	-- Setup Mouse Watcher:
	--------------------------------------------------------------------------------
	log.df("Starting Distributed Observer.")
	mod.distributedObserver = distributednotifications.new(function(name)	
	    if name == "com.apple.MultitouchSupport.HID.DeviceAdded" then
	    	log.df("New Multi-touch Device Detected. Re-scanning...")
	    	mod.stop()
	    	mod.update()
	    end	    
	end):start()
		
	--------------------------------------------------------------------------------
	-- Setup Preferences Watcher:
	--------------------------------------------------------------------------------
	mod.preferencesWatcher = pathwatcher.new("~/Library/Preferences/", function(files) 
		local doReload = false
		for _,file in pairs(files) do
			if file:sub(-24) == ".GlobalPreferences.plist" then
				doReload = true
			end
		end
		if doReload then
			log.df("Preferences Updated.")
			--------------------------------------------------------------------------------
			-- Cache Scroll Direction:
			--------------------------------------------------------------------------------
			mod.scrollDirection = mouse.scrollDirection()
		end
	end):start()
	
	
	--------------------------------------------------------------------------------
	-- Setup Mouse Scroll Wheel Watcher:
	--------------------------------------------------------------------------------
	mod.mousetap = eventtap.new({eventtap.event.types.scrollWheel}, function(e)		
		local mods = eventtap.checkKeyboardModifiers()
		local mouseButtons = eventtap.checkMouseButtons()
		if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] and not next(mouseButtons) and fcp.isFrontmost() and fcp:timeline():isShowing() then		
			if mod.foundMagicMouse then 			
				--log.df("OVERRIDING MOUSE SCROLL!")
				return true
			else
				local direction = e:getProperty(eventtap.event.properties.scrollWheelEventDeltaAxis1)				
				if mod.scrollDirection == "normal" then				
					if direction >= 1 then
						log.df("Zoom In")
						fcp:selectMenu({"View", "Zoom In"})
						return false
					else
						log.df("Zoom Out")
						fcp:selectMenu({"View", "Zoom Out"})
						return false
					end			
				else				
					if direction >= 1 then
						log.df("Zoom Out")
						fcp:selectMenu({"View", "Zoom Out"})
						return false
					else
						log.df("Zoom In")
						fcp:selectMenu({"View", "Zoom In"})
						return false						
					end			
				end
			end
		end
	end):start()
	
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.mousezoom",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.preferences.app"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)	

	--------------------------------------------------------------------------------
	-- Cache Scroll Direction:
	--------------------------------------------------------------------------------
	mod.scrollDirection = mouse.scrollDirection()
					
	--------------------------------------------------------------------------------
	-- Update:
	--------------------------------------------------------------------------------				
	mod.update()
	
	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs.panel then
		deps.prefs.panel
			:addHeading(100, i18n("modifierHeading"))
			:addCheckbox(101,
			{
				label = i18n("allowZoomingWithOptionKey"),
				onchange = function(_, params) mod.enabled(params.checked) end,
				checked = mod.enabled,
			}
		)
	end
	
	return mod
end

return plugin