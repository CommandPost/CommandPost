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
	fcp:watch({
		active 		= function()
			if not fcp:commandEditor():isShowing() and not fcp:mediaImport():isShowing() then
				--log.df("Final Cut Pro Commands Enabled")
				cmds:enable()
			end
		end,
		inactive	= function()
			--log.df("Final Cut Pro Commands Disabled")
			cmds:disable()
		end,
	})

	--------------------------------------------------------------------------------
	-- Disable when the Command Editor window is open:
	--------------------------------------------------------------------------------
	fcp:commandEditor():watch({
		show		= function()
			--log.df("Final Cut Pro Commands Disabled due to Command Editor")
			cmds:disable()
		end,
		hide		= function()
			if fcp:isShowing() then
				--log.df("Final Cut Pro Commands Enabled due to Command Editor")
				cmds:enable()
			end
		end,
	})

	--------------------------------------------------------------------------------
	-- Disable when the Media Import window is open:
	--------------------------------------------------------------------------------
	fcp:mediaImport():watch({
		show		= function()
			--log.df("Final Cut Pro Commands Dsiabled due to Media Import")
			cmds:disable()
		end,
		hide		= function()
			if fcp:isShowing() then
				--log.df("Final Cut Pro Commands Enabled due to Media Import")
				cmds:enable()
			end
		end,
	})

	return cmds
end

return plugin