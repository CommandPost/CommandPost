--- === plugins.finalcutpro.tangent.edit ===
---
--- Final Cut Pro Tangent View Group

local require   = require

local fcp       = require "cp.apple.finalcutpro"
local i18n      = require "cp.i18n"

local plugin = {
    id = "finalcutpro.tangent.edit",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)

    local fcpGroup = deps.fcpGroup
    local baseID = 0x00090000

    local group = fcpGroup:group(i18n("edit"))

    group:action(baseID+1, i18n("undo"))
        :onPress(fcp:doSelectMenu({"Edit", "Undo"}))

    group:action(baseID+2, i18n("redo"))
        :onPress(fcp:doSelectMenu({"Edit", "Redo"}))

    group:action(baseID+3, i18n("delete"))
        :onPress(fcp:doSelectMenu({"Edit", "Delete"}))

    group:action(baseID+4, i18n("overwriteToPrimaryStoryline"))
        :onPress(fcp:doSelectMenu({"Edit", "Overwrite to Primary Storyline"}))

    group:action(baseID+5, i18n("liftFromStoryline"))
        :onPress(fcp:doSelectMenu({"Edit", "Lift from Storyline"}))

    group:action(baseID+6, i18n("select") .. " " .. i18n("next"))
        :onPress(fcp:doSelectMenu({"Edit", "Select", "Select Next"}))

    group:action(baseID+7, i18n("select") .. " " .. i18n("previous"))
        :onPress(fcp:doSelectMenu({"Edit", "Select", "Select Previous"}))

    group:action(baseID+8, i18n("select") .. " " .. i18n("above"))
        :onPress(fcp:doSelectMenu({"Edit", "Select", "Select Above"}))

    group:action(baseID+9, i18n("select") .. " " .. i18n("below"))
        :onPress(fcp:doSelectMenu({"Edit", "Select", "Select Below"}))

    group:menu(baseID + 10)
        :name(i18n("select") .. " " .. i18n("next") .. "/" .. i18n("previous"))
        :onGet(function() end)
        :onNext(function()
            fcp:doSelectMenu({"Edit", "Select", "Select Next"}):Now()
         end)
        :onPrev(function()
            fcp:doSelectMenu({"Edit", "Select", "Select Previous"}):Now()
        end)
        :onReset(function() end)

    group:menu(baseID + 11)
        :name(i18n("select") .. " " .. i18n("above") .. "/" .. i18n("below"))
        :onGet(function() end)
        :onNext(function()
            fcp:doSelectMenu({"Edit", "Select", "Select Above"}):Now()
         end)
        :onPrev(function()
            fcp:doSelectMenu({"Edit", "Select", "Select Below"}):Now()
        end)
        :onReset(function() end)

end

return plugin
