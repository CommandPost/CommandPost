--- === plugins.finalcutpro.browser.layouts ===
---
--- Allows you to save and restore Browser Layouts.

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

local delayedTimer      = timer.delayed
local childWithRole     = axutils.childWithRole

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local NUMBER_OF_LAYOUTS = 5

function mod.setupWatcher()
    local collectionLayout = config.get("finalcutpro.browser.collectionLayout", {})
    if tools.tableCount(collectionLayout) >= 1 then
        --------------------------------------------------------------------------------
        -- Start the watcher:
        --------------------------------------------------------------------------------
        if not mod._watcher then
            log.df("STARTING THE WATCHER")
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
                            timer.doAfter(0.1, function()
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
            log.df("DESTROYING THE WATCHER")
            mod._watcher:stop()
            mod._watcher = nil
        end
    end
end

function mod.getClipNameSize()
    local menu = fcp:menu()
    if menu:isChecked({"View", "Browser", "Clip Name Size", "Small"}) then
        return "Small"
    elseif menu:isChecked({"View", "Browser", "Clip Name Size", "Medium"}) then
        return "Medium"
    elseif menu:isChecked({"View", "Browser", "Clip Name Size", "Large"}) then
        return "Large"
    end
end

function mod.restoreLayoutFromTable(layout)

    local libraries = fcp:libraries()
    local appearanceAndFiltering = fcp:libraries():appearanceAndFiltering()

    --------------------------------------------------------------------------------
    -- Show Libraries:
    --------------------------------------------------------------------------------
    libraries:show()
    if not just.doUntil(function()
        return libraries:isShowing()
    end) then
        tools.playErrorSound()
        log.ef("Failed to show libraries panel.")
        return
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
            tools.playErrorSound()
            log.ef("Failed to change to list view.")
            return
        end
    else
        if not just.doUntil(function()
            libraries:filmstrip():show()
            return libraries:isFilmstripView()
        end) then
            tools.playErrorSound()
            log.ef("Failed to change to filmstrip view.")
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Restore Column Data:
    --------------------------------------------------------------------------------
    if layout["isListView"] and layout["columns"] and #layout["columns"] >= 1 then

        if not just.doUntil(function()
            libraries:list():columns():show()
            return libraries:list():columns():isMenuShowing()
        end) then
            tools.playErrorSound()
            log.ef("Failed to activate the columns menu popup when restoring column data.")
            return
        end

        local menu = libraries:list():columns():menu()
        if not menu then
            tools.playErrorSound()
            log.ef("Failed to get the columns menu popup.")
            return
        end

        local menuUI = menu:UI()
        if not menuUI then
            tools.playErrorSound()
            log.ef("Failed to get the columns menu popup UI.")
            return
        end

        local menuChildren = menuUI:attributeValue("AXChildren")
        if not menuChildren then
            tools.playErrorSound()
            log.ef("Could not get popup menu children.")
            return
        end

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
                    tools.playErrorSound()
                    log.ef("Failed to close menu after pressing a button.")
                    return
                end

                if not just.doUntil(function()
                    libraries:list():columns():show()
                    return libraries:list():columns():isMenuShowing()
                end) then
                    tools.playErrorSound()
                    log.ef("Failed to activate the columns menu popup in loop.")
                    return
                end
            end
        end

        menu:close()

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
                    button:performAction("AXPress")
                    if layout["sortOrder"][button:attributeValue("AXTitle")] ~= button:attributeValue("AXSortDirection") then
                        button:performAction("AXPress")
                    end
                    if layout["sortOrder"][button:attributeValue("AXTitle")] ~= button:attributeValue("AXSortDirection") then
                        button:performAction("AXPress")
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Restore Appearance & Filtering Options:
    --------------------------------------------------------------------------------
    if not just.doUntil(function()
        appearanceAndFiltering:show()
        return appearanceAndFiltering:isShowing()
    end) then
        tools.playErrorSound()
        log.ef("Could not open the Appearance & Filtering popup.")
        return
    end

    appearanceAndFiltering:clipHeight():value(layout["clipHeight"])
    appearanceAndFiltering:duration():value(layout["duration"])
    appearanceAndFiltering:groupBy():value(layout["groupBy"])
    appearanceAndFiltering:sortBy():value(layout["sortBy"])
    appearanceAndFiltering:waveforms():checked(layout["waveforms"])
    appearanceAndFiltering:continuousPlayback():checked(layout["continuousPlayback"])

    appearanceAndFiltering:hide()
end

function mod.saveLayoutToTable()

    local libraries = fcp:libraries()
    local appearanceAndFiltering = fcp:libraries():appearanceAndFiltering()

    --------------------------------------------------------------------------------
    -- Show Libraries:
    --------------------------------------------------------------------------------
    libraries:show()
    if not just.doUntil(function()
        return libraries:isShowing()
    end) then
        tools.playErrorSound()
        log.ef("Failed to show libraries panel.")
        return
    end

    --------------------------------------------------------------------------------
    -- Save Clip Name Size:
    --------------------------------------------------------------------------------
    local getClipNameSize = function()
        local menu = fcp:menu()
        if menu:isChecked({"View", "Browser", "Clip Name Size", "Small"}) then
            return "Small"
        elseif menu:isChecked({"View", "Browser", "Clip Name Size", "Medium"}) then
            return "Medium"
        elseif menu:isChecked({"View", "Browser", "Clip Name Size", "Large"}) then
            return "Large"
        end
    end

    local isListView = libraries:isListView()

    --------------------------------------------------------------------------------
    -- Save Column Data:
    --------------------------------------------------------------------------------
    local columnResult = {}
    if isListView then

        if not just.doUntil(function()
            libraries:list():columns():show()
            return libraries:list():columns():isMenuShowing()
        end) then
            tools.playErrorSound()
            log.ef("Failed to activate the columns menu popup when saving.")
            return
        end

        local menu = libraries:list():columns():menu()
        if not menu then
            tools.playErrorSound()
            log.ef("Failed to get the columns menu popup.")
            return
        end

        local menuUI = menu:UI()
        if not menuUI then
            tools.playErrorSound()
            log.ef("Failed to get the columns menu popup UI.")
            return
        end

        local menuChildren = menuUI:attributeValue("AXChildren")

        for i, menuItem in pairs(menuChildren) do
            columnResult[i] = menuItem:attributeValue("AXMenuItemMarkChar") ~= nil
        end

        menu:close()

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
    -- Save Appearance & Filtering Options:
    --------------------------------------------------------------------------------
    if not just.doUntil(function()
        appearanceAndFiltering:show()
        return appearanceAndFiltering:isShowing()
    end) then
        tools.playErrorSound()
        log.ef("Could not open the Appearance & Filtering popup.")
        return
    end

    local result = {
        ["clipNameSize"] = mod.getClipNameSize(),
        ["columns"] = columnResult,
        ["sortOrder"] = sortOrder,
        ["isListView"] = isListView,
        ["clipHeight"] = appearanceAndFiltering:clipHeight():value(),
        ["duration"] = appearanceAndFiltering:duration():value(),
        ["groupBy"] = appearanceAndFiltering:groupBy():value(),
        ["sortBy"] = appearanceAndFiltering:sortBy():value(),
        ["waveforms"] = appearanceAndFiltering:waveforms():checked(),
        ["continuousPlayback"] = appearanceAndFiltering:continuousPlayback():checked(),
    }

    appearanceAndFiltering:hide()

    return result
end


function mod.getSingleSelectedCollection()
    local selectedRowsUI = fcp:libraries():sidebar():selectedRowsUI()
    if selectedRowsUI and #selectedRowsUI == 1 and childWithRole(selectedRowsUI[1], "AXTextField") then
        return childWithRole(selectedRowsUI[1], "AXTextField"):attributeValue("AXValue")
    end
    return nil
end

function mod.restoreBrowserLayoutForSelectedCollection()
    local value = mod.getSingleSelectedCollection()
    if value then
        local collectionLayout = config.get("finalcutpro.browser.collectionLayout", {})
        local selectedCollection = collectionLayout[value]
        if selectedCollection then
            if mod.lastCollection == value then
                log.df("we already have this collection loaded")
                return
            end
            mod.restoreLayoutFromTable(selectedCollection)
            mod.lastCollection = value
            return
        end
    end
    tools.playErrorSound()
end

function mod.saveBrowserLayoutForSelectedCollection()

    local value = mod.getSingleSelectedCollection()

    if value then
        local collectionLayout = config.get("finalcutpro.browser.collectionLayout", {})
        local result = mod.saveLayoutToTable()
        if result then
            collectionLayout[value] = mod.saveLayoutToTable()
            config.set("finalcutpro.browser.collectionLayout", collectionLayout)
            log.df("VICTORY!")
            mod.setupWatcher()
            return
        end
    else
        tools.playErrorSound()
        log.ef("More than one collection selected.")
        return
    end
end

function mod.resetBrowserLayoutForSelectedCollection()
    local value = mod.getSingleSelectedCollection()
    if value then
        local collectionLayout = config.get("finalcutpro.browser.collectionLayout", {})
        collectionLayout[value] = nil
        config.set("finalcutpro.browser.collectionLayout", collectionLayout)
        mod.setupWatcher()
        log.df("VICTORY!")
    else
        log.df("Nothing to reset")
        tools.playErrorSound()
    end
end

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
                local result = mod.saveLayoutToTable()
                if result then
                    config.set("finalcutpro.browser.layout." .. id, result)
                end
            end)

        fcpxCmds
            :add("restoreBrowserLayoutToMemory" .. id)
            :titled(i18n("restoreBrowserLayoutToMemory") .. " " .. id)
            :groupedBy("browser")
            :whenActivated(function()
                local layout = config.get("finalcutpro.browser.layout." .. id)
                if not mod.restoreLayoutFromTable(layout) then
                    tools.playErrorSound()
                end
            end)
    end

    --------------------------------------------------------------------------------
    -- Save/Restore Browser Layout for Selected Collection Commands:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("saveBrowserLayoutForSelectedCollection")
        :groupedBy("browser")
        :whenActivated(mod.saveBrowserLayoutForSelectedCollection)

    fcpxCmds
        :add("restoreBrowserLayoutForSelectedCollection")
        :groupedBy("browser")
        :whenActivated(mod.restoreBrowserLayoutForSelectedCollection)

    fcpxCmds
        :add("resetBrowserLayoutForSelectedCollection")
        :groupedBy("browser")
        :whenActivated(mod.resetBrowserLayoutForSelectedCollection)

    return mod

end

return plugin
