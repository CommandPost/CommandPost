--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               V I R T U A L   T O U C H B A R     P L U G I N              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.touchbar.virtual ===
---
--- Virtual Touch Bar Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("virtualTouchBar")

local eventtap									= require("hs.eventtap")

local touchbar 									= require("hs._asm.undocumented.touchbar")

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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.LOCATION_TIMELINE		= "TimelineTopCentre"

mod.VISIBILITY_ALWAYS		= "Always"
mod.VISIBILITY_FCP			= "Final Cut Pro"

--- plugins.finalcutpro.touchbar.virtual.visibility <cp.prop: string>
--- Field
--- When should the Virtual Touch Bar be visible?
mod.visibility = config.prop("virtualTouchBarVisibility", VISIBILITY_FCP):watch(function(enabled)
	if mod.visibility() == VISIBILITY_ALWAYS then 
		mod.manager.virtual.show()
	else
		if fcp.isFrontmost() then 
			mod.manager.virtual.show()
		else
			mod.manager.virtual.hide()
		end
	end
end)

--- plugins.finalcutpro.touchbar.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
	--------------------------------------------------------------------------------
	-- Check for compatibility:
	--------------------------------------------------------------------------------
	if enabled and not mod.manager.supported() then
		dialog.displayMessage(i18n("touchBarError"))
		mod.enabled(false)
	end
	if enabled then
		mod.manager.virtual.start()
	else
		mod.manager.virtual.stop()
	end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.touchbar.virtual",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.tools"]		= "prefs",
		["finalcutpro.commands"]		= "fcpxCmds",
		["core.touchbar.manager"]		= "manager",
		["core.commands.global"] 		= "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Connect to Manager:
	--------------------------------------------------------------------------------
	mod.manager = deps.manager
	
	if mod.manager.supported() then

		--------------------------------------------------------------------------------
		-- Update Touch Bar Buttons when FCPX is active:
		--------------------------------------------------------------------------------
		fcp:watch({
			active		= function() mod.manager.groupStatus("fcpx", true) end,
			inactive	= function() mod.manager.groupStatus("fcpx", false) end,
		})

		--------------------------------------------------------------------------------
		-- Disable/Enable the Touchbar when the Command Editor/etc is open:
		--------------------------------------------------------------------------------
		fcp.isFrontmost:AND(fcp.isModalDialogOpen:NOT()):watch(function(active)
			if mod.visibility() == VISIBILITY_ALWAYS then	
				mod.manager.virtual.show()
			else
				if active then
					mod.manager.virtual.show()
				else
					mod.manager.virtual.hide()
				end
			end
		end)
	
		--------------------------------------------------------------------------------
		-- Update the Virtual Touch Bar position if either of the main windows move:
		--------------------------------------------------------------------------------
		fcp:primaryWindow().frame:watch(mod.manager.virtual.updateLocation)
		fcp:secondaryWindow().frame:watch(mod.manager.virtual.updateLocation)

		--------------------------------------------------------------------------------
		-- Add Callbacks to Control Location:
		--------------------------------------------------------------------------------
		mod.manager.virtual.updateLocationCallback:new("fcp", function() 
		
			local displayVirtualTouchBarLocation = mod.manager.virtual.location()
		
			--------------------------------------------------------------------------------
			-- Show Touch Bar at Top Centre of Timeline:
			--------------------------------------------------------------------------------
			local timeline = fcp:timeline()
			if timeline and displayVirtualTouchBarLocation == mod.LOCATION_TIMELINE and timeline:isShowing() then
				--------------------------------------------------------------------------------
				-- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
				--------------------------------------------------------------------------------
				local viewFrame = timeline:contents():viewFrame()
				if viewFrame then
					local topLeft = {x = viewFrame.x + viewFrame.w/2 - mod.manager.touchBar():getFrame().w/2, y = viewFrame.y + 20}
					mod.manager.touchBar():topLeft(topLeft)
				end
			elseif displayVirtualTouchBarLocation == LOCATION_MOUSE then

				--------------------------------------------------------------------------------
				-- Position Touch Bar to Mouse Pointer Location:
				--------------------------------------------------------------------------------
				mod.manager.touchBar():atMousePosition()

			end
		
		end)

		--------------------------------------------------------------------------------
		-- Menu items:
		--------------------------------------------------------------------------------
		local section = deps.prefs:addSection(PRIORITY)
		
		local LOCATION_DRAGGABLE 		= mod.manager.virtual.LOCATION_DRAGGABLE
		local LOCATION_MOUSE 			= mod.manager.virtual.LOCATION_MOUSE
		local LOCATION_TIMELINE			= mod.LOCATION_TIMELINE		
		
		local VISIBILITY_ALWAYS			= mod.VISIBILITY_ALWAYS
		local VISIBILITY_FCP			= mod.VISIBILITY_FCP

		if mod.manager.supported() then 
			section:addMenu(2000, function() return i18n("touchBar") end)
				:addItems(1000, function()
					local location = mod.manager.virtual.location()
					return {
						{ title = i18n("enableTouchBar"), 		fn = function() mod.enabled:toggle() end, 								checked = mod.enabled() },
						{ title = "-" },
						{ title = string.upper(i18n("visibility") .. ":"), disabled = true },												
						{ title = i18n("always"), 				fn = function() mod.visibility(VISIBILITY_ALWAYS) end, 					checked = mod.visibility() == VISIBILITY_ALWAYS },
						{ title = i18n("finalCutPro"), 			fn = function() mod.visibility(VISIBILITY_FCP) end, 					checked = mod.visibility() == VISIBILITY_FCP },				
						{ title = "-" },
						{ title = string.upper(i18n("location") .. ":"), disabled = true },
						{ title = i18n("topCentreOfTimeline"), 	fn = function() mod.manager.virtual.location(LOCATION_TIMELINE) end,	checked = mod.manager.virtual.location() == LOCATION_TIMELINE },
						{ title = i18n("mouseLocation"), 		fn = function() mod.manager.virtual.location(LOCATION_MOUSE) end,		checked = mod.manager.virtual.location() == LOCATION_MOUSE },
						{ title = i18n("draggable"), 			fn = function() mod.manager.virtual.location(LOCATION_DRAGGABLE) end,	checked = mod.manager.virtual.location() == LOCATION_DRAGGABLE },
						{ title = "-" },
						{ title = i18n("touchBarTipOne"), 		disabled = true },
						{ title = i18n("touchBarTipTwo"), 		disabled = true },
					}
				end)
		end
	
		--------------------------------------------------------------------------------
		-- Final Cut Pro Command:
		--------------------------------------------------------------------------------
		deps.fcpxCmds
			:add("cpToggleTouchBar")
			:activatedBy():ctrl():option():cmd("z")
			:whenActivated(function() mod.enabled:toggle() end)
		
		--------------------------------------------------------------------------------
		-- Global Command:
		--------------------------------------------------------------------------------
		deps.global
			:add("cpGlobalToggleTouchBar")
			:whenActivated(function() mod.enabled:toggle() end)	
			
	end
	
	return mod
end

function plugin.postInit()
	--------------------------------------------------------------------------------
	-- Show on Startup:
	--------------------------------------------------------------------------------
	if mod.manager.supported() and mod.manager.virtual.enabled() then
		if mod.visibility() == VISIBILITY_ALWAYS then 
			mod.manager.virtual.show()
		else
			if fcp.isFrontmost() then 
				mod.manager.virtual.show()
			end
		end
	end
end

return plugin