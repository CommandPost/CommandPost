--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      D E V E L O P E R     G U I D E                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.helpandsupport.developerguide ===
---
--- Developer Guide Menu Item.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local config			= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 1.1

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.developerguide.show() -> nil
--- Function
--- Opens the CommandPost Developer Guide in the Default Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
	os.execute('open "http://dev.commandpost.io/"')
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.helpandsupport.developerguide",
	group			= "core",
	dependencies	= {
		["core.menu.helpandsupport.commandpost"]	= "helpandsupport",
		["core.commands.global"] 					= "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global
	global:add("cpDeveloperGuide")
		:whenActivated(mod.show)
		:groupedBy("helpandsupport")

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	deps.helpandsupport:addItem(PRIORITY, function()
		return { title = i18n("developerGuide"),	fn = mod.show }
	end)
	:addSeparator(PRIORITY+0.1)

	return mod
end

return plugin