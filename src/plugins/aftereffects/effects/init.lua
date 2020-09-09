--- === plugins.aftereffects.effects ===
---
--- Apply an After Effect effect to selected layer

local require                   = require

--local log                       = require "hs.logger".new "actions"

local application               = require "hs.application"
local image                     = require "hs.image"
local json                      = require "hs.json"
local osascript                 = require "hs.osascript"

local ae                        = require "cp.adobe.aftereffects"
local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local applescript               = osascript.applescript
local doesFileExist             = tools.doesFileExist
local imageFromPath             = image.imageFromPath
local infoForBundleID           = application.infoForBundleID
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID
local playErrorSound            = tools.playErrorSound

local mod = {}

local plugin = {
    id              = "aftereffects.effects",
    group           = "aftereffects",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    local bundleID = ae:bundleID()
    if infoForBundleID(bundleID) then

        local iconPath = config.basePath .. "/plugins/aftereffects/console/images/fx.png"
        local icon = imageFromPath(iconPath)

        local userCache = config.cachePath .."/After Effects/Effects.cpCache"
        local defaultCache = config.bundledPluginsPath .. "/aftereffects/effects/effects.json"

        --------------------------------------------------------------------------------
        -- Setup Handler:
        --------------------------------------------------------------------------------
        local actionmanager = deps.actionmanager
        mod._handler = actionmanager.addHandler("aftereffects_effects", "aftereffects")
            :onChoices(function(choices)
                local effects
                if doesFileExist(userCache) then
                    effects = json.read(userCache)
                else
                    effects = json.read(defaultCache)
                end
                for _, v in pairs(effects) do
                    local category = v.category
                    if v.category == "" then
                        category = i18n("noCategory")
                    end
                    choices
                        :add(v.displayName)
                        :subText(category)
                        :params({
                            matchName = v.matchName,
                        })
                        :id("aftereffects_effects" .. v.matchName)
                        :image(icon)
                end
            end)
            :onExecute(function(action)
                if launchOrFocusByBundleID(bundleID) then
                    if applescript([[
                    tell application id "]] .. bundleID .. [["
                        activate
                        DoScript "
                            {
                                // create an undo group
                                app.beginUndoGroup('AddEffect');

                                var curItem = app.project.activeItem;
                                var selectedLayers = curItem.selectedLayers;

                                // check if comp is selected
                                if (curItem == null || !(curItem instanceof CompItem)){
                                    // if no comp selected, display an alert
                                    alert('Please make sure a composition is active and try again.');
                                } else {
                                    if(typeof curItem.selectedLayers[0] === 'undefined') {
                                        alert('Please make sure you have a layer selected and try again.');
                                    }
                                    else {
                                        // define the layer in the loop we're currently looking at
                                        var curLayer = curItem.selectedLayers[0];

                                        // check if that layer is a footage layer
                                        if (curLayer.matchName == 'ADBE AV Layer'){
                                            curLayer.Effects.addProperty(']] .. action.matchName .. [[');
                                        }
                                    }
                                }

                                // close the undo group
                                app.endUndoGroup();
                            }"
                    end tell
                    ]]) then
                        return
                    end
                end
                playErrorSound()
            end)
            :onActionId(function(params)
                return "aftereffects_effects" .. params.matchName
            end)
    end
    return mod
end

return plugin
