--- === plugins.finalcutpro.hud.panels.search ===
---
--- Ten Panel for the Final Cut Pro HUD.

local require                   = require

local log                       = require("hs.logger").new("hudButton")

local dialog                    = require("hs.dialog")
local image                     = require("hs.image")
local menubar                   = require("hs.menubar")
local mouse                     = require("hs.mouse")

local axutils                   = require("cp.ui.axutils")
local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")
local i18n                      = require("cp.i18n")
local just                      = require("cp.just")
local tools                     = require("cp.tools")

local childrenWithRole          = axutils.childrenWithRole
local childWithRole             = axutils.childWithRole
local doUntil                   = just.doUntil
local iconFallback              = tools.iconFallback
local imageFromPath             = image.imageFromPath
local tableContains             = tools.tableContains
local webviewAlert              = dialog.webviewAlert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- MAXIMUM_HISTORY -> number
-- Constant
-- The Maximum Number of History items.
local MAXIMUM_HISTORY = 5

-- MAXIMUM_LOOPS -> number
-- Constant
-- The Maximum amount of times we'll do the loop of doom.
local MAXIMUM_LOOPS = 500

--- plugins.finalcutpro.hud.panels.search.lastValue <cp.prop: string>
--- Variable
--- Last Value
mod.lastValue = config.prop("hud.search.lastValue", "")

--- plugins.finalcutpro.hud.panels.search.lastColumn <cp.prop: string>
--- Variable
--- Last Column
mod.lastColumn = config.prop("hud.search.lastColumn", "Name")

--- plugins.finalcutpro.hud.panels.search.matchCase <cp.prop: boolean>
--- Variable
--- Match Case
mod.matchCase = config.prop("hud.search.matchCase", false)

--- plugins.finalcutpro.hud.panels.search.matchWords <cp.prop: boolean>
--- Variable
--- Match Case
mod.matchWords = config.prop("hud.search.matchWords", true)

--- plugins.finalcutpro.hud.panels.search.filterBrowserBeforeSearch <cp.prop: boolean>
--- Variable
--- Filter Browser Before Search
mod.filterBrowserBeforeSearch = config.prop("hud.search.filterBrowserBeforeSearch", false)

--- plugins.finalcutpro.hud.panels.search.wholeWords <cp.prop: boolean>
--- Variable
--- Whole Words
mod.wholeWords = config.prop("hud.search.wholeWords", false)

--- plugins.finalcutpro.hud.panels.search.playAfterFind <cp.prop: boolean>
--- Variable
--- Play After Find
mod.playAfterFind = config.prop("hud.search.playAfterFind", false)

--- plugins.finalcutpro.hud.panels.search.loopSearch <cp.prop: boolean>
--- Variable
--- Loop Search
mod.loopSearch = config.prop("hud.search.loopSearch", false)

--- plugins.finalcutpro.hud.panels.search.openProject <cp.prop: boolean>
--- Variable
--- Open Project
mod.openProject = config.prop("hud.search.openProject", false)

--- plugins.finalcutpro.hud.panels.search.history <cp.prop: table>
--- Variable
--- Search History
mod.history = config.prop("hud.search.history", {})

-- getColumnNames() -> table
-- Function
-- Gets a table of column names.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table.
local function getColumnNames()
    return {
        ["All"] = i18n("allVisibleColumns"),
        ["Name"] = fcp:string("Name"),
        ["Start"] = fcp:string("Start"),
        ["End"] = fcp:string("End"),
        ["Duration"] = fcp:string("Duration"),
        ["Content Created"] = fcp:string("content created"),
        ["Camera Angle"] = fcp:string("Camera Angle"),
        ["Notes"] = fcp:string("Notes"),
        ["Video Roles"] = fcp:string("Video Roles"),
        ["Audio Roles"] = fcp:string("Audio Roles"),
        ["Camera Name"] = fcp:string("Camera Name"),
        ["Reel"] = fcp:string("Reel"),
        ["Scene"] = fcp:string("Scene"),
        ["Shot/Take"] = fcp:string("FFNamingTokenShotTake"),
        ["Media Start"] = fcp:string("Media Start"),
        ["Media End"] = fcp:string("Media End"),
        ["Frame Size"] = fcp:string("Frame Size"),
        ["Video Frame Rate"] = fcp:string("Video Frame Rate"),
        ["Audio Output Channels"] = fcp:string("Audio Channel Count"),
        ["Audio Sample Rate"] = fcp:string("Audio Sample Rate"),
        ["Audio Configuration"] = fcp:string("Audio Channel Config"),
        ["File Type"] = fcp:string("file type"),
        ["Date Imported"] = fcp:string("Date Imported"),
        ["Codecs"] = fcp:string("CPCodecs"),
        ["360° Mode"] = fcp:string("FFOrganizerFilterHUDFormatInfoSphericalType"),
        ["Stereoscopic Mode"] = fcp:string("FFMD3DStereoMode"),
    }
