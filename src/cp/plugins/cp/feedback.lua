local metadata			= require("cp.metadata")
local sharing			= require("hs.sharing")
local console			= require("hs.console")
local screen			= require("hs.screen")

--- The function

local PRIORITY = 2

local mod = {}

-- TODO: Replace this with a hs.webview eventually...
function mod.emailBugReport()
	local mailer = sharing.newShare("com.apple.share.Mail.compose"):subject("[" .. metadata.scriptName .. " " .. metadata.scriptVersion .. "] Bug Report"):recipients({metadata.bugReportEmail})
																   :shareItems({"Please enter any notes, comments or suggestions here.\n\n---",console.getConsole(true), screen.mainScreen():snapshot()})
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