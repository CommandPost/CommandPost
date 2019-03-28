--- === plugins.finalcutpro.browser.layouts ===
---
--- Allows you to save and restore Browser Layouts.
---
--- This plugin creates two different types of actions:
---
--- **Save/Restore Browser Layout to Memory**
--- This feature allows you save and restore five custom browser layouts, which can be
--- easily triggered by a CommandPost action, such as a keyboard shortcut.
---
--- *Save/Restore/Set Browser Layout for Selected Collection**
--- This feature allows you to save a browser layout for the currently selected
--- collection. This feature will only work if a single collection (either Keyword
--- Collection or Smart Collection) is selected - if more than one is selected then
--- you'll just hear an error beep. Once you save a browser layout, then the next time
--- you click on the collection with your mouse, your previously saved browser layout
--- will be automatically restored. Browser layouts are only automatically loaded when
--- you use your mouse - collection layouts won't be loaded if you change collections
--- using keyboard shortcuts. You can also temporarily prevent a browser layout from
--- automatically loading by holding down the OPTION key.
---
--- **Developer Note:**
--- This plugin currently uses a `hs.eventtap` rather than AX Notifications, because in
--- testing we found the AX Notifications to be too unreliable. We also opted to just
--- use the collection name as the reference point, rather than the path to the
--- collection name (i.e. "Edits" instead of
--- "Library Name > Event Name > Folder Name > Collection Name") so that browser
--- layouts can easily be common across multiple libraries (i.e if you always have a
--- Smart Collection called "Edits", then this smart collection will always have the
--- same browser layout across all your libraries.
---
--- We're also currently using the menu position for selecting "Show/Hide All Columns"
--- as the strings for these values are contained within a `.nib` file not a `.strings`
--- file.

local require           = require

local log               = require("hs.logger").new("layouts")

local eventtap          = require("hs.eventtap")
local geometry          = require("hs.geometry")
local timer             = require("hs.timer")

local axutils           = require("cp.ui.axutils")
local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local just              = require("cp.just")
local tools	            = require("cp.tools")

local tableCount        = tools.tableCount
local tableMatch        = tools.tableMatch

local playErrorSound    = tools.playErrorSound

local childrenWithRole  = axutils.childrenWithRole
local childWithRole     = axutils.childWithRole

local doAfter           = timer.doAfter

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- NUMBER_OF_LAYOUTS -> number
-- Constant
-- The number of layouts supported.
local NUMBER_OF_LAYOUTS = 5

-- COLLECTION_LAYOUT_PREFERENCES_KEY -> string
-- Constant
-- The Preferences key for the Collection Layouts.
local COLLECTION_LAYOUT_PREFERENCES_KEY = "finalcutpro.browser.collectionLayout"

-- BROWSER_LAYOUT_PREFERENCES_KEY -> string
-- Constant
-- The Browser Layout Preferences Key.
local BROWSER_LAYOUT_PREFERENCES_KEY = "finalcutpro.browser.layout."

--- plugins.finalcutpro.browser.layouts.busy -> boolean
--- Variable
--- Are we already in the process of doing something?
mod.busy = false

--- plugins.finalcutpro.browser.layouts.setupWatcher() -> none
--- Function
--- Creates or destroys the keyboard watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setupWatcher()
    local collectionLayout = config.get(COLLECTION_LAYOUT_PREFERENCES_KEY, {})
    if tableCount(collectionLayout) >= 1 then
        --------------------------------------------------------------------------------
        -- Start the watcher:
        --------------------------------------------------------------------------------
        if not mod._watcher then
            mod._watcher = eventtap.new({eventtap.event.types.leftMouseDown}, function(event)
                if fcp:isFrontmost() then
                    local ui = fcp:browser():UI()
                    if ui then
                        local browserFrame = ui:attributeValue("AXFrame")
                        local location = event:location() and geometry.point(event:location())
                        if browserFrame and location and location:inside(geometry.rect(browserFrame)) then
                            --------------------------------------------------------------------------------
                            -- We need to add in a delay to give the UI time to update:
                            --------------------------------------------------------------------------------
                            doAfter(0.1, function()
                                mod.restoreBrowserLayoutForSelectedCollection()
                            end)
                        end
                    end
                end
            end):start()
        end
    else
        --------------------------------------------------------------------------------
        -- Destroy the watcher:
        --------------------------------------------------------------------------------
        if mod._watcher then
            mod._watcher:stop()
            mod._watcher = nil
        end
    end
end

--- plugins.finalcutpro.browser.layouts.getClipNameSize() -> string | nil
--- Function
--- Gets the Clip Name Size as a string.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Clip Name Size as a string or `nil` if cannot be found.
function mod.getClipNameSize()
    local menu = fcp:menu()
    if menu:isChecked({"View", "Browser", "Clip Name Size", "Small"}) then
        return "Small"
    elseif menu:isChecked({"View", "Browser", "Clip Name Size", "Medium"}) then
        return "Medium"
    elseif menu:isChecked({"View", "Browser", "Clip Name Size", "Large"}) then
        return "Large"
    end
    return nil
end

--- plugins.finalcutpro.browser.layouts.getActiveColumnsNames() -> table
--- Function
--- Get active column names in a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of active column names or an empty table if something goes wrong.
function mod.getActiveColumnsNames()
    local libraries = fcp:libraries()
    local listUI = libraries:list():UI()
    local scrollAreaUI = listUI and childWithRole(listUI, "AXScrollArea")
    local outlineUI = scrollAreaUI and childWithRole(scrollAreaUI, "AXOutline")
    local groupUI = outlineUI and childWithRole(outlineUI, "AXGroup")
    local buttons = groupUI and childrenWithRole(groupUI, "AXButton")
    if not buttons then
        return {}
    end
    local activeButtons = {}
    for _, button in pairs(buttons) do
        table.insert(activeButtons, button:attributeValue("AXTitle"))
    end
    return activeButtons
end

--- plugins.finalcutpro.browser.layouts.restoreLayoutFromTable(layout) -> boolean
--- Function
--- Restore Layout from Table.
---
--- Parameters:
---  * layout - The layout settings in a table.
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.restoreLayoutFromTable(layout)

    local libraries = fcp:libraries()
    local appearanceAndFiltering = fcp.libraries.appearanceAndFiltering

    --------------------------------------------------------------------------------
    -- Show Libraries:
    --------------------------------------------------------------------------------
    libraries:show()
    if not just.doUntil(function()
        return libraries:isShowing()
    end) then
        log.ef("restoreLayoutFromTable: Failed to show libraries panel.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Clip Name Size:
    --------------------------------------------------------------------------------
    if layout["clipNameSize"] then
        fcp:menu():selectMenu({"View", "Browser", "Clip Name Size", layout["clipNameSize"]})
    end

    --------------------------------------------------------------------------------
    -- Restore List or Filmstrip View:
    --------------------------------------------------------------------------------
    if layout["isListView"] then
        if not just.doUntil(function()
            libraries:list():show()
            return libraries:isListView()
        end) then
            log.ef("restoreLayoutFromTable: Failed to change to list view.")
            return false
        end
    else
        if not just.doUntil(function()
            libraries:filmstrip():show()
            return libraries:isFilmstripView()
        end) then
            log.ef("restoreLayoutFromTable: Failed to change to filmstrip view.")
            return false
        end
    end

    --------------------------------------------------------------------------------
    -- Restore Column Data:
    --------------------------------------------------------------------------------
    if layout["isListView"] and layout["columns"] and #layout["columns"] >= 1 then

        --------------------------------------------------------------------------------
        -- Check to see if we actually need to change the column data:
        --------------------------------------------------------------------------------
        local savedActiveColumnsNames = layout["activeColumnsNames"] or {}
        local activeColumnsNames = mod.getActiveColumnsNames()
        local match = tableMatch(savedActiveColumnsNames, activeColumnsNames)

        --------------------------------------------------------------------------------
        -- We only update the columns if there's columns missing or need to be added:
        --------------------------------------------------------------------------------
        if not match then

            if not just.doUntil(function()
                libraries:list():columns():show()
                return libraries:list():columns():isMenuShowing()
            end) then
                log.ef("restoreLayoutFromTable: Failed to activate the columns menu popup when restoring column data.")
                return false
            end

            local menu = libraries:list():columns():menu()
            if not menu then
                log.ef("restoreLayoutFromTable: Failed to get the columns menu popup.")
                return false
            end

            local menuUI = menu:UI()
            if not menuUI then
                log.ef("restoreLayoutFromTable: Failed to get the columns menu popup UI.")
                return false
            end

            local menuChildren = menuUI:attributeValue("AXChildren")
            if not menuChildren then
                log.ef("restoreLayoutFromTable: Could not get popup menu children.")
                return false
            end

            --------------------------------------------------------------------------------
            -- We press 'Show All Columns' or 'Hide All Columns' if half of the menu items
            -- are different than what has been requested:
            --------------------------------------------------------------------------------
            local threshold = 24/2
            local activeColumnsNamesCount = tableCount(activeColumnsNames)
            local savedActiveColumnsNamesCount = tableCount(savedActiveColumnsNames)
            if (activeColumnsNamesCount > threshold and savedActiveColumnsNamesCount < threshold) or (activeColumnsNamesCount < threshold and savedActiveColumnsNamesCount > threshold) then
                --------------------------------------------------------------------------------
                -- Press 'Show All' or 'Hide All':
                --------------------------------------------------------------------------------
                local success = false
                if tableCount(savedActiveColumnsNames) > 10 then
                    --------------------------------------------------------------------------------
                    -- Show All Columns:
                    --------------------------------------------------------------------------------
                    local showAllUI = menu:UI():attributeValue("AXChildren")[6]
                    if showAllUI then
                        success = showAllUI:performAction("AXPress")
                    end
                else
                    --------------------------------------------------------------------------------
                    -- Hide All Columns:
                    --------------------------------------------------------------------------------
                    local showAllUI = menu:UI():attributeValue("AXChildren")[7]
                    if showAllUI then
                        success = showAllUI:performAction("AXPress")
                    end
                end

                if success then
                    --------------------------------------------------------------------------------
                    -- Wait until menu has disappeared:
                    --------------------------------------------------------------------------------
                    if not just.doUntil(function()
                        return not libraries:list():columns():isMenuShowing()
                    end) then
                        log.ef("restoreLayoutFromTable: Failed to close menu after pressing a button.")
                        return
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Trigger the columns popup:
            --------------------------------------------------------------------------------
            if not just.doUntil(function()
                libraries:list():columns():show()
                return libraries:list():columns():isMenuShowing()
            end) then
                log.ef("restoreLayoutFromTable: Failed to activate the columns menu popup when restoring column data.")
                return false
            end

            --------------------------------------------------------------------------------
            -- Press individual menu items:
            --------------------------------------------------------------------------------
            local numberOfMenuItems = #menuChildren
            for i=1, numberOfMenuItems do

                local menuItem = menu:UI():attributeValue("AXChildren")[i]

                local currentValue = menuItem:attributeValue("AXMenuItemMarkChar") ~= nil
                local savedValue = layout["columns"][i]

                if currentValue ~= savedValue then

                    menuItem:performAction("AXPress")

                    if not just.doUntil(function()
                        return not libraries:list():columns():isMenuShowing()
                    end) then
                        log.ef("restoreLayoutFromTable: Failed to close menu after pressing a button.")
                        return
                    end

                    if not just.doUntil(function()
                        libraries:list():columns():show()
                        return libraries:list():columns():isMenuShowing()
                    end) then
                        log.ef("restoreLayoutFromTable: Failed to activate the columns menu popup in loop.")
                        return
                    end
                end
            end

            menu:close()
        end
    end

    --------------------------------------------------------------------------------
    -- Restore Sort Order:
    --------------------------------------------------------------------------------
    if layout["isListView"] and layout["sortOrder"] then
        local ui = libraries:list():columns():UI()
        local outline = ui and childWithRole(ui, "AXOutline")
        local group = outline and childWithRole(outline, "AXGroup")
        if group then
            local kids = group:attributeValue("AXChildren")
            for _, button in pairs(kids) do
                if layout["sortOrder"][button:attributeValue("AXTitle")] ~= "AXUnknownSortDirection" then
                    --------------------------------------------------------------------------------
                    -- We only need to press the button if it's not already selected:
                    --------------------------------------------------------------------------------
                    if button:attributeValue("AXSortDirection") == "AXUnknownSortDirection" then
                        button:performAction("AXPress")
                    end

                    --------------------------------------------------------------------------------
                    -- We then need to press it again if it's going the wrong direction:
                    --------------------------------------------------------------------------------
                    if layout["sortOrder"][button:attributeValue("AXTitle")] ~= button:attributeValue("AXSortDirection") then
                        button:performAction("AXPress")
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Open the Appearance & Filtering Popup:
    --------------------------------------------------------------------------------
    if not just.doUntil(function()
        appearanceAndFiltering:show()
        return appearanceAndFiltering:isShowing()
    end) then
        log.ef("restoreLayoutFromTable: Could not open the Appearance & Filtering popup.")
        return
    end

    --------------------------------------------------------------------------------
    -- Restore Appearance & Filtering Options:
    --------------------------------------------------------------------------------
    appearanceAndFiltering:clipHeight():value(layout["clipHeight"])
    appearanceAndFiltering:duration():value(layout["duration"])
    appearanceAndFiltering:groupBy():value(layout["groupBy"])
    appearanceAndFiltering:sortBy():value(layout["sortBy"])
    appearanceAndFiltering:waveforms():checked(layout["waveforms"])
    appearanceAndFiltering:continuousPlayback():checked(layout["continuousPlayback"])

    --------------------------------------------------------------------------------
    -- Close the Appearance & Filtering Popup:
    --------------------------------------------------------------------------------
    appearanceAndFiltering:hide()
    if not just.doUntil(function()
        return not appearanceAndFiltering:isShowing()
    end) then
        log.ef("restoreLayoutFromTable: Could not close the Appearance & Filtering popup.")
        return
    end

    return true
end

--- plugins.finalcutpro.browser.layouts.saveLayoutToTable() -> table | boolean
--- Function
--- Save Layout to Table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the layout settings if successful otherwise `false`.
function mod.saveLayoutToTable()

    local libraries = fcp.libraries
    local appearanceAndFiltering = libraries.appearanceAndFiltering

    --------------------------------------------------------------------------------
    -- Show Libraries:
    --------------------------------------------------------------------------------
    libraries:show()
    if not just.doUntil(function()
        return libraries:isShowing()
    end) then
        log.ef("saveLayoutToTable: Failed to show libraries panel.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Are we currently in list view?
    --------------------------------------------------------------------------------
    local isListView = libraries:isListView()

    --------------------------------------------------------------------------------
    -- Save Column Data:
    --------------------------------------------------------------------------------
    local columnResult = {}
    if isListView then

        --------------------------------------------------------------------------------
        -- Open the Columns popup:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            libraries:list():columns():show()
            return libraries:list():columns():isMenuShowing()
        end) then
            log.ef("saveLayoutToTable: Failed to activate the columns menu popup when saving.")
            return false
        end

        local menu = libraries:list():columns():menu()
        if not menu then
            log.ef("saveLayoutToTable: Failed to get the columns menu popup.")
            return false
        end

        local menuUI = menu:UI()
        if not menuUI then
            log.ef("saveLayoutToTable: Failed to get the columns menu popup UI.")
            return false
        end

        local menuChildren = menuUI:attributeValue("AXChildren")

        for i, menuItem in pairs(menuChildren) do
            columnResult[i] = menuItem:attributeValue("AXMenuItemMarkChar") ~= nil
        end

        --------------------------------------------------------------------------------
        -- Close the Columns popup:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            menu:close()
            return not libraries:list():columns():isMenuShowing()
        end) then
            log.ef("saveLayoutToTable: Failed to close the columns menu popup when saving.")
            return false
        end

    end

    --------------------------------------------------------------------------------
    -- Save Column Sorting Order:
    --------------------------------------------------------------------------------
    local sortOrder = {}
    if isListView then
        local ui = libraries:list():columns():UI()
        local outline = ui and childWithRole(ui, "AXOutline")
        local group = outline and childWithRole(outline, "AXGroup")
        if group then
            local kids = group:attributeValue("AXChildren")
            for _, button in pairs(kids) do
                local title = button:attributeValue("AXTitle")
                local direction = button:attributeValue("AXSortDirection")
                sortOrder[title] = direction
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Open the Appearance & Filtering Popup:
    --------------------------------------------------------------------------------
    if not just.doUntil(function()
        appearanceAndFiltering:show()
        return appearanceAndFiltering:isShowing()
    end) then
        log.ef("saveLayoutToTable: Could not open the Appearance & Filtering popup.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Get Active Column Names:
    --------------------------------------------------------------------------------
    local activeColumnsNames = mod.getActiveColumnsNames()

    --------------------------------------------------------------------------------
    -- Save Appearance & Filtering Options:
    --------------------------------------------------------------------------------
    local result = {
        ["clipNameSize"] = mod.getClipNameSize(),
        ["columns"] = columnResult,
        ["activeColumnsNames"] = activeColumnsNames,
        ["sortOrder"] = sortOrder,
        ["isListView"] = isListView,
        ["clipHeight"] = appearanceAndFiltering:clipHeight():value(),
        ["duration"] = appearanceAndFiltering:duration():value(),
        ["groupBy"] = appearanceAndFiltering:groupBy():value(),
        ["sortBy"] = appearanceAndFiltering:sortBy():value(),
        ["waveforms"] = appearanceAndFiltering:waveforms():checked(),
        ["continuousPlayback"] = appearanceAndFiltering:continuousPlayback():checked(),
    }

    --------------------------------------------------------------------------------
    -- Close the Appearance & Filtering Popup:
    --------------------------------------------------------------------------------
    appearanceAndFiltering:hide()
    if not just.doUntil(function()
        return not appearanceAndFiltering:isShowing()
    end) then
        log.ef("saveLayoutToTable: Could not close the Appearance & Filtering popup.")
        return
    end

    return result
end

--- plugins.finalcutpro.browser.layouts.getSingleSelectedCollection() -> string | nil
--- Function
--- If a single collection is selected in the browser it's value is returned as a string.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string if successful otherwise `nil`.
function mod.getSingleSelectedCollection()
    local selectedRowsUI = fcp:libraries():sidebar():selectedRowsUI()
    if selectedRowsUI and #selectedRowsUI == 1 and childWithRole(selectedRowsUI[1], "AXTextField") then
        return childWithRole(selectedRowsUI[1], "AXTextField"):attributeValue("AXValue")
    end
    return nil
end

--- plugins.finalcutpro.browser.layouts.restoreBrowserLayoutForSelectedCollection() -> none
--- Function
--- Restore Browser Layout for selected collection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
--- Notes:
---  * An error sound will play if there's nothing to restore.
function mod.restoreBrowserLayoutForSelectedCollection()
    local value = mod.getSingleSelectedCollection()
    if value then
        local collectionLayout = config.get(COLLECTION_LAYOUT_PREFERENCES_KEY, {})
        local selectedCollection = collectionLayout[value]
        if selectedCollection and not eventtap.checkKeyboardModifiers()["alt"] then
            if mod.lastCollection == value then
                --------------------------------------------------------------------------------
                -- Collection is already loaded:
                --------------------------------------------------------------------------------
                return
            end
            mod.lastCollection = value
            if not mod.restoreLayoutFromTable(selectedCollection) then
                playErrorSound()
                return
            end
        else
            mod.lastCollection = value
        end
    end
end

--- plugins.finalcutpro.browser.layouts.saveBrowserLayoutForSelectedCollection() -> none
--- Function
--- Save Browser Layout for selected collection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
--- Notes:
---  * An error sound will play if there's nothing to save.
function mod.saveBrowserLayoutForSelectedCollection()
    local value = mod.getSingleSelectedCollection()
    if value then
        local collectionLayout = config.get(COLLECTION_LAYOUT_PREFERENCES_KEY, {})
        local result = mod.saveLayoutToTable()
        if result then
            collectionLayout[value] = mod.saveLayoutToTable()
            config.set(COLLECTION_LAYOUT_PREFERENCES_KEY, collectionLayout)
            mod.setupWatcher()
            return
        end
    end
    playErrorSound()
end

--- plugins.finalcutpro.browser.layouts.resetBrowserLayoutForSelectedCollection() -> none
--- Function
--- Reset Browser Layout for selected collection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
--- Notes:
---  * An error sound will play if there's nothing to reset.
function mod.resetBrowserLayoutForSelectedCollection()
    local value = mod.getSingleSelectedCollection()
    if value then
        local collectionLayout = config.get(COLLECTION_LAYOUT_PREFERENCES_KEY, {})
        collectionLayout[value] = nil
        config.set(COLLECTION_LAYOUT_PREFERENCES_KEY, collectionLayout)
        mod.setupWatcher()
    else
        playErrorSound()
    end
end

--- plugins.finalcutpro.browser.layouts.lastCollection -> string | nil
--- Variable
--- The last collection registered.
mod.lastCollection = mod.getSingleSelectedCollection()

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.browser.layouts",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Mouse Watcher:
    --------------------------------------------------------------------------------
    mod.setupWatcher()

    --------------------------------------------------------------------------------
    -- Save/Restore Browser Layout to Memory Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    for id=1, NUMBER_OF_LAYOUTS do
        fcpxCmds
            :add("saveBrowserLayoutToMemory" .. id)
            :titled(i18n("saveBrowserLayoutToMemory") .. " " .. id)
            :groupedBy("browser")
            :whenActivated(function()
                if mod.busy then return end
                mod.busy = true
                local result = mod.saveLayoutToTable()
                if result then
                    config.set(BROWSER_LAYOUT_PREFERENCES_KEY .. id, result)
                else
                    playErrorSound()
                end
                mod.busy = false
            end)

        fcpxCmds
            :add("restoreBrowserLayoutToMemory" .. id)
            :titled(i18n("restoreBrowserLayoutToMemory") .. " " .. id)
            :groupedBy("browser")
            :whenActivated(function()
                if mod.busy then return end
                mod.busy = true
                local layout = config.get(BROWSER_LAYOUT_PREFERENCES_KEY .. id)
                if not mod.restoreLayoutFromTable(layout) then
                    playErrorSound()
                end
                mod.busy = false
            end)
    end

    --------------------------------------------------------------------------------
    -- Save/Restore Browser Layout for Selected Collection Commands:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("saveBrowserLayoutForSelectedCollection")
        :groupedBy("browser")
        :whenActivated(function()
            if mod.busy then return end
            mod.busy = true
            mod.saveBrowserLayoutForSelectedCollection()
            mod.busy = false
        end)

    fcpxCmds
        :add("restoreBrowserLayoutForSelectedCollection")
        :groupedBy("browser")
        :whenActivated(function()
            if mod.busy then return end
            mod.busy = true
            mod.restoreBrowserLayoutForSelectedCollection()
            mod.busy = false
        end)

    fcpxCmds
        :add("resetBrowserLayoutForSelectedCollection")
        :groupedBy("browser")
        :whenActivated(function()
            if mod.busy then return end
            mod.busy = true
            mod.resetBrowserLayoutForSelectedCollection()
            mod.busy = false
        end)

    return mod

end

return plugin
