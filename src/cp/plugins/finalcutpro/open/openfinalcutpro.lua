--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    O P E N   F I N A L   C U T   P R O                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local fcp			= require("cp.finalcutpro")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY = 3

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	function mod.openFinalCutPro()
		fcp:launch()
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.menu.top"] = "top",
		["cp.plugins.core.commands.global"] = "global",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		local top 		= deps.top
		local global	= deps.global

		top:addItem(PRIORITY + 1, function()
			return { title = i18n("open") .. " Final Cut Pro",	fn = mod.openFinalCutPro }
		end)

		global:add("cpLaunchFinalCutPro")
			:activatedBy():ctrl():alt():cmd("l")
			:whenPressed(openFcpx)

		return mod
	end

return plugin