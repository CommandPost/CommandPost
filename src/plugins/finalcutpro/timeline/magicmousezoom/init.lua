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
	
	if touchdevice.available() then	
	
		-- TODO: We need to actually pick the Magic Mouse, not just the first Touchpad Device:
		
		local devices = touchdevice.devices()
		local deviceID = devices[1]
		
		local lastValue = nil
		
		mod.touchdevice = touchdevice.forDeviceID(deviceID):frameCallback(function(self, touches, time, frame)
			if #touches == 2 then -- Only trigger when two fingers are detected.
				local mods = eventtap.checkKeyboardModifiers()
				local mouseButtons = eventtap.checkMouseButtons()
				if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] and not next(mouseButtons) and fcp.isFrontmost() and fcp:timeline():isShowing() then
				
					-- TODO: Need to work out how best to work out the scrolling direction.
					
					--print("Touch Data: " .. hs.inspect(touches))
					
					currentValue = touches[1].normalizedVector.position.x

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
				end
			end
		end):start()
	end
			
end

--- plugins.finalcutpro.timeline.magicmousezoom.stop() -> none
--- Function
--- Disables the ability to zoon a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	if mod.touchdevice then
		mod.touchdevice:stop()
		mod.touchdevice = nil
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