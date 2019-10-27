--- === plugins.finalcutpro.pasteboard.translation ===
---
--- Pasteboard Translation Facilities.

local require           = require

local log               = require "hs.logger".new "translation"

local fs                = require "hs.fs"

local fcp               = require "cp.apple.finalcutpro"
local just              = require "cp.just"
local tools             = require "cp.tools"

local mod = {}

-- ninjaPasteboardCopy() -> boolean, data
-- Function
-- Ninja Pasteboard Copy. Copies something to the pasteboard, then restores the original pasteboard item.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful otherwise `false`
--  * The pasteboard data
local function ninjaPasteboardCopy()

    local errorFunction = " Error occurred in ninjaPasteboardCopy()."

    --------------------------------------------------------------------------------
    -- Variables:
    --------------------------------------------------------------------------------
    local pasteboard = mod.pasteboardManager

    --------------------------------------------------------------------------------
    -- Stop Watching Pasteboard:
    --------------------------------------------------------------------------------
    pasteboard.stopWatching()

    --------------------------------------------------------------------------------
    -- Save Current Pasteboard Contents for later:
    --------------------------------------------------------------------------------
    local originalPasteboard = pasteboard.readFCPXData()

    --------------------------------------------------------------------------------
    -- Trigger 'copy' from Menubar:
    --------------------------------------------------------------------------------
    local menuBar = fcp:menu()
    if menuBar:isEnabled({"Edit", "Copy"}) then
        menuBar:selectMenu({"Edit", "Copy"})
    else
        log.ef("Failed to select Copy from Menubar." .. errorFunction)
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Wait until something new is actually on the Pasteboard:
    --------------------------------------------------------------------------------
    local newPasteboard = nil
    just.doUntil(function()
        newPasteboard = pasteboard.readFCPXData()
        if newPasteboard ~= originalPasteboard then
            return true
        end
    end, 10, 0.1)
    if newPasteboard == nil then
        log.ef("Failed to get new pasteboard contents." .. errorFunction)
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Original Pasteboard Contents:
    --------------------------------------------------------------------------------
    if originalPasteboard ~= nil then
        local result = pasteboard.writeFCPXData(originalPasteboard)
        if not result then
            log.ef("Failed to restore original Pasteboard item." .. errorFunction)
            pasteboard.startWatching()
            return false
        end
    end

    --------------------------------------------------------------------------------
    -- Start Watching Pasteboard:
    --------------------------------------------------------------------------------
    pasteboard.startWatching()

    --------------------------------------------------------------------------------
    -- Return New Pasteboard:
    --------------------------------------------------------------------------------
    return true, newPasteboard

end


local function decodeBase64(base64Data)
    --------------------------------------------------------------------------------
    -- Trim Base64 data:
    --------------------------------------------------------------------------------
    if base64Data then
         base64Data = tools.trim(base64Data)
     end

    --------------------------------------------------------------------------------
    -- Define Temporary Files:
    --------------------------------------------------------------------------------
    local base64FileName = os.tmpname()
    local decodedFileName = os.tmpname()

    --------------------------------------------------------------------------------
    -- Write data to file:
    --------------------------------------------------------------------------------
    local file = io.open(base64FileName, "w")
    file:write(base64Data)
    file:close()

    --------------------------------------------------------------------------------
    -- Decode the base64 data:
    --------------------------------------------------------------------------------
    local executeCommand = 'openssl base64 -in "' .. tostring(base64FileName) .. '" -out "' .. tostring(decodedFileName) .. '" -d'
    local executeOutput, executeStatus, _, _ = hs.execute(executeCommand)
    if not executeStatus then
        log.d("Failed to convert base64 data: " .. tostring(executeOutput))
        return
    end

    --------------------------------------------------------------------------------
    -- Read data from file:
    --------------------------------------------------------------------------------
    file = io.open(decodedFileName, "r")
    if not file then
        log.ef("Failed to open decoded file.")
        return
    end
    local content = file:read "*a"
    file:close()

    --------------------------------------------------------------------------------
    -- Clean up the Temporary Files:
    --------------------------------------------------------------------------------
    os.remove(base64FileName)
    os.remove(decodedFileName)

    return content
end

local plugin = {
    id              = "finalcutpro.pasteboard.translation",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.pasteboard.manager"]  = "manager",
        ["finalcutpro.menu.manager"]        = "menu",
        ["finalcutpro.commands"]            = "commands",
    }
}

function plugin.init(deps)

    local manager = deps.manager
    mod.pasteboardManager = manager

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local commands = deps.commands
    commands:add("sendTimelineClipToAdobeAfterEffects")
        :whenActivated(function()
            local result, archivedData = ninjaPasteboardCopy()
            local data = result and manager.unarchiveFCPXData(archivedData)
            if data then
                local encodedBookmark = data.media[1].originalMediaRep.metadata.FFMediaRep.bookmark["NS.data"]
                local decodedBookmark = decodeBase64(encodedBookmark)
                local path = fs.pathFromBookmark(decodedBookmark)

                local clippedRange = data.root.objects[1].clippedRange
                local mediaRange = data.media[1].mediaRange

                log.df("path: %s", path)
                log.df("mediaRange: %s", mediaRange)
                log.df("clippedRange: %s", clippedRange)

                --chris = data

                local metadata = {
                    path = path,
                }

                return metadata
            end
        end)
        :titled("Send Timeline Clip to Adobe After Effects")

    return mod
end

return plugin
