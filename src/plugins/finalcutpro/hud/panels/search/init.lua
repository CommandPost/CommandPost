--- === plugins.finalcutpro.hud.panels.search ===
---
--- Ten Panel for the Final Cut Pro HUD.

local require                   = require

local log                       = require("hs.logger").new("hudButton")

local dialog                    = require("hs.dialog")
local image                     = require("hs.image")
local inspect                   = require("hs.inspect")
local menubar                   = require("hs.menubar")
local mouse                     = require("hs.mouse")

local axutils                   = require("cp.ui.axutils")
local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")
local i18n                      = require("cp.i18n")
local json                      = require("cp.json")
local just                      = require("cp.just")
local tools                     = require("cp.tools")

local cleanupButtonText         = tools.cleanupButtonText
local iconFallback              = tools.iconFallback
local imageFromPath             = image.imageFromPath
local stringMaxLength           = tools.stringMaxLength
local webviewAlert              = dialog.webviewAlert

local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local tableMatch                = tools.tableMatch

local playErrorSound            = tools.playErrorSound

local childrenWithRole          = axutils.childrenWithRole
local childWithRole             = axutils.childWithRole

local doUntil                   = just.doUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.general.openErrorLogOnDockClick <cp.prop: boolean>
--- Variable
--- Open Error Log on Dock Icon Click.
mod.lastValue = config.prop("hud.search.lastValue", "")

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

local function showNotesColumn()

    if not doUntil(function()
        fcp:launch()
        return fcp:isFrontmost()
    end, 5, 0.1) then
        log.ef("showNotesColumn: Failed to switch back to Final Cut Pro.")
        return false
    end

    local libraries = fcp:libraries()
    if not just.doUntil(function()
        libraries:list():columns():show()
        return libraries:list():columns():isMenuShowing()
    end) then
        log.ef("showNotesColumn: Failed to activate the columns menu popup when restoring column data.")
        return false
    end

    local menu = libraries:list():columns():menu()
    if not menu then
        log.ef("showNotesColumn: Failed to get the columns menu popup.")
        return false
    end

    local menuUI = menu:UI()
    if not menuUI then
        log.ef("showNotesColumn: Failed to get the columns menu popup UI.")
        return false
    end

    local menuChildren = menuUI:attributeValue("AXChildren")
    if not menuChildren then
        log.ef("showNotesColumn: Could not get popup menu children.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Press individual menu items:
    --------------------------------------------------------------------------------
    local numberOfMenuItems = #menuChildren
    for i=1, numberOfMenuItems do

        local menuItem = menu:UI():attributeValue("AXChildren")[i]

        if menuItem:attributeValue("AXValue") == fcp:string("FFInspectorModuleProjectPropertiesNotes") then
            local result = menuItem:performAction("AXPress")

            if not just.doUntil(function()
                return not libraries:list():columns():isMenuShowing()
            end) then
                log.ef("restoreLayoutFromTable: Failed to close menu after pressing a button.")
                return
            end

            return result
        end
    end
    menu:close()
end

--- plugins.finalcutpro.hud.panels.search.updateInfo() -> none
--- Function
--- Update the Buttons Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
local function updateInfo()
    local script = [[changeValueByID("searchField", "]] .. mod.lastValue() .. [[");]] .. "\n"
    mod._manager.injectScript(script)
end

local function find(value)
    if tools.trim(value) == "" then
        local webview = mod._manager._webview
        if webview then
            webviewAlert(webview, function() end, "The search field looks invalid.", "Please check what you've written in the search field and try again.", i18n("ok"))
        end
        return
    end

    fcp:browser():libraries():list():show()

    local activeColumnsNames = getActiveColumnsNames()

    if not tableContains(activeColumnsNames, fcp:string("FFInspectorModuleProjectPropertiesNotes")) then
       local result = showNotesColumn()
       if not result then
            local webview = mod._manager._webview
            if webview then
                webviewAlert(webview, function() end, "The Notes column could not be shown.", "Please make sure the notes column is visible and try again.", i18n("ok"))
            end
            return
       end
    end

    --log.df("activeColumnsNames: %s", hs.inspect(activeColumnsNames))


end

local function findNext(value)

end

local function findPrevious(value)

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
            priority    = 3,
            id          = "search",
            label       = "Search",
            tooltip     = "Search",
            image       = imageFromPath(iconFallback(env:pathToAbsolute("/images/search.png"))),
            height      = 200,
            loadedFn    = updateInfo,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel() end, false)

        --------------------------------------------------------------------------------
        -- Setup Controller Callback:
        --------------------------------------------------------------------------------
        local controllerCallback = function(_, params)
            local value = params["value"]
            if params["type"] == "find" then
                find(value)
            elseif params["type"] == "findNext" then
                findNext(value)
            elseif params["type"] == "findPrevious" then
                findPrevious(value)
            elseif params["type"] == "clear" then
                mod.lastValue("")
                updateInfo()
            elseif params["type"] == "update" and value then
                mod.lastValue(value)
            end
        end
        deps.manager.addHandler("hudSearch", controllerCallback)
    end
end

return plugin
