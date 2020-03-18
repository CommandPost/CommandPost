--- === plugins.finalcutpro.inspector.text ===
---
--- Final Cut Pro Text Inspector Additions.

local require                   = require

local log                       = require "hs.logger".new "textInspector"

local pasteboard                = require "hs.pasteboard"

local dialog                    = require "cp.dialog"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local just                      = require "cp.just"
local tools                     = require "cp.tools"

local displayErrorMessage       = dialog.displayErrorMessage
local playErrorSound            = tools.playErrorSound

local function setTextAlign(value)

    --------------------------------------------------------------------------------
    -- TODO: This should probably be Rx-ified.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Make sure at least one clip is selected:
    --------------------------------------------------------------------------------
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local clips = timelineContents:selectedClipsUI()
    if clips and #clips == 0 then
        log.df("No clips selected.")
        tools.playErrorSound()
        return
    end

    --------------------------------------------------------------------------------
    -- Process each clip individually:
    --------------------------------------------------------------------------------
    for _,clip in tools.spairs(clips, function(t,a,b) return t[a]:attributeValue("AXValueDescription") < t[b]:attributeValue("AXValueDescription") end) do

        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            fcp:launch()
            return fcp:isFrontmost()
        end) then
            displayErrorMessage(i18n("failedToSwitchBackToFinalCutPro"))
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure the Timeline is selected:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            timeline:show()
            return timeline:isShowing()
        end) then
            displayErrorMessage(i18n("timelineCouldNotBeShown"))
            return false
        end

        if #clips ~= 1 then
            --------------------------------------------------------------------------------
            -- Select the clip:
            --------------------------------------------------------------------------------
            timelineContents:selectClip(clip)

            --------------------------------------------------------------------------------
            -- TODO: I'm not exactly sure why, but this only works if I add a wait here?
            --------------------------------------------------------------------------------
            just.wait(0.3)
        end

        --------------------------------------------------------------------------------
        -- Make sure Text Inspector is active:
        --------------------------------------------------------------------------------
        local text = fcp:inspector():text()
        if not just.doUntil(function()
            text:show()
            return text:isShowing()
        end) then
            displayErrorMessage(i18n("textInspectorCouldNotBeShown"))
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure there's a Basic Section:
        --------------------------------------------------------------------------------
        local basic = text:basic()
        if not just.doUntil(function()
            basic:show()
            return basic:isShowing()
        end) then
            displayErrorMessage(i18n("selectedClipDoesntOfferAnyTextAlignmentOptions"))
            return false
        end

        --------------------------------------------------------------------------------
        -- Set Text Alignment:
        --------------------------------------------------------------------------------
        local alignment = basic:alignment()
        if value == "left" then
            alignment:left(true)
        elseif value == "center" then
            alignment:center(true)
        elseif value == "right" then
            alignment:right(true)
        elseif value == "justifiedLeft" then
            alignment:justifiedLeft(true)
        elseif value == "justifiedCenter" then
            alignment:justifiedCenter(true)
        elseif value == "justifiedRight" then
            alignment:justifiedRight(true)
        elseif value == "justifiedFull" then
            alignment:justifiedFull(true)
        end
    end

    --------------------------------------------------------------------------------
    -- Reselect original clips:
    --------------------------------------------------------------------------------
    timelineContents:selectClips(clips)

end

local plugin = {
    id              = "finalcutpro.inspector.text",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Text Align:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("alignTextToTheLeft")
        :whenActivated(function() setTextAlign("left") end)

    fcpxCmds
        :add("alignTextToTheCentre")
        :whenActivated(function() setTextAlign("center") end)

    fcpxCmds
        :add("alignTextToTheRight")
        :whenActivated(function() setTextAlign("right") end)

    --------------------------------------------------------------------------------
    -- Text Justify:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("justifyLastLeft")
        :whenActivated(function() setTextAlign("justifiedLeft") end)

    fcpxCmds
        :add("justifyLastCentre")
        :whenActivated(function() setTextAlign("justifiedCenter") end)

    fcpxCmds
        :add("justifyLastRight")
        :whenActivated(function() setTextAlign("justifiedRight") end)

    fcpxCmds
        :add("justifyAll")
        :whenActivated(function() setTextAlign("justifiedFull") end)

    --------------------------------------------------------------------------------
    -- Replace Pasteboard Contents with Selected Title Text:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("replaceSelectedTitleTextwithPasteboardContents")
        :whenActivated(function()
            local textArea = fcp:inspector():text():textArea()
            local contents = pasteboard.getContents()
            if contents then
                textArea:show()
                textArea:value(contents)
                return
            end
            playErrorSound()
        end)
        :titled(i18n("replaceSelectedTitleTextwithPasteboardContents"))

    --------------------------------------------------------------------------------
    -- Replace Pasteboard Contents with Selected Title Text:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("appendSelectedTitleTextwithPasteboardContents")
        :whenActivated(function()
            local textArea = fcp:inspector():text():textArea()
            local contents = pasteboard.getContents()
            if contents then
                textArea:show()
                local original = textArea:value()
                if original then
                    textArea:value(original .. contents)
                    return
                end
            end
            playErrorSound()
        end)
        :titled(i18n("appendSelectedTitleTextwithPasteboardContents"))

    --------------------------------------------------------------------------------
    -- Focus on Title Text in Inspector:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("focusOnTitleTextInInspector")
        :whenActivated(function()
            local textArea = fcp:inspector():text():textArea()
            textArea:show()
            fcp:selectMenu({"Window", "Go To", "Inspector"})
            textArea:focused(true)
        end)
        :titled(i18n("focusOnTitleTextInInspector"))

    --------------------------------------------------------------------------------
    -- Copy Title Text Contents to Pasteboard:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("copyTitleTextContentsToPasteboard")
        :whenActivated(function()
            local textArea = fcp:inspector():text():textArea()
            textArea:show()
            local value = textArea:value()
            if value then
                pasteboard.writeObjects(value)
                return
            end
            playErrorSound()
        end)
        :titled(i18n("copyTitleTextContentsToPasteboard"))

end

return plugin