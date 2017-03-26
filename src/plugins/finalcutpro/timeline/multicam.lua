--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local fcp								= require("cp.finalcutpro")

local log								= require("hs.logger").new("multicam")

-- Constants:

local MAX_ANGLES 						= 16
local ANGLE_TYPES 						= {"Video", "Audio", "Both"}

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

function mod.cutAndSwitchMulticam(whichMode, whichAngle)

	if whichMode == "Audio" then
		if not fcp:performShortcut("MultiAngleEditStyleAudio") then
			log.ef("We were unable to trigger the 'Cut/Switch Multicam Audio Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
			return false
		end
	end

	if whichMode == "Video" then
		if not fcp:performShortcut("MultiAngleEditStyleVideo") then
			log.ef("We were unable to trigger the 'Cut/Switch Multicam Video Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
			return false
		end
	end

	if whichMode == "Both" then
		if not fcp:performShortcut("MultiAngleEditStyleAudioVideo") then
			log.ef("We were unable to trigger the 'Cut/Switch Multicam Audio and Video' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
			return false
		end
	end

	if not fcp:performShortcut("CutSwitchAngle" .. tostring(string.format("%02d", whichAngle))) then
		log.ef("We were unable to trigger the 'Cut and Switch to Viewer Angle " .. tostring(whichAngle) .. "' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
		return false
	end

	return true

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------

local plugin = {
	id = "finalcutpro.timeline.multicam",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

function plugin.init(deps)

	for i = 1, MAX_ANGLES do
    	for _, whichType in ipairs(ANGLE_TYPES) do
			deps.fcpxCmds:add("cpCutSwitchAngle" .. string.format("%02d", tostring(i)) .. whichType)
				:titled(i18n("cpCutSwitch" .. whichType .. "Angle_customTitle", {count = i}))
				:whenActivated(function() mod.cutAndSwitchMulticam(whichType, i) end)
		end
	end

	return mod
end

return plugin