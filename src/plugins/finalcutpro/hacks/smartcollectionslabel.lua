--- === plugins.finalcutpro.hacks.smartcollectionslabel ===
---
--- Smart Collections Label.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("smartCollections")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PLIST_PATH
-- Constant
-- Property List Path
local PLIST_PATH = "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.hacks.smartcollectionslabel.change() -> none
--- Function
--- Triggers the Change Smart Collections Label Dialog Boxes.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function mod.change()

    --------------------------------------------------------------------------------
    -- Get existing value:
    --------------------------------------------------------------------------------
    local FFOrganizerSmartCollections = ""
    local executeResult = hs.execute("/usr/libexec/PlistBuddy -c \"Print :FFOrganizerSmartCollections\" '" .. fcp:getPath() .. PLIST_PATH .. "'")
    if tools.trim(executeResult) ~= "" then FFOrganizerSmartCollections = executeResult end

    --------------------------------------------------------------------------------
    -- If Final Cut Pro is running...
    --------------------------------------------------------------------------------
    local restartStatus = false
    if fcp:isRunning() then
        if dialog.displayYesNoQuestion(i18n("changeSmartCollectionsLabel"), i18n("doYouWantToContinue")) then
            restartStatus = true
        else
            return true
        end
    end

    --------------------------------------------------------------------------------
    -- Ask user what to set the backup interval to:
    --------------------------------------------------------------------------------
    local userSelectedSmartCollectionsLabel = dialog.displayTextBoxMessage(i18n("smartCollectionsLabelTextbox"), i18n("smartCollectionsLabelError"), tools.trim(FFOrganizerSmartCollections))
    if not userSelectedSmartCollectionsLabel then
        return false
    end

    --------------------------------------------------------------------------------
    -- Update plist for every Flexo language:
    --------------------------------------------------------------------------------
    local executeCommands = {}
    local fcpPath = fcp:getPath()
    for k, _ in pairs(fcp.FLEXO_LANGUAGES) do
        if type(k) == "string" then
            local path = fcpPath .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/" .. k .. ".lproj/FFLocalizable.strings"
            if tools.doesFileExist(path) then
                local executeCommand = "/usr/libexec/PlistBuddy -c \"Set :FFOrganizerSmartCollections " .. tools.trim(userSelectedSmartCollectionsLabel) .. "\" '" .. path .. "'"
                executeCommands[#executeCommands + 1] = executeCommand
            else
                log.df("File not found: %s", path)
            end
        end
    end
    local result = tools.executeWithAdministratorPrivileges(executeCommands)
    if type(result) == "string" then
        dialog.displayErrorMessage(result)
    end

    --------------------------------------------------------------------------------
    -- Restart Final Cut Pro:
    --------------------------------------------------------------------------------
    if restartStatus then
        if not fcp:restart() then
            --------------------------------------------------------------------------------
            -- Failed to restart Final Cut Pro:
            --------------------------------------------------------------------------------
            dialog.displayErrorMessage(i18n("failedToRestart"))
            return false
        end
    end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hacks.smartcollectionslabel",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]                            = "fcpxCmds",
        ["finalcutpro.preferences.app"]                     = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            :addButton(2203,
                {
                    width       = 200,
                    label       = i18n("changeSmartCollectionLabel"),
                    onclick     = mod.change,
                }
            )
    end

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    if deps and deps.fcpxCmds then
        deps.fcpxCmds
            :add("cpChangeSmartCollectionsLabel")
            :whenActivated(mod.change)
    end

    --------------------------------------------------------------------------------
    -- Return Module:
    --------------------------------------------------------------------------------
    return mod

end

return plugin
