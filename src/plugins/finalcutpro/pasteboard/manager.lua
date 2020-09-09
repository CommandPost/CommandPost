--- === plugins.finalcutpro.pasteboard.manager ===
---
--- Pasteboard Manager.

local require               = require

local log                   = require "hs.logger".new "clipmgr"

local base64                = require "hs.base64"
local host                  = require "hs.host"
local pasteboard            = require "hs.pasteboard"
local timer                 = require "hs.timer"

local archiver              = require "cp.plist.archiver"
local config                = require "cp.config"
local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local json                  = require "cp.json"
local just                  = require "cp.just"
local plist                 = require "cp.plist"
local prop                  = require "cp.prop"
local protect               = require "cp.protect"
local Set                   = require "cp.collect.Set"
local tools                 = require "cp.tools"

local Do                    = require "cp.rx.go.Do"
local Require               = require "cp.rx.go.Require"
local Retry                 = require "cp.rx.go.Retry"
local Throw                 = require "cp.rx.go.Throw"

local uuid                  = host.uuid

local mod = {}

-- PASTEBOARD -> table
-- Constant
-- Pasteboard Types
local PASTEBOARD = protect({
    --------------------------------------------------------------------------------
    -- Final Cut Pro Types:
    --------------------------------------------------------------------------------
    COLLECTION                                  = "FFAnchoredCollection",
    TIME_MARKER                                 = "FFAnchoredTimeMarker",
    KEYWORD_MARKER                              = "FFAnchoredKeywordMarker",
    FAVORITE_MARKER                             = "FFAnchoredFavoriteMarker",
    GAP                                         = "FFAnchoredGapGeneratorComponent",

    --------------------------------------------------------------------------------
    -- The default name used when copying from the Timeline:
    --------------------------------------------------------------------------------
    TIMELINE_DISPLAY_NAME                       = "__timelineContainerClip",

    --------------------------------------------------------------------------------
    -- The pasteboard property containing the copied clips:
    --------------------------------------------------------------------------------
    PASTEBOARD_OBJECT                           = "ffpasteboardobject",
    UTI                                         = "com.apple.flexo.proFFPasteboardUTI"
})

--- plugins.finalcutpro.pasteboard.manager.WATCHER_FREQUENCY -> number
--- Variable
--- The Pasteboard Watcher Update frequency.
mod.WATCHER_FREQUENCY = 0.5

--- plugins.finalcutpro.pasteboard.manager.NUMBER_OF_PASTEBOARD_BUFFERS -> number
--- Constant
--- Number of Pasteboard Buffers.
mod.NUMBER_OF_PASTEBOARD_BUFFERS = 9

--- plugins.finalcutpro.pasteboard.manager.RESTART_DELAY -> number
--- Constant
--- How long to wait until we restart any Pasteboard Watchers in milliseconds.
mod.RESTART_DELAY = 1000

--- plugins.finalcutpro.pasteboard.manager.excludedClassnames -> table
--- Variable
--- Table of data we don't want to count when copying.
mod.excludedClassnames = Set(PASTEBOARD.TIME_MARKER, PASTEBOARD.KEYWORD_MARKER, PASTEBOARD.FAVORITE_MARKER)

-- plugins.finalcutpro.pasteboard.manager._watchersCount -> number
-- Variable
-- Watchers Count.
mod._watchersCount = 0

--- plugins.finalcutpro.pasteboard.manager.isTimelineClip(data) -> boolean
--- Function
--- Is the data a timeline clip.
---
--- Parameters:
---  * data - The pasteboard data you want to check.
---
--- Returns:
---  * `true` if a timeline clip otherwise `false`.
function mod.isTimelineClip(data)
    return data.displayName == PASTEBOARD.TIMELINE_DISPLAY_NAME
end

--- plugins.finalcutpro.pasteboard.manager.processObject(data) -> string, number
--- Function
--- Processes the provided data object, which should have a '$class' property.
---
--- Parameters:
---  * data - The pasteboard data you want to check.
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

--- plugins.finalcutpro.pasteboard.manager.processArray(data) -> string, number
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
    for _,v in ipairs(data) do
        local n,c = mod.processObject(v, data)
        if name == nil then
            name = n
        end
        count = count + c
    end
    return name, count
end

--- plugins.finalcutpro.pasteboard.manager.supportsContainedItems(data) -> boolean
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
    return data.containedItems and classname ~= PASTEBOARD.COLLECTION
end

