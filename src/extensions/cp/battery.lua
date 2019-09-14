--- === cp.battery ===
---
--- Provides access to various properties of the battery. Each of these properties
--- is a `cp.prop`, so it can be watched for changes. For example:
---
--- ```lua
--- local battery = require("cp.battery")
--- battery.powerSupply:watch(function(value)
---     print("Now using "..value)
--- end)
--- ```
---
--- This will `print` "Now using AC Power" or "Now using Battery Power" whenever the
--- power supply changes.
---
--- By default the watcher initialises in a "stopped" state, and must be started for
--- the `cp.prop` watchers to trigger.

--- cp.battery.amperage <cp.prop: number; read-only>
--- Constant
--- Returns the amount of current flowing through the battery, in mAh.
---
--- Notes:
--- * A number containing the amount of current flowing through the battery. The value may be:
--- ** Less than zero if the battery is being discharged (i.e. the computer is running on battery power)
--- ** Zero if the battery is being neither charged nor discharded
--- ** Greater than zero if the bettery is being charged

--- cp.battery.capacity <cp.prop: number; read-only>
--- Constant
--- Returns the current capacity of the battery in mAh.
---
--- Notes:
--- * This is the measure of how charged the battery is, vs the value of `cp.battery.maxCapacity()`.

--- cp.battery.cycles <cp.prop: number; read-only>
--- Constant
--- Returns the number of discharge cycles of the battery.
---
--- Notes:
--- * One cycle is a full discharge of the battery, followed by a full charge. This may also be an aggregate of many smaller discharge-then-charge cycles (e.g. 10 iterations of discharging the battery from 100% to 90% and then charging back to 100% each time, is considered to be one cycle).

--- cp.battery.designCapacity <cp.prop: number; read-only>
--- Constant
--- Returns the design capacity of the battery in mAh.

--- cp.battery.health <cp.prop: string; read-only>
--- Constant
--- Returns the health status of the battery; either "Good", "Fair" or "Poor",
--- as determined by the Apple Smart Battery controller.

--- cp.battery.healthCondition <cp.prop: string; read-only>
--- Constant
--- Returns the health condition status of the battery:
--- `nil` if there are no health conditions to report, or a string containing either:
--- * "Check Battery"
--- * "Permanent Battery Failure"

--- cp.battery.isCharged <cp.prop: boolean; read-only>
--- Constant
--- Checks if the battery is fully charged.

--- cp.battery.isCharging <cp.prop: boolean; read-only>
--- Constant
--- Checks if the battery is currently charging.

--- cp.battery.isFinishingCharge <cp.prop: boolean | string; read-only>
--- Constant
--- Checks if the battery is trickle charging;
--- either `true` if trickle charging, `false` if charging faster, or `"n/a" if the battery is not charging at all.

--- cp.battery.maxCapacity <cp.prop; number; read-only>
--- Constant
--- Returns the maximum capacity of the battery in mAh.
---
--- Notes:
--- * This may exceed the value of `cp.battery.designCapacity()` due to small variations in the production chemistry vs the design.

--- cp.battery.otherBatteryInfo <cp.prop: table | nil; read-only>
--- Constant
--- Returns information about non-PSU batteries (e.g. bluetooth accessories). If none are found, `nil` is returned.

--- cp.battery.percentage <cp.prop; string; read-only>
--- Constant
--- Returns the current source of power; either `"AC Power"`, `"Battery Power"` or `"Off Line"`.

--- cp.battery.psuSerial <cp.prop: number; read-only>
--- Constant
--- Returns the serial number of the attached power supply, or `0` if not present.

--- cp.battery.timeRemaining <cp.prop: number; read-only>
--- Constant
--- The amount of battery life remaining, in minuges.
---
--- Notes:
--- * The return value may be:
--- ** Greater than zero to indicate the number of minutes remaining.
--- ** `-1` if the remaining batttery life is being calculated.
--- ** `-2` if there is unlimited time remaining (i.e. the system is on AC power).

--- cp.battery.timeToFullCharge <cp.prop; number; read-only>
--- Constant
--- Returns the time remaining for the battery to be fully charged, in minutes, or `-`` if still being calculated.

--- cp.battery.voltage <cp.prop: number; read-only>
--- Constant
--- Returns the current voltage of the battery in mV.

--- cp.battery.watts <cp.prop: number; read-only>
--- Constant
--- Returns the power entering or leaving the battery, in W.
--- Discharging will be less than zero, charging greater than zero.

local require = require

local log           = require("hs.logger").new("cpBattery")

local battery       = require("hs.battery")

local prop          = require("cp.prop")


local mod = {}

-- EXCLUDED -> table
-- Constant
-- Table of excluded items.
local EXCLUDED = {
    ["privateBluetoothBatteryInfo"] = true,
    ["getAll"] = true,
}

--- cp.battery._watcher -> hs.battery.watcher object
--- Variable
--- The battery watcher.
mod._watcher = battery.watcher.new(function()
    for key,value in pairs(mod) do
        if prop.is(value) then
            local ok, result = xpcall(function() value:update() end, debug.traceback)
            if not ok then
                log.ef("Error while updating '%s'", key, result)
            end
        end
    end
end)

--- cp.battery.start() -> none
--- Function
--- Starts the battery watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    mod._watcher:start()
end

--- cp.battery.stop() -> none
--- Function
--- Stops the battery watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    mod._watcher:stop()
end

-- init() -> none
-- Function
-- Initialise the module.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The module
local function init()
    for key,value in pairs(battery) do
        if EXCLUDED[key] ~= true and type(value) == "function" then
            mod[key] = prop(value):label(string.format("cp.battery: %s", key))
        end
    end
    return mod
end

return init()
