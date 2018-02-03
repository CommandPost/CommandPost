--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              C L I P B O A R D   M A N A G E R    P L U G I N              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.clipboard.manager ===
---
--- Clipboard Manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("clipmgr")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local pasteboard                                = require("hs.pasteboard")
local timer                                     = require("hs.timer")
local uuid                                      = require("hs.host").uuid

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local plist                                     = require("cp.plist")
local protect                                   = require("cp.protect")
local archiver                                  = require("cp.plist.archiver")
local fcp                                       = require("cp.apple.finalcutpro")
local dialog                                    = require("cp.dialog")
local prop                                      = require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local CLIPBOARD = protect({
    --------------------------------------------------------------------------------
    -- FCPX Types:
    --------------------------------------------------------------------------------
    ANCHORED_COLLECTION                         = "FFAnchoredCollection",
    MARKER                                      = "FFAnchoredTimeMarker",
    GAP                                         = "FFAnchoredGapGeneratorComponent",

    --------------------------------------------------------------------------------
    -- The default name used when copying from the Timeline:
    --------------------------------------------------------------------------------
    TIMELINE_DISPLAY_NAME                       = "__timelineContainerClip",

    --------------------------------------------------------------------------------
    -- The pasteboard/clipboard property containing the copied clips:
    --------------------------------------------------------------------------------
    PASTEBOARD_OBJECT                           = "ffpasteboardobject",
    UTI                                         = "com.apple.flexo.proFFPasteboardUTI"
})

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.clipboard.manager.excludedClassnames -> table
--- Variable
--- Table of data we don't want to count when copying.
mod.excludedClassnames = {CLIPBOARD.MARKER}

--- plugins.finalcutpro.clipboard.manager.watcherFrequency -> number
--- Variable
--- The Clipboard Watcher Update frequency.
mod.watcherFrequency = 0.5

--- plugins.finalcutpro.clipboard.manager.excludedClassnames -> table
--- Variable
--- Table of data we don't want to count when copying.
mod._watchersCount                      = 0

--- plugins.finalcutpro.clipboard.manager.isTimelineClip(data) -> boolean
--- Function
--- Is the data a timeline clip.
---
--- Parameters:
---  * data - The clipboard data you want to check.
---
--- Returns:
---  * `true` if a timeline clip otherwise `false`.
function mod.isTimelineClip(data)
    return data.displayName == CLIPBOARD.TIMELINE_DISPLAY_NAME
end

--- plugins.finalcutpro.clipboard.manager.processObject(data) -> string, number
--- Function
--- Processes the provided data object, which should have a '$class' property.
---
--- Parameters:
---  * data - The clipboard data you want to check.
---
--- Returns:
---  * The primary clip name as a string.
---  * The number of clips as number.
function mod.processObject(data)
    if type(data) == "table" then
        local class = data['$class']
        if class then
            return mod.processContent(data)
        elseif data[1] then
            --------------------------------------------------------------------------------
            -- It's an array:
            --------------------------------------------------------------------------------
            return mod.processArray(data)
        end
    end
    return nil, 0
end

--- plugins.finalcutpro.clipboard.manager.isClassnameSupported(classname) -> boolean
--- Function
--- Is the class name supported?
---
--- Parameters:
---  * classname - The class name you want to check
---
--- Returns:
---  * `true` if the class name is supported otherwise `false`.
function mod.isClassnameSupported(classname)
    for i,name in ipairs(mod.excludedClassnames) do
        if name == classname then
            return false
        end
    end
    return true
end

--- plugins.finalcutpro.clipboard.manager.processArray(data) -> string, number
--- Function
--- Processes an 'array' table.
---
--- Parameters:
---  * data - The data object to process
---
--- Returns:
---  * The primary clip name as a string.
---  * The number of clips as number.
function mod.processArray(data)
    local name = nil
    local count = 0
    for i,v in ipairs(data) do
        local n,c = mod.processObject(v, objects)
        if name == nil then
            name = n
        end
        count = count + c
    end
    return name, count
end

--- plugins.finalcutpro.clipboard.manager.supportsContainedItems(data) -> boolean
--- Function
--- Gets whether or not the data supports contained items.
---
--- Parameters:
---  * data - The data object to process
---
--- Returns:
---  * `true` if supported otherwise `false`.
function mod.supportsContainedItems(data)
    local classname = mod.getClassname(data)
    return data.containedItems and classname ~= CLIPBOARD.ANCHORED_COLLECTION
end

