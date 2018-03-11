--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.matchframe ===
---
--- Match Frame Tools for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                           = require("hs.logger").new("matchframe")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                        = require("cp.dialog")
local fcp                           = require("cp.apple.finalcutpro")
local just                          = require("cp.just")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- ninjaPasteboardCopy() -> boolean, data
-- Function
-- Ninja Pasteboard Copy. Copies something to the clipboard, then restores the original clipboard item.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful otherwise `false`
--  * The clipboard data
local function ninjaPasteboardCopy()

    local errorFunction = " Error occurred in ninjaPasteboardCopy()."

    --------------------------------------------------------------------------------
    -- Variables:
    --------------------------------------------------------------------------------
    local clipboard = mod.clipboardManager

    --------------------------------------------------------------------------------
    -- Stop Watching Clipboard:
    --------------------------------------------------------------------------------
    clipboard.stopWatching()

    --------------------------------------------------------------------------------
    -- Save Current Clipboard Contents for later:
    --------------------------------------------------------------------------------
    local originalClipboard = clipboard.readFCPXData()

    --------------------------------------------------------------------------------
    -- Trigger 'copy' from Menubar:
    --------------------------------------------------------------------------------
    local menuBar = fcp:menuBar()
    if menuBar:isEnabled({"Edit", "Copy"}) then
        menuBar:selectMenu({"Edit", "Copy"})
    else
        log.ef("Failed to select Copy from Menubar." .. errorFunction)
        clipboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Wait until something new is actually on the Pasteboard:
    --------------------------------------------------------------------------------
    local newClipboard = nil
    just.doUntil(function()
        newClipboard = clipboard.readFCPXData()
        if newClipboard ~= originalClipboard then
            return true
        end
    end, 10, 0.1)
    if newClipboard == nil then
        log.ef("Failed to get new clipboard contents." .. errorFunction)
        clipboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Original Clipboard Contents:
    --------------------------------------------------------------------------------
    if originalClipboard ~= nil then
        local result = clipboard.writeFCPXData(originalClipboard)
        if not result then
            log.ef("Failed to restore original Clipboard item." .. errorFunction)
            clipboard.startWatching()
            return false
        end
    end

    --------------------------------------------------------------------------------
    -- Start Watching Clipboard:
    --------------------------------------------------------------------------------
    clipboard.startWatching()

    --------------------------------------------------------------------------------
    -- Return New Clipboard:
    --------------------------------------------------------------------------------
    return true, newClipboard

end

