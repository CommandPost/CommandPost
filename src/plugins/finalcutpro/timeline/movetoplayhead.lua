--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local fcp								= require("cp.finalcutpro")
local log								= require("hs.logger").new("selectalltimelineclips")

-- Constants

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.moveToPlayhead()

	local clipboardManager = plugins("cp.plugins.clipboard.manager")

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
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

function plugin.init(deps)

	deps.fcpxCmds:add("cpMoveToPlayhead")
		:whenActivated(function() mod.moveToPlayhead() end)

	return mod

end

return plugin