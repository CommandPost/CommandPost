local prop					= require("cp.prop")

local mod = {}

--- plugin.core.accessibility.enabled <cp.prop: boolean; read-only>
--- Constant
--- Is `true` if Accessibility permissions have been enabled for CommandPost.
--- Plugins interested in being notfied about accessibility status should
--- `watch` this property.
mod.enabled = prop.new(hs.accessibilityState):watch(function(enabled)
	if enabled then
		mod.completeSetupPanel()
	else
		mod.showSetupPanel()
	end
end)

-- Called when the setup panel for accessibility was shown and is ready to complete.
function mod.completeSetupPanel()
	if mod.showing then
		mod.showing = false
		mod.setup.nextPanel()
	end
end

-- Called when the Setup Panel should be shown to prompt the user about enabling Accessbility.
function mod.showSetupPanel()
	mod.showing = true
	mod.setup.addPanel(mod.panel)
	mod.setup.show()
end

function mod.init(setup, iconPath)
	mod.setup = setup
	mod.panel = setup.panel.new("accessibility", 10)
		:addIcon(10, {src = iconPath})
		:addParagraph(i18n("accessibilityNote"), true)
		:addButton(1, {
			label		= i18n("enableAccessibility"),
			onclick		= function()
				hs:accessibilityState(true)
			end,
		})
		:addButton(2, {
			label		= i18n("quit"),
			onclick		= function() config.application():kill() end,
		})
	
	-- Get updated when the accessibility state changes
	hs.accessibilityStateCallback = function()
		mod.enabled:update()
	end
	
	-- Update to the current state
	mod.enabled:update()
	
	return mod
end

local plugin = {
	id				= "core.accessibility",
	group			= "core",
	required		= true,
	dependencies	= {
		["core.setup"]	= "setup",
	}
}

function plugin.init(deps, env)
	return mod.init(deps.setup, env:pathToAbsolute("images/accessibility_icon.png"))
end


return plugin