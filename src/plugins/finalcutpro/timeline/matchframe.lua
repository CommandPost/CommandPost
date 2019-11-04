--- === plugins.finalcutpro.timeline.matchframe ===
---
--- Match Frame Tools for Final Cut Pro.

local require                   = require

local log                       = require "hs.logger".new "matchframe"

local chooser                   = require "hs.chooser"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"

local axutils                   = require "cp.ui.axutils"
local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local just                      = require "cp.just"
local tools                     = require "cp.tools"

local childIndex                = axutils.childIndex
local displayErrorMessage       = dialog.displayErrorMessage
local displayNotification       = dialog.displayNotification
local playErrorSound            = tools.playErrorSound
local sort                      = table.sort
local tableCount                = tools.tableCount

local mod = {}

-- TODO: Add documentation
mod.hiddenKeywords = config.prop("revealInKeywordCollection.hiddenKeywords", {})

-- TODO: Add Favourite Keywords:
--mod.favouriteKeywords = config.prop("revealInKeywordCollection.favouriteKeywords", {})

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
    local menuBar = fcp:menu()
    if menuBar:isEnabled({"Clip", "Open in Angle Editor"}) then
        menuBar:selectMenu({"Clip", "Open in Angle Editor"})
    else
        displayErrorMessage("Failed to open clip in Angle Editor.\n\nAre you sure the clip you have selected is a Multicam?" .. errorFunction)
        return false
    end

    --------------------------------------------------------------------------------
    -- Put focus back on the timeline:
    --------------------------------------------------------------------------------
    if menuBar:isEnabled({"Window", "Go To", "Timeline"}) then
        menuBar:selectMenu({"Window", "Go To", "Timeline"})
    else
        displayErrorMessage("Unable to return to timeline." .. errorFunction)
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
            displayErrorMessage("Unable to go back to previous timeline." .. errorFunction)
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
    local result, pasteboardData = mod.pasteboardManager.ninjaPasteboardCopy()
    if not result then
        log.ef("Ninja Pasteboard Copy Failed." .. errorFunction)
        return false
    end

    local pasteboard = mod.pasteboardManager

    --------------------------------------------------------------------------------
    -- Convert Binary Data to Table:
    --------------------------------------------------------------------------------
    local fcpxTable = pasteboard.unarchiveFCPXData(pasteboardData)
    if fcpxTable == nil then
        log.ef("Converting Binary Data to Table failed." .. errorFunction)
        return false
    end

    local timelineClip = fcpxTable.root.objects[1]
    if not pasteboard.isTimelineClip(timelineClip) then
        log.ef("Not copied from the Timeline." .. errorFunction)
        return false
    end

    local selectedClips = timelineClip.containedItems
    if #selectedClips ~= 1 or pasteboard.getClassname(selectedClips[1]) ~= "FFAnchoredAngle" then
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

-- soloClip() -> none
-- Function
-- Solo's a clip in the Browser.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function soloClip()
    --------------------------------------------------------------------------------
    -- Give FCPX time to find the clip
    --------------------------------------------------------------------------------
    local libraries = fcp:libraries()
    local selectedClips = nil
    just.doUntil(function()
        selectedClips = libraries:selectedClipsUI()
        return selectedClips and #selectedClips > 0
    end)

    --------------------------------------------------------------------------------
    -- Check that there is exactly one Selected Clip
    --------------------------------------------------------------------------------
    if not selectedClips or #selectedClips ~= 1 then
        displayErrorMessage("Expected exactly 1 selected clip in the Libraries Browser.\n\nError occurred in soloClip().")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Get Browser Playhead:
    --------------------------------------------------------------------------------
    local playhead = libraries:playhead()
    if not playhead:isShowing() then
        displayErrorMessage("Unable to find Browser Persistent Playhead.\n\nError occurred in soloClip().")
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
        if not libraries.search:isShowing() then
            libraries:searchToggle()
        end

        --------------------------------------------------------------------------------
        -- Search for the title
        --------------------------------------------------------------------------------
        libraries:search(clipName)
    else
        log.ef("Unable to find the clip title.")
    end
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
    if not fcp:menu():isEnabled({"File", "Reveal in Browser"}) then
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
    fcp:menu():selectMenu({"File", "Reveal in Browser"})

    --------------------------------------------------------------------------------
    -- Solo Clip:
    --------------------------------------------------------------------------------
    if focus then
        soloClip()
    end

    --------------------------------------------------------------------------------
    -- Highlight Browser Playhead:
    --------------------------------------------------------------------------------
    mod.browserPlayhead.highlight()
