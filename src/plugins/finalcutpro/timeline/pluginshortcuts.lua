--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.pluginshortcuts ===
---
--- Controls Final Cut Pro's Titles.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

local plugins							= require("cp.apple.finalcutpro.plugins")
local prop								= require("cp.prop")
local tools								= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local MAX_SHORTCUTS = 5

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.init(actionmanager)
	mod._manager = actionmanager
end

mod.shortcuts = prop(
	function()
		return config.get(fcp:currentLanguage() .. ".videoEffectShortcuts", {})
	end,
	function(value)
		config.set(fcp:currentLanguage() .. ".videoEffectShortcuts", value)
	end
)

function mod.setShortcut(number, value)
	assert(number >= 1 and number <= MAX_SHORTCUTS)
	local shortcuts = mod.shortcuts()
	shortcuts[number] = value
	mod.shortcuts(shortcuts)
end

--- plugins.finalcutpro.timeline.pluginshortcuts.assignShortcut(shortcutNumber, handlerId) -> nothing
--- Function
--- Asks the user to assign the specified video effect shortcut number to a selected effect.
--- A chooser will be displayed, and the selected item will become the shortcut.
---
--- Parameters:
--- * `shortcutNumber`	- The shortcut number, between 1 and 5, which is being assigned.
---
--- Returns:
--- * Nothing
function mod.assignShortcut(shortcutNumber, handlerId)
	mod._shortcutNumber = shortcutNumber

	local activator = mod._actionmanager.getActivator("finalcutpro.timeline.plugin.shortcuts")
		:allowHandlers(handlerId)
		:configurable(false)
		:onExecute(function(handler, action)
			activator:hide()
			if action ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				mod.setShortcut(handlerId, mod._shortcutNumber, action)
			end
		end)

	activator:show()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------

local plugin = {
	id = "finalcutpro.timeline.pluginshortcuts",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.timeline"]					= "menu",
		["finalcutpro.commands"]						= "fcpxCmds",
		["finalcutpro.action.manager"]					= "actionmanager",
		["finalcutpro.timeline.generators"]				= "generators",
		["finalcutpro.timeline.titles"]					= "titles",
		["finalcutpro.timeline.transitions"]			= "transitions",
	}
}

function plugin.init(deps)
	mod.init(deps.actionmanager)

	local menu = deps.menu:addMenu(PRIORITY, function() return i18n("pluginShortcuts") end)

	-- loop through the plugin types
	for _,type in pairs(plugins.types) do
		-- The 'Assign Shortcuts' menu
		local menu = menu:addMenu(PRIORITY, function() return i18n(type.."_action") end)

		menu:addItems(1000, function()
			--------------------------------------------------------------------------------
			-- Effects Shortcuts:
			--------------------------------------------------------------------------------
			local listUpdated 		= mod.listUpdated()
			local effectsShortcuts	= mod.getShortcuts()

			local items = {}

			for i = 1,MAX_SHORTCUTS do
				local shortcutName = effectsShortcuts[i] or i18n("unassignedTitle")
				items[i] = { title = i18n("pluginShortcutTitle", { number = i, title = shortcutName}), fn = function() mod.assignShortcut(i) end,	disabled = not listUpdated }
			end

			return items
		end)

		-- Commands with default shortcuts
		local fcpxCmds = deps.fcpxCmds
		for i = 1, MAX_SHORTCUTS do
			fcpxCmds:add("cpEffects"..tools.numberToWord(i))
				:activatedBy():ctrl():shift(tostring(i))
				:whenPressed(function() mod.apply(i) end)
		end
	end

	return mod
end

return plugin