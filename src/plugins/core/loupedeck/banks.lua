--- === plugins.core.loupedeck.banks ===
---
--- Loupedeck+ Bank Actions.

local require               = require

local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"

local displayNotification   = dialog.displayNotification

local plugin = {
    id              = "core.loupedeck.banks",
    group           = "core",
    dependencies    = {
        ["core.midi.manager"]   = "manager",
        ["core.action.manager"]	= "actionmanager",
    }
}

function plugin.init(deps)
    local manager = deps.manager
    local actionmanager = deps.actionmanager
    actionmanager.addHandler("global_loupedeckbanks")
        :onChoices(function(choices)
            for i=1, manager.numberOfSubGroups do
                choices:add(i18n("loupedeckPlus") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("loupedeckBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("loupedeckPlus") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("loupedeckPlus") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckBankDescription"))
                :params({ id = "previous" })
                :id("previous")

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then
                if type(result.id) == "number" then
                    manager.gotoLoupedeckSubGroup(result.id)
                else
                    if result.id == "next" then
                        manager.nextLoupedeckSubGroup()
                    elseif result.id == "previous" then
                        manager.previousLoupedeckSubGroup()
                    end
                end
                local activeGroup = manager.activeGroup()
                local activeSubGroup = manager.activeLoupedeckSubGroup()
                if activeGroup and activeSubGroup then
                    displayNotification(i18n("switchingTo") .. " " .. i18n("loupedeckPlus") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. activeGroup) .. " " .. activeSubGroup)
                end
            end
        end)
        :onActionId(function(action) return "loupedeckBank" .. action.id end)
end

return plugin