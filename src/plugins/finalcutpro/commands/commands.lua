--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               F I N A L    C U T    P R O    C O M M A N D S               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.commands ===
---
--- The 'fcpx' command collection.
--- These are only active when FCPX is the active (ie. frontmost) application.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("fcpxCmds")

local commands					= require("cp.commands")
local fcp						= require("cp.apple.finalcutpro")

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
	cmds.isEnabled(fcp:isFrontmost())

	--------------------------------------------------------------------------------
	-- Switch to Final Cut Pro to activate:
	--------------------------------------------------------------------------------
	cmds:watch({
		activate	= function()
			--log.df("Final Cut Pro Activated by Commands Plugin")
			fcp:launch()
		end,
	})

	--------------------------------------------------------------------------------
	-- Enable/Disable as Final Cut Pro becomes Active/Inactive:
	--------------------------------------------------------------------------------
	fcp.isFrontmost:AND(fcp.isModalDialogOpen:NOT()):watch(function(enabled)
		cmds:isEnabled(enabled)
	end)

	return cmds
end

return plugin