--- plugins.finalcutpro.clipboard.manager.getClassname(data) -> string
--- Function
--- Gets a class anem from data
---
--- Parameters:
---  * data - The data object to process
---
--- Returns:
---  * Class name as string
function mod.getClassname(data)
    return data["$class"]["$classname"]
end

--- plugins.finalcutpro.clipboard.manager.processContent(data) -> string, number
--- Function
--- Process objects which have a `displayName`, such as Compound Clips, Images, etc.
---
--- Parameters:
---  * data - The data object to process
---
--- Returns:
---  * The primary clip name as a string.
---  * The number of clips as number.
function mod.processContent(data)
    if not mod.isClassnameSupported(classname) then
        return nil, 0
    end

    if mod.isTimelineClip(data) then
        --------------------------------------------------------------------------------
        -- Just process the contained items directly:
        --------------------------------------------------------------------------------
        return mod.processObject(data.containedItems)
    end

    local displayName = data.displayName
    local count = displayName and 1 or 0

    if mod.getClassname(data) == CLIPBOARD.GAP then
        displayName = nil
        count = 0
    end

    if mod.supportsContainedItems(data) then
        n, c = mod.processObject(data.containedItems)
        count = count + c
        displayName = displayName or n
    end

    if data.anchoredItems then
        n, c = mod.processObject(data.anchoredItems)
        count = count + c
        displayName = displayName or n
    end

    if displayName then
        return displayName, count
    else
        return nil, 0
    end
end

--- plugins.finalcutpro.clipboard.manager.processContent(fcpxData, default) -> string, number
--- Function
--- Searches the Pasteboard binary plist data for the first clip name, and returns it.
---
--- Parameters:
---  * fcpxData - The data object to process
---  * default - The default value
---
--- Returns:
---  * Returns the 'default' value if the pasteboard contains a media clip but we could not interpret it, otherwise `nil` if the data did not contain Final Cut Pro Clip data.
---
--- Notes:
---  * Example usage: `local name = mod.findClipName(myFcpxData, "Unknown")`
function mod.findClipName(fcpxData, default)
    local data = mod.unarchiveFCPXData(fcpxData)

    if data then
        local name, count = mod.processObject(data.root.objects)

        if name then
            if count > 1 then
                return name.." (+"..(count-1)..")"
            else
                return name
            end
        else
            return default
        end
    end
    return nil
end

--- plugins.finalcutpro.clipboard.manager.overrideNextClipName(overrideName) -> None
--- Function
--- Overrides the name for the next clip which is copied from FCPX to the specified
--- value. Once the override has been used, the standard clip name via
--- `mod.findClipName(...)` will be used for subsequent copy operations.
---
--- Parameters:
---  * overrideName - The override name.
---
--- Returns:
---  * None
function mod.overrideNextClipName(overrideName)
    mod._overrideName = overrideName
end

--- plugins.finalcutpro.clipboard.manager.copyWithCustomClipName() -> None
--- Function
--- Copy with custom label.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.copyWithCustomClipName()
    log.d("Copying Clip with custom Clip Name")
    local menuBar = fcp:menuBar()
    if menuBar:enabled("Edit", "Copy") then
        local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod.overrideNextClipName(result)
        menuBar:selectMenu({"Edit", "Copy"})
    end
end

--- plugins.finalcutpro.clipboard.manager.copyWithCustomClipName() -> data | nil
--- Function
--- Reads FCPX Data from the Pasteboard as a binary Plist, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The clipboard data or `nil`.
function mod.readFCPXData()
    local clipboardContent = pasteboard.allContentTypes()
    if clipboardContent ~= nil then
        if clipboardContent[1] ~= nil then
            if clipboardContent[1][1] == CLIPBOARD.UTI then
                return pasteboard.readDataForUTI(CLIPBOARD.UTI)
            end
        end
    end
    return nil
end

--- plugins.finalcutpro.clipboard.manager.unarchiveFCPXData(fcpxData) -> data | nil
--- Function
--- Unarchive Final Cut Pro data.
---
--- Parameters:
---  * fcpxData - The data object to process
---
--- Returns:
---  * The unarchived Final Cut Pro Pasteboard data or `nil`.
function mod.unarchiveFCPXData(fcpxData)
    if not fcpxData then
        fcpxData = mod.readFCPXData()
    end

    local clipboardTable = plist.binaryToTable(fcpxData)
    if clipboardTable then
        local base64Data = clipboardTable[CLIPBOARD.PASTEBOARD_OBJECT]
        if base64Data then
            local fcpxTable, errorMessage = plist.base64ToTable(base64Data)
            if fcpxTable then
                return archiver.unarchive(fcpxTable)
            else
                log.ef("plist.base64ToTable Error: %s", errorMessage)
            end
        end
    end
    log.e("The clipboard does not contain any FCPX clip data.")
    return nil
