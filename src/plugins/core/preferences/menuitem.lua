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
	id				= "core.preferences.menuitem",
	group			= "core",
	required		= true,
	dependencies	= {
		["core.menu.bottom"]			= "bottom",
		["core.preferences.manager"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	deps.bottom:addItem(PRIORITY, function()
		return { title = i18n("preferences") .. "...", fn = deps.prefs.show }
	end)
	
end

return plugin