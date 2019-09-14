--- === plugins.finalcutpro.tangent.trim ===
---
--- Final Cut Pro Tangent Trim Group

local require = require

local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")

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
        :onPress(fcp:doSelectMenu({"Trim", "Blade"}))

    mod.group:action(baseID+2, i18n("blade") .. " " .. i18n("all"))
        :onPress(fcp:doSelectMenu({"Trim", "Blade All"}))

    mod.group:action(baseID+3, i18n("joinClips"))
        :onPress(fcp:doSelectMenu({"Trim", "Join Clips"}))

    mod.group:action(baseID+4, i18n("trim") .. " " .. i18n("start"))
        :onPress(fcp:doSelectMenu({"Trim", "Trim Start"}))

    mod.group:action(baseID+5, i18n("trim") .. " " .. i18n("end"))
        :onPress(fcp:doSelectMenu({"Trim", "Trim End"}))

    mod.group:action(baseID+6, i18n("trimToPlayhead"))
        :onPress(fcp:doSelectMenu({"Trim", "Trim To Playhead"}))

    mod.group:action(baseID+7, i18n("extendEdit"))
        :onPress(fcp:doSelectMenu({"Trim", "Extend Edit"}))

    mod.group:action(baseID+8, i18n("alignAudioToVideo"))
        :onPress(fcp:doSelectMenu({"Trim", "Align Audio to Video"}))

    mod.group:action(baseID+9, i18n("nudge") .. " " .. i18n("left"))
        :onPress(fcp:doSelectMenu({"Trim", "Nudge Left"}))

    mod.group:action(baseID+10, i18n("nudge") .. " " .. i18n("right"))
        :onPress(fcp:doSelectMenu({"Trim", "Nudge Right"}))
end


local plugin = {
    id = "finalcutpro.tangent.trim",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin
