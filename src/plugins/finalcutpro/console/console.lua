--- === plugins.finalcutpro.console ===
---
--- Final Cut Pro Search Consoles

local require           = require

local image             = require "hs.image"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local imageFromPath     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "finalcutpro.console",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]               = "fcpxCmds",
        ["core.action.manager"]                = "actionmanager",
        ["core.console"]                       = "console",
        ["finalcutpro.timeline.pluginactions"] = "pluginactions", -- Load all the plugin actions first!
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Dependencies:
    --------------------------------------------------------------------------------
    local cmds = deps.fcpxCmds
    local actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Paths:
    --------------------------------------------------------------------------------
    local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
    local coreIconPath = config.basePath .. "/plugins/core/console/images/"

    --------------------------------------------------------------------------------
    -- Register a Final Cut Pro specific activator for the Search Console:
    --------------------------------------------------------------------------------
    local bundleID = fcp:bundleID()
    deps.console.register(bundleID, function()
        if not mod.activator then
            mod.activator = actionmanager.getActivator("finalcutpro.console")

            --------------------------------------------------------------------------------
            -- Allow specific handlers in the Search Console:
            --------------------------------------------------------------------------------
            local allowedHandlers = {}
            local handlerIds = actionmanager.handlerIds()
            for _,id in pairs(handlerIds) do
                local handlerTable = tools.split(id, "_")
                if handlerTable[1] == "global" or handlerTable[1] == "fcpx" then
                    if handlerTable[2]~= "widgets" and id ~= "global_menuactions" and id ~= "global_shortcuts" then
                        table.insert(allowedHandlers, id)
                    end
                end
            end
            mod.activator:allowHandlers(table.unpack(allowedHandlers))

            --------------------------------------------------------------------------------
            -- Allow specific toolbar icons in the Search Console:
            --------------------------------------------------------------------------------
            local toolbarIcons = {
                global_applications = { path = coreIconPath .. "apps.png",      priority = 1},
                fcpx_videoEffect    = { path = iconPath .. "videoEffect.png",   priority = 2},
                fcpx_audioEffect    = { path = iconPath .. "audioEffect.png",   priority = 3},
                fcpx_generator      = { path = iconPath .. "generator.png",     priority = 4},
                fcpx_title          = { path = iconPath .. "title.png",         priority = 5},
                fcpx_transition     = { path = iconPath .. "transition.png",    priority = 6},
                fcpx_fonts          = { path = iconPath .. "font.png",          priority = 7},
                fcpx_shortcuts      = { path = iconPath .. "shortcut.png",      priority = 8},
                fcpx_menu           = { path = iconPath .. "menu.png",          priority = 9},
            }
            mod.activator:toolbarIcons(toolbarIcons)
        end
        return mod.activator
    end)

    --------------------------------------------------------------------------------
    -- Add a Final Cut Pro specific action to open the Search Console:
    --------------------------------------------------------------------------------
    cmds:add("cpConsole")
        :groupedBy("commandPost")
        :whenActivated(function()
            deps.console.show()
        end)
        :activatedBy():ctrl("space")

    --------------------------------------------------------------------------------
    -- Video Effect Search Console:
    --------------------------------------------------------------------------------
    mod.videoEffect = actionmanager.getActivator("finalcutpro.videoEffect"):allowHandlers("fcpx_videoEffect")
    cmds:add("cpFinalCutProVideoEffect")
        :whenActivated(function()
            mod.videoEffect:show()
        end)
        :titled(i18n("openVideoEffectsInSearchConsole"))
        :image(imageFromPath(iconPath .. "videoEffect.png"))

    --------------------------------------------------------------------------------
    -- Audio Effect Search Console:
    --------------------------------------------------------------------------------
    mod.audioEffect = actionmanager.getActivator("finalcutpro.videoEffect"):allowHandlers("fcpx_audioEffect")
    cmds:add("cpFinalCutProAudioEffect")
        :whenActivated(function()
            mod.audioEffect:show()
        end)
        :titled(i18n("openAudioEffectsInSearchConsole"))
        :image(imageFromPath(iconPath .. "audioEffect.png"))

    --------------------------------------------------------------------------------
    -- Generators Search Console:
    --------------------------------------------------------------------------------
    mod.generators = actionmanager.getActivator("finalcutpro.videoEffect"):allowHandlers("fcpx_generator")
    cmds:add("cpFinalCutProGenerator")
        :whenActivated(function()
            mod.generators:show()
        end)
        :titled(i18n("openGeneratorsInSearchConsole"))
        :image(imageFromPath(iconPath .. "generator.png"))

    --------------------------------------------------------------------------------
    -- Titles Search Console:
    --------------------------------------------------------------------------------
    mod.title = actionmanager.getActivator("finalcutpro.title"):allowHandlers("fcpx_title")
    cmds:add("cpFinalCutProTitle")
        :whenActivated(function()
            mod.title:show()
        end)
        :titled(i18n("openTitlesInSearchConsole"))
        :image(imageFromPath(iconPath .. "title.png"))

    --------------------------------------------------------------------------------
    -- Transition Search Console:
    --------------------------------------------------------------------------------
    mod.transitions = actionmanager.getActivator("finalcutpro.transitions"):allowHandlers("fcpx_transition")
    cmds:add("cpFinalCutProTransition")
        :whenActivated(function()
            mod.transitions:show()
        end)
        :titled(i18n("openTransitionsInSearchConsole"))
        :image(imageFromPath(iconPath .. "transition.png"))

    return mod
end

return plugin
