--- === plugins.core.touchbar.banks ===
---
--- Touch Bar Bank Actions.

local require               = require

local image                 = require "hs.image"

local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"

local displayNotification   = dialog.displayNotification
local imageFromPath         = image.imageFromPath

local mod = {}

local plugin = {
    id              = "core.touchbar.banks",
    group           = "core",
    dependencies    = {
        ["core.touchbar.manager"]   = "manager",
        ["core.action.manager"]	= "actionmanager",
    }
}

function plugin.init(deps, env)

    local icon = imageFromPath(env:pathToAbsolute("/../prefs/images/touchbar.icns"))

    mod._manager = deps.manager
    mod._actionmanager = deps.actionmanager

    mod._handler = mod._actionmanager.addHandler("global_touchbarbanks")
        :onChoices(function(choices)
            for i=1, mod._manager.numberOfSubGroups do
                choices:add(i18n("touchBar") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("touchBarBankDescription"))
                    :params({ id = i })
                    :id(i)
                    :image(icon)
            end

            choices:add(i18n("next") .. " " .. i18n("touchBar") .. " " .. i18n("bank"))
                :subText(i18n("touchBarBankDescription"))
                :params({ id = "next" })
                :id("next")
                :image(icon)

            choices:add(i18n("previous") .. " " .. i18n("touchBar") .. " " .. i18n("bank"))
                :subText(i18n("touchBarBankDescription"))
                :params({ id = "previous" })
                :id("previous")
                :image(icon)

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
                    local bankLabel = mod._manager.getBankLabel(activeGroup .. activeSubGroup)
                    if bankLabel then
                        displayNotification(i18n("switchingTo") .. " " .. i18n("touchBar") .. " " .. i18n("bank") .. ": " .. bankLabel)
                    else
                        displayNotification(i18n("switchingTo") .. " " .. i18n("touchBar") .. " " .. i18n("bank") .. ": " .. i18n("shortcut_group_" .. activeGroup) .. " " .. activeSubGroup)
                    end
                end
                mod._manager.update()
            end
        end)
        :onActionId(function(action) return "touchbarBank" .. action.id end)
    return mod
end

return plugin
