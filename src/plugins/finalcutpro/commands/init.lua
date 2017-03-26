--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               F I N A L    C U T    P R O    C O M M A N D S               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The 'fcpx' command collection.
--- These are only active when FCPX is the active (ie. frontmost) application.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("fcpxCmds")

local commands					= require("cp.commands")
local fcp						= require("cp.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.commands",
	group			= "finalcutpro",
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init()
	local cmds = commands:new("fcpx")

	--------------------------------------------------------------------------------
	-- Switch to Final Cut Pro to activate:
	--------------------------------------------------------------------------------
	cmds:watch({
		activate	= function() log.df("activated"); fcp:launch() end,
	})

	--------------------------------------------------------------------------------
	-- Enable/Disable as Final Cut Pro becomes Active/Inactive:
	--------------------------------------------------------------------------------
	fcp:watch({
		active 		= function() cmds:enable() end,
		inactive	= function() cmds:disable() end,
	})

	--------------------------------------------------------------------------------
	-- Disable when the Command Editor window is open:
	--------------------------------------------------------------------------------
	fcp:commandEditor():watch({
		show		= function() cmds:disable() end,
		hide		= function() cmds:enable() end,
	})

	--------------------------------------------------------------------------------
	-- Disable when the Media Import window is open:
	--------------------------------------------------------------------------------
	fcp:mediaImport():watch({
		show		= function() cmds:disable() end,
		hide		= function() cmds:enable() end,
	})

	return cmds
end

return plugin