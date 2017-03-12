-- The 'fcpx' command collection.
-- These are only active when FCPX is the active (ie. frontmost) application.

local commands					= require("cp.commands")
local fcp						= require("cp.finalcutpro")
local log						= require("hs.logger").new("fcpxCmds")

local plugin = {}

function plugin.init()
	local cmds = commands:new("fcpx")
	
	-- switch to fcp to activate
	cmds:watch({
		activate	= function() log.df("activated"); fcp:launch() end,
	})

	-- enable/disable as fcpx becomes active/inactive
	fcp:watch({
		active 		= function() cmds:enable() end,
		inactive	= function() cmds:disable() end,
	})

	-- disable when the Command Editor window is open:
	fcp:commandEditor():watch({
		show		= function() cmds:disable() end,
		hide		= function() cmds:enable() end,
	})

	-- disable when the Media Import window is open:
	fcp:mediaImport():watch({
		show		= function() cmds:disable() end,
		hide		= function() cmds:enable() end,
	})

	return cmds
end

return plugin