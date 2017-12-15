--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       M I D I    C O N T R O L S                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.controls.colorboard ===
---
--- Final Cut Pro MIDI Color Controls.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("colorMIDI")

local fcp				= require("cp.apple.finalcutpro")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.midi.controls.colorboard.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

	--------------------------------------------------------------------------------
	-- MIDI Controller Value: 		   0 to 127
	-- Percentage Slider:			-100 to 100
	-- Angle Slider:				   0 to 360
	--------------------------------------------------------------------------------					
	
	--  * aspect - "color", "saturation" or "exposure"
	--  * property - "global", "shadows", "midtones", "highlights"

	local colorFunction = {
		[1] = "global",
		[2] = "shadows",
		[3] = "midtones",
		[4] = "highlights",
	}

	for i=1, 4 do
		
		--------------------------------------------------------------------------------
		-- Current Puck:
		--------------------------------------------------------------------------------		
		deps.manager.controls:new("puck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = "MIDI: Color Board Puck " .. tostring(i),
			subText = "Controls the Color Board via MIDI Controls",
			fn = function(metadata)						
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then				
						colorBoard:show():applyPercentage("*", colorFunction[i], tools.round(metadata.controllerValue / 127*200-100) )					
					end
				end
			end,
		})
		
		--------------------------------------------------------------------------------
		-- Color (Percentage):
		--------------------------------------------------------------------------------
		deps.manager.controls:new("colorPercentagePuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = "MIDI: Color Board Color Puck " .. tostring(i) .. " (Percentage)",
			subText = "Controls the Color Board via MIDI Controls",
			fn = function(metadata)						
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then				
						colorBoard:show():applyPercentage("color", colorFunction[i], tools.round(metadata.controllerValue / 127*200-100) )					
					end
				end
			end,
		})
		
		--------------------------------------------------------------------------------
		-- Color (Angle):
		--------------------------------------------------------------------------------		
		deps.manager.controls:new("colorAnglePuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = "MIDI: Color Board Color Puck " .. tostring(i) .. " (Angle)",
			subText = "Controls the Color Board via MIDI Controls",
			fn = function(metadata)						
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then				
						colorBoard:show():applyAngle("color", colorFunction[i], tools.round(metadata.controllerValue / (127/360)) )					
					end
				end
			end,
		})
		
		--------------------------------------------------------------------------------
		-- Saturation:
		--------------------------------------------------------------------------------
		deps.manager.controls:new("saturationPuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = "MIDI: Color Board Saturation Puck " .. tostring(i),
			subText = "Controls the Color Board via MIDI Controls",
			fn = function(metadata)						
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then				
						colorBoard:show():applyPercentage("saturation", colorFunction[i], tools.round(metadata.controllerValue / 127*200-100) )					
					end
				end
			end,
		})
		
		--------------------------------------------------------------------------------
		-- Exposure:
		--------------------------------------------------------------------------------
		deps.manager.controls:new("exposurePuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = "MIDI: Color Board Exposure Puck " .. tostring(i),
			subText = "Controls the Color Board via MIDI Controls",
			fn = function(metadata)						
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then				
						colorBoard:show():applyPercentage("exposure", colorFunction[i], tools.round(metadata.controllerValue / 127*200-100) )					
					end
				end
			end,
		})
		
	end
	
	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.midi.controls.color",
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