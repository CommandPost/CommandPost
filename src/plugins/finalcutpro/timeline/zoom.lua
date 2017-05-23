--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.zoom ===
---
--- Allows you to zoom a timeline using your mouse scroll wheel (whilst holding down CONTROL+OPTION+COMMAND).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("zoom")

local eventtap							= require("hs.eventtap")

local fcp								= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.init()
	mod.mousetap = eventtap.new({eventtap.event.types.scrollWheel}, function(e)
		local mods = eventtap.checkKeyboardModifiers()
		if fcp.isFrontmost() and mods['ctrl'] and mods['alt'] and mods['cmd'] then
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.zoom",
	group = "finalcutpro",
	dependencies = {
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	mod.init()
	return mod
end

return plugin