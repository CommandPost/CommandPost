local fcp			= require("cp.finalcutpro")

--- The function

local PRIORITY = 3

local function openFcpx()
	fcp:launch()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.top"] = "top",
	["cp.plugins.commands.global"] = "global",
}

function plugin.init(deps)
	local top 		= deps.top
	local global	= deps.global

	top:addItem(PRIORITY + 1, function()
		return { title = i18n("open") .. " Final Cut Pro",	fn = openFcpx }
	end)

	global:add("cpLaunchFinalCutPro")
		:activatedBy():ctrl():alt():cmd("l")
		:whenPressed(openFcpx)

	return openFcpx
end

return plugin