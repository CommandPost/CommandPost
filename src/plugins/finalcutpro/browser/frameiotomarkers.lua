--- === plugins.finalcutpro.browser.frameiotomarkers ===
---
--- Takes the contents of a Frame.io CSV file and adds markers to a clip
--- selected in the Final Cut Pro Browser. Only one clip can be selected.

local require           = require

local log               = require "hs.logger".new "frameiotomarkers"

local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local just              = require "cp.just"
local i18n              = require "cp.i18n"

local csv               = require "csv"

-- process() -> nil
-- Function
-- Processes CSV to Markers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function process()
    --------------------------------------------------------------------------------
    -- Request the CSV file:
    --------------------------------------------------------------------------------
    local path = dialog.displayChooseFile(i18n("pickAFrameIOCSVFile") .. ":", "csv")
    if not path then
        return
    end

    --------------------------------------------------------------------------------
    -- Process the CSV file:
    --------------------------------------------------------------------------------
    local data = csv.open(path)
    if not data then
        dialog.displayAlertMessage(i18n("problemProcessingCSV"))
        return
    end

    local results = {}

    local firstLine = true
    local commentColumn = nil
    local timecodeColumn = nil
    for fields in data:lines() do
        if firstLine then
            for i, v in ipairs(fields) do
                if v == "Comment" then
                    commentColumn = i
                end
                if v == "Timecode" then
                    timecodeColumn = i
                end
            end
            firstLine = false
        else

            local comment = commentColumn and fields[commentColumn]
            local timecode = timecodeColumn and fields[timecodeColumn]

            if comment and timecode then
                table.insert(results, {
                    comment = comment,
                    timecode = timecode,
                })
            else
                dialog.displayAlertMessage(i18n("problemProcessingCSV"))
                return
            end
        end
    end

    if next(results) == nil then
        dialog.displayAlertMessage(i18n("problemProcessingCSV"))
        return
    end

    --------------------------------------------------------------------------------
    -- Make sure the browser is showing:
    --------------------------------------------------------------------------------
    if not fcp.browser:isShowing() then
        dialog.displayAlertMessage(i18n("atLeastOneBrowserClipMustBeSelected"))
        return
    end

    --------------------------------------------------------------------------------
    -- Make sure only one clip is selected in the browser:
    --------------------------------------------------------------------------------
    local selectedClips = fcp.browser.libraries:selectedClips()
    if not selectedClips or #selectedClips == 0 then
        dialog.displayAlertMessage(i18n("atLeastOneBrowserClipMustBeSelected"))
        return
    elseif #selectedClips ~= 1 then
        dialog.displayAlertMessage(i18n("onlyOneBrowserClipMustBeSelected"))
        return
    end

    --------------------------------------------------------------------------------
    -- Add Markers:
    --------------------------------------------------------------------------------
    for i, v in pairs(results) do
        --------------------------------------------------------------------------------
        -- Goto timecode:
        --------------------------------------------------------------------------------
        local result = fcp.viewer:timecode(v.timecode)
        if not result then
            log.df("Current Line: %s", v)
            dialog.displayErrorMessage(string.format("Could not go to timecode for line %s.", i))
            return
        end

        --------------------------------------------------------------------------------
        -- Add Marker & Modify:
        --------------------------------------------------------------------------------
        local markerPopover = fcp.browser.markerPopover
        markerPopover:show()
        result = just.doUntil(function() return markerPopover:isShowing() end)
        if not result then
            dialog.displayErrorMessage(string.format("Could not add marker for line %s.", i))
            return
        end

        --------------------------------------------------------------------------------
        -- Set Name & Press "Done":
        --------------------------------------------------------------------------------
        markerPopover:name(v.comment)
        markerPopover:hide()
    end

    --------------------------------------------------------------------------------
    -- Success:
    --------------------------------------------------------------------------------
    dialog.displayMessage(i18n("addMarkersToSelectedClipInBrowserFromFrameIOCSVCompleted"))

end

local plugin = {
    id                = "finalcutpro.browser.frameiotomarkers",
    group            = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("addMarkersToSelectedClipInBrowserFromFrameIOCSV")
        :whenPressed(process)
end

return plugin