--- plugins.finalcutpro.pasteboard.manager.getClassname(data) -> string
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

--- plugins.finalcutpro.pasteboard.manager.processContent(data) -> string, number
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
    local classname = mod.getClassname(data)
    if mod.excludedClassnames:has(classname) then
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

    if classname == PASTEBOARD.GAP then
        displayName = nil
        count = 0
    end

    local n, c
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

--- plugins.finalcutpro.pasteboard.manager.processContent(fcpxData, default) -> string, number
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

--- plugins.finalcutpro.pasteboard.manager.overrideNextClipName(overrideName) -> none
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

--- plugins.finalcutpro.pasteboard.manager.copyWithCustomClipName() -> none
--- Function
--- Copy with custom label.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.copyWithCustomClipName()
    local menuBar = fcp.menu
    if menuBar:enabled("Edit", "Copy") then
        local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod.overrideNextClipName(result)
        menuBar:selectMenu({"Edit", "Copy"})
    end
end

--- plugins.finalcutpro.pasteboard.manager.readFCPXData() -> data | nil
--- Function
--- Reads Final Cut Pro Data from the Pasteboard as a binary Property List, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The pasteboard data or `nil`.
function mod.readFCPXData()
    local pasteboardContent = pasteboard.allContentTypes()
    if pasteboardContent ~= nil then
        if pasteboardContent[1] ~= nil then
            if pasteboardContent[1][1] == PASTEBOARD.UTI then
                return pasteboard.readDataForUTI(PASTEBOARD.UTI)
            end
        end
    end
    return nil
end

--- plugins.finalcutpro.pasteboard.manager.unarchiveFCPXData(fcpxData) -> data | nil
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

    local pasteboardTable = plist.binaryToTable(fcpxData)
    if pasteboardTable then
        local base64Data = pasteboardTable[PASTEBOARD.PASTEBOARD_OBJECT]
        if base64Data then
            local fcpxTable, errorMessage = plist.base64ToTable(base64Data)
            if fcpxTable then
                return archiver.unarchive(fcpxTable)
            else
                log.ef("plist.base64ToTable Error: %s", errorMessage)
            end
        end
    end
    log.e("The pasteboard does not contain any FCPX clip data.")
    return nil
end

--- plugins.finalcutpro.pasteboard.manager.writeFCPXData(fcpxData, quiet) -> boolean
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
    -- Write data back to Pasteboard:
    --------------------------------------------------------------------------------
    if quiet then mod.stopWatching() end
    local result = pasteboard.writeDataForUTI(PASTEBOARD.UTI, fcpxData)
    if quiet then mod.startWatching() end
    return result
end

--- plugins.finalcutpro.pasteboard.manager.watch(events) -> table
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

--- plugins.finalcutpro.pasteboard.manager.unwatch(id) -> boolean
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

--- plugins.finalcutpro.pasteboard.manager.startWatching() -> none
--- Function
--- Start Watching the Pasteboard.
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

    if mod._timer then
        mod.stopWatching()
    end

    --------------------------------------------------------------------------------
    -- Reset:
    --------------------------------------------------------------------------------
    mod._lastChange = pasteboard.changeCount()

    --------------------------------------------------------------------------------
    -- Watch for Pasteboard Changes:
    --------------------------------------------------------------------------------
    mod._timer = timer.new(mod.WATCHER_FREQUENCY, function()
        if not mod._watchers then
            return
        end

        local currentChange = pasteboard.changeCount()

        if (currentChange > mod._lastChange) then
            --------------------------------------------------------------------------------
            -- Read Pasteboard Data:
            --------------------------------------------------------------------------------
            local data = mod.readFCPXData()

            --------------------------------------------------------------------------------
            -- Notify watchers
            --------------------------------------------------------------------------------
            if data then
                local name
                --------------------------------------------------------------------------------
                -- An override was set:
                --------------------------------------------------------------------------------
                if mod._overrideName ~= nil then
                    --------------------------------------------------------------------------------
                    -- Apply it:
                    --------------------------------------------------------------------------------
                    name = mod._overrideName
                    --------------------------------------------------------------------------------
                    -- Reset it:
                    --------------------------------------------------------------------------------
                    mod._overrideName = nil
                else
                    --------------------------------------------------------------------------------
                    -- Find the name from inside the clip data:
                    --------------------------------------------------------------------------------
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
end

--- plugins.finalcutpro.pasteboard.manager.stopWatching() -> none
--- Function
--- Stop Watching the Pasteboard.
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
    end
end

--- plugins.finalcutpro.pasteboard.manager.watching <cp.prop: boolean>
--- Field
--- Gets whether or not we're watching the pasteboard as a boolean.
mod.watching = prop.new(function()
    return mod._timer ~= nil
end)

--- plugins.finalcutpro.pasteboard.manager.buffer <cp.prop: table>
--- Field
--- Contains the Pasteboard Buffer.
mod.buffer = json.prop(config.userConfigRootPath, "Pasteboard Buffer", "Pasteboard Buffer.cpPasteboard", {})

--- plugins.finalcutpro.pasteboard.manager.doWaitForFreshData(oldData) -> cp.rx.go.Statement
--- Function
--- A [Statement](cp.rx.go.Statement.md) which waits for up to 10 seconds for new data to copy
--- to the clipboard. If none is found, an error is sent.
---
--- Parameters:
---  * oldData - The original Pasteboard data.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md)
function mod.doWaitForFreshData(oldData)
    return Retry(function()
        local d = mod.readFCPXData()
        if d and d ~= oldData then
            return d
        else
            return Throw("Waited 10 seconds for new pasteboard data, but none was detected.")
        end
    end):DelayedBy(100):UpTo(100)