--- plugins.finalcutpro.timeline.matchframe.multicamMatchFrame(goBackToTimeline) -> none
--- Function
--- Multicam Match Frame
---
--- Parameters:
---  * goBackToTimeline - `true` if you want to go back to the timeline after opening the clip in the Multicam Editor
---
--- Returns:
---  * None
function mod.multicamMatchFrame(goBackToTimeline)

    local errorFunction = "\n\nError occurred in multicamMatchFrame()."

    --------------------------------------------------------------------------------
    -- Just in case:
    --------------------------------------------------------------------------------
    if goBackToTimeline == nil then goBackToTimeline = true end
    if type(goBackToTimeline) ~= "boolean" then goBackToTimeline = true end

    --------------------------------------------------------------------------------
    -- Delete any pre-existing highlights:
    --------------------------------------------------------------------------------
    mod.browserPlayhead.deleteHighlight()

    local contents = fcp:timeline():contents()

    --------------------------------------------------------------------------------
    -- Store the originally-selected clips
    --------------------------------------------------------------------------------
    local originalSelection = contents:selectedClipsUI()

    --------------------------------------------------------------------------------
    -- If nothing is selected, select the top clip under the playhead:
    --------------------------------------------------------------------------------
    if not originalSelection or #originalSelection == 0 then
        local playheadClips = contents:playheadClipsUI(true)
        contents:selectClip(playheadClips[1])
    elseif #originalSelection > 1 then
        log.ef("Unable to match frame on multiple clips." .. errorFunction)
        return false
    end

    --------------------------------------------------------------------------------
    -- Get Multicam Angle:
    --------------------------------------------------------------------------------
    local multicamAngle = mod.getMulticamAngleFromSelectedClip()
    if multicamAngle == false then
        log.ef("The selected clip is not a multicam clip." .. errorFunction)
        contents:selectClips(originalSelection)
        return false
    end

    --------------------------------------------------------------------------------
    -- Open in Angle Editor:
    --------------------------------------------------------------------------------
    local menuBar = fcp:menuBar()
    if menuBar:isEnabled({"Clip", "Open in Angle Editor"}) then
        menuBar:selectMenu({"Clip", "Open in Angle Editor"})
    else
        dialog.displayErrorMessage("Failed to open clip in Angle Editor.\n\nAre you sure the clip you have selected is a Multicam?" .. errorFunction)
        return false
    end

    --------------------------------------------------------------------------------
    -- Put focus back on the timeline:
    --------------------------------------------------------------------------------
    if menuBar:isEnabled({"Window", "Go To", "Timeline"}) then
        menuBar:selectMenu({"Window", "Go To", "Timeline"})
    else
        dialog.displayErrorMessage("Unable to return to timeline." .. errorFunction)
        return false
    end

    --------------------------------------------------------------------------------
    -- Ensure the playhead is visible:
    --------------------------------------------------------------------------------
    contents:playhead():show()

    contents:selectClipInAngle(multicamAngle)

    --------------------------------------------------------------------------------
    -- Reveal In Browser:
    --------------------------------------------------------------------------------
    if menuBar:isEnabled({"File", "Reveal in Browser"}) then
        menuBar:selectMenu({"File", "Reveal in Browser"})
    end

    --------------------------------------------------------------------------------
    -- Go back to original timeline if appropriate:
    --------------------------------------------------------------------------------
    if goBackToTimeline then
        if menuBar:isEnabled({"View", "Timeline History Back"}) then
            menuBar:selectMenu({"View", "Timeline History Back"})
        else
            dialog.displayErrorMessage("Unable to go back to previous timeline." .. errorFunction)
            return false
        end
    end

    --------------------------------------------------------------------------------
    -- Select the original clips again.
    --------------------------------------------------------------------------------
    contents:selectClips(originalSelection)

    --------------------------------------------------------------------------------
    -- Highlight Browser Playhead:
    --------------------------------------------------------------------------------
    mod.browserPlayhead.highlight()

end

