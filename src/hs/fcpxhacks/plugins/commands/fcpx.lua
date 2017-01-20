-- The 'fcpx' command collection.
-- These are only active when FCPX is the active (ie. frontmost) application.

local commands					= require("hs.commands")
local fcp						= require("hs.finalcutpro")

local plugin = {}

function plugin.init()
	local cmds = commands:new("fcpx")
	
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