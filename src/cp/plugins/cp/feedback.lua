local feedback			= require("cp.feedback")
local metadata			= require("cp.metadata")

--- The function

local PRIORITY = 2

local mod = {}

function mod.emailBugReport()
	feedback.showFeedback()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.helpandsupport"] = "helpandsupport"
}

function plugin.init(deps)
	deps.helpandsupport:addItem(PRIORITY, function()
		return { title = i18n("provideFeedback"),	fn = mod.emailBugReport }
	end)

	return mod
end

return plugin