end

-- getActiveColumnsNames() -> table
-- Function
-- Get active column names in a table.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of active column names or an empty table if something goes wrong.
local function getActiveColumnsNames()
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

-- showColumn() -> table
-- Function
-- Show the "Notes" Column in the Browser.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful otherwise `false`.
local function showColumn(column)
    if not doUntil(function()
        fcp:launch()
        return fcp:isFrontmost()
    end, 5, 0.1) then
        log.ef("showColumn: Failed to switch back to Final Cut Pro.")
        return false
    end

    local libraries = fcp:libraries()
    if not doUntil(function()
        libraries:list():columns():show()
        return libraries:list():columns():isMenuShowing()
    end) then
        log.ef("showColumn: Failed to activate the columns menu popup when restoring column data.")
        return false
    end

    local menu = libraries:list():columns():menu()
    if not menu then
        log.ef("showColumn: Failed to get the columns menu popup.")
        return false
    end

    local menuUI = menu:UI()
    if not menuUI then
        log.ef("showColumn: Failed to get the columns menu popup UI.")
        return false
    end

    local menuChildren = menuUI:attributeValue("AXChildren")
    if not menuChildren then
        log.ef("showColumn: Could not get popup menu children.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Press individual menu items:
    --------------------------------------------------------------------------------
    local numberOfMenuItems = #menuChildren
    for i=1, numberOfMenuItems do
        local menuItem = menu:UI():attributeValue("AXChildren")[i]
        local columnNames = getColumnNames()
        if menuItem:attributeValue("AXTitle") == columnNames[column] then
            local result = menuItem:performAction("AXPress")
            if not doUntil(function()
                return not libraries:list():columns():isMenuShowing()
            end) then
                log.ef("showColumn: Failed to close menu after pressing a button.")
                return
            end
            return result
        end
    end
    menu:close()
end

-- updateInfo() -> none
-- Function
-- Update the Buttons Panel HTML content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateInfo()
    local script = [[changeValueByID("searchField", "]] .. mod.lastValue() .. [[");]] .. "\n"
    script = script .. [[changeCheckedByID('matchWords', ]] .. tostring(mod.matchWords()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('matchCase', ]] .. tostring(mod.matchCase()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('wholeWords', ]] .. tostring(mod.wholeWords()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('playAfterFind', ]] .. tostring(mod.playAfterFind()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('filterBrowserBeforeSearch', ]] .. tostring(mod.filterBrowserBeforeSearch()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('loopSearch', ]] .. tostring(mod.loopSearch()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('openProject', ]] .. tostring(mod.openProject()) .. [[);]] .. "\n"
    script = script .. [[focusOnSearchField();]] .. "\n"
    mod._manager.injectScript(script)
end

-- popupMessage(a, b) -> none
-- Function
-- Popup a message on the HUD webview.
--
-- Parameters:
--  * a - Main message as string.
--  * b - Secondary message as string.
--
-- Returns:
--  * None
local function popupMessage(a, b)
    local webview = mod._manager._webview
    if webview then
        webviewAlert(webview, function() end, a, b, i18n("ok"))
    end
end

-- doesMatch(source, find) -> boolean
-- Function
-- Does Match?
--
-- Parameters:
--  * source - The source string.
--  * find - The string to search the source for.
--
-- Returns:
--  * `true` if matched, otherwise `false`
local function doesMatch(source, find)
    return string.find(source, find, nil, true) ~= nil
end

-- doesMatchWholeWord(source, find) -> boolean
-- Function
-- Does Match Whole Word?
--
-- Parameters:
--  * source - The source string.
--  * find - The string to search the source for.
--
-- Returns:
--  * `true` if matched, otherwise `false`.
local function doesMatchWholeWord(source, find)
    if source and find then
        local a, b = string.find(source, find, nil, true)
        if source == find then
            return true
        end
        if a == 1 then
            if b == string.len(source) then
                return true
            else
                if string.sub(source, b + 1, b + 1) == " " then
                    return true
                end
            end
        end
        if b == string.len(source) then
            if string.sub(source, a - 1, a - 1) == " " then
                return true
            end
        end
        if a and b and string.len(source) > string.len(find) + 2 then
            if string.sub(source, a - 1, a - 1) == " " and string.sub(source, b + 1, b + 1) == " " then
                return true
            end
        end
    end
    return false
end

-- doesMatchWords(source, find) -> boolean
-- Function
-- Does Match Words?
--
-- Parameters:
--  * source - The source string.
--  * find - The string to search the source for.
--
-- Returns:
--  * `true` if matched, otherwise `false`
local function doesMatchWords(source, find)
    if source and find then
        for word in find:gmatch("%S+") do
            if not string.find(source, word, nil, true) then
                return false
            end
        end
        return true
    else
        return false
    end
end

-- process(cell, isProject) -> boolean
-- Function
-- Process a cell.
--
-- Parameters:
--  * cell - The UI element to process.
--  * isProject - Is it a project?
--
-- Returns:
--  * `true` if matched, otherwise `false`
local function process(cell, row, searchString, isProject)
    local matchCase         = mod.matchCase()
    local matchWords        = mod.matchWords()
    local wholeWords        = mod.wholeWords()
    local openProject       = mod.openProject()
    local playAfterFind     = mod.playAfterFind()

    local textfield
    if cell and cell[1]:attributeValue("AXRole") == "AXImage" then
        if cell[1]:attributeValue("AXDescription") == "F General ObjectGlyphs Project" then
            isProject = true
        else
            isProject = false
        end
        textfield = cell[2]
    else
        textfield = cell and cell[1]
    end

    local value
    if textfield and textfield:attributeValue("AXRole") == "AXMenuButton" then
        value = textfield and textfield:attributeValue("AXTitle")
    else
        value = textfield and textfield:attributeValue("AXValue")
    end

    if not matchCase then
        value = value and string.lower(value)
    end

    if value
    and (not wholeWords and matchWords and doesMatch(value, searchString))
    or  (wholeWords and not matchWords and doesMatchWholeWord(value, searchString))
    or  (not matchWords and not wholeWords and doesMatchWords(value, searchString))
    or  (matchWords and wholeWords and doesMatchWholeWord(value, searchString)) then
        fcp:launch()
        if not fcp:libraries():isFocused() then
            fcp:selectMenu({"Window", "Go To", "Libraries"})
        end
        fcp:libraries():list():contents():selectRow(row)
        fcp:libraries():list():contents():showRow(row)
        if openProject and isProject then
            fcp:selectMenu({"Clip", "Open Clip"})
        end
        if playAfterFind then
            if not fcp:viewer():isPlaying() and not fcp:eventViewer():isPlaying() then
                fcp:selectMenu({"View", "Playback", "Play"})
            end
        end
        return true
    end

    return false
end

-- find(value) -> none
-- Function
-- Find a string in the Notes section of the Browser.
--
-- Parameters:
--  * searchString - The string to search for.
--  * column - The name of the column to search as a string
--
-- Returns:
--  * None
local function find(searchString, column, findNext, findPrevious)
    --------------------------------------------------------------------------------
    -- Make sure the value is valid:
    --------------------------------------------------------------------------------
    if searchString and tools.trim(searchString) == "" then
        popupMessage(i18n("invalidSearchField"), i18n("invalidSearchFieldDescription"))
        return
    end

    --------------------------------------------------------------------------------
    -- Keep it lowercase unless we're matching case:
    --------------------------------------------------------------------------------
    if not mod.matchCase() then
        searchString = string.lower(searchString)
    end

    --------------------------------------------------------------------------------
    -- Add it to the history if it's unique:
    --------------------------------------------------------------------------------
    local history = mod.history()
    if not tableContains(history, searchString) then
        while (#(history) >= MAXIMUM_HISTORY) do
            table.remove(history,1)
        end
        table.insert(history, searchString)
        mod.history(history)
    end

    --------------------------------------------------------------------------------
    -- Make sure we're in list view:
    --------------------------------------------------------------------------------
    local libraries = fcp:libraries()
    if not doUntil(function()
        libraries:list():show()
        return libraries:isListView()
    end) then
        popupMessage(i18n("selectedColumnNotShown"), i18n("selectedColumnNotShownDescription"))
        return
    end

    --------------------------------------------------------------------------------
    -- Filter Browser Before Search:
    --------------------------------------------------------------------------------
    if mod.filterBrowserBeforeSearch() then
        --------------------------------------------------------------------------------
        -- Ensure the Search Bar is visible
        --------------------------------------------------------------------------------
        if not libraries:search():isShowing() then
            libraries:searchToggle():press()
        end

        --------------------------------------------------------------------------------
        -- Search for the title
        --------------------------------------------------------------------------------
        if libraries:search():value() ~= searchString then
            libraries:search():setValue(searchString)
        end
    end

    --------------------------------------------------------------------------------
    -- Make sure the column is showing (assuming we're not looking "all" columns):
    --------------------------------------------------------------------------------
    if column ~= i18n("allVisibleColumns") then
        if not tableContains(getActiveColumnsNames(), column) then
            if not showColumn(column) then
                popupMessage(i18n("selectedColumnNotShown"), i18n("selectedColumnNotShownDescription"))
                return
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Get column number:
    --------------------------------------------------------------------------------
    local columnNumber
    if column ~= i18n("allVisibleColumns") then
        local listUI = fcp:libraries():list():UI()
        local scrollAreaUI = listUI and childWithRole(listUI, "AXScrollArea")
        local outlineUI = scrollAreaUI and childWithRole(scrollAreaUI, "AXOutline")
        local groupUI = outlineUI and childWithRole(outlineUI, "AXGroup")
        local buttons = groupUI and childrenWithRole(groupUI, "AXButton")
        if not buttons then
            popupMessage(i18n("selectedColumnNotShown"), i18n("selectedColumnNotShownDescription"))
            return
        end
        for i, button in pairs(buttons) do
            if button:attributeValue("AXTitle") == column then
                columnNumber = i
                break
            end
        end
        if not columnNumber then
            popupMessage(i18n("selectedColumnNotShown"), i18n("selectedColumnNotShownDescription"))
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Check each row:
    --------------------------------------------------------------------------------
    local loopCount = 0
    local loopSearch = mod.loopSearch()
    local firstAttempt = true
    local currentRowID
    local contents = fcp:libraries():list():contents()
    local contentUI = contents:contentUI() -- Returns an AXOutline, which holds the rows
    if contentUI then

        --------------------------------------------------------------------------------
        -- Use the currently selected row otherwise start at 0:
        --------------------------------------------------------------------------------
        local rows = contentUI:attributeValue("AXChildren")
        local selectedRows = contentUI:attributeValue("AXSelectedRows")
        if selectedRows and next(selectedRows) then
            currentRowID = axutils.childIndex(rows, selectedRows[#selectedRows])
        else
            currentRowID = 0
        end

        --------------------------------------------------------------------------------
        -- Increase or decrease the current row ID depending on whether we're going
        -- forward or backward:
        --------------------------------------------------------------------------------
        if findPrevious then
            currentRowID = currentRowID - 1
        else
            currentRowID = currentRowID + 1
        end

        --------------------------------------------------------------------------------
        -- Begin the loop of doom:
        --------------------------------------------------------------------------------
        local eof = false
        repeat
            loopCount = loopCount + 1
            --------------------------------------------------------------------------------
            -- It's a row:
            --------------------------------------------------------------------------------
            local row = contents:contentUI()[currentRowID]
            if row and row:attributeValue("AXRole") == "AXRow" then
                if row:attributeValue("AXDisclosureLevel") <= 1 and row:attributeValue("AXDisclosing") == false then
                    row:setAttributeValue("AXDisclosing", true)
                    row = contents:contentUI()[currentRowID] -- Update the row data
                end

                --------------------------------------------------------------------------------
                -- Searching all visible columns:
                --------------------------------------------------------------------------------
                if column == i18n("allVisibleColumns") then
                    local isProject = false
                    local children = row:attributeValue("AXChildren")
                    for _, cell in pairs(children) do
                        local result, lastProject = process(cell, row, searchString, isProject)
                        isProject = lastProject
                        if result then
                            return
                        end
                    end
                --------------------------------------------------------------------------------
                -- Searching a specific column:
                --------------------------------------------------------------------------------
                else
                    local isProject = false
                    local children = row:attributeValue("AXChildren")
                    local cell = children and children[columnNumber]
                    if process(cell, row, searchString, isProject) then
                        return
                    end
                end

                --------------------------------------------------------------------------------
                -- Increase or decrease the current row ID depending on whether we're going
                -- forward or backward:
                --------------------------------------------------------------------------------
                if findPrevious then
                    currentRowID = currentRowID - 1
                else
                    currentRowID = currentRowID + 1
                end

            --------------------------------------------------------------------------------
            -- There's no more rows left:
            --------------------------------------------------------------------------------
            else
                if loopSearch and firstAttempt then
                    firstAttempt = false
                    if findNext then
                        currentRowID = 1
                    else
                        currentRowID = contents:contentUI():attributeValueCount("AXRows")
                    end
                else
                   eof = true
                end
            end
        until (eof == true or loopCount > MAXIMUM_LOOPS)
    end

    if loopCount > MAXIMUM_LOOPS then
        --------------------------------------------------------------------------------
        -- Aborted:
        --------------------------------------------------------------------------------
        popupMessage(i18n("searchAborted"), i18n("searchAbortedDescription"))
    else
        --------------------------------------------------------------------------------
        -- Could not find any matches:
        --------------------------------------------------------------------------------
        popupMessage(i18n("noMatchesFound"), i18n("noMatchesFoundDescription"))
    end

end

-- getEnv() -> table
-- Function
-- Set up the template environment.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function getEnv()
    local env = {}

    --------------------------------------------------------------------------------
    -- Generate Column Names List:
    --------------------------------------------------------------------------------
    local columnNames = getColumnNames()
    local options = ""
    for i, v in tools.spairs(columnNames) do
        local selected = ""
        if mod.lastColumn() == i then
            selected = [[ selected="selected" ]]
        end
        options = options .. [[<option ]] .. selected .. [[value="]] .. i .. [[">]] .. v .. [[</option>]] .. "\n"
    end
    env.options = options

    env.i18n = i18n
    return env
end

-- showHistoryPopup() -> none
-- Function
-- Shows the History Popup.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function showHistoryPopup()
    local menu = {}
    local history = mod.history()

    for _, v in pairs(history) do
        table.insert(menu, {
            title = v,
            fn = function()
                local script = [[changeValueByID("searchField", "]] .. v .. [[");]] .. "\n"
                script = script .. [[focusOnSearchField();]] .. "\n"
                mod._manager.injectScript(script)
            end,
        })
    end

    if next(history) then
        table.insert(menu, {
            title = "-"
        })

        table.insert(menu, {
            title = i18n("clearHistory"),
            fn = function() mod.history({}) end
        })
    else
        table.insert(menu, {
            title = i18n("historyIsEmpty"),
            disabled = true,
        })
    end

    local popup = menubar.new()
    popup:setMenu(menu)
    popup:removeFromMenuBar()
    popup:popupMenu(mouse.getAbsolutePosition(), true)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud.panels.search",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]     = "manager",
        ["core.action.manager"]         = "actionManager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then

        mod._manager = deps.manager
        mod._actionManager = deps.actionManager

        local panel = deps.manager.addPanel({
            priority    = 2.1,
            id          = "search",
            label       = i18n("search"),
            tooltip     = i18n("search"),
            image       = imageFromPath(iconFallback(env:pathToAbsolute("/images/search.png"))),
            height      = 345,
            loadedFn    = updateInfo,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(getEnv()) end, false)

        --------------------------------------------------------------------------------
        -- Setup Controller Callback:
        --------------------------------------------------------------------------------
        local controllerCallback = function(_, params)
            local value = params["value"]
            local column = params["column"]
            local columnID = params["columnID"]
            if params["type"] == "find" then
                find(value, column, false, false)
            elseif params["type"] == "findNext" then
                find(value, column, true, false)
            elseif params["type"] == "findPrevious" then
                find(value, column, false, true)
            elseif params["type"] == "clear" then
                mod.lastValue("")
                updateInfo()
            elseif params["type"] == "update" then
                if value then
                    mod.lastValue(value)
                end
                if column then
                    mod.lastColumn(columnID)
                end
            elseif params["type"] == "matchCase" then
                mod.matchCase(params["matchCase"])
            elseif params["type"] == "matchWords" then
                mod.matchWords(params["matchWords"])
            elseif params["type"] == "wholeWords" then
                mod.wholeWords(params["wholeWords"])
            elseif params["type"] == "playAfterFind" then
                mod.playAfterFind(params["playAfterFind"])
            elseif params["type"] == "loopSearch" then
                mod.loopSearch(params["loopSearch"])
            elseif params["type"] == "filterBrowserBeforeSearch" then
                mod.filterBrowserBeforeSearch(params["filterBrowserBeforeSearch"])
            elseif params["type"] == "openProject" then
                mod.openProject(params["openProject"])
            elseif params["type"] == "history" then
                showHistoryPopup()
            end
        end
        deps.manager.addHandler("hudSearch", controllerCallback)
    end
end

return plugin
