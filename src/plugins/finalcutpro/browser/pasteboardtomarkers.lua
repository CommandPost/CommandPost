--- === plugins.finalcutpro.browser.pasteboardtomarkers ===
---
--- Take the contents of the Pasteboard and pastes it as clip markers on the
--- selected clip in the Final Cut Pro Browser. Only one clip can be selected.
---
--- Supported format:
---
--- ```
--- 05:00:00: Test Keyword 1
--- #05:01:00:01: Test Keyword 2
--- *05:02:00: Test Keyword 3
--- 05:02:15: Test Keyword 4
--- *05:03:00: Test Keyword 5
--- 05:03:15: Test Keyword 6
--- #05:03:30: Test Keyword 7
--- *05:04:00: Test Keyword 8
--- ```
---
--- If a * is place before the timecode, it will make the clip as a favourite
--- between the current timecode value and the next timecode value.
---
--- If a # is place before the timecode, it will create a "To Do" marker.

local require = require

local log                       = require("hs.logger").new("pasteboardtomarkers")

local pasteboard                = require("hs.pasteboard")

local dialog                    = require("cp.dialog")
local fcp                       = require("cp.apple.finalcutpro")
local just                      = require("cp.just")
local tools                     = require("cp.tools")
local i18n                      = require("cp.i18n")


local mod = {}

