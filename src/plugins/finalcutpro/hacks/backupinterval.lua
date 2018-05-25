--- === plugins.finalcutpro.hacks.backupinterval ===
---
--- Change Final Cut Pro's Backup Interval.

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

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY          = 30
local DEFAULT_VALUE     = "15"
local PREFERENCES_KEY   = "FFPeriodicBackupInterval"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.hacks.backupinterval.get() -> number
--- Function
--- Gets the Periodic Backup Interval.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The periodic backup interval as number
function mod.get()
    local FFPeriodicBackupInterval = DEFAULT_VALUE
    local preferences = fcp:getPreferences()
    if preferences and preferences[PREFERENCES_KEY] then
        FFPeriodicBackupInterval = preferences[PREFERENCES_KEY]
    end
    return FFPeriodicBackupInterval
end

--- plugins.finalcutpro.hacks.backupinterval.set() -> number
--- Function
--- Sets the Periodic Backup Interval via a dialog box.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The periodic backup interval as number
function mod.set()
    --------------------------------------------------------------------------------
    -- Get existing value:
    --------------------------------------------------------------------------------
    local FFPeriodicBackupInterval = mod.get()

    --------------------------------------------------------------------------------
    -- Ask user what to set the backup interval to:
    --------------------------------------------------------------------------------
    local userSelectedBackupInterval = dialog.displaySmallNumberTextBoxMessage(i18n("changeBackupIntervalTextbox"), i18n("changeBackupIntervalError"), FFPeriodicBackupInterval)
    if not userSelectedBackupInterval then
        return "Cancel"
    end

    --------------------------------------------------------------------------------
    -- Update plist:
    --------------------------------------------------------------------------------
    local result = fcp:setPreference(PREFERENCES_KEY, tostring(userSelectedBackupInterval))
    if result == nil then
        dialog.displayErrorMessage(i18n("backupIntervalFail"))
        return "Failed"
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hacks.backupinterval",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.administrator.advancedfeatures"] = "menu",
        ["finalcutpro.commands"]                            = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menu Item:
    --------------------------------------------------------------------------------
    deps.menu:addItem(PRIORITY, function()
        return { title = i18n("changeBackupInterval") .. " (" .. tostring(mod.get()) .. " " .. i18n("mins") .. ")",   fn = mod.set }
    end)

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpChangeBackupInterval")
        :groupedBy("hacks")
        :activatedBy():ctrl():option():cmd("b")
        :whenActivated(mod.set)

    return mod

end

return plugin
