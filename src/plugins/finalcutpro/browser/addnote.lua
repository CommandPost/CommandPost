--- === plugins.finalcutpro.browser.addnote ===
---
--- Add Note Plugin.

local require                   = require

local log                       = require "hs.logger".new "addnote"

local chooser                   = require "hs.chooser"
local drawing                   = require "hs.drawing"
local eventtap                  = require "hs.eventtap"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local screen                    = require "hs.screen"

local axutils                   = require "cp.ui.axutils"
local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local just                      = require "cp.just"

local childWithRole             = axutils.childWithRole
local displayErrorMessage       = dialog.displayErrorMessage
local displayMessage            = dialog.displayMessage
local doUntil                   = just.doUntil

local mod = {}

--- plugins.finalcutpro.browser.addnote.recentNotes <cp.prop: table>
--- Field
--- Table of recent notes.
mod.recentNotes = config.prop("recentNotes", {})

--- plugins.finalcutpro.browser.addnote.addNoteToSelectedClip() -> none
--- Function
--- Add Note to Selected Clip.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.addNoteToSelectedClips()

    local errorFunction = " Error occurred in addNoteToSelectedClip()."

    --------------------------------------------------------------------------------
    -- Make sure the Browser is visible:
    --------------------------------------------------------------------------------
    local libraries = fcp:browser():libraries()
    if not doUntil(function()
        libraries:show()
        return libraries:show()
    end, 5, 0.1) then
        displayErrorMessage("Failed to show the Browser.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Check to see if Timeline has focus.
    --------------------------------------------------------------------------------
    local timeline = fcp:timeline()
    local contents = timeline:contents()
    local selectedTimelineClips = contents:selectedClipsUI()
    local timelineMode = false
    if timeline:isFocused() then
        log.df("TIMELINE MODE")
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        if #selectedTimelineClips == 0 then
            displayMessage("There are no clips selected in the timeline.\n\nPlease select one or more clips and try again.")
            return
        end
        --------------------------------------------------------------------------------
        -- If the timeline has focus, reveal the first clip in the browser:
        --------------------------------------------------------------------------------
        fcp:selectMenu({"File", "Reveal in Browser"})
        doUntil(function()
            return #libraries:selectedClipsUI() == 1
        end, 5, 0.1)
        --------------------------------------------------------------------------------
        -- We're now in timeline mode:
        --------------------------------------------------------------------------------
        timelineMode = true
    end

    --------------------------------------------------------------------------------
    -- Get number of Selected Browser Clips:
    --------------------------------------------------------------------------------
    local clips = libraries:selectedClipsUI()
    if not timelineMode and #clips == 0 then
        displayMessage("There are no clips selected in the browser.\n\nPlease select one or more clips and try again.")
        return
    end

    --------------------------------------------------------------------------------
    -- Check to see if the playhead is moving:
    --------------------------------------------------------------------------------
    local wasPlaying = fcp:timeline():isPlaying()

    --------------------------------------------------------------------------------
    -- Check to see if we're in Filmstrip or List View:
    --------------------------------------------------------------------------------
    local filmstripView = false
    if libraries:isFilmstripView() then
        filmstripView = true
        libraries:toggleViewMode()
        if wasPlaying then fcp:menu():selectMenu({"View", "Playback", "Play"}) end
    end

    --------------------------------------------------------------------------------
    -- Get Selected Clip & Selected Clip's Parent:
    --------------------------------------------------------------------------------
    local selectedClips = libraries:selectedClipsUI()
    local selectedClip = selectedClips[1]
    local selectedClipParent = selectedClip:attributeValue("AXParent")

    --------------------------------------------------------------------------------
    -- Get the AXGroup:
    --------------------------------------------------------------------------------
    local listHeadingGroup = axutils.childWithRole(selectedClipParent, "AXGroup")

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
    -- If the 'Notes' column is missing:
    --------------------------------------------------------------------------------
    local notesPressed = false
    if notesFieldID == nil then
        listHeadingGroup:performAction("AXShowMenu")
        local menu = axutils.childWithRole(listHeadingGroup, "AXMenu")
        for i=1, menu:attributeValueCount("AXChildren") do
            if not notesPressed then
                local title = menu[i]:attributeValue("AXTitle")
                if title == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
                    menu[i]:performAction("AXPress")
                    notesPressed = true
                    for ii=1, listHeadingGroup:attributeValueCount("AXChildren") do
                        local xtitle = listHeadingGroup[ii]:attributeValue("AXTitle")
                        if xtitle == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
                            notesFieldID = ii
                        end
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- If the 'Notes' column is missing then error:
    --------------------------------------------------------------------------------
    if notesFieldID == nil then
        dialog.errorMessage(config.appName .. " could not find the Notes Column." .. errorFunction)
        return
    end

    local selectedNotesField = selectedClip[notesFieldID][1]
    local existingValue = selectedNotesField:attributeValue("AXValue")

    --------------------------------------------------------------------------------
    -- Setup Chooser:
    --------------------------------------------------------------------------------
    mod.noteChooser = chooser.new(function(result)
        --------------------------------------------------------------------------------
        -- When Chooser Item is Selected or Closed:
        --------------------------------------------------------------------------------
        doUntil(function()
            mod.noteChooser:hide()
            return mod.noteChooser:isVisible() == false
        end, 5, 0.1)

        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        if not doUntil(function()
            fcp:launch()
            return fcp:isFrontmost()
        end, 5, 0.1) then
            displayErrorMessage("Failed to switch back to Final Cut Pro.")
            return false
        end

        if result ~= nil then
            if timelineMode then
                --------------------------------------------------------------------------------
                -- Timeline Clips:
                --------------------------------------------------------------------------------
                for _, timelineClip in ipairs(selectedTimelineClips) do
                    --------------------------------------------------------------------------------
                    -- Make sure the timeline has focus:
                    --------------------------------------------------------------------------------
                    doUntil(function()
                        fcp:selectMenu({"Window", "Go To", "Timeline"})
                        return contents:isFocused()
                    end, 5, 0.1)

                    --------------------------------------------------------------------------------
                    -- Select the timeline clip:
                    --------------------------------------------------------------------------------
                    contents:selectClip(timelineClip)
                    doUntil(function()
                        local selected = contents:selectedClipsUI()
                        return selected and #selected == 1 and selected[1] == timelineClip
                    end, 5, 0.1)

                    --------------------------------------------------------------------------------
                    -- Reveal in Browser:
                    --------------------------------------------------------------------------------
                    local textField = childWithRole(timelineClip, "AXTextField")
                    local timelineClipName = textField and textField:attributeValue("AXValue")
                    fcp:selectMenu({"File", "Reveal in Browser"})
                    doUntil(function()
                        local selectedClips = libraries:selectedClipsUI()
                        local textField = selectedClips and selectedClips[1] and selectedClips[1][1] and childWithRole(selectedClips[1][1], "AXTextField")
                        local browserClipName = textField and textField:attributeValue("AXValue")
                        return browserClipName and browserClipName == timelineClipName
                    end, 3, 0.1)

                    --------------------------------------------------------------------------------
                    -- Apply note:
                    --------------------------------------------------------------------------------
                    local selectedClip = libraries:selectedClipsUI()[1]
                    local clipNotesField = selectedClip[notesFieldID][1]
                    clipNotesField:setAttributeValue("AXFocused", true)
                    clipNotesField:setAttributeValue("AXValue", result["text"])
                    clipNotesField:setAttributeValue("AXFocused", false)
                    if not filmstripView then
                        eventtap.keyStroke({}, "return") -- List view requires an "return" key press
                    end
                end
            else
                --------------------------------------------------------------------------------
                -- Browser Clips:
                --------------------------------------------------------------------------------
                for _, clip in pairs(selectedClips) do
                    local clipNotesField = clip[notesFieldID][1]
                    clipNotesField:setAttributeValue("AXFocused", true)
                    clipNotesField:setAttributeValue("AXValue", result["text"])
                    clipNotesField:setAttributeValue("AXFocused", false)
                    if not filmstripView then
                        eventtap.keyStroke({}, "return") -- List view requires an "return" key press
                    end
                end
            end

            local selectedRow = mod.noteChooser:selectedRow()

            local recentNotes = mod.recentNotes()
            if selectedRow == 1 then
                table.insert(recentNotes, 1, result)
                mod.recentNotes(recentNotes)
            else
                table.remove(recentNotes, selectedRow)
                table.insert(recentNotes, 1, result)
                mod.recentNotes(recentNotes)
            end
        end

        if filmstripView then
            libraries:toggleViewMode()
        end

        if wasPlaying then fcp:menu():selectMenu({"View", "Playback", "Play"}) end

    end):bgDark(true):query(existingValue):queryChangedCallback(function()
        --------------------------------------------------------------------------------
        -- Chooser Query Changed by User:
        --------------------------------------------------------------------------------
        local recentNotes = mod.recentNotes()

        local currentQuery = mod.noteChooser:query()

        local currentQueryTable = {
            {
                ["text"] = currentQuery
            },
        }

        for i=1, #recentNotes do
            table.insert(currentQueryTable, recentNotes[i])
        end

        mod.noteChooser:choices(currentQueryTable)
        return
    end):rightClickCallback(function()
        --------------------------------------------------------------------------------
        -- Right Click Menu:
        --------------------------------------------------------------------------------
        local rightClickMenu = {
            { title = i18n("clearList"), fn = function()
                log.df("Clearing List")
                mod.recentNotes({})
                local currentQuery = mod.noteChooser:query()
                local currentQueryTable = {
                    {
                        ["text"] = currentQuery
                    },
                }
                mod.noteChooser:choices(currentQueryTable)
            end },
        }
        mod.rightClickMenubar = menubar.new(false)
        mod.rightClickMenubar:setMenu(rightClickMenu)
        mod.rightClickMenubar:popupMenu(mouse.getAbsolutePosition(), true)
    end)

    --------------------------------------------------------------------------------
    -- Allow for Reduce Transparency:
    --------------------------------------------------------------------------------
    if screen.accessibilitySettings()["ReduceTransparency"] then
        mod.noteChooser:fgColor(nil)
                       :subTextColor(nil)
    else
        mod.noteChooser:fgColor(drawing.color.x11.snow)
                       :subTextColor(drawing.color.x11.snow)
    end

    --------------------------------------------------------------------------------
    -- Show Chooser:
    --------------------------------------------------------------------------------
    mod.noteChooser:show()

end

local plugin = {
    id              = "finalcutpro.browser.addnote",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    deps.fcpxCmds
        :add("cpAddNoteToSelectedClips")
        :whenActivated(function() mod.addNoteToSelectedClips() end)

    return mod
end

return plugin
