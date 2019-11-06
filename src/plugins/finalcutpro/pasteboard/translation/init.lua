--- === plugins.finalcutpro.pasteboard.translation ===
---
--- Pasteboard Translation Facilities.

local require           = require

local log               = require "hs.logger".new "translation"

local fs                = require "hs.fs"
local host              = require "hs.host"
local pasteboard        = require "hs.pasteboard"

local fcp               = require "cp.apple.finalcutpro"
local just              = require "cp.just"
local tools             = require "cp.tools"

local aetemplate        = require "aetemplate"

local replace           = tools.replace
local uuid              = host.uuid
local pathFromBookmark  = fs.pathFromBookmark

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

    local pasteboardManager = mod.pasteboardManager

    local errorFunction = " Error occurred in ninjaPasteboardCopy()."

    --------------------------------------------------------------------------------
    -- Stop Watching Pasteboard:
    --------------------------------------------------------------------------------
    pasteboardManager.stopWatching()

    --------------------------------------------------------------------------------
    -- Save Current Pasteboard Contents for later:
    --------------------------------------------------------------------------------
    local originalPasteboard = pasteboardManager.readFCPXData()

    --------------------------------------------------------------------------------
    -- Trigger 'copy' from Menubar:
    --------------------------------------------------------------------------------
    local menuBar = fcp:menu()
    if menuBar:isEnabled({"Edit", "Copy"}) then
        menuBar:selectMenu({"Edit", "Copy"})
    else
        log.ef("Failed to select Copy from Menubar." .. errorFunction)
        pasteboardManager.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Wait until something new is actually on the Pasteboard:
    --------------------------------------------------------------------------------
    local newPasteboard = nil
    just.doUntil(function()
        newPasteboard = pasteboardManager.readFCPXData()
        if newPasteboard ~= originalPasteboard then
            return true
        end
    end, 10, 0.1)
    if newPasteboard == nil then
        log.ef("Failed to get new pasteboard contents." .. errorFunction)
        pasteboardManager.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Original Pasteboard Contents:
    --------------------------------------------------------------------------------
    if originalPasteboard ~= nil then
        local result = pasteboardManager.writeFCPXData(originalPasteboard)
        if not result then
            log.ef("Failed to restore original Pasteboard item." .. errorFunction)
            pasteboardManager.startWatching()
            return false
        end
    end

    --------------------------------------------------------------------------------
    -- Start Watching Pasteboard:
    --------------------------------------------------------------------------------
    pasteboardManager.startWatching()

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

