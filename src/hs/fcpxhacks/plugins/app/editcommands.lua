local fcp			= require("hs.finalcutpro")
local settings		= require("hs.settings")

local module = {}

module.OPEN_COMMAND_EDITOR_PRIORITY = 1000

local function editCommands()
	fcp:launch()
	fcp:commandEditor():show()
end

local function createMenuItem()
	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local hacksInFcpx = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false
	
	if hacksInFcpx then
		return { title = i18n("openCommandEditor"), fn = editCommands, disabled = not fcp:isRunning() }
	else
		return nil
	end
end

local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.top"] = "top"
}

function plugin.init(deps)
	local top = deps.top
	
	top:addItem(module.OPEN_COMMAND_EDITOR_PRIORITY, createMenuItem)
	
	return editCommands
end

return plugin