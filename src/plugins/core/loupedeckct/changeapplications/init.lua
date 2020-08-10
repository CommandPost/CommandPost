--- === plugins.core.loupedeckct.changeapplications ===
---
--- Allows you to change the Loupedeck CT application if set to manual.

local require                       = require

--local log                           = require "hs.logger".new "changeapplications"

local application                   = require "hs.application"

local i18n                          = require "cp.i18n"

local launchOrFocusByBundleID       = application.launchOrFocusByBundleID

local mod = {}

local plugin = {
    id              = "core.loupedeckct.changeapplications",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
        ["core.application.manager"] = "applicationmanager",
        ["core.loupedeckct.manager"] = "loupedeckctmanager",
    }
}

function plugin.init(deps)
    local actionmanager = deps.actionmanager
    local applicationmanager = deps.applicationmanager
    local loupedeckctmanager = deps.loupedeckctmanager

    mod._handler = actionmanager.addHandler("global_loupedeckctapplications", "global")
        :onChoices(function(choices)
            local applications = applicationmanager.getApplications()

            applications["All Applications"] = {
                displayName = "All Applications",
            }

            -- Add User Added Applications from Loupedeck CT Preferences:
            local items = loupedeckctmanager.items()
            for bundleID, v in pairs(items) do
                if not applications[bundleID] and v.displayName then
                    applications[bundleID] = {}
                    applications[bundleID].displayName = v.displayName
                end
            end

            for bundleID, item in pairs(applications) do
                choices
                    :add(i18n("switchLoupedeckCTTo") .. " " .. item.displayName)
                    :subText("")
                    :params({
                        bundleID = bundleID,
                    })
                    :id("global_loupedeckctapplications_switch_" .. bundleID)

                if bundleID ~= "All Applications" then
                    choices
                        :add(i18n("switchLoupedeckCTTo") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                        :subText("")
                        :params({
                            bundleID = bundleID,
                            launch = true,
                        })
                        :id("global_loupedeckctapplications_launch_" .. bundleID)
                end
            end
        end)
        :onExecute(function(action)
            local bundleID = action.bundleID
            loupedeckctmanager.lastBundleID(bundleID)
            loupedeckctmanager.refresh()

            if action.launch then
                launchOrFocusByBundleID(bundleID)
            end
        end)
        :onActionId(function(params)
            return "global_loupedeckctapplications_" .. params.bundleID
        end)
        :cached(false)

    return mod
end

return plugin
