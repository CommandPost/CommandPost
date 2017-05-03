--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
-- Adds a 'Preferences...' menu item to the menu.
--
-- Note: Has to be a separate plugin to avoid a circular dependency between
--       the menu manager and preferences manager.
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.watchfolders.menuitem",
	group			= "core",
	required		= true,
	dependencies	= {
		["core.menu.bottom"]			= "bottom",
		["core.watchfolders.manager"]	= "watchfolders",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	deps.bottom:addItem(5, function()
		return { title = i18n("setupWatchFolders"), fn = deps.watchfolders.show }
	end)

	--------------------------------------------------------------------------------
	-- Add separator:
	--------------------------------------------------------------------------------
	deps.bottom:addItem(6, function()
		return { title = "-" }
	end)

end

return plugin