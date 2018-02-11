--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.watchfolders.menuitem ===
---
--- Adds the "Setup Watch Folders" to the menu bar.

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.watchfolders.menuitem",
	group			= "core",
	dependencies	= {
		["core.menu.bottom"]			= "bottom",
		["core.watchfolders.manager"]	= "watchfolders",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	deps.bottom:addItem(10.2, function()
		return { title = i18n("setupWatchFolders"), fn = deps.watchfolders.show }
	end)
end

return plugin