local log                   = require("hs.logger").new("automount")

local config                = require("cp.config")
local dialog                = require("cp.dialog")
local battery               = require("cp.battery")
local disk                  = require("cp.disk")

local mod = {}

function mod.unmountPhysicalDrives()
    disk.unmount({ejectable = true, physical = true})
end

function mod.mountPhysicalDrives()
    disk.mount({ejectable = true, physical = true})
end

mod.autoUnmountOnBattery = config.prop("autoUnmountOnBattery", false)
mod.autoMountOnAC = config.prop("autoMountOnAC", false)

local plugin = {
    id = "core.disk.automount",
    group = "core",
    dependencies = {
        ["core.commands.global"]                    = "global",
        ["core.preferences.panels.general"]         = "prefs",
    }
}

function plugin.init(deps)
    -- watch for power source changes.
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

    local global, prefs = deps.global, deps.prefs

    -- add commands
    global:add("unmountExternalDrives")
        :whenActivated(mod.unmountPhysicalDrives)

    global:add("mountExternalDrives")
        :whenActivated(mod.mountPhysicalDrives)

    prefs:addHeading(20, i18n("driveManagement"))

    :addCheckbox(21,
        {
            label		= i18n("autoUnmountOnBattery"),
            checked		= mod.autoUnmountOnBattery,
            onchange	= function(_, params) mod.autoUnmountOnBattery(params.checked) end,
        }
    )
    :addCheckbox(22,
        {
            label		= i18n("autoMountOnAC"),
            checked		= mod.autoMountOnAC,
            onchange	= function(_, params) mod.autoMountOnAC(params.checked) end,
        }
    )


    return mod
end

return plugin