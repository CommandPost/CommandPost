local application		= require("hs.application")
local metadata			= require("cp.metadata")

--- The function

local PRIORITY = 9999999

local function quitScript()
	application.applicationsForBundleID(hs.processInfo["bundleID"])[1]:kill()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.bottom"] = "bottom"
}

function plugin.init(deps)
	deps.bottom:addSeparator(9999998):addItem(PRIORITY, function()
		return { title = i18n("quit"),	fn = quitScript }
	end)

	return quitScript
end

return plugin