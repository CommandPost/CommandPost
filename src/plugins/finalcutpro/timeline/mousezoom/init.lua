--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.mousezoom ===
---
--- Allows you to zoom a timeline using your mouse scroll wheel (whilst holding down the OPTION key).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("mousezoom")

local eventtap							= require("hs.eventtap")
local touchdevice						= require("hs._asm.undocumented.touchdevice")

local config							= require("cp.config")
local fcp								= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local ENABLED_DEFAULT 	= true

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
--- Constant
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enableMouseZoom", ENABLED_DEFAULT):watch(mod.update)

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
	mod.mousetap = eventtap.new({eventtap.event.types.scrollWheel}, function(e)
		local mods = eventtap.checkKeyboardModifiers()
		local mouseButtons = eventtap.checkMouseButtons()
		if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] and not next(mouseButtons) and fcp.isFrontmost() and fcp:timeline():isShowing() then
			local direction = e:getProperty(eventtap.event.properties.scrollWheelEventDeltaAxis1)
			if direction >= 1 then
				--log.df("Zoom In")
				fcp:selectMenu({"View", "Zoom In"})
			else
				--log.df("Zoom Out")
				fcp:selectMenu({"View", "Zoom Out"})
			end			
		end
	end):start()
end

--- plugins.finalcutpro.timeline.mousezoom.stop() -> none
--- Function
--- Disables the ability to zoon a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	if mod.mousetap then 
		mod.mousetap:stop()
		mod.mousetap = nil
	end
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
	
	mod.update()
	
	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs.panel then
		deps.prefs.panel:addHeading(100, i18n("modifierHeading"))

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