--- The 'Preferences' menu section

local PRIORITY = 8888889

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.bottom"] = "bottom"
}

function plugin.init(dependencies)
	local section = dependencies.bottom:addSection(PRIORITY)

	return section
		:addSeparator(100)
		:addMenu(0, function() return i18n("helpAndSupport") end)
end

return plugin