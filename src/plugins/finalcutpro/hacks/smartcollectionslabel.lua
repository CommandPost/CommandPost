--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--      S M A R T    C O L L E C T I O N S    L A B E L    P L U G I N        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.smartcollectionslabel ===
---
--- Smart Collections Label.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY
-- Constant
-- The menubar position priority.
local PRIORITY = 20

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
        if dialog.displayYesNoQuestion(i18n("change"), i18n("doYouWantToContinue")) then
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
    for k, _ in pairs(fcp:getFlexoLanguages()) do
        local executeCommand = "/usr/libexec/PlistBuddy -c \"Set :FFOrganizerSmartCollections " .. tools.trim(userSelectedSmartCollectionsLabel) .. "\" '" .. fcp:getPath() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/" .. fcp:getFlexoLanguages()[k] .. ".lproj/FFLocalizable.strings'"
        executeCommands[#executeCommands + 1] = executeCommand
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
        ["finalcutpro.menu.administrator.advancedfeatures"] = "advancedfeatures",
        ["finalcutpro.commands"]                            = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menu:
    --------------------------------------------------------------------------------
    deps.advancedfeatures
        :addItem(PRIORITY, function()
            return { title = i18n("changeSmartCollectionLabel"),    fn = mod.change }
        end)

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpChangeSmartCollectionsLabel")
        :whenActivated(mod.change)

    --------------------------------------------------------------------------------
    -- Return Module:
    --------------------------------------------------------------------------------
    return mod

end

return plugin