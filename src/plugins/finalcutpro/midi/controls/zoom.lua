--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       M I D I    C O N T R O L S                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.controls.zoom ===
---
--- Final Cut Pro MIDI Zoom Control.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("zoomMIDI")

local fcp				= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.control(metadata)
	if metadata.controllerValue then
		local appearance = fcp:timeline():toolbar():appearance()
		if appearance then
			--------------------------------------------------------------------------------
			-- MIDI Controller Value: 		0 to 127
			-- Zoom Slider:					0 to 10
			--------------------------------------------------------------------------------
			appearance:show():zoomAmount():setValue(metadata.controllerValue / (127/10) )
		end
	end
end

--- plugins.finalcutpro.midi.controls.zoom.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

	local params = {
		group = "fcpx",
		text = i18n("midiTimelineZoom"),
		subText = i18n("midiTimelineZoomDescription"),
		fn = mod.control,
	}
	deps.manager.controls:new("zoomSlider", params)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.midi.controls.zoom",
	group			= "finalcutpro",
	dependencies	= {
		["core.midi.manager"] = "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod.init(deps)
end

return plugin