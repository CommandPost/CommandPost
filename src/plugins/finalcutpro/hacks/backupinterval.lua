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
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY          = 30
local DEFAULT_VALUE     = "15"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local periodicBackupInterval = fcp.preferences:prop("FFPeriodicBackupInterval", DEFAULT_VALUE)

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
    return periodicBackupInterval()
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
    -- Ask user what to set the backup interval to:
    --------------------------------------------------------------------------------
    local newInterval = dialog.displaySmallNumberTextBoxMessage(i18n("changeBackupIntervalTextbox"), i18n("changeBackupIntervalError"), mod.get())

    --------------------------------------------------------------------------------
    -- Update plist:
    --------------------------------------------------------------------------------
    if newInterval then
        periodicBackupInterval(tostring(newInterval))
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
