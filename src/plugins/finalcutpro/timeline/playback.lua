--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.playback ===
---
--- Playback Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local fcp							= require("cp.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.playback.play() -> nil
--- Function
--- 'Play' in Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.play()
	fcp:performShortcut("PlayPause")
end

--- plugins.finalcutpro.timeline.playback.pause() -> nil
--- Function
--- 'Pause' in Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.pause()
	mod.play()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.playback",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	local cmds = deps.fcpxCmds

	cmds:add("cpPlay")
		:whenActivated(mod.play)

	cmds:add("cpPause")
		:whenActivated(mod.pause)

	return mod
end

return plugin