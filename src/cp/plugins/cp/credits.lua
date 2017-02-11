local metadata			= require("cp.metadata")

--- The function

local PRIORITY = 3

local function aboutButton()
	hs.openAbout()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.helpandsupport"] = "helpandsupport"
}

function plugin.init(deps)
	deps.helpandsupport:addItem(PRIORITY, function()
		return { title = i18n("credits"),	fn = aboutButton }
	end)
	return aboutButton
end

return plugin