--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.pluginactions ===
---
--- Adds Final Cut Pro Plugins (i.e. Effects, Generators, Titles and Transitions) to CommandPost Actions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log               = require("hs.logger").new("plgnactns")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local timer             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local plugins           = require("cp.apple.finalcutpro.plugins")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- GROUP -> string
-- Constant
-- The group.
local GROUP = "fcpx"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.pluginactions.init(actionmanager, generators, titles, transitions, audioeffects, videoeffects) -> module
--- Function
--- Initialise the module.
---
--- Parameters:
---  * `actionmanager` - Action Manager Plugin
---  * `generators` - Generators Plugin
---  * `titles` - Titles Plugin
---  * `transitions` - Transitions Plugin
---  * `audioeffects` - Audio Effects Plugin
---  * `videoeffects` - Video Effects Plugin
---
--- Returns:
---  * The module
function mod.init(actionmanager, generators, titles, transitions, audioeffects, videoeffects)
    mod._manager = actionmanager
    mod._actors = {
        [plugins.types.generator]       = generators,
        [plugins.types.title]           = titles,
        [plugins.types.transition]      = transitions,
        [plugins.types.audioEffect]     = audioeffects,
        [plugins.types.videoEffect]     = videoeffects,
    }

    mod._handlers = {}

    for pluginType,_ in pairs(plugins.types) do

        mod._handlers[pluginType] = actionmanager.addHandler(GROUP .. "_" .. pluginType, GROUP)
        :onChoices(function(choices)
            --------------------------------------------------------------------------------
            -- Get the effects of the specified type in the current language:
            --------------------------------------------------------------------------------
            local list = fcp:plugins():ofType(pluginType)
            if list then
                for _,plugin in ipairs(list) do
                    local subText = i18n(pluginType .. "_group")
                    local category = "none"
                    if plugin.category then
                        subText = subText..": "..plugin.category
                        category = plugin.category
                    end
                    local theme = "none"
                    if plugin.theme then
                        theme = plugin.theme
                        subText = subText.." ("..plugin.theme..")"
                    end
                    choices:add(plugin.name)
                        :subText(subText)
                        :params(plugin)
                        :id(GROUP .. "_" .. pluginType .. "_" .. plugin.name .. "_" .. category .. "_" .. theme)
                end
            end
        end)
        :onExecute(function(action)
            local actor = mod._actors[pluginType]
            if actor then
                actor.apply(action)
            else
                error(string.format("Unsupported plugin type: %s", pluginType))
            end
        end)
        :onActionId(function() return GROUP .. "_" .. pluginType end)
    end

    --------------------------------------------------------------------------------
    -- Reset the handler choices when the Final Cut Pro language changes:
    --------------------------------------------------------------------------------
    fcp.currentLocale:watch(function()
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
        ["core.action.manager"]                         = "actionmanager",
        ["finalcutpro.timeline.generators"]             = "generators",
        ["finalcutpro.timeline.titles"]                 = "titles",
        ["finalcutpro.timeline.transitions"]            = "transitions",
        ["finalcutpro.timeline.audioeffects"]           = "audioeffects",
        ["finalcutpro.timeline.videoeffects"]           = "videoeffects",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod.init(deps.actionmanager, deps.generators, deps.titles, deps.transitions, deps.audioeffects, deps.videoeffects)
end

return plugin