end

--- plugins.finalcutpro.pasteboard.manager.doWaitForData(newData) -> cp.rx.go.Statement
--- Function
--- A [Statement](cp.rx.go.Statement.md) which waits for up to 10 seconds for new data to appear
--- on the clipboard. If none is found, an error is sent.
---
--- Parameters:
---  * newData - The new Pasteboard data.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md)
function mod.doWaitForData(newData)
    return Retry(function()
        local d = mod.readFCPXData()
        if d and d == newData then
            return d
        else
            return Throw("Waited 10 seconds for new pasteboard data, but none was detected.")
        end
    end):DelayedBy(100):UpTo(100)
end

--- plugins.finalcutpro.pasteboard.manager.doSaveToBuffer(id) -> cp.rx.go.Statement
--- Function
--- A [Statement](cp.rx.go.Statement.md) which saves a Pasteboard item to the buffer.
---
--- Parameters:
---  * id - The ID of the buffer item.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md)
function mod.doSaveToBuffer(id)
    local menuBar = fcp.menu

    return Do(
        Require(menuBar:doIsEnabled({"Edit", "Copy"}))
        :OrThrow(i18n("pasteboardManager_CopyDisabled"))
    )
    :Then(fcp:doLaunch())
    :Then(function()
        local wasWatching = mod.watching()
        if wasWatching then
            mod.stopWatching()
        end

        local originalContents = mod.readFCPXData()

        return Do(menuBar:doSelectMenu({"Edit", "Copy"}))
        :Then(mod.doWaitForFreshData(originalContents))
        :Then(function(data)
            local buffer = mod.buffer()
            buffer[id] = base64.encode(data)
            mod.buffer(buffer)
            dialog.displayNotification(i18n("savedToPasteboardBuffer", {id=tostring(id)}))

            return Do(function()
                if originalContents then
                    mod.writeFCPXData(originalContents)
                end
                if wasWatching then
                    mod.startWatching()
                end
            end)
            :After(mod.RESTART_DELAY)
        end)
    end)
    :Catch(function(message)
        log.ef("pasteboardManager.doSaveToBuffer: error: %s", message)
        tools.playErrorSound()
    end)
end

--- plugins.finalcutpro.pasteboard.manager.doDecodeBuffer(id) -> cp.rx.go.Statement
--- Function
--- A [Statement](cp.rx.go.Statement.md) which decodes the buffer with the specified ID.
---
--- Parameters:
--- * id        - The ID to decode
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) that sends the decoded buffer, or throws an error if not available.
function mod.doDecodeBuffer(id)
    return Do(function()
        local buffer = mod.buffer()
        local encodedData = buffer[id]
        if encodedData then
            return base64.decode(encodedData)
        else
            return Throw("Unable to find data with ID: %s", id)
        end
    end)
end

