--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.pluginactions ===
---
--- Controls Final Cut Pro's Titles.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("plgnactns")

local chooser			= require("hs.chooser")
local drawing			= require("hs.drawing")
local screen			= require("hs.screen")
local timer				= require("hs.timer")

local config			= require("cp.config")
local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local plugins			= require("cp.apple.finalcutpro.plugins")
local tools				= require("cp.tools")
local prop				= require("cp.prop")

local format			= string.format

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 3000
local MAX_SHORTCUTS 	= 5

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.init(actionmanager, generators, titles, transitions)
	mod._manager = actionmanager
	mod._actors = {
		[plugins.types.generator]	= generators,
		[plugins.types.title]		= titles,
		[plugins.types.transition]	= transitions,
	}

	mod._handlers = {}

	for type,_ in pairs(plugins.types) do
		local actionId = function(action)
			return format("%s:%s:%s", type, action.name, action.category)
		end

		mod._handlers[type] = actionmanager.addHandler(type)
		:onChoices(function(choices)
			-- get the effects of the specified type in the current language.
			local list = fcp:plugins():ofType(type)
			if list then
				for i,plugin in ipairs(list) do
					local action = { name = plugin.name, category = plugin.category }
					local subText = i18n(type .. "_group")
					if plugin.category then
						subText = subText..": "..plugin.category
					end
					if plugin.theme then
						subText = subText.." ("..plugin.theme..")"
					end
					choices:add(plugin.name)
						:subText(subText)
						:params(action)
						:id(actionId(action))
				end
			end
		end)
		:onExecute(function(action)
			local actor = mod._actors[type]
			if actor then
				actor.apply(action.name, action.category)
			else
				error(string.format("Unsupported plugin type: %s", type))
			end
		end)
		:onActionId(actionId)
	end

	-- reset the handler choices when the FCPX language changes.
	fcp.currentLanguage:watch(function(value)
		for _,handler in pairs(mod._handlers) do
			handler:reset()
			timer.doAfter(0.01, function() handler.choices:update() end)
		end
	end)

	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.pluginactions",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.action.manager"]					= "actionmanager",
		["finalcutpro.timeline.generators"]				= "generators",
		["finalcutpro.timeline.titles"]					= "titles",
		["finalcutpro.timeline.transitions"]			= "transitions",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod.init(deps.actionmanager, deps.generators, deps.titles, deps.transitions)
end

return plugin