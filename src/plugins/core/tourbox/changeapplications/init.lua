--- === plugins.core.tourbox.changeapplications ===
---
--- Allows you to change the TourBox application if set to manual.

local require                       = require

--local log                           = require "hs.logger".new "changeapplications"

local application                   = require "hs.application"
local image                         = require "hs.image"

local i18n                          = require "cp.i18n"

local imageFromPath                 = image.imageFromPath
local launchOrFocusByBundleID       = application.launchOrFocusByBundleID

local mod = {}

local plugin = {
    id              = "core.tourbox.changeapplications",
    group           = "core",
    dependencies    = {
        ["core.action.manager"]         = "actionmanager",
        ["core.application.manager"]    = "applicationmanager",
        ["core.tourbox.manager"]        = "tourboxManager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- TourBox Icon:
    --------------------------------------------------------------------------------
    local tourBoxIcon = imageFromPath(env:pathToAbsolute("/../prefs/images/TourBox.icns"))

    local actionmanager = deps.actionmanager
    local applicationmanager = deps.applicationmanager
    local tourboxManager = deps.tourboxManager

    mod._handler = actionmanager.addHandler("global_tourbox_applications", "global")
        :onChoices(function(choices)
            local applications = applicationmanager.getApplications()

            applications["All Applications"] = {
                displayName = "All Applications",
            }

            -- Add User Added Applications from TourBox Preferences:
            local items = tourboxManager.items()
            for bundleID, v in pairs(items) do
                if not applications[bundleID] and v.displayName then
                    applications[bundleID] = {}
                    applications[bundleID].displayName = v.displayName
                end
            end

            for bundleID, item in pairs(applications) do
                choices
                    :add(i18n("switchTourBoxTo") .. " " .. item.displayName)
                    :subText("")
                    :params({
                        bundleID = bundleID,
                    })
                    :id("global_tourbox_applications_switch_" .. bundleID)
                    :image(tourBoxIcon)

                if bundleID ~= "All Applications" then
                    choices
                        :add(i18n("switchTourBoxTo") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                        :subText("")
                        :params({
                            bundleID = bundleID,
                            launch = true,
                        })
                        :id("global_tourbox_applications_launch_" .. bundleID)
                        :image(tourBoxIcon)
                end
            end
        end)
        :onExecute(function(action)
            local bundleID = action.bundleID
            tourboxManager.lastBundleID(bundleID)

            if action.launch then
                launchOrFocusByBundleID(bundleID)
            end
        end)
        :onActionId(function(params)
            return "global_tourbox_applications_" .. params.bundleID
        end)
        :cached(false)

    return mod
end

return plugin