--- plugins.finalcutpro.pasteboard.manager.doRestoreFromBuffer(id) -> cp.rx.go.Statement
--- Function
--- A [Statement](cp.rx.go.Statement.md) which restore a Pasteboard item from the buffer.
---
--- Parameters:
---  * id - The ID of the buffer item.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md)
function mod.doRestoreFromBuffer(id)
    return Do(mod.doDecodeBuffer(id))
    :Then(function(data)
        local wasWatching = mod.watching()
        if wasWatching then
            mod.stopWatching()
        end

        --------------------------------------------------------------------------------
        -- Hide the HUD if triggered from the HUD:
        --------------------------------------------------------------------------------
        if mod.hudManager.enabled() then
            mod.hudManager._webview:hide()
        end

        local originalContents = mod.readFCPXData()
        return Do(function() return mod.writeFCPXData(data) end)
        :Then(mod.doWaitForData(data))
        :Then(fcp:doShortcut("Paste"))
        :Then(function()
            Do(function()
                --------------------------------------------------------------------------------
                -- Show the HUD if triggered from the HUD:
                --------------------------------------------------------------------------------
                mod.hudManager.update()

                if originalContents then
                    mod.writeFCPXData(originalContents)
                end
                if wasWatching then
                    mod.startWatching()
                end
            end)
            :After(mod.RESTART_DELAY)
        end)
    end)
    :Catch(function(message)
        log.ef("doRestoreFromBuffer failed: %s", message)
        tools.playErrorSound()
    end)
end

--- plugins.finalcutpro.pasteboard.manager.ninjaPasteboardCopy() -> boolean, data
--- Function
--- Ninja Pasteboard Copy. Copies something to the pasteboard, then restores the original pasteboard item.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
---  * The pasteboard data
function mod.ninjaPasteboardCopy()

    local errorFunction = " Error occurred in plugins.finalcutpro.pasteboard.manager.ninjaPasteboardCopy()."

    --------------------------------------------------------------------------------
    -- Stop Watching Pasteboard:
    --------------------------------------------------------------------------------
    mod.stopWatching()

    --------------------------------------------------------------------------------
    -- Save Current Pasteboard Contents for later:
    --------------------------------------------------------------------------------
    local originalPasteboard = mod.readFCPXData()

    --------------------------------------------------------------------------------
    -- Trigger 'copy' from Menubar:
    --------------------------------------------------------------------------------
    local menuBar = fcp.menu
    if menuBar:isEnabled({"Edit", "Copy"}) then
        menuBar:selectMenu({"Edit", "Copy"})
    else
        log.ef("Failed to select Copy from Menubar." .. errorFunction)
        mod.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Wait until something new is actually on the Pasteboard:
    --------------------------------------------------------------------------------
    local newPasteboard = nil
    just.doUntil(function()
        newPasteboard = mod.readFCPXData()
        if newPasteboard ~= originalPasteboard then
            return true
        end
    end, 3, 0.1)
    if newPasteboard == nil then
        log.ef("Failed to get new pasteboard contents." .. errorFunction)
        mod.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Original Pasteboard Contents:
    --------------------------------------------------------------------------------
    if originalPasteboard ~= nil then
        local result = mod.writeFCPXData(originalPasteboard)
        if not result then
            log.ef("Failed to restore original Pasteboard item." .. errorFunction)
            mod.startWatching()
            return false
        end
    end

    --------------------------------------------------------------------------------
    -- Start Watching Pasteboard:
    --------------------------------------------------------------------------------
    mod.startWatching()

    --------------------------------------------------------------------------------
    -- Return New Pasteboard:
    --------------------------------------------------------------------------------
    return true, newPasteboard

end

local plugin = {
    id              = "finalcutpro.pasteboard.manager",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
        ["finalcutpro.hud.manager"] = "hudManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Manage dependancies:
    --------------------------------------------------------------------------------
    mod.hudManager = deps.hudManager

    --------------------------------------------------------------------------------
    -- Copy with Custom Label:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpCopyWithCustomLabel")
        :whenActivated(function() mod.copyWithCustomClipName() end)

    --------------------------------------------------------------------------------
    -- Pasteboard Buffer:
    --------------------------------------------------------------------------------
    for id=1, mod.NUMBER_OF_PASTEBOARD_BUFFERS do
        fcpxCmds
            :add("saveToPasteboardBuffer" .. tostring(id))
            :titled(i18n("copyToFinalCutProPasteboardBuffer", {id=tostring(id)}))
            :whenActivated(function() mod.doSaveToBuffer(id):Now() end)

        fcpxCmds
            :add("restoreFromPasteboardBuffer" .. tostring(id))
            :titled(i18n("pasteFromFinalCutProPasteboardBuffer", {id=tostring(id)}))
            :whenActivated(function() mod.doRestoreFromBuffer(id):Now() end)
    end

    return mod
end

return plugin
