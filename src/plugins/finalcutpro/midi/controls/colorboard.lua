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
	-- Angle Slider:				   0 to 360 (359 in Final Cut Pro 10.4)
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
			text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("puck") .. " " .. tostring(i),
			subText = i18n("midiColorBoardDescription"),
			fn = function(metadata)
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then
						local value = tools.round(metadata.controllerValue / 127*200-100)
						if metadata.controllerValue == 128/2 then value = 0 end
						colorBoard:show():applyPercentage("*", colorFunction[i], value)
					end
				end
			end,
		})

		--------------------------------------------------------------------------------
		-- Color (Percentage):
		--------------------------------------------------------------------------------
		deps.manager.controls:new("colorPercentagePuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("color") .. " " .. i18n("puck") .. " " .. tostring(i) .. " (" .. i18n("percentage") .. ")",
			subText = i18n("midiColorBoardDescription"),
			fn = function(metadata)
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then
						local value = tools.round(metadata.controllerValue / 127*200-100)
						if metadata.controllerValue == 128/2 then value = 0 end
						colorBoard:show():applyPercentage("color", colorFunction[i], value)
					end
				end
			end,
		})

		--------------------------------------------------------------------------------
		-- Color (Angle):
		--------------------------------------------------------------------------------
		deps.manager.controls:new("colorAnglePuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("color") .. " " .. i18n("puck") .. " " .. tostring(i) .. " (" .. i18n("angle") .. ")",
			subText = i18n("midiColorBoardDescription"),
			fn = function(metadata)
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then
						local angle = 360
						if fcp.isColorInspectorSupported() then
							angle = 359
						end
						local value = tools.round(metadata.controllerValue / (127/angle))
						if metadata.controllerValue == 128/2 then value = angle/2 end
						colorBoard:show():applyAngle("color", colorFunction[i], value)
					end
				end
			end,
		})

		--------------------------------------------------------------------------------
		-- Saturation:
		--------------------------------------------------------------------------------
		deps.manager.controls:new("saturationPuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("saturation") .. " " .. i18n("puck") .. " " .. tostring(i),
			subText = i18n("midiColorBoardDescription"),
			fn = function(metadata)
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then
						local value = tools.round(metadata.controllerValue / 127*200-100)
						if metadata.controllerValue == 128/2 then value = 0 end
						colorBoard:show():applyPercentage("saturation", colorFunction[i], value)
					end
				end
			end,
		})

		--------------------------------------------------------------------------------
		-- Exposure:
		--------------------------------------------------------------------------------
		deps.manager.controls:new("exposurePuck" .. tools.numberToWord(i), {
			group = "fcpx",
			text = string.upper(i18n("midi")) .. ": " .. i18n("colorBoard") .. " " .. i18n("exposure") .. " " .. i18n("puck") .. " " .. tostring(i),
			subText = i18n("midiColorBoardDescription"),
			fn = function(metadata)
				if metadata.controllerValue then
					local colorBoard = fcp:colorBoard()
					if colorBoard then
						local value = tools.round(metadata.controllerValue / 127*200-100)
						if metadata.controllerValue == 128/2 then value = 0 end
						colorBoard:show():applyPercentage("exposure", colorFunction[i], value)
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
	id				= "finalcutpro.midi.controls.colorboard",
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