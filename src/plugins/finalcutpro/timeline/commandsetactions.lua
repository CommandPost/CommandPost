--- === plugins.finalcutpro.timeline.commandsetactions ===
---
--- Adds Actions to the Console for triggering Final Cut Pro shortcuts as defined in the Command Set files.

local require               = require

local log                   = require "hs.logger".new "commandsetactions"

local image                 = require "hs.image"
local timer                 = require "hs.timer"
local http                  = require "hs.http"

local config                = require "cp.config"
local deferred              = require "cp.deferred"
local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local plist                 = require "cp.plist"

local convertHtmlEntities   = http.convertHtmlEntities
local displayMessage        = dialog.displayMessage
local doAfter               = timer.doAfter
local fileToTable           = plist.fileToTable
local imageFromPath         = image.imageFromPath

local mod = {}

-- GROUP -> string
-- Constant
-- The group
local GROUP = "fcpx"

-- ICON -> hs.image object
-- Constant
-- Icon
local ICON = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/shortcut.png")

local plugin = {
    id = "finalcutpro.timeline.commandsetactions",
    group = "finalcutpro",
    dependencies = {
        ["core.action.manager"]                 = "actionmanager",
    }
}

function plugin.init(deps)

    local cachedAction
    local triggerDeferredAction = deferred.new(0.01):action(function()
        local action = cachedAction
        if action then
            if type(action) == "table" then
                --------------------------------------------------------------------------------
                -- Used by URL Handler:
                --------------------------------------------------------------------------------
                action = action.id
            end
            fcp
                :doShortcut(action)
                :Catch(function(message)
                    displayMessage(i18n("shortcutCouldNotBeTriggered"), i18n("ok"))
                    log.ef("Failed to trigger shortcut with action: %s; %s", hs.inspect(action), message)
                end)
                :Now()
        end
    end)

    --------------------------------------------------------------------------------
    -- Add Action Handler:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler(GROUP .. "_shortcuts", GROUP)
        :onChoices(function(choices)
            local fcpPath = fcp:getPath()
            local currentLocale = fcp:currentLocale()
            if fcpPath and currentLocale then

                local namePath          = fcpPath .. "/Contents/Resources/" .. currentLocale.code .. ".lproj/NSProCommandNames.strings"
                local descriptionPath   = fcpPath .. "/Contents/Resources/" .. currentLocale.code .. ".lproj/NSProCommandDescriptions.strings"

                local nameData          = fileToTable(namePath)
                local descriptionData   = fileToTable(descriptionPath)

                if nameData and descriptionData then
                    for id, name in pairs(nameData) do
                        local subText = descriptionData[id] or i18n("commandEditorShortcut")
                        choices
                            :add(convertHtmlEntities(name))
                            :subText(convertHtmlEntities(subText))
                            :params(id)
                            :image(ICON)
                            :id(id)
                    end
                end
            end
        end)
        :onExecute(function(action)
            --------------------------------------------------------------------------------
            -- Defer the execution of the action:
            --------------------------------------------------------------------------------
            cachedAction = action
            triggerDeferredAction()
        end)
        :onActionId(function()
            return "fcpxShortcuts"
        end)

    --------------------------------------------------------------------------------
    -- Reset the handler choices when the Final Cut Pro language changes:
    --------------------------------------------------------------------------------
    fcp.currentLocale:watch(function()
        mod._handler:reset()
        doAfter(0.01, function() mod._handler.choices:update() end)
    end)

    return mod
end

return plugin
