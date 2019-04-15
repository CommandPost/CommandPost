--- === plugins.finalcutpro.browser.addnote ===
---
--- Add Note Plugin.

local require = require

local log                               = require("hs.logger").new("addnote")

local chooser                           = require("hs.chooser")
local drawing                           = require("hs.drawing")
local eventtap                          = require("hs.eventtap")
local menubar                           = require("hs.menubar")
local mouse                             = require("hs.mouse")
local screen                            = require("hs.screen")

local axutils                           = require("cp.ui.axutils")
local config                            = require("cp.config")
local fcp                               = require("cp.apple.finalcutpro")
local dialog                            = require("cp.dialog")
local i18n                              = require("cp.i18n")


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
function mod.addNoteToSelectedClip()

    local errorFunction = " Error occurred in addNoteToSelectedClip()."

    --------------------------------------------------------------------------------
    -- Make sure the Browser is visible:
    --------------------------------------------------------------------------------
    local libraries = fcp:browser():libraries()
    if not libraries:isShowing() then
        log.df("Library Panel is closed." .. errorFunction)
        return false
    end

    --------------------------------------------------------------------------------
    -- Get number of Selected Browser Clips:
    --------------------------------------------------------------------------------
    local clips = libraries:selectedClipsUI()
    if #clips ~= 1 then
        log.df("Wrong number of clips selected." .. errorFunction)
        return false
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
    local selectedClip = libraries:selectedClipsUI()[1]
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
        mod.noteChooser:hide()
        fcp:launch()

        if result ~= nil then
            selectedNotesField:setAttributeValue("AXFocused", true)
            selectedNotesField:setAttributeValue("AXValue", result["text"])
            selectedNotesField:setAttributeValue("AXFocused", false)
            if not filmstripView then
                eventtap.keyStroke({}, "return") -- List view requires an "return" key press
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
        :add("cpAddNoteToSelectedClip")
        :whenActivated(function() mod.addNoteToSelectedClip() end)

    return mod
end

return plugin
