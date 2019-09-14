--- === plugins.core.midi.controls.banks ===
---
--- MIDI Control Bank Actions.

local require               = require

local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"

local displayNotification   = dialog.displayNotification

local plugin = {
    id              = "core.midi.controls.banks",
    group           = "core",
    dependencies    = {
        ["core.midi.manager"]   = "manager",
        ["core.action.manager"]	= "actionmanager",
    }
}

function plugin.init(deps)
    local manager = deps.manager
    local actionmanager = deps.actionmanager
    actionmanager.addHandler("global_midibanks")
        :onChoices(function(choices)
            for i=1, manager.numberOfSubGroups do
                choices:add(i18n("midi") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("midiBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("midi") .. " " .. i18n("bank"))
                :subText(i18n("midiBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("midi") .. " " .. i18n("bank"))
                :subText(i18n("midiBankDescription"))
                :params({ id = "previous" })
                :id("previous")

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then
                if type(result.id) == "number" then
                    manager.gotoSubGroup(result.id)
                else
                    if result.id == "next" then
                        manager.nextSubGroup()
                    elseif result.id == "previous" then
                        manager.previousSubGroup()
                    end
                end
                local activeGroup = manager.activeGroup()
                local activeSubGroup = manager.activeSubGroup()
                if activeGroup and activeSubGroup then
                    local bankLabel = manager.getBankLabel(activeGroup .. activeSubGroup)
                    if bankLabel then
                        displayNotification(i18n("switchingTo") .. " " .. i18n("midi") .. " " .. i18n("bank") .. ": " .. bankLabel)
                    else
                        displayNotification(i18n("switchingTo") .. " " .. i18n("midi") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. activeGroup) .. " " .. activeSubGroup)
                    end
                end
            end
        end)
        :onActionId(function(action) return "midiBank" .. action.id end)
end

return plugin