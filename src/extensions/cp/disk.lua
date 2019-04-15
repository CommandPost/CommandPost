--- === cp.disk ===
---
--- Provides provides details about disk devices attached to the system.
--- These may be mounted, unmounted, and may include devices which do not
--- mount, or appear in the user interface by default.
---
--- The various methods have `options` table parameters, which allow filtering
--- to be performed on the operations. These tables can have any combination of
--- the following:
---
--- * `physical`        - only process physical drives.
--- * `virtual`         - only process virtual drives.
--- * `external`        - only external drives.
--- * `internal`        - only internal drives.
--- * `ejectable`       - only drives that can be ejected.
--- * `bootable`        - only bootable drives.
--- * `writable`        - only writeable drives.
--- * `root`            - only top-level drives (vs partitions)
--- * `hidden`          - by default, only 'unhidden' devices are returned.
--- * `mounted`         - only mounted drives.
--- * `unmounted`       - only unmounted drives.
---
--- ```lua
--- local battery = require("cp.battery")
--- local externalDrives = battery.devices({physical = true, ejectable = true})
--- ```

local require = require

local log                   = require("hs.logger").new("disk")

local execute               = hs.execute

local plist                 = require("cp.plist")
local isBlank               = require("cp.is").blank


local mod = {}

-- EXCLUDED_CONTENT -> table
-- Constant
-- The menubar position priority.
local EXCLUDED_CONTENT = {
    ["Apple_Boot"] = true,
    ["EFI"] = true,
}

local function diskList(options)
    options = options or {}
    local optionsString = ""
    if options.physical then
        if not options.virtual then
            optionsString = optionsString .. " physical"
        end
    elseif options.virtual then
        optionsString = optionsString .. " virtual"
    end

    if options.external then
        if not options.internal then
            optionsString = optionsString .. " external"
        end
    elseif options.internal then
        optionsString = optionsString .. " internal"
    end
    local output, ok = execute("diskutil list -plist"..optionsString)
    if ok then
        local result, err = plist.xmlToTable(output)
        if err then
            log.ef("Error while retrieving disk list: %s", err)
        end
        return result
    end
    return nil
end

local function diskInfo(diskID)
    local output, ok = execute("diskutil info -plist "..diskID)
    if ok then
        local result, err = plist.xmlToTable(output)
        if err then
            log.ef("Error while retrieving disk info: %s", err)
        end
        return result
    end
    return nil
end

local function unmount(diskID)
    local _, ok = execute("diskutil unmount "..diskID)
    return ok
end

local function mount(diskID)
    local _, ok = execute("diskutil mount "..diskID)
    return ok
end

local function eject(diskID)
    local _, ok = execute("diskutil eject "..diskID)
    return ok
end

local function listFilesystems()
    local output, ok = execute("diskutil listFilesystems -plist")
    if ok then
        local result, err = plist.xmlToTable(output)
        if err then
            log.ef("Error while retrieving disk info: %s", err)
        end
        return result
    end
    return nil
end

local function isHidden(info)
    return isBlank(info.VolumeName) or EXCLUDED_CONTENT[info.Content] == true
end

mod._disks = diskList

mod._diskInfo = diskInfo

mod._filesystems = listFilesystems

function mod.devices(options)
    options = options or {}
    local devices = {}
    local list = diskList(options)
    local allDisks = list.AllDisks
    if allDisks then
        for _,deviceID in ipairs(allDisks) do
            local deviceInfo = diskInfo(deviceID)
            local matches = true
            if options.ejectable and not deviceInfo.Ejectable then
                matches = false
            end
            if options.bootable and not deviceInfo.Bootable then
                matches = false
            end
            if options.writable and not deviceInfo.WritableVolume then
                matches = false
            end
            if options.root and not deviceInfo.WholeDisk then
                matches = false
            end
            if not options.hidden and isHidden(deviceInfo) then
                matches = false
            end
            if options.mounted and isBlank(deviceInfo.MountPoint) then
                matches = false
            end
            if options.unmounted and not isBlank(deviceInfo.MountPoint) then
                matches = false
            end

            if matches then
                devices[deviceID] = deviceInfo
            end
        end
    end
    return devices
end

--- cp.disk.visit(options, fn) -> nil
--- Function
--- Visits all drives matching the `options` and executes the
--- `fn` function with the `deviceID` string (e.g. "disk0" or "disk2s1") and a table of additional data about the drive.
---
--- Parameters:
--- * options   - The table of filter options.
--- * fn        - The function to execute.
---
--- Returns:
--- * Nothing.
function mod.visit(options, fn)
    options = options or {}

    local devices = mod.devices(options)
    for deviceID,info in pairs(devices) do
        fn(deviceID, info)
    end
end

--- cp.disk.mount(options) -> nil
--- Function
--- Mounts all disks matching the provided `options`.
---
--- Parameters:
--- * options   - The table of filter options.
---
--- Returns:
--- * Nothing.
function mod.mount(options)
    options = options or {}
    options.unmounted = true
    mod.visit(options, mount)
end

--- cp.disk.unmount(options) -> nil
--- Function
--- Unmounts all disks matching the provided `options`.
---
--- Parameters:
--- * options   - The table of filter options.
---
--- Returns:
--- * Nothing.
function mod.unmount(options)
    options = options or {}
    options.mounted = true
    mod.visit(options, unmount)
end

--- cp.disk.eject(options) -> nil
--- Function
--- Unmounts and ejects (where appropriate) all disks matching the provided `options`.
---
--- Parameters:
--- * options   - The table of filter options.
---
--- Returns:
--- * Nothing.
function mod.eject(options)
    options = options or {}
    options.ejectable = true
    mod.visit(options, eject)
end

return mod