end

-- selectKeywordCollection(keyword[, solo]) -> none
-- Function
-- Reveal in Keyword Collection
--
-- Parameters:
--  * keyword - The keyword to select as string
--  * solo - An optional boolean which specific whether or not to solo the clip
--
-- Returns:
--  * None
local function selectKeywordCollection(keyword, solo)
    fcp:selectMenu({"File", "Reveal in Browser"})

    local sidebar = fcp:libraries():sidebar()

    local selectedRowsUI = sidebar:selectedRowsUI()
    local selectedRowUI = selectedRowsUI and selectedRowsUI[1]

    if selectedRowUI then
        --------------------------------------------------------------------------------
        -- Show & Disclose the Event:
        --------------------------------------------------------------------------------
        sidebar:showRow(selectedRowUI)
        selectedRowUI:setAttributeValue("AXDisclosing", true)

        local index = childIndex(selectedRowUI)
        local rows = sidebar:rowsUI()

        for i=index + 1, #rows do
            local selectedRow = rows[i]
            if selectedRow then
                --------------------------------------------------------------------------------
                -- This should never happen, but just in-case:
                --------------------------------------------------------------------------------
                if selectedRow:attributeValue("AXDisclosureLevel") == 1 then
                    playErrorSound()
                    return
                end

                --------------------------------------------------------------------------------
                -- Disclose each folder:
                --------------------------------------------------------------------------------
                selectedRow:setAttributeValue("AXDisclosing", true)

                --------------------------------------------------------------------------------
                -- Check to see if we have a match:
                --------------------------------------------------------------------------------
                local children = selectedRow:attributeValue("AXChildren")
                local selectedValue = children and children[1] and children[1]:attributeValue("AXValue")
                if selectedValue and string.lower(selectedValue) == keyword then -- All keywords in the Pasteboard are lowercase
                    --------------------------------------------------------------------------------
                    -- Select the keyword collection:
                    --------------------------------------------------------------------------------
                    sidebar:selectRowAt(i)

                    --------------------------------------------------------------------------------
                    -- Solo the clip if necessary:
                    --------------------------------------------------------------------------------
                    if solo then
                        soloClip()
                    end
                    return
                end
            end
        end
    end
    playErrorSound()
end

