--- === plugins.core.disk.automount ===
---
--- Automatic Disk Mounting & Unmounting.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                   = require("hs.logger").new("automount")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                = require("cp.config")
local dialog                = require("cp.dialog")
local battery               = require("cp.battery")
local disk                  = require("cp.disk")
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.disk.automount.unmountPhysicalDrives() -> none
--- Function
--- Unmount Physical Drives
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.unmountPhysicalDrives()
    disk.unmount({ejectable = true, physical = true})
end

--- plugins.core.disk.automount.mountPhysicalDrives() -> none
--- Function
--- Mount Physical Drives
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mountPhysicalDrives()
    disk.mount({ejectable = true, physical = true})
end

-- update(enabled) -> none
-- Function
-- Enables or disabled the battery watcher.
--
-- Parameters:
--  * enabled - `true` if enabled otherwise `false`
--
-- Returns:
--  * None
local function update(enabled)
    if enabled then
        battery.start()
    else
        battery.stop()
    end
end

--- plugins.core.disk.automount.autoUnmountOnBattery <cp.prop: boolean>
--- Variable
--- Automatically Unmount on disconnection from battery.
mod.autoUnmountOnBattery = config.prop("autoUnmountOnBattery", false):watch(update)

--- plugins.core.disk.automount.autoMountOnAC <cp.prop: boolean>
--- Variable
--- Automatically mount on connection to mains power.
mod.autoMountOnAC = config.prop("autoMountOnAC", false):watch(update)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.disk.automount",
    group = "core",
    dependencies = {
        ["core.commands.global"]                    = "global",
        ["core.preferences.panels.general"]         = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    local global, prefs = deps.global, deps.prefs
    local hasBattery = battery.powerSource()

    --------------------------------------------------------------------------------
    -- Force update of props:
    --------------------------------------------------------------------------------
    mod.autoMountOnAC:update()
    mod.autoUnmountOnBattery:update()

    --------------------------------------------------------------------------------
    -- Watch for power source changes:
    --------------------------------------------------------------------------------
    if hasBattery then
        battery.powerSource:watch(function(value)
            if value == "Battery Power" and mod.autoUnmountOnBattery() then
                log.df("Unmounting all external drives when on battery power...")
                dialog.displayNotification(i18n("unmountingExternalDrivesMsg"))
                mod.unmountPhysicalDrives()
            elseif value == "AC Power" and mod.autoMountOnAC() then
                log.df("Mounting external drives when on AC power...")
                dialog.displayNotification(i18n("mountingExternalDrivesMsg"))
                mod.mountPhysicalDrives()
            end
        end, true)
    end

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    global:add("unmountExternalDrives")
        :whenActivated(mod.unmountPhysicalDrives)

    global:add("mountExternalDrives")
        :whenActivated(mod.mountPhysicalDrives)

    --------------------------------------------------------------------------------
    -- Add Preferences:
    --------------------------------------------------------------------------------
    prefs:addHeading(20, i18n("driveManagement"))

    :addCheckbox(21,
        {
            label       = i18n("autoUnmountOnBattery"),
            checked     = mod.autoUnmountOnBattery,
            onchange    = function(_, params) mod.autoUnmountOnBattery(params.checked) end,
            disabled    = not hasBattery
        }
    )
    :addCheckbox(22,
        {
            label       = i18n("autoMountOnAC"),
            checked     = mod.autoMountOnAC,
            onchange    = function(_, params) mod.autoMountOnAC(params.checked) end,
            disabled    = not hasBattery
        }
    )

    return mod
end

return plugin
