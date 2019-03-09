--- === plugins.finalcutpro.hud.panels.search ===
---
--- Ten Panel for the Final Cut Pro HUD.

local require                   = require

local log                       = require("hs.logger").new("hudButton")

local dialog                    = require("hs.dialog")
local image                     = require("hs.image")

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

--- plugins.finalcutpro.hud.panels.search.lastValue <cp.prop: string>
--- Variable
--- Last Value
mod.lastValue = config.prop("hud.search.lastValue", "")

--- plugins.finalcutpro.hud.panels.search.lastIndex <cp.prop: number>
--- Variable
--- Last Index
mod.lastIndex = config.prop("hud.search.lastIndex", nil)

--- plugins.finalcutpro.hud.panels.search.lastColumn <cp.prop: string>
--- Variable
--- Last Column
mod.lastColumn = config.prop("hud.search.lastColumn", "Notes")

--- plugins.finalcutpro.hud.panels.search.lastColumn <cp.prop: boolean>
--- Variable
--- Match Case
mod.matchCase = config.prop("hud.search.matchCase", false)

--- plugins.finalcutpro.hud.panels.search.playAfterFind <cp.prop: boolean>
--- Variable
--- Play After Find
mod.playAfterFind = config.prop("hud.search.playAfterFind", false)

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
        ["Codecs"] = "Codecs", -- TODO: we need to find a way of getting the localisation for this.
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
    script = script .. [[changeCheckedByID('matchCase', ]] .. tostring(mod.matchCase()) .. [[);]] .. "\n"
    script = script .. [[changeCheckedByID('playAfterFind', ]] .. tostring(mod.playAfterFind()) .. [[);]] .. "\n"
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
    if tools.trim(searchString) == "" then
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
    -- Make sure the column is showing:
    --------------------------------------------------------------------------------
    if not tableContains(getActiveColumnsNames(), column) then
        if not showColumn(column) then
            popupMessage(i18n("selectedColumnNotShown"), i18n("selectedColumnNotShownDescription"))
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Make sure all the rows are visible:
    --------------------------------------------------------------------------------
    if not findNext and not findPrevious then
        local list = fcp:libraries():list()
        local contentUI = list:contents():contentUI()
        if contentUI then
            for _,child in ipairs(contentUI) do
                if child:attributeValue("AXRole") == "AXRow" and child:attributeValue("AXDisclosureLevel") <= 1 and child:attributeValue("AXDisclosing") == false then
                    child:setAttributeValue("AXDisclosing", true)
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Get column number:
    --------------------------------------------------------------------------------
    local listUI = fcp:libraries():list():UI()
    local scrollAreaUI = listUI and childWithRole(listUI, "AXScrollArea")
    local outlineUI = scrollAreaUI and childWithRole(scrollAreaUI, "AXOutline")
    local groupUI = outlineUI and childWithRole(outlineUI, "AXGroup")
    local buttons = groupUI and childrenWithRole(groupUI, "AXButton")
    if not buttons then
        popupMessage(i18n("selectedColumnNotShown"), i18n("selectedColumnNotShownDescription"))
        return
    end
    local columnNumber
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

    --------------------------------------------------------------------------------
    -- Find our item:
    --------------------------------------------------------------------------------
    local contentUI = fcp:libraries():list():contents():contentUI()
    if contentUI then
        local maxRows = contentUI:attributeValueCount("AXChildren")
        if maxRows and maxRows > 1 then
            local start = 1
            local finish = maxRows
            local direction = 1

            local lastIndex = mod.lastIndex()

            if findNext and lastIndex then
                start = mod.lastIndex() + 1
            end

            if findPrevious and lastIndex then
                start = mod.lastIndex() - 1
                finish = 1
                direction = -1
            end

            for id=start, finish, direction do
                local row = contentUI[id]
                if row and row:attributeValue("AXRole") == "AXRow" then
                    local children = row:attributeValue("AXChildren")
                    local cell = children and children[columnNumber]
                    local textfield = cell and cell[1]
                    local value = textfield and textfield:attributeValue("AXValue")
                    if not mod.matchCase() then
                        value = string.lower(value)
                    end
                    if value and string.find(value, searchString, nil, true) ~= nil then
                        mod.lastIndex(id)
                        fcp:launch()
                        fcp:libraries():list():contents():selectRow(row)
                        fcp:libraries():list():contents():showRow(row)
                        if mod.playAfterFind() then
                            fcp:selectMenu({"View", "Playback", "Play"})
                        end
                        return
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Could not find any matches:
    --------------------------------------------------------------------------------
    popupMessage(i18n("noMatchesFound"), i18n("noMatchesFoundDescription"))
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
    for i, v in pairs(columnNames) do
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
            height      = 240,
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
                mod.lastIndex(nil)
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
            elseif params["type"] == "playAfterFind" then
                mod.playAfterFind(params["playAfterFind"])
            end
        end
        deps.manager.addHandler("hudSearch", controllerCallback)
    end
end

return plugin
