--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    O P E N   F I N A L   C U T   P R O                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.open ===
---
--- Opens Final Cut Pro via Global Shortcut & Menubar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local fcp			= require("cp.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 3

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.open.openFinalCutPro() -> none
--- Function
--- Opens Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openFinalCutPro()
	fcp:launch()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.open",
	group = "finalcutpro",
	dependencies = {
		["core.menu.top"] = "top",
		["core.commands.global"] = "global",
	}
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
		:whenPressed(mod.openFinalCutPro)

	return mod
end

return plugin