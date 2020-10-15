--- === plugins.finalcutpro.browser.clearnotes ===
---
--- Clear Notes in Final Cut Pro Browser.

local require = require

--local log                   = require "hs.logger".new "clearNotes"

local axutils               = require "cp.ui.axutils"
local fcp                   = require "cp.apple.finalcutpro"
local tools                 = require "cp.tools"

local playErrorSound        = tools.playErrorSound
local childWithRole         = axutils.childWithRole

local plugin = {
    id              = "finalcutpro.browser.clearnotes",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    deps.fcpxCmds
        :add("clearBrowserNotes")
        :whenActivated(function()
            --------------------------------------------------------------------------------
            -- Make sure the Browser is visible:
            --------------------------------------------------------------------------------
            local libraries = fcp.browser.libraries
            if not libraries:isShowing() then
                playErrorSound()
                return
            end

            --------------------------------------------------------------------------------
            -- Make sure we're in list mode:
            --------------------------------------------------------------------------------
            if libraries:isFilmstripView() then
                playErrorSound()
                return
            end

            --------------------------------------------------------------------------------
            -- Make sure there's at least one clip selected:
            --------------------------------------------------------------------------------
            local clipsUI = libraries:selectedClipsUI()
            if #clipsUI == 0 then
                playErrorSound()
                return
            end

            --------------------------------------------------------------------------------
            -- Get Selected Clip & Selected Clip's Parent:
            --------------------------------------------------------------------------------
            local selectedClip = clipsUI[1]
            local selectedClipParent = selectedClip:attributeValue("AXParent")

            --------------------------------------------------------------------------------
            -- Get the AXGroup:
            --------------------------------------------------------------------------------
            local listHeadingGroup = childWithRole(selectedClipParent, "AXGroup")

            --------------------------------------------------------------------------------
            -- Find the 'Notes' column:
            --------------------------------------------------------------------------------
            local notesFieldID = nil
            for i=1, listHeadingGroup:attributeValueCount("AXChildren") do
                local title = listHeadingGroup[i]:attributeValue("AXTitle")
                if title == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
                    notesFieldID = i
                end
            end

            --------------------------------------------------------------------------------
            -- Make sure the Notes field is actually showing:
            --------------------------------------------------------------------------------
            if notesFieldID == nil then
                playErrorSound()
                return
            end

            --------------------------------------------------------------------------------
            -- Loop through the selected clips:
            --------------------------------------------------------------------------------
            local clips = libraries:selectedClips()
            for _, clip in pairs(clips) do
                libraries:selectClip(clip)

                local selectedClipUI = libraries:selectedClipsUI()[1]
                local selectedNotesField = selectedClipUI[notesFieldID][1]

                selectedNotesField:setAttributeValue("AXFocused", true)
                selectedNotesField:setAttributeValue("AXValue", "")
                selectedNotesField:performAction("AXConfirm")
                selectedNotesField:setAttributeValue("AXFocused", false)
            end

            --------------------------------------------------------------------------------
            -- Select all the original clips again:
            --------------------------------------------------------------------------------
            libraries:selectAll(clips)

        end)
end

return plugin
