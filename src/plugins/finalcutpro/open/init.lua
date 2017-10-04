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
local fcp			= require("cp.apple.finalcutpro")

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

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	deps.top
		:addItem(PRIORITY + 0.1, function()
			if fcp:isInstalled() then
				return { title = string.upper(i18n("finalCutPro")) .. ":", disabled = true }
			end
		end)

		:addItem(PRIORITY + 1, function()
			if fcp:isInstalled() then
				return { title = i18n("launch") .. " " .. i18n("finalCutPro"), fn = mod.openFinalCutPro }
			end
		end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global
	global:add("cpLaunchFinalCutPro")
		:activatedBy():ctrl():alt():cmd("l")
		:whenPressed(mod.openFinalCutPro)
		:groupedBy("finalCutPro")

	return mod
end

return plugin