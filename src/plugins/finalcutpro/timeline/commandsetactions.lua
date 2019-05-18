--- === plugins.finalcutpro.timeline.commandsetactions ===
---
--- Adds Actions to the Console for triggering Final Cut Pro shortcuts as defined in the Command Set files.

local require = require

local log				= require("hs.logger").new("commandsetactions")

local image             = require("hs.image")
local timer				= require("hs.timer")

local config            = require("cp.config")
local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local plist				= require("cp.plist")

local doAfter           = timer.doAfter
local imageFromPath     = image.imageFromPath

local mod = {}

-- GROUP -> string
-- Constant
-- The group
local GROUP = "fcpx"

-- ICON -> hs.image object
-- Constant
-- Icon
local ICON = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/shortcut.png")

--- plugins.finalcutpro.timeline.commandsetactions.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()

    --------------------------------------------------------------------------------
    -- Add Action Handler:
    --------------------------------------------------------------------------------
    mod._handler = mod._actionmanager.addHandler(GROUP .. "_shortcuts", GROUP)
        :onChoices(function(choices)
            local fcpPath = fcp:getPath()
            local currentLocale = fcp:currentLocale()
            if fcpPath and currentLocale then

                local namePath 			= fcpPath .. "/Contents/Resources/" .. currentLocale.code .. ".lproj/NSProCommandNames.strings"
                local descriptionPath 	= fcpPath .. "/Contents/Resources/" .. currentLocale.code .. ".lproj/NSProCommandDescriptions.strings"

                local nameData 			= plist.fileToTable(namePath)
                local descriptionData 	= plist.fileToTable(descriptionPath)

                if nameData and descriptionData then
                    for id, name in pairs(nameData) do
                        local subText = descriptionData[id] or i18n("commandEditorShortcut")
                        choices
                            :add(name)
                            :subText(subText)
                            :params(id)
                            :image(ICON)
                            :id(id)
                    end
                end
            end
        end)
        :onExecute(function(action)
            if type(action) == "table" then
                --------------------------------------------------------------------------------
                -- Used by URL Handler:
                --------------------------------------------------------------------------------
                action = action.id
            end
            fcp:doShortcut(action)
            :Catch(function(message)
                dialog.displayMessage(i18n("shortcutCouldNotBeTriggered"), i18n("ok"))
                log.ef("Failed to trigger shortcut with action: %s; %s", hs.inspect(action), message)
            end)
            :Now()
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


local plugin = {
    id = "finalcutpro.timeline.commandsetactions",
    group = "finalcutpro",
    dependencies = {
        ["core.action.manager"]					= "actionmanager",
    }
}

function plugin.init(deps)
    mod._actionmanager = deps.actionmanager
    return mod.init()
end

return plugin