end

--- plugins.finalcutpro.clipboard.manager.writeFCPXData(fcpxData, quiet) -> boolean
--- Function
--- Write Final Cut Pro data to Pasteboard.
---
--- Parameters:
---  * fcpxData - The data to write
---  * quiet - Whether or not we should stop/start the watcher.
---
--- Returns:
---  * `true` if the operation succeeded, otherwise `false` (which most likely means ownership of the pasteboard has changed).
function mod.writeFCPXData(fcpxData, quiet)
    --------------------------------------------------------------------------------
    -- Write data back to Clipboard:
    --------------------------------------------------------------------------------
    if quiet then mod.stopWatching() end
    local result = pasteboard.writeDataForUTI(CLIPBOARD.UTI, fcpxData)
    if quiet then mod.startWatching() end
    return result
end

--- plugins.finalcutpro.clipboard.manager.watch(events) -> table
--- Function
--- Watch events.
---
--- Parameters:
---  * events - Table of events
---
--- Returns:
---  * Table of watchers.
function mod.watch(events)
    local startWatching = false
    if not mod._watchers then
        mod._watchers = {}
        mod._watchersCount = 0
        startWatching = true
    end
    local id = uuid()
    mod._watchers[id] = {update = events.update}
    mod._watchersCount = mod._watchersCount + 1

    if startWatching then
        mod.startWatching()
    end

    return {id=id}
end

--- plugins.finalcutpro.clipboard.manager.unwatch(id) -> boolean
--- Function
--- Stop a watcher.
---
--- Parameters:
---  * id - The ID of the watcher you want to stop.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function mod.unwatch(id)
    if mod._watchers then
        if mod._watchers[id.id] then
            mod._watchers[id.id] = nil
            mod._watchersCount = mod._watchersCount - 1
            if mod._watchersCount < 1 then
                mod.stopWatching()
            end
            return true
        end
    end
    return false
end

--- plugins.finalcutpro.clipboard.manager.startWatching() -> None
--- Function
--- Start Watching the Clipboard.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.startWatching()
    if mod._watchersCount < 1 then
        return
    end

    --log.d("Starting Clipboard Watcher.")

    if mod._timer then
        mod.stopWatching()
    end

    --------------------------------------------------------------------------------
    -- Reset:
    --------------------------------------------------------------------------------
    mod._lastChange = pasteboard.changeCount()

    --------------------------------------------------------------------------------
    -- Watch for Clipboard Changes:
    --------------------------------------------------------------------------------
    mod._timer = timer.new(mod.watcherFrequency, function()
        if not mod._watchers then
            return
        end

        local currentChange = pasteboard.changeCount()

        if (currentChange > mod._lastChange) then
            --------------------------------------------------------------------------------
            -- Read Clipboard Data:
            --------------------------------------------------------------------------------
            local data = mod.readFCPXData()

            --------------------------------------------------------------------------------
            -- Notify watchers
            --------------------------------------------------------------------------------
            if data then
                local name = nil
                -- An override was set
                if mod._overrideName ~= nil then
                    -- apply it
                    name = mod._overrideName
                    -- reset it
                    mod._overrideName = nil
                else
                    -- find the name from inside the clip data
                    name = mod.findClipName(data, os.date())
                end
                for _,events in pairs(mod._watchers) do
                    if events.update then
                        events.update(data, name)
                    end
                end
            end
        end
        mod._lastChange = currentChange
    end)
    mod._timer:start()

    mod.watching:update()
    --log.d("Started Clipboard Watcher")
end

--- plugins.finalcutpro.clipboard.manager.stopWatching() -> None
--- Function
--- Stop Watching the Clipboard.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stopWatching()
    if mod._timer then
        mod._timer:stop()
        mod._timer = nil
        mod.watching:update()
        --log.d("Stopped Clipboard Watcher")
    end
end

--- plugins.finalcutpro.clipboard.manager.watching <cp.prop: boolean>
--- Field
--- Gets whether or not we're watching the clipboard as a boolean.
mod.watching = prop.new(function()
    return mod._timer ~= nil
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.clipboard.manager",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- COMMANDS:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpCopyWithCustomLabel")
        :whenActivated(mod.copyWithCustomClipName)

    return mod
end

return plugin