--- plugins.finalcutpro.browser.pasteboardtomarkers.process() -> nil
--- Function
--- Processes Pasteboard to Markers
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.process()

    local result

    --------------------------------------------------------------------------------
    -- Make sure the browser is showing:
    --------------------------------------------------------------------------------
    if not fcp:browser():isShowing() then
        dialog.displayAlertMessage(i18n("atLeastOneBrowserClipMustBeSelected"))
        return
    end

    --------------------------------------------------------------------------------
    -- Make sure only one clip is selected in the browser:
    --------------------------------------------------------------------------------
    local selectedClips = fcp:browser():libraries():selectedClips()
    if not selectedClips or #selectedClips == 0 then
        dialog.displayAlertMessage(i18n("atLeastOneBrowserClipMustBeSelected"))
        return
    elseif #selectedClips ~= 1 then
        dialog.displayAlertMessage(i18n("onlyOneBrowserClipMustBeSelected"))
        return
    end

    --------------------------------------------------------------------------------
    -- Get the contents of the pasteboard:
    --------------------------------------------------------------------------------
    local pasteboardContents = pasteboard.getContents()
    if not pasteboardContents then
        log.df("pasteboardContents: %s", pasteboardContents)
        dialog.displayErrorMessage(i18n("pasteboardToMarkersFailed"))
        return
    end

    --------------------------------------------------------------------------------
    -- Seperate the pasteboard contents by line:
    --------------------------------------------------------------------------------
    local lines = tools.lines(pasteboardContents)
    if not lines then
        log.df("pasteboardContents: %s", pasteboardContents)
        dialog.displayErrorMessage(i18n("pasteboardToMarkersFailed"))
        return
    end

    --------------------------------------------------------------------------------
    -- Process lines:
    --------------------------------------------------------------------------------
    for i, v in pairs(lines) do

        local toDoMarker = false
        local timecode, description, favouriteStart, favouriteEnd
        if string.sub(v, 1, 1) == "*" and string.find(v, "*%d%d:%d%d:%d%d:%d%d:") then
            --------------------------------------------------------------------------------
            -- *05:00:00:00: Example Marker Description
            --------------------------------------------------------------------------------
            timecode = string.sub(v, 2, 12)
            description = string.sub(v, 15)
            favouriteStart = timecode
        elseif string.sub(v, 1, 1) == "*" and string.find(v, "*%d%d:%d%d:%d%d:") then
            --------------------------------------------------------------------------------
            -- *05:00:00: Example Marker Description
            --------------------------------------------------------------------------------
            timecode = string.sub(v, 2, 9) .. ":00"
            description = string.sub(v, 12)
            favouriteStart = timecode
        elseif string.sub(v, 1, 1) == "#" and string.find(v, "#%d%d:%d%d:%d%d:%d%d:") then
            --------------------------------------------------------------------------------
            -- #05:00:00:00: Example Marker Description
            --------------------------------------------------------------------------------
            timecode = string.sub(v, 2, 12)
            description = string.sub(v, 15)
            toDoMarker = true
        elseif string.sub(v, 1, 1) == "#" and string.find(v, "#%d%d:%d%d:%d%d:") then
            --------------------------------------------------------------------------------
            -- #05:00:00: Example Marker Description
            --------------------------------------------------------------------------------
            timecode = string.sub(v, 2, 9) .. ":00"
            description = string.sub(v, 12)
            toDoMarker = true
        elseif string.find(v, "%d%d:%d%d:%d%d:%d%d:") then
            --------------------------------------------------------------------------------
            -- 05:00:00:00: Example Marker Description
            --------------------------------------------------------------------------------
            timecode = string.sub(v, 1, 11)
            description = string.sub(v, 14)
        elseif string.find(v, "%d%d:%d%d:%d%d:") then
            --------------------------------------------------------------------------------
            -- 05:00:00: Example Marker Description
            --------------------------------------------------------------------------------
            timecode = string.sub(v, 1, 8) .. ":00"
            description = string.sub(v, 11)
        end
        if not timecode or not description then
            if i == 1 then
                log.df("pasteboardContents: %s", pasteboardContents)
                dialog.displayErrorMessage(i18n("pasteboardToMarkersFailed"))
            else
                log.df("pasteboardContents: %s", pasteboardContents)
                dialog.displayErrorMessage(string.format("Failed to process line %s of the pasteboard contents.", i))
            end
            return
        end

        --------------------------------------------------------------------------------
        -- If it's a favourite...
        --------------------------------------------------------------------------------
        if favouriteStart then
            local nextLine = lines[i + 1]
            if nextLine then
                if string.sub(nextLine, 1, 1) == "*" and string.find(nextLine, "*%d%d:%d%d:%d%d:%d%d:") then
                    favouriteEnd = string.sub(nextLine, 2, 12)
                elseif string.sub(nextLine, 1, 1) == "*" and string.find(nextLine, "*%d%d:%d%d:%d%d:") then
                    favouriteEnd = string.sub(nextLine, 2, 9)
                elseif string.find(nextLine, "%d%d:%d%d:%d%d:%d%d:") then
                    favouriteEnd = string.sub(nextLine, 1, 11)
                elseif string.find(nextLine, "%d%d:%d%d:%d%d:") then
                    favouriteEnd = string.sub(nextLine, 1, 8)
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Goto timecode:
        --------------------------------------------------------------------------------
        result = fcp:viewer():timecode(timecode)
        if not result then
            log.df("Current Line: %s", v)
            dialog.displayErrorMessage(string.format("Could not go to timecode for line %s.", i))
            return
        end

        --------------------------------------------------------------------------------
        -- Add Marker & Modify:
        --------------------------------------------------------------------------------
        local markerPopover = fcp:browser():markerPopover()
        markerPopover:show()
        result = just.doUntil(function() return markerPopover:isShowing() end)
        if not result then
            dialog.displayErrorMessage(string.format("Could not add marker for line %s.", i))
            return
        end

        --------------------------------------------------------------------------------
        -- If it's a "To Do" Marker then change tabs:
        --------------------------------------------------------------------------------
        if toDoMarker then
            markerPopover:toDo():press()
            result = just.doUntil(function() return markerPopover:toDo():checked() end)
            if not result then
                dialog.displayErrorMessage(string.format("Could not check 'To Do' for line %s.", i))
                return
            end
        end

        --------------------------------------------------------------------------------
        -- Set Name & Press "Done":
        --------------------------------------------------------------------------------
        markerPopover:name(description)
        markerPopover:hide()

        --------------------------------------------------------------------------------
        -- Add Favourite Range:
        --------------------------------------------------------------------------------
        if favouriteStart then

            --------------------------------------------------------------------------------
            -- Add frames if missing:
            --------------------------------------------------------------------------------
            if string.len(favouriteStart) == 8 then
                favouriteStart = favouriteStart .. ":00"
            end
            if favouriteEnd then
                if string.len(favouriteEnd) == 8 then
                    favouriteEnd = favouriteEnd .. ":00"
                end
            end

            --------------------------------------------------------------------------------
            -- Goto start timecode:
            --------------------------------------------------------------------------------
            result = fcp:viewer():timecode(favouriteStart)
            if not result then
                log.df("favouriteStart: %s", favouriteStart)
                dialog.displayErrorMessage(string.format("Could not go to favourite start timecode for line %s.", i))
                return
            end

            --------------------------------------------------------------------------------
            -- Mark in:
            --------------------------------------------------------------------------------
            result = fcp:selectMenu({"Mark", "Set Range Start"})
            if not result then
                dialog.displayErrorMessage(string.format("Could not set in point for favourite start on line %s.", i))
                return
            end

            --------------------------------------------------------------------------------
            -- Goto end timecode:
            --------------------------------------------------------------------------------
            if favouriteEnd then
                result = fcp:libraries():playhead():timecode(favouriteEnd)
                if not result then
                    log.df("favouriteEnd: %s", favouriteEnd)
                    dialog.displayErrorMessage(string.format("Could not go to favourite end timecode for line %s.", i))
                    return
                end
            else
                --------------------------------------------------------------------------------
                -- Go to the end of the clip:
                --------------------------------------------------------------------------------
                result = fcp:selectMenu({"Mark", "Go to", "End"})
                if not result then
                    dialog.displayErrorMessage(string.format("Could not go to end for favourite end on line %s.", i))
                    return
                end
            end

            --------------------------------------------------------------------------------
            -- Mark out:
            --------------------------------------------------------------------------------
            result = fcp:selectMenu({"Mark", "Set Range End"})
            if not result then
                dialog.displayErrorMessage(string.format("Could not set out point for favourite start on line %s.", i))
                return
            end

            --------------------------------------------------------------------------------
            -- Favourite:
            --------------------------------------------------------------------------------
            result = fcp:selectMenu({"Mark", "Favorite"})
            if not result then
                dialog.displayErrorMessage(string.format("Could not favourite on line %s.", i))
                return
            end

        end

    end

    --------------------------------------------------------------------------------
    -- Success:
    --------------------------------------------------------------------------------
    dialog.displayMessage(i18n("pasteboardToMarkersCompleted"))

end

--- plugins.finalcutpro.browser.pasteboardtomarkers.init() -> deps
--- Function
--- Initialise the module.
---
--- Parameters:
---  * deps - Plugin Dependencies
---
--- Returns:
---  * None
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- Add a new Global Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("pasteboardToMarkers")
        :whenPressed(mod.process)

    return mod
end


local plugin = {
    id                = "finalcutpro.browser.pasteboardtomarkers",
    group            = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    return mod.init(deps)
end

return plugin
