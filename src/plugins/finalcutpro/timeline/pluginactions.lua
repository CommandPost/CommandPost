--- === plugins.finalcutpro.timeline.pluginactions ===
---
--- Adds Final Cut Pro Plugins (i.e. Effects, Generators, Titles and Transitions) to CommandPost Actions.

local require = require

local log				= require("hs.logger").new("pluginActions")

local timer             = require("hs.timer")
local image             = require("hs.image")

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local plugins           = require("cp.apple.finalcutpro.plugins")

local imageFromPath     = image.imageFromPath

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- GROUP -> string
-- Constant
-- The group.
local GROUP = "fcpx"

-- ICON_PATH -> string
-- Constant
-- Path to the icons.
local ICON_PATH = config.basePath .. "/plugins/finalcutpro/console/images/"

-- ICONS -> table
-- Constant
-- A table of Final Cut Pro plugin icons.
local ICONS = {
    audioEffect = imageFromPath(ICON_PATH .. "audioEffect.png"),
    generator = imageFromPath(ICON_PATH .. "generator.png"),
    title = imageFromPath(ICON_PATH .. "title.png"),
    transition = imageFromPath(ICON_PATH .. "transition.png"),
    videoEffect = imageFromPath(ICON_PATH .. "videoEffect.png"),
}

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

                    local icon
                    if ICONS[pluginType] then
                        icon = ICONS[pluginType]
                    end

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
                    local name = plugin.name or "[" .. i18n("unknown") .. "]"
                    choices:add(name)
                        :subText(subText)
                        :params(plugin)
                        :image(icon)
                        :id(GROUP .. "_" .. pluginType .. "_" .. name .. "_" .. category .. "_" .. theme)
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

function plugin.init(deps)
    return mod.init(deps.actionmanager, deps.generators, deps.titles, deps.transitions, deps.audioeffects, deps.videoeffects)
end

return plugin
