--- === plugins.finalcutpro.tangent.trim ===
---
--- Final Cut Pro Tangent Trim Group

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("fcptng_timeline")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.trim.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro Trim actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.trim.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)

    local baseID = 0x00070000

    mod.group = fcpGroup:group(i18n("trim"))

    mod.group:action(baseID+1, i18n("blade"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Blade"})
        end)

    mod.group:action(baseID+2, i18n("blade") .. " " .. i18n("all"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Blade All"})
        end)

    mod.group:action(baseID+3, i18n("joinClips"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Join Clips"})
        end)

    mod.group:action(baseID+4, i18n("trim") .. " " .. i18n("start"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Trim Start"})
        end)

    mod.group:action(baseID+5, i18n("trim") .. " " .. i18n("end"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Trim End"})
        end)

    mod.group:action(baseID+6, i18n("trimToPlayhead"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Trim To Playhead"})
        end)

    mod.group:action(baseID+7, i18n("extendEdit"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Extend Edit"})
        end)

    mod.group:action(baseID+8, i18n("alignAudioToVideo"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Align Audio to Video"})
        end)

    mod.group:action(baseID+9, i18n("nudge") .. " " .. i18n("left"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Nudge Left"})
        end)

    mod.group:action(baseID+10, i18n("nudge") .. " " .. i18n("right"))
        :onPress(function()
            fcp:selectMenuItem({"Trim", "Nudge Right"})
        end)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.trim",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin