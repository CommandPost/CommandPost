--- === plugins.finalcutpro.browser.layouts ===
---
--- Allows you to save and restore Browser Layouts.

local require   = require

local log       = require("hs.logger").new("layouts")

local geometry  = require("hs.geometry")

local axutils   = require("cp.ui.axutils")
local config    = require("cp.config")
local fcp       = require("cp.apple.finalcutpro")
local i18n      = require("cp.i18n")
local just      = require("cp.just")
local tools	    = require("cp.tools")

local childWithRole = axutils.childWithRole

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

    local NUMBER_OF_LAYOUTS = 5

    local fcpxCmds = deps.fcpxCmds
    local libraries = fcp:libraries()
    local appearanceAndFiltering = fcp:libraries():appearanceAndFiltering()

    --------------------------------------------------------------------------------
    -- Save Layout:
    --------------------------------------------------------------------------------
    local saveLayout = function(id)

        if not libraries:isShowing() then
            tools.playErrorSound()
            return
        end

        local isListView = libraries:isListView()

        --------------------------------------------------------------------------------
        -- Save Column Data:
        --------------------------------------------------------------------------------
        local columnResult = {}
        if isListView then

            libraries:list():columns():show()

            if not just.doUntil(function()
                return libraries:list():columns():isMenuShowing()
            end) then
                tools.playErrorSound()
                log.ef("Failed to activate the columns menu popup.")
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

        log.df("SAVING: %s", hs.inspect(result))

        config.set("finalcutpro.browser.layout." .. id, result)

    end

    --------------------------------------------------------------------------------
    -- Restore Layout:
    --------------------------------------------------------------------------------
    local restoreLayout = function(id)

        local layout = config.get("finalcutpro.browser.layout." .. id)

        --log.df("RESTORING: %s", hs.inspect(layout))

        if not layout then
            tools.playErrorSound()
            return
        end

        if not libraries:isShowing() then
            tools.playErrorSound()
            return
        end

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
            libraries:list():columns():show()

            if not just.doUntil(function()
                return libraries:list():columns():isMenuShowing()
            end) then
                tools.playErrorSound()
                log.ef("Failed to activate the columns menu popup.")
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

                --log.df("currentValue: %s, savedValue: %s", currentValue, savedValue)

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
                        log.df("FOUND BUTTON: %s", button:attributeValue("AXTitle"))
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

    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
    for id=1, NUMBER_OF_LAYOUTS do
        fcpxCmds
            :add("saveBrowserLayoutToMemory" .. id)
            :titled(i18n("saveBrowserLayoutToMemory") .. " " .. id)
            :groupedBy("browser")
            :whenActivated(function() saveLayout(id) end)

        fcpxCmds
            :add("restoreBrowserLayoutToMemory" .. id)
            :titled(i18n("restoreBrowserLayoutToMemory") .. " " .. id)
            :groupedBy("browser")
            :whenActivated(function() restoreLayout(id) end)
    end

end

return plugin
