--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.magicmousezoom ===
---
--- Allows you to zoom a timeline using your Magic Mouse (whilst holding down the OPTION key).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("magicmousezoom")

local eventtap							= require("hs.eventtap")
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

mod.touchDevices = {}
mod.magicMouseIDs = {}	
mod.numberOfTouchDevices = 0

--- plugins.finalcutpro.timeline.magicmousezoom.update() -> none
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

--- plugins.finalcutpro.timeline.magicmousezoom.enabled <cp.prop: boolean>
--- Constant
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enablemagicmousezoom", ENABLED_DEFAULT):watch(mod.update)

--- plugins.finalcutpro.timeline.magicmousezoom.stop() -> none
--- Function
--- Disables the ability to zoom a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	-- Clear any existing existing Touch Devices:
	if mod.touchDevices then		
		for i=0, #mod.touchDevices do 
			mod.touchDevices[i] = nil 
		end
		mod.touchDevices = nil
	end
end

--- plugins.finalcutpro.timeline.magicmousezoom.findMagicMouses() -> none
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
					end
				end		
			end
		end
	end
end

mod.timeInterval = 0.09

local function touchCallback(self, touches, time, frame)
	local currentTime = touchdevice.absoluteTime()
	if not mod.absoluteTime then mod.absoluteTime = currentTime end
	if #touches == 1 and touches[1].stage == "touching" and currentTime > mod.absoluteTime + mod.timeInterval then -- Only trigger when one finger is detected.
		local mods = eventtap.checkKeyboardModifiers()
		local mouseButtons = eventtap.checkMouseButtons()
		if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] and not next(mouseButtons) and fcp.isFrontmost() and fcp:timeline():isShowing() then
		
			-- TODO: Need to work out how best to work out the scrolling direction.
			
			log.df("touchdevice.absoluteTime(): %s", touchdevice.absoluteTime())
			
			
			
			--print("Touch Data: " .. hs.inspect(touches))
			
			currentValue = touches[1].absoluteVector.position.x

			if lastValue then 
				if lastValue > currentValue then
					log.df("Zoom In")
					fcp:selectMenu({"View", "Zoom In"})
				else
					log.df("Zoom Out")
					fcp:selectMenu({"View", "Zoom Out"})
				end
			end										
			lastValue = currentValue
			
			mod.absoluteTime = currentTime					
		end
	end
end			

--- plugins.finalcutpro.timeline.magicmousezoom.start() -> none
--- Function
--- Enables the ability to zoon a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()		
	mod.findMagicMouses()
	if not mod.touchDevices then mod.touchDevices = {} end
	if mod.numberOfTouchDevices >= 1 then 	
		for _, id in ipairs(mod.magicMouseIDs) do					
			mod.touchDevices[id] = touchdevice.forDeviceID(id):frameCallback(touchCallback):start()		
		end		
	end	
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.magicmousezoom",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.preferences.app"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)	
	
	mod.update()
	
	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs.panel then
		deps.prefs.panel:addCheckbox(102,
			{
				label = i18n("allowZoomingWithMagicMouse"),
				onchange = function(_, params) mod.enabled(params.checked) end,
				checked = mod.enabled,
			}
		)
	end
	
	return mod
end

return plugin