-- revealInKeywordCollection(solo) -> none
-- Function
-- Reveal in Keyword Collection
--
-- Parameters:
--  * solo - An optional boolean which specific whether or not to solo the clip
--
-- Returns:
--  * None
local function revealInKeywordCollection(solo)
    --------------------------------------------------------------------------------
    -- Make sure the timeline is focussed:
    --------------------------------------------------------------------------------
    fcp:selectMenu({"Window", "Go To", "Timeline"})

    --------------------------------------------------------------------------------
    -- Ninja Pasteboard time:
    --------------------------------------------------------------------------------
    local manager = mod.pasteboardManager
    local result, archivedData = manager.ninjaPasteboardCopy()
    local data = result and manager.unarchiveFCPXData(archivedData)
    if data and data.root and data.root.objects and data.root.objects[1] then
        --------------------------------------------------------------------------------
        -- Get root object:
        --------------------------------------------------------------------------------
        local object = data.root.objects[1]
        local containedItems = object.containedItems

        --------------------------------------------------------------------------------
        -- Make sure only one clip is selected:
        --------------------------------------------------------------------------------
        local singleClipSelected = true
        if containedItems and containedItems[1] and containedItems[1]["anchoredItems"] then
            --------------------------------------------------------------------------------
            -- More than one clip in primary storyline selected:
            --------------------------------------------------------------------------------
            if object.displayName == "__timelineContainerClip" and tableCount(containedItems) ~= 1 then
                singleClipSelected = false
            end

            --------------------------------------------------------------------------------
            -- More than one clip in secondary storyline groups selected:
            --------------------------------------------------------------------------------
            if containedItems[1]["displayName"] == "Gap" and tableCount(containedItems[1]["anchoredItems"]) ~= 1 then
                singleClipSelected = false
            elseif containedItems[1]["displayName"] == "Gap" and tableCount(containedItems[1]["anchoredItems"][1]["containedItems"]) ~= 1 then
                singleClipSelected = false
            end
        end
        if not singleClipSelected then
            displayNotification(i18n("mustHaveSingleClipSelectedInTimeline"))
            playErrorSound()
            return
        end

        --------------------------------------------------------------------------------
        -- Get keywords from Pasteboard:
        --------------------------------------------------------------------------------
        local keywords = {}
        for _, vv in pairs(containedItems) do

            local cr = vv.clippedRange and load("return " .. vv.clippedRange)()

            local clipStart = cr[1]
            local clipEnd = cr[1] + cr[2]

            local anchoredItems = vv.anchoredItems
            if anchoredItems then
                for _, v in pairs(anchoredItems) do

                    local anchorPair = v.anchorPair and load("return " .. v.anchorPair)()
                    local duration = v.duration and load("return " .. v.duration)()

                    local aClippedRange = v.clippedRange and load("return " .. v.clippedRange)()
                    local baseClipStart = aClippedRange and aClippedRange[1]
                    local baseClipEnd = aClippedRange and (aClippedRange[1] + aClippedRange[2])

                    --------------------------------------------------------------------------------
                    -- If the clip is in the primary storyline:
                    --------------------------------------------------------------------------------
                    local metadata = v.metadata
                    if metadata and metadata.keywords then
                        local keywordStart = anchorPair and anchorPair[2]
                        local keywordEnd = duration and keywordStart and (duration + keywordStart)

                        --------------------------------------------------------------------------------
                        -- If a keyword begins at the start of a multicam clip, it might not have an
                        -- anchorPair value for some reason:
                        --------------------------------------------------------------------------------
                        if duration and not anchorPair then
                            keywordStart = 0
                            keywordEnd = duration
                        end

                        --------------------------------------------------------------------------------
                        -- Make sure the keyword is within the range of the selected clip:
                        --------------------------------------------------------------------------------
                        if keywordStart and keywordEnd and clipStart and clipEnd
                        and (clipStart >= keywordStart and clipStart <= keywordEnd)
                        or (clipEnd >= keywordStart and clipEnd <= keywordEnd)
                        or (clipStart < keywordStart and clipEnd > keywordEnd) then
                            for _, keyword in pairs(metadata.keywords) do
                                local r
                                if type(keyword) == "table" and keyword["NS.string"] then
                                    r = keyword["NS.string"]
                                else
                                    r = keyword
                                end
                                table.insert(keywords, r)
                            end
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- If the clip is above or below the primary storyline, but not in a
                    -- secondary storyline group:
                    --------------------------------------------------------------------------------
                    if v["anchoredItems"] then
                        for _, vvv in pairs(v["anchoredItems"]) do
                            local m = vvv.metadata
                            if m and m.keywords then

                                local sAnchorPair = vvv.anchorPair and load("return " .. vvv.anchorPair)()
                                local sDuration = vvv.duration and load("return " .. vvv.duration)()

                                local keywordStart = sAnchorPair and sAnchorPair[2]
                                local keywordEnd = sDuration and keywordStart and (sDuration + keywordStart)

                                --------------------------------------------------------------------------------
                                -- If a keyword begins at the start of a multicam clip, it might not have an
                                -- anchorPair value for some reason:
                                --------------------------------------------------------------------------------
                                if sDuration and not sAnchorPair then
                                    keywordStart = 0
                                    keywordEnd = sDuration
                                end

                                --------------------------------------------------------------------------------
                                -- Make sure the keyword is within the range of the selected clip:
                                --------------------------------------------------------------------------------
                                if keywordStart and keywordEnd and baseClipStart and baseClipEnd
                                and (baseClipStart >= keywordStart and baseClipStart <= keywordEnd)
                                or (baseClipEnd >= keywordStart and baseClipEnd <= keywordEnd)
                                or (baseClipStart < keywordStart and baseClipEnd > keywordEnd) then
                                    for _, keyword in pairs(m.keywords) do
                                        local r
                                        if type(keyword) == "table" and keyword["NS.string"] then
                                            r = keyword["NS.string"]
                                        else
                                            r = keyword
                                        end
                                        table.insert(keywords, r)
                                    end
                                end
                            end
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- If the clip is within a secondary storyline:
                    --------------------------------------------------------------------------------
                    if v["containedItems"] then
                        for _, c in pairs(v["containedItems"]) do

                            local bClippedRange = c.clippedRange and load("return " .. c.clippedRange)()
                            local bClipStart = bClippedRange and bClippedRange[1]
                            local bClipEnd = bClippedRange and (bClippedRange[1] + bClippedRange[2])

                            local ai = c.anchoredItems
                            if ai then
                                for _, a in pairs(ai) do
                                    local mm = a and a.metadata
                                    if mm and mm.keywords then

                                        local ap = a.anchorPair and load("return " .. a.anchorPair)()
                                        local du = a.duration and load("return " .. a.duration)()

                                        local keywordStart = ap and ap[2]
                                        local keywordEnd = du and keywordStart and (du + keywordStart)

                                        --------------------------------------------------------------------------------
                                        -- If a keyword begins at the start of a multicam clip, it might not have an
                                        -- anchorPair value for some reason:
                                        --------------------------------------------------------------------------------
                                        if du and not ap then
                                            keywordStart = 0
                                            keywordEnd = du
                                        end

                                        --------------------------------------------------------------------------------
                                        -- Make sure the keyword is within the range of the selected clip:
                                        --------------------------------------------------------------------------------
                                        if keywordStart and keywordEnd and bClipStart and bClipEnd
                                        and (bClipStart >= keywordStart and bClipStart <= keywordEnd)
                                        or (bClipEnd >= keywordStart and bClipEnd <= keywordEnd)
                                        or (bClipStart < keywordStart and bClipEnd > keywordEnd) then
                                            for _, keyword in pairs(mm.keywords) do
                                                if type(keyword) == "table" and keyword["NS.string"] then
                                                    table.insert(keywords, keyword["NS.string"])
                                                else
                                                    table.insert(keywords, keyword)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Remove duplicate keywords:
        --------------------------------------------------------------------------------
        local hash = {}
        local uniqueKeywords = {}
        for _, v in ipairs(keywords) do
           if not hash[v] then
               uniqueKeywords[#uniqueKeywords+1] = v
               hash[v] = true
           end
        end
        keywords = uniqueKeywords

        if #keywords == 0 then
            --------------------------------------------------------------------------------
            -- If no keywords on the clip, just "Reveal in Browser":
            --------------------------------------------------------------------------------
            fcp:menu():selectMenu({"File", "Reveal in Browser"})

            --------------------------------------------------------------------------------
            -- Solo the clip if necessary:
            --------------------------------------------------------------------------------
            if solo then
                soloClip()
            end

            return
        elseif #keywords == 1 then
            --------------------------------------------------------------------------------
            -- If there's only a single keyword on the clip:
            --------------------------------------------------------------------------------
            selectKeywordCollection(keywords[1], solo)
            return
        elseif #keywords > 1 then
            --------------------------------------------------------------------------------
            -- If there's multiple keywords on the clip, open the Search Console:
            --------------------------------------------------------------------------------
            if keywords then
                mod.chooser = chooser.new(function(k)
                    if k and k.text then
                        selectKeywordCollection(k.text, solo)
                    end
                end)
                    :choices(function()
                        local choices = {}
                        local hiddenKeywords = mod.hiddenKeywords()
                        for _, keyword in ipairs(keywords) do
                            if not hiddenKeywords[keyword] then
                                table.insert(choices, {
                                    ["text"] = keyword,
                                })
                            end
                        end
                        sort(choices, function(a, b) return a.text < b.text end)
                        return choices
                    end)
                    :bgDark(true)
                    :rightClickCallback(function(row)
                        local hiddenKeywords = mod.hiddenKeywords()
                        local hiddenKeywordsMenu = {}
                        if next(hiddenKeywords) == nil then
                            table.insert(hiddenKeywordsMenu, { title = i18n("none"), disabled = true })
                        else
                            for i,_ in pairs(hiddenKeywords) do
                                table.insert(hiddenKeywordsMenu, {title = i, fn = function()
                                    hiddenKeywords[i] = nil
                                    mod.hiddenKeywords(hiddenKeywords)
                                    mod.chooser:refreshChoicesCallback(true)
                                end})
                            end
                        end

                        local menu = {
                            { title = i18n("hideKeyword"), fn = function()
                                local contents = mod.chooser:selectedRowContents(row)
                                local hk = mod.hiddenKeywords()
                                hk[contents.text] = true
                                mod.hk(hiddenKeywords)
                                mod.chooser:refreshChoicesCallback(true)
                            end, disabled = row == 0 },
                            { title = i18n("restoreHiddenKeyword"), menu = hiddenKeywordsMenu }
                        }

                        local mb = menubar.new(false)
                            :setMenu(menu)
                            :popupMenu(mouse.getAbsolutePosition(), true)
                    end)
                    :show()
            end
        end
    else
        playErrorSound()
    end
end

local plugin = {
    id = "finalcutpro.timeline.matchframe",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.browser.playhead"]    = "browserPlayhead",
        ["finalcutpro.pasteboard.manager"]   = "pasteboardManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Link to dependencies:
    --------------------------------------------------------------------------------
    mod.browserPlayhead = deps.browserPlayhead
    mod.pasteboardManager = deps.pasteboardManager

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local cmds = deps.fcpxCmds
    cmds
        :add("cpRevealMulticamClipInBrowserAndHighlight")
        :groupedBy("timeline")
        :whenActivated(function() mod.multicamMatchFrame(true) end)

    cmds
        :add("cpRevealMulticamClipInAngleEditorAndHighlight")
        :groupedBy("timeline")
        :whenActivated(function() mod.multicamMatchFrame(false) end)

    cmds
        :add("cpRevealInBrowserAndHighlight")
        :groupedBy("timeline")
        :whenActivated(function() mod.matchFrame(false) end)

    cmds
        :add("cpSingleMatchFrameAndHighlight")
        :groupedBy("timeline")
        :whenActivated(function() mod.matchFrame(true) end)

    cmds
        :add("revealInKeywordCollection")
        :whenActivated(revealInKeywordCollection)
        :titled(i18n("revealInKeywordCollection"))
        :subtitled(i18n("revealInKeywordCollectionDescription"))

    cmds
        :add("revealInKeywordCollectionAndSolo")
        :whenActivated(function() revealInKeywordCollection(true) end)
        :titled(i18n("revealInKeywordCollectionAndSolo"))
        :subtitled(i18n("revealInKeywordCollectionAndSoloDescription"))

    return mod
end

return plugin
