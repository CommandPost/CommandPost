--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.accessibility ===
---
--- Accessibility Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local application			= require("hs.application")

local config				= require("cp.config")
local prop					= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugin.core.accessibility.systemPreferencesAlreadyOpen
--- Variable
--- Was System Preferences already open?
mod.systemPreferencesAlreadyOpen = false

--- plugin.core.accessibility.enabled <cp.prop: boolean; read-only>
--- Constant
--- Is `true` if Accessibility permissions have been enabled for CommandPost.
--- Plugins interested in being notfied about accessibility status should
--- `watch` this property.
mod.enabled = prop.new(hs.accessibilityState):watch(function(enabled)
	if enabled then
		--------------------------------------------------------------------------------
		-- Close System Preferences, unless it was already open:
		--------------------------------------------------------------------------------
		if not mod.systemPreferencesAlreadyOpen then
			local systemPrefs = application.applicationsForBundleID("com.apple.systempreferences")
			if systemPrefs and next(systemPrefs) ~= nil then
				systemPrefs[1]:kill()
			end
		end
		mod.completeSetupPanel()
	else
		mod.showSetupPanel()
	end
end)

--- plugin.core.accessibility.completeSetupPanel() -> none
--- Function
--- Called when the setup panel for accessibility was shown and is ready to complete.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.completeSetupPanel()
	if mod.showing then
		mod.showing = false
		mod.setup.nextPanel()
	end
end

--- plugin.core.accessibility.showSetupPanel() -> none
--- Function
--- Called when the Setup Panel should be shown to prompt the user about enabling Accessbility.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.showSetupPanel()
	mod.showing = true
	mod.setup.addPanel(mod.panel)
	mod.setup.show()
end

--- plugin.core.accessibility.init(setup, iconPath) -> table
--- Function
--- Initialises the module.
---
--- Parameters:
---  * setup - Dependancies setup
---  * iconPath - Path to the panel icon
---
--- Returns:
---  * The module as a table
function mod.init(setup, iconPath)

	-- TODO: Use this instead:
	-- /System/Library/PreferencePanes/UniversalAccessPref.prefPane/Contents/Resources/UniversalAccessPref.icns

	mod.setup = setup
	mod.panel = setup.panel.new("accessibility", 10)
		:addIcon(iconPath)
		:addParagraph(i18n("accessibilityNote"), true)
		:addButton({
			label		= i18n("enableAccessibility"),
			onclick		= function()
				local systemPrefs = application.applicationsForBundleID("com.apple.systempreferences")
				if systemPrefs and next(systemPrefs) ~= nil then
					mod.systemPreferencesAlreadyOpen = true
				end
				hs:accessibilityState(true)
			end,
		})
		:addButton({
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
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