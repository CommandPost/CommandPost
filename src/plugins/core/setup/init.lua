local config			= require("cp.config")

local mod = {}

mod.FIRST_PRIORITY	= 0
mod.LAST_PRIORITY	= 1000

mod.complete = config.prop("setupComplete", false):watch(function(complete)
	if not complete then
		mod.addWelcomePanels()
	end
end)

mod.incomplete = mod.complete:NOT()

function mod.addWelcomePanels()
	mod.welcome.addPanel(mod.introPanel)
	mod.welcome.addPanel(mod.outroPanel)
	mod.welcome.show()
end

function mod.init(welcome, iconPath)
	mod.welcome = welcome
	mod.iconPath = iconPath
	
	mod.introPanel = welcome.panel.new("intro", mod.FIRST_PRIORITY)
		:addIcon(10, {src = mod.iconPath})
		:addHeading(20, config.appName)
		:addSubHeading(30, i18n("welcomeTagLine"))
		:addParagraph(40, i18n("welcomeIntro"), true)
		:addButton(1, {
			value	= i18n("continue"),
			onclick = function() welcome.nextPanel() end,
		})
		:addButton(2, {
			value	= i18n("quit"),
			onclick	= function() config.application():kill() end,
		})
	
	mod.outroPanel = welcome.panel.new("outro", mod.LAST_PRIORITY)
		:addIcon(10, {src = mod.iconPath})
		:addSubHeading(30, i18n("completeHeading"))
		:addParagraph(40, i18n("completeText"), true)
		:addButton(1, {
			value	= i18n("close"),
			onclick	= function()
				mod.complete(true)
				welcome.nextPanel()
			end,
		})

		-- update the complete status
	mod.complete:update()
	
	return mod
end

local plugin = {
	id				= "core.setup",
	group			= "core",
	dependencies	= {
		["core.welcome.manager"]	= "welcome",
	}
}

function plugin.init(deps, env)
	return mod.init(deps.welcome, env:pathToAbsolute("images/commandpost_icon.png"))
end

return plugin