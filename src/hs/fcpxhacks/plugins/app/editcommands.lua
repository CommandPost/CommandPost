local fcp			= require("hs.finalcutpro")
local settings		= require("hs.settings")

local PRIORITY = 1000

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

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.top"] = "top"
}

function plugin.init(deps)
	-- Add the menu item to the top section.
	deps.top:addItem(PRIORITY, createMenuItem)
	
	return editCommands
end

return plugin