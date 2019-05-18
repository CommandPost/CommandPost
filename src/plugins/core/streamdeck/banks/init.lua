--- === plugins.core.streamdeck.banks ===
---
--- Stream Deck Bank Actions.

local require = require

local dialog      = require("cp.dialog")
local i18n        = require("cp.i18n")

local mod = {}

--- plugins.core.streamdeck.banks.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    mod._handler = mod._actionmanager.addHandler("global_streamDeckbanks")
        :onChoices(function(choices)
            for i=1, mod._manager.numberOfSubGroups do
                choices:add(i18n("streamDeck") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("streamDeckBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("streamDeck") .. " " .. i18n("bank"))
                :subText(i18n("streamDeckBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("streamDeck") .. " " .. i18n("bank"))
                :subText(i18n("streamDeckBankDescription"))
                :params({ id = "previous" })
                :id("previous")

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then
                if type(result.id) == "number" then
                    mod._manager.gotoSubGroup(result.id)
                else
                    if result.id == "next" then
                        mod._manager.nextSubGroup()
                    elseif result.id == "previous" then
                        mod._manager.previousSubGroup()
                    end
                end
                local activeGroup = mod._manager.activeGroup()
                local activeSubGroup = mod._manager.activeSubGroup()
                if activeGroup and activeSubGroup then
                    dialog.displayNotification(i18n("switchingTo") .. " " .. i18n("streamDeck") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. activeGroup) .. " " .. activeSubGroup)
                end
                mod._manager.update()
            end
        end)
        :onActionId(function(action) return "streamDeckBank" .. action.id end)
    return mod
end

local plugin = {
    id              = "core.streamdeck.banks",
    group           = "core",
    dependencies    = {
        ["core.streamdeck.manager"] = "manager",
        ["core.action.manager"]	= "actionmanager",
    }
}

function plugin.init(deps)
    mod._manager = deps.manager
    mod._actionmanager = deps.actionmanager
    return mod.init()
end

return plugin
