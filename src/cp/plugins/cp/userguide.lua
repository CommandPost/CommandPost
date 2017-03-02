local metadata			= require("cp.metadata")

--- The function

local PRIORITY = 1

local function helpButton()
	os.execute('open "http://help.commandpost.io/"')
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.helpandsupport"] = "helpandsupport"
}

function plugin.init(deps)
	deps.helpandsupport:addItem(PRIORITY, function()
		return { title = i18n("userGuide"),	fn = helpButton }
	end)
	return helpButton
end

return plugin