--- plugins.finalcutpro.timeline.matchframe.getMulticamAngleFromSelectedClip() -> angle | boolean
--- Function
--- Get Multicam Angle From Selected Clip
---
--- Parameters:
---  * None
---
--- Returns:
---  * Angle or `false` on error
function mod.getMulticamAngleFromSelectedClip()

    local errorFunction = "\n\nError occurred in getMulticamAngleFromSelectedClip()."

    --------------------------------------------------------------------------------
    -- Ninja Pasteboard Copy:
    --------------------------------------------------------------------------------
    local result, clipboardData = ninjaPasteboardCopy()
    if not result then
        log.ef("Ninja Pasteboard Copy Failed." .. errorFunction)
        return false
    end

    local clipboard = mod.clipboardManager

    --------------------------------------------------------------------------------
    -- Convert Binary Data to Table:
    --------------------------------------------------------------------------------
    local fcpxTable = clipboard.unarchiveFCPXData(clipboardData)
    if fcpxTable == nil then
        log.ef("Converting Binary Data to Table failed." .. errorFunction)
        return false
    end

    local timelineClip = fcpxTable.root.objects[1]
    if not clipboard.isTimelineClip(timelineClip) then
        log.ef("Not copied from the Timeline." .. errorFunction)
        return false
    end

    local selectedClips = timelineClip.containedItems
    if #selectedClips ~= 1 or clipboard.getClassname(selectedClips[1]) ~= "FFAnchoredAngle" then
        log.ef("Expected a single Multicam clip to be copied." .. errorFunction)
        return false
    end

    local multicamClip = selectedClips[1]
    local videoAngle = multicamClip.videoAngle

    --------------------------------------------------------------------------------
    -- Find the original media:
    --------------------------------------------------------------------------------
    local mediaId = multicamClip.media.mediaIdentifier
    local media = nil
    for _,item in ipairs(fcpxTable.media) do
        if item.mediaIdentifier == mediaId then
            media = item
            break
        end
    end

    if media == nil or not media.primaryObject or not media.primaryObject.isMultiAngle then
        log.ef("Couldn't find the media for the multicam clip.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Find the Angle
    --------------------------------------------------------------------------------
    local angles = media.primaryObject.containedItems[1].anchoredItems
    for _,angle in ipairs(angles) do
        if angle.angleID == videoAngle then
            return angle.anchoredLane
        end
    end

    log.ef("Failed to get anchoredLane." .. errorFunction)
    return false
end

--- plugins.finalcutpro.timeline.matchframe.matchFrame() -> none
--- Function
--- Performs a Single Match Frame.
---
--- Parameters:
---  * `focus`  - If set to `true`, the library will search for the matched clip title
---
--- Returns:
---  * None
function mod.matchFrame(focus)

    --------------------------------------------------------------------------------
    -- Check the option is available in the current context
    --------------------------------------------------------------------------------
    if not fcp:menuBar():isEnabled({"File", "Reveal in Browser"}) then
        return nil
    end

    --------------------------------------------------------------------------------
    -- Delete any pre-existing highlights:
    --------------------------------------------------------------------------------
    mod.browserPlayhead.deleteHighlight()

    local libraries = fcp:libraries()

    --------------------------------------------------------------------------------
    -- Clear the selection first
    --------------------------------------------------------------------------------
    libraries:deselectAll()

    --------------------------------------------------------------------------------
    -- Trigger the menu item to reveal the clip
    --------------------------------------------------------------------------------
    fcp:menuBar():selectMenu({"File", "Reveal in Browser"})

    if focus then
        --------------------------------------------------------------------------------
        -- Give FCPX time to find the clip
        --------------------------------------------------------------------------------
        local selectedClips = nil
        just.doUntil(function()
            selectedClips = libraries:selectedClipsUI()
            return selectedClips and #selectedClips > 0
        end)

        --------------------------------------------------------------------------------
        -- Check that there is exactly one Selected Clip
        --------------------------------------------------------------------------------
        if not selectedClips or #selectedClips ~= 1 then
            dialog.displayErrorMessage("Expected exactly 1 selected clip in the Libraries Browser.\n\nError occurred in matchFrame().")
            return nil
        end

        --------------------------------------------------------------------------------
        -- Get Browser Playhead:
        --------------------------------------------------------------------------------
        local playhead = libraries:playhead()
        if not playhead:isShowing() then
            dialog.displayErrorMessage("Unable to find Browser Persistent Playhead.\n\nError occurred in matchFrame().")
            return nil
        end

        --------------------------------------------------------------------------------
        -- Get Clip Name from the Viewer
        --------------------------------------------------------------------------------
        local clipName = fcp:viewer():title()

        if clipName then
            --------------------------------------------------------------------------------
            -- Ensure the Search Bar is visible
            --------------------------------------------------------------------------------
            if not libraries:search():isShowing() then
                libraries:searchToggle():press()
            end

            --------------------------------------------------------------------------------
            -- Search for the title
            --------------------------------------------------------------------------------
            libraries:search():setValue(clipName)
        else
            log.ef("Unable to find the clip title.")
        end
    end

    --------------------------------------------------------------------------------
    -- Highlight Browser Playhead:
    --------------------------------------------------------------------------------
    mod.browserPlayhead.highlight()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.matchframe",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.browser.playhead"]    = "browserPlayhead",
        ["finalcutpro.clipboard.manager"]   = "clipboardManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Link to dependencies:
    --------------------------------------------------------------------------------
    mod.browserPlayhead = deps.browserPlayhead
    mod.clipboardManager = deps.clipboardManager

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        local cmds = deps.fcpxCmds
        cmds:add("cpRevealMulticamClipInBrowserAndHighlight")
            :groupedBy("timeline")
            :activatedBy():ctrl():option():cmd("d")
            :whenActivated(function() mod.multicamMatchFrame(true) end)

        cmds:add("cpRevealMulticamClipInAngleEditorAndHighlight")
            :groupedBy("timeline")
            :activatedBy():ctrl():option():cmd("g")
            :whenActivated(function() mod.multicamMatchFrame(false) end)

        cmds:add("cpRevealInBrowserAndHighlight")
            :groupedBy("timeline")
            :activatedBy():ctrl():option():cmd("f")
            :whenActivated(function() mod.matchFrame(false) end)

        cmds:add("cpSingleMatchFrameAndHighlight")
            :groupedBy("timeline")
            :activatedBy():ctrl():option():cmd("s")
            :whenActivated(function() mod.matchFrame(true) end)
    end

    return mod
end

return plugin