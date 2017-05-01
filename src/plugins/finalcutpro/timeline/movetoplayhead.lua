--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.movetoplayhead ===
---
--- Move To Playhead.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("selectalltimelineclips")

local fcp								= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.movetoplayhead.moveToPlayhead() -> nil
--- Function
--- Move to Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.moveToPlayhead()

	local clipboardManager = mod.clipboardManager

	clipboardManager.stopWatching()

	if not fcp:performShortcut("Cut") then
		log.ef("Failed to trigger the 'Cut' Shortcut.\n\nError occurred in moveToPlayhead().")
		timer.doAfter(2, function() clipboardManager.startWatching() end)
		return false
	end

	if not fcp:performShortcut("Paste") then
		log.ef("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in moveToPlayhead().")
		timer.doAfter(2, function() clipboardManager.startWatching() end)
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
	id = "finalcutpro.timeline.movetoplayhead",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]			= "fcpxCmds",
		["finalcutpro.clipboard.manager"]	= "clipboardManager",
	}
}

function plugin.init(deps)

	mod.clipboardManager = deps.clipboardManager

	deps.fcpxCmds:add("cpMoveToPlayhead")
		:whenActivated(function() mod.moveToPlayhead() end)

	return mod

end

return plugin