local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local function randomString(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock()^5)
    return randomString(length - 1) .. charset[math.random(1, #charset)]
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
                --------------------------------------------------------------------------------
                -- Debugging:
                --------------------------------------------------------------------------------
                --[[
                hs.console.clearConsole()
                log.df("Final Cut Pro X Pasteboard:\n%s", hs.inspect(data))
                log.df("")
                --]]

                --------------------------------------------------------------------------------
                -- Get source file path:
                --------------------------------------------------------------------------------
                local encodedBookmark = data.media[1].originalMediaRep.metadata.FFMediaRep.bookmark["NS.data"]
                local decodedBookmark = decodeBase64(encodedBookmark)
                local path = pathFromBookmark(decodedBookmark)

                --------------------------------------------------------------------------------
                -- Get source & project timecode:
                --------------------------------------------------------------------------------
                local clippedRange = load("return " .. data.root.objects[1].clippedRange)()
                local mediaRange = load("return " .. data.media[1].mediaRange)()
                local displayName = data.media[1].displayName
                --local timecodeFrameDuration = data.media[1].timecodeFrameDuration -- "1/25"

                --------------------------------------------------------------------------------
                -- Debugging:
                --------------------------------------------------------------------------------
                --[[
                log.df("path: %s", path)
                log.df("mediaRange: %s", hs.inspect(mediaRange))
                log.df("clippedRange: %s", hs.inspect(clippedRange))
                log.df("")
                --]]

                --------------------------------------------------------------------------------
                -- Translate source & project timecode:
                --------------------------------------------------------------------------------
                local BASERATE = 10160640000 / 25 -- 25fps

                local mediaFPS = 25

                local mediaFrameRate = BASERATE

                local mediaIn = mediaRange[1] * mediaFPS * (BASERATE * mediaFPS)
                local mediaOut = mediaRange[2] * mediaFPS * (BASERATE * mediaFPS)

                local clipIn = clippedRange[1] * mediaFPS * (BASERATE * mediaFPS)
                local clipOut = clippedRange[2] * mediaFPS * (BASERATE * mediaFPS)

                local clipDuration = clipOut - clipIn

                --------------------------------------------------------------------------------
                -- Remove the decimal places:
                --------------------------------------------------------------------------------
                mediaIn = round(mediaIn, 0)
                mediaOut = round(mediaOut, 0)
                clipIn = round(clipIn, 0)
                clipOut = round(clipOut, 0)
                mediaFrameRate = round(mediaFrameRate, 0)

                --------------------------------------------------------------------------------
                -- Debugging:
                --------------------------------------------------------------------------------
                --[[
                log.df("mediaIn: %s", mediaIn)
                log.df("mediaOut: %s", mediaOut)
                log.df("")
                log.df("mediaFrameRate: %s", mediaFrameRate)
                log.df("")
                log.df("clipIn: %s", clipIn)
                log.df("clipOut: %s", clipOut)
                log.df("")
                --]]

                --------------------------------------------------------------------------------
                -- Fill in the Pasteboard Template:
                --------------------------------------------------------------------------------
                local template = aetemplate

                template = replace(template, "xxCopyPasteSequenceGUIDxx", uuid())
                template = replace(template, "xxRootProjectItemGUIDxx", uuid())
                template = replace(template, "xxClipProjectItemOneGUIDxx", uuid())
                template = replace(template, "xxClipProjectItemOneGUIDxx", uuid())
                template = replace(template, "xxFilePathxx", path)
                template = replace(template, "xxClipNamexx", displayName)

                template = replace(template, "xxMediaOutPointxx", mediaOut)
                template = replace(template, "xxMediaInPointxx", mediaIn)
                template = replace(template, "xxMediaFrameRatexx", mediaFrameRate)

                template = replace(template, "xxInPointxx", clipIn)
                template = replace(template, "xxOutPointxx", clipOut)

                template = replace(template, "xxTrackItemStartxx", clipIn)
                template = replace(template, "xxTrackItemEndxx", clipOut)

                template = replace(template, "xxOriginalDurationxx", clipDuration)

                --------------------------------------------------------------------------------
                -- Debugging:
                --------------------------------------------------------------------------------
                --log.df("template: %s", template)

                --------------------------------------------------------------------------------
                -- Write to the Pasteboard:
                --------------------------------------------------------------------------------
                local uniqueID = "dyn.ah62d4rv4gq80g55rf3u0k55cqy1gk7xbszyw66dusm10c3mtqz6gg4dbr3x0np5ysmu0g45msvw04"
                pasteboard.writeDataForUTI(nil, uniqueID, template)

                --------------------------------------------------------------------------------
                --
                -- NOTE: It seems that this code stays the same, at least on my machine.
                --       If I try and generate a random UUID, it doesn't work.
                --
                -- XML:        dyn.ah62d4rv4gq80g55rf3u0k55cqy1gk7xbszyw66dusm10c3mtqz6gg4dbr3x0np5ysmu0g45msvw04
                -- Made in AE: dyn.ah62d4rv4gq80g55rf3u0k55cqy1gk7xbszyw62pff7v0855prfww85pbqvw0w5xbqy
                --
                --------------------------------------------------------------------------------
                --local uniqueID = "dyn.ah62d4rv4gq80g55rf3u0k55cqy1gk7xbszyw6" .. randomString(40)
                --local uniqueIDb = "dyn.ah62d4rv4gq80g55rf3u0k55cqy1gk7xbszyw6" .. randomString(29)
                --local uniqueIDb = "dyn.ah62d4rv4gq80g55rf3u0k55cqy1gk7xbszyw62pff7v0855prfww85pbqvw0w5xbqy"
                --pasteboard.writeDataForUTI(nil, "public.utf8-plain-text", "After Effects must have keyframes selected from one layer in order to export them as text.")
                --pasteboard.writeDataForUTI(nil, "public.utf16-plain-text", "After Effects must have keyframes selected from one layer in order to export them as text.")
                --pasteboard.writeDataForUTI(nil, uniqueIDb, "Made in After Effects 9374")
            end
        end)
        :titled("Send Timeline Clip to Adobe After Effects")

    return mod
end

return plugin
