--- === plugins.finalcutpro.inspector.text ===
---
--- Final Cut Pro Text Inspector Additions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("textInspector")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")
local just              = require("cp.just")
local dialog            = require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local function setTextAlign(value)

    --------------------------------------------------------------------------------
    -- TODO: This could probably be Rx-ified?
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
            dialog.displayErrorMessage("Failed to switch back to Final Cut Pro.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure the Timeline is selected:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            timeline:show()
            return timeline:isShowing()
        end) then
            dialog.displayErrorMessage("Timeline could not be shown.")
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
            dialog.displayErrorMessage("Text Inspector could not be shown.")
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
            dialog.displayErrorMessage("The selected clip doesn't offer any Text Alignment options.")
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.inspector.text",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds
            :add("alignTextToTheLeft")
            :whenActivated(function() setTextAlign("left") end)

        deps.fcpxCmds
            :add("alignTextToTheCentre")
            :whenActivated(function() setTextAlign("center") end)

        deps.fcpxCmds
            :add("alignTextToTheRight")
            :whenActivated(function() setTextAlign("right") end)

        deps.fcpxCmds
            :add("justifyLastLeft")
            :whenActivated(function() setTextAlign("justifiedLeft") end)

        deps.fcpxCmds
            :add("justifyLastCentre")
            :whenActivated(function() setTextAlign("justifiedCenter") end)

        deps.fcpxCmds
            :add("justifyLastRight")
            :whenActivated(function() setTextAlign("justifiedRight") end)

        deps.fcpxCmds
            :add("justifyAll")
            :whenActivated(function() setTextAlign("justifiedFull") end)

    end

end

return plugin