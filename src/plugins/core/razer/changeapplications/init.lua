--- === plugins.core.razer.changeapplications ===
---
--- Allows you to change the Razer application if set to manual.

local require                       = require

--local log                           = require "hs.logger".new "changeapplications"

local application                   = require "hs.application"
local image                         = require "hs.image"

local i18n                          = require "cp.i18n"

local imageFromPath                 = image.imageFromPath
local launchOrFocusByBundleID       = application.launchOrFocusByBundleID

local mod = {}

local plugin = {
    id              = "core.razer.changeapplications",
    group           = "core",
    dependencies    = {
        ["core.action.manager"]         = "actionmanager",
        ["core.application.manager"]    = "applicationmanager",
        ["core.razer.manager"]          = "razerManager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Razer Icon:
    --------------------------------------------------------------------------------
    local razerIcon = imageFromPath(env:pathToAbsolute("/../prefs/images/razerIcon.png"))

    local actionmanager         = deps.actionmanager
    local applicationmanager    = deps.applicationmanager
    local razerManager          = deps.razerManager

    local supportedDevices      = razerManager.supportedDevices

    mod.handlers = {}

    for _, deviceName in pairs(supportedDevices) do
        local deviceID = deviceName:lower():gsub("%s+", "")
        mod.handlers[deviceName] = actionmanager.addHandler("global_" .. deviceID .. "_applications", "global")
            :onChoices(function(choices)
                local applications = applicationmanager.getApplications()

                applications["All Applications"] = {
                    displayName = "All Applications",
                }

                -- Add User Added Applications from Razer Preferences:
                local items = razerManager.items()
                for _, device in pairs(items) do
                    for bundleID, v in pairs(device) do
                        if not applications[bundleID] and v.displayName then
                            applications[bundleID] = {}
                            applications[bundleID].displayName = v.displayName
                        end
                    end
                end

                for bundleID, item in pairs(applications) do
                    choices
                        :add(i18n("switchRazerTo") .. " " .. item.displayName)
                        :subText("")
                        :params({
                            bundleID    = bundleID,
                            deviceName  = deviceName,
                        })
                        :id("global_razer_applications_switch_" .. bundleID)
                        :image(razerIcon)

                    if bundleID ~= "All Applications" then
                        choices
                            :add(i18n("switchRazerTo") .. " " .. item.displayName .. " " .. i18n("andLaunch"))
                            :subText("")
                            :params({
                                bundleID    = bundleID,
                                launch      = true,
                                deviceName  = deviceName,
                            })
                            :id("global_razer_applications_launch_" .. bundleID)
                            :image(razerIcon)
                    end
                end
            end)
            :onExecute(function(action)
                local bundleID = action.bundleID

                local lastBundleID = razerManager.lastBundleID()
                lastBundleID[action.deviceName] = bundleID
                razerManager.lastBundleID(lastBundleID)

                if action.launch then
                    launchOrFocusByBundleID(bundleID)
                end
            end)
            :onActionId(function(params)
                return "global_" .. deviceID .. "_applications_" .. params.bundleID
            end)
            :cached(false)
    end

    return mod
end

return plugin
