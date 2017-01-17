local settings					= require("hs.settings")

--- The top menu section.

local PRIORITY = 1000

local function isShortcutsDisabled()
	return not (settings.get("fcpxHacks.menubarShortcutsEnabled") or false)
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.manager"] = "manager"
}

function plugin.init(dependencies)
	local shortcuts = dependencies.manager.addSection(PRIORITY)
	
	-- Disable the section if the shortcuts option is disabled
	shortcuts:setDisabledFn(isShortcutsDisabled)
	
	-- Add the separator and title for the section.
	shortcuts:addItems(0, function()
		return {
			{ title = "-" },
			{ title = string.upper(i18n("shortcuts")) .. ":", disabled = true },
		}
	end)
	
	return shortcuts